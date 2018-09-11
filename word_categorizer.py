# R = Regular word (a-z only)
# T1, T2, etc. = Typo likely in regular word; number gives edit
#                distance to nearest common dictionary word
# TS = Typo likely in regular word; probably two words that need to be
#      split by space or dash
# C = Chemistry
# P = Pattern of some kind (rhyme scheme, reduplication)
# D = DNA sequence
# N = Numbers or punctuation
# I = International (non-ASCII characters)

from collections import defaultdict
import difflib
import enchant
import fileinput
from nltk.metrics import distance
import re
from sectionalizer import get_word


enchant_en = enchant.Dict("en_US")  # en_GB seems to give US dictionary
az_re = re.compile("^[a-z]+$", flags=re.I)
az_plus_re = re.compile("^[a-z|\d|\-]+$", flags=re.I)
ag_re = re.compile("^[a-g]+$")
mz_re = re.compile("[m-z]")
dna_re = re.compile("^[acgt]+$")
chem_re = re.compile(
    "(\d+\-|"
    "mono|di|bi|tri|tetr|pent|hex|hept|oct|nona|deca|"
    "methyl|phenyl|acetate|ene|ine|ane|ide|hydro|nyl|ate$|ium$|acetyl|"
    "gluco|aminyl|galacto|pyro|benz|brom|amino|fluor|glycer|cholester|ase$|"
    "chlor|oxy|nitr|silic|phosph|nickel|copper|iron|carb|sulf|alumin|arsen|magnesium|mercury|lead|calcium|"
    "propyl|itol|ethyl|oglio|stearyl|alkyl|ethan|amine|ether|keton|oxo|pyri|ine$|"
    "cyclo|poly|iso)")


# Note: This may malfunction slightly if there are commas inside the
# chemical name.
# https://en.wikipedia.org/wiki/IUPAC_nomenclature_of_inorganic_chemistry
# https://en.wikipedia.org/wiki/IUPAC_nomenclature_of_organic_chemistry
# https://en.wikipedia.org/wiki/Chemical_nomenclature
def is_chemistry_word(word):
    small_word = chem_re.sub("", word)
    if len(word) > 14:
        if len(small_word) < len(word) * .50:
            return True
    if len(small_word) < len(word) * .25:
        return True
    return False


def is_rhyme_scheme(word):
    word = word.lower()
    points = 0

    if word == "abab" or word == "cdcd" or word == "efef":
        return True

    if ag_re.match(word):
        points += 50
    if mz_re.search(word):
        points -= 30
    substring_counts = defaultdict(int)
    for i in range(0, len(word)):
        if i < len(word) - 1:
            substring2 = word[i:i + 2]
            substring_counts[substring2] += 1
        if i < len(word) - 2:
            substring3 = word[i:i + 3]
            substring_counts[substring3] += 1

    repeated_substrings = 0
    for (sequence, instances) in substring_counts.items():
        if sequence[0] == sequence[1]:
            points += 10
        if instances > 1:
            repeated_substrings += 1
            points += 10
    if repeated_substrings / len(substring_counts) > .5:
        points += 50

    if points > 100:
        return True
    return False


# Returns False if not near a common word, or integer edit distance to
# closest word, or "S" for word split
def near_common_word(word):
    close_matches = difflib.get_close_matches(word, enchant_en.suggest(word))
    if close_matches:
        if " " in close_matches[0] or "-" in close_matches[0]:
            return "S"
        return distance.edit_distance(word, close_matches[0], transpositions=True)
    return False
# Other spell check and spelling suggestion libraries:
# https://textblob.readthedocs.io/en/dev/quickstart.html#spelling-correction
#  -> based on NLTK and http://norvig.com/spell-correct.html
# https://pypi.org/project/autocorrect/
#  from autocorrect import spell
#  print(spell('caaaar'))
# https://github.com/wolfgarbe/SymSpell


def get_word_category(word):
    category = None
    if az_plus_re.match(word):
        if dna_re.match(word):
            category = "D"
        elif is_chemistry_word(word):
            category = "C"
        elif is_rhyme_scheme(word):
            category = "P"
        elif az_re.match(word):
            edit_distance = near_common_word(word)
            if edit_distance:
                category = "T" + str(edit_distance)
            else:
                category = "R"
        else:
            category = "N"
    else:
        category = "I"
    return category


if __name__ == '__main__':
    for line in fileinput.input("-"):
        line = line.strip()

        length = None
        word = None

        if "\t" in line:
            (length, word) = line.split("\t")
        else:
            word = get_word(line)

        category = get_word_category(word)

        if length:
            print("%s\t* %s [https://en.wikipedia.org/w/index.php?search=%s %s]"
                  % (category, length, word, word))
        else:
            print("%s\t%s" % (category, line))
