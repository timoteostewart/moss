# head /backup/whata/home/beland/moss/run-c600526+2019-08-26T20\:46\:38-dump-2019-08-20/done/tmp-articles-linked-words.txt | python3 t1-extractor.py

import fileinput
import re
import string

from sectionalizer import sectionalize_lines

unsorted = [
    "BW",
    # TODO: BW needs to ignore italics and capital letters for "You"
    # in titles etc.  See [[1947]], [[1972 in film]]

    "W",
    # TODO: Contractions like "I'm" are mixed in, should be in BW
    # Most of these need {{lang}}

    "I",
    # TODO: "/" and other punctuation needs to be sorted out

    "MW",
    "MI",
    # TODO: Making compounds that combine English and non-English
    # words lets a lot of misspellings in.  Non-English words need
    # {{lang}} anyway.

    "Z", "R", "N", "P", "H", "U", "TS"]
probably_wrong = ["T1", "TS+DOT", "TS+COMMA", "TS+BRACKET", "TS+EXTRA", "T2", "T3", "HB", "HL", "BC"]
probably_right = ["L", "ME", "C", "D"]

line_parser_re = re.compile(r"^(.*?)\t\* \d+ - \[\[(.*?)\]\] - (.*$)")
first_letters = ["BEFORE A"] + [letter for letter in string.ascii_uppercase] + ["AFTER Z"]
typos_by_letter = {
    letter: {type_: [] for type_ in probably_wrong}
    for letter in first_letters
}
before_a = {"0", "1", "2", "3", "4", "5", "6", "7", "8", "9"}
comma_missing_ws_re = re.compile(r"\w,\w")
extra_ws_re = re.compile(r"\w ,\w|\w .\w|\w \)\w|\w\( \w|\w\[ \w|\w ]\w")
bracket_missing_ws_re = re.compile(r"\w[\[\]\(\)]\w")


def get_first_letter(input_string):
    if input_string[0] in first_letters:
        return input_string[0]
    if input_string[0] in before_a:
        return "BEFORE A"
    return "AFTER Z"


for line in fileinput.input("-"):
    line = line.strip()
    if line.startswith("* 0 -"):
        continue
    groups = line_parser_re.match(line)
    if not groups:
        print(f"FAILED TO PARSE: '{line}'")
    types = groups[1].split(",")
    article_title = groups[2]
    typo_links = groups[3].split(", ")

    for (index, typo_link) in enumerate(typo_links):
        if types[index] == "TS" and "." in typo_link:
            types[index] = "TS+DOT"
        if types[index] == "TS" and comma_missing_ws_re.search(typo_link):
            types[index] = "TS+COMMA"
        if types[index] == "TS" and extra_ws_re.search(typo_link):
            types[index] = "TS+EXTRA"
        if types[index] == "TS" and bracket_missing_ws_re.search(typo_link):
            types[index] = "TS+BRACKET"

    if any(type_ in unsorted for type_ in types):
        continue

    best_type = None
    for type_ in probably_wrong:
        if type_ in types:
            best_type = type_
            break

    if not best_type:
        # Ignore any article that does have at least one probably wrong typo
        continue
    typos_by_letter[get_first_letter(article_title)][best_type].append((article_title, types, typo_links))


def clean_typo_link(typo_link):
    core = typo_link.replace("[[wikt:", "")
    core = core.replace("]]", "")
    if any(substring in core for substring in ["&lt;", "[", "]"]):
        typo_link = core
    return typo_link


for (letter, typos_by_best_type) in typos_by_letter.items():
    print(f"= {letter} =")
    for (best_type, tuple_list) in typos_by_best_type.items():
        print(f"=== {best_type}+ ===")
        output_lines = []
        for (article_title, types, typo_links) in sorted(tuple_list):
            bad_typo_links = []
            not_typo_links = []
            for (index, type_) in enumerate(types):
                if type_ in probably_wrong:
                    bad_typo_links.append(clean_typo_link(typo_links[index]))
                else:
                    not_typo_links.append(clean_typo_link(typo_links[index]))
            output_line = f'* {len(typo_links)} - [[{article_title}]] - {", ".join(bad_typo_links)}'
            if not_typo_links:
                output_line += f'  (probably OK: {", ".join(not_typo_links)})'
            output_lines.append(output_line)
        print(sectionalize_lines(output_lines))
