#!/usr/bin/bash

# Run time for commit 2ec07e4: 4h30m to start of readability report,
#  5h50m overall (8-core parallel, big-bucks)
# Run time for commit 17ca7d3: ~4h to start of readability report,
#  5.5h overall (8-core parallel, big-bucks)
# Run time for commit c6ce3ab: ~26h (whata)
# Run time for commit 5e6b2ce: 21h 18m (whata)
# Run time for commit 10512ac: 23h 19m (whata)
# Run time for commit 4933ad4: 22h 00m (whata) +/- 10 min
# Run time for commit e20e070: 19h 47m (whata)
# Run time: 12h 38m (whata)
# Run time for commit e317dab: 3 hours (free-spin)
# Run time for commit 57a461: 22 hours (big-bucks)

set -e

RUN_NAME=run-`git log | head -c 14 | perl -pe "s/commit //"`+`date "+%Y-%m-%dT%T"`
mkdir $RUN_NAME
cd $RUN_NAME

# --- HTML ENTITIES ---

echo "Beginning HTML entity check"
echo `date`

# Run time for this segment: ~1 h 20 min (8-core parallel)

# ../venv/bin/python3 ../moss_entity_check.py | ../venv/bin/python3 ../summarizer.py --find-all > post-entities.txt
../venv/bin/python3 ../moss_entity_check.py > tmp-entities
cat tmp-entities | ../venv/bin/python3 ../summarizer.py --find-all > post-entities.txt
# "Worst" report disabled because it's mostly [[MOS:STRAIGHT]]
# violations, which are not a priority.
# ../venv/bin/python3 ../moss_entity_check.py > tmp-entities.txt
# mv tmp-worst.txt post-entities.txt
# cat tmp-entities.txt | ../venv/bin/python3 ../summarizer.py --find-all >> post-entities.txt

# --- PRIME ---

echo "Beginning prime template check"
echo `date`

# Incorrect template usage
../venv/bin/python3 ../dump_grep_csv.py "\{\{prime\}\}" | perl -pe 's/^(.*?):.*/$1/' | uniq | sort > jwb-articles-prime.txt
../venv/bin/python3 ../dump_grep_csv.py "\{\{prime\|'" | perl -pe 's/^(.*?):.*/$1/' | uniq | sort >> jwb-articles-prime.txt

# Can be converted to {{coord}} or {{sky}} or {{prime}}
../venv/bin/python3 ../dump_grep_csv.py "[0-9]+° ?[0-9]+['′] ?" | perl -pe 's/^(.*?):.*/$1/' | uniq | sort >> jwb-articles-prime.txt

# --- FRAC REPAIR ---

# Run time for this segment: ~15 min (8-core parallel)

echo "Beginning {{frac}} repair scan"
echo `date`

../venv/bin/python3 ../dump_grep_csv.py '[0-9]\{\{frac\|[0-9]+\|' | perl -pe 's/^(.*?):.*/$1/' | uniq | sort > jwb-frac-repair.txt

# --- TEMPERATURE CONVERSION ---

# Run time for this segment: ~1 h 30 min (8-core parallel)

echo "Beginning temperature conversion scan"
echo `date`

# per [[MOS:UNITSYMBOLS]]

# Need to convert to C:
../venv/bin/python3 ../dump_grep_csv.py '°F' | perl -pe "s/\{\{([Cc]onvert|[Cc]vt).*?\}\}//g" | grep -vP '°C.{0,30}°F' | grep -vP '°F.{0,30}°C' | grep -vP "(min|max|mean)_temp_[0-9]" | grep "°F" | sort > tmp-temperature-convert1.txt

../venv/bin/python3 ../dump_grep_csv.py '[ \(][0-9](C|F)[^a-zA-Z0-9]' | grep -iP "weather|temperature" | sort > tmp-temperature-convert2.txt
../venv/bin/python3 ../dump_grep_csv.py "[0-9]+s?( |&nbsp;)(C|F)[^a-zA-Z0-9]" | grep -iP "weather|temperature" | sort > tmp-temperature-convert3.txt
../venv/bin/python3 ../dump_grep_csv.py "degrees? \[*(C|c|F)" | perl -pe "s%<ref.*?</ref>%%g" | grep -P "degrees? \[*(C|c|F)" | sort > tmp-temperature-convert4.txt
../venv/bin/python3 ../dump_grep_csv.py '[0-9]°' | grep -iP "heat|chill|weather" | sort > tmp-temperature-convert4b.txt
../venv/bin/python3 ../dump_grep_csv.py '[0-9][0-9],' | grep -iP "weather=" | sort > tmp-temperature-convert4c.txt

#
../venv/bin/python3 ../dump_grep_csv.py "[0-9]0s( |&nbsp;)?F[^b-z]" | grep -vP "[0-9]{3}0s" | perl -pe "s%<ref.*?</ref>%%g" | grep -v "Celsius" | grep "0s" | sort > tmp-temperature-convert5.txt
../venv/bin/python3 ../dump_grep_csv.py "(low|lower|mid|middle|high|upper|the)[ \-][0-9][0-9]?0s" | perl -pe "s%<ref.*?</ref>%%g" | grep -v "Celsius" | grep -i "temperature" | grep "0s" | sort > tmp-temperature-convert6.txt

# low 40s F (~5°C)
# mid 40s F (~7°C)
# high 40s F (~9°C)
# low 50s F (~11°C)
# mid 50s F (~13°C)
# high 50s F (~14°C)
# low 60s F (~16°C)
# mid 60s F (~18°C)
# high 60s F (~20°C)
# low 70s F (~22°C)
# mid 70s F (~24°C)
# high 70s F (~25°C)
# low 80s F (~27°C)
# mid 80s F (~29°C)
# high 80s F (~31°C)
# low 90s F (~33°C)
# mid 90s F (~35°C)
# high 90s F (~36°C)
#
# F  C
# 40 4.4
# 45 7.2
# 50 10
# 55 12.8
# 60 15.5
# 65 18.3
# 70 21.1
# 75 23.8
# 80 26.7
# 85 29.4
# 90 32.2
# 95 35
# 100 37.8

cat tmp-temperature-convert1.txt tmp-temperature-convert2.txt tmp-temperature-convert3.txt tmp-temperature-convert4.txt tmp-temperature-convert4b.txt tmp-temperature-convert4c.txt tmp-temperature-convert5.txt tmp-temperature-convert6.txt | perl -pe 's/^(.*?):.*/$1/' | uniq > jwb-temperature-convert.txt

# --- SPEED CONVERSION ---

# [[MOS:UNITNAMES]]

echo "Beginning speed conversion scan"
echo `date`

../venv/bin/python3 ../dump_grep_csv.py 'mph|MPH' | perl -pe "s/\{\{([Cc]onvert|[Cc]vt).*?\}\}//g" | perl -pe "s%<ref.*?</ref>%%g" | grep -vP 'km/h.{0,30}mph' | grep -vP 'mph.{0,30}km/h' | grep -iP "\bmph\b" | grep -v ", MPH" | grep -iP "(speed|mile|[0-9](&nbsp;| )MPH)" | grep -v "mph=" | sort > tmp-mph-convert.txt
cat tmp-mph-convert.txt | perl -pe 's/^(.*?):.*/$1/' | uniq > jwb-speed-convert.txt

../venv/bin/python3 ../dump_grep_csv.py '[0-9](&nbsp;| )?kph|KPH' | sort > tmp-kph-convert.txt

# --- MORE METRIC CONVERSIONS ---

# TODO:
# * miles
# * pounds (weight vs. money)
# * tons (various)
# * hp
# * gallons (various)

# --- FUEL EFFICIENCY CONVERSION ---

echo "Beginning MPG conversion scan"
echo `date`

../venv/bin/python3 ../dump_grep_csv.py 'mpg|MPG' | perl -pe "s/\{\{([Cc]onvert|[Cc]vt).*?\}\}//g" | perl -pe "s%<ref.*?</ref>%%g" | grep -iP "\bmpg\b" | grep -iP "[0-9]( |&nbsp;)mpg" | grep -vP 'L/100.{0,30}mpg' | grep -vP 'mpg.{0,30}L/100'| sort > tmp-mpg-convert.txt
cat tmp-mpg-convert.txt | perl -pe 's/^(.*?):.*/$1/' | uniq > jwb-mpg-convert.txt

# TODO: DEPENDING ON CONTEXT, WILL NEED:
# {{convert|$1|mpgus|abbr=on}}
# {{convert|$1|mpgimp|abbr=on}}

# --- BROKEN NBSP ---

# Run time for this segment: ~21 min (8-core parallel)

echo "Beginning broken nbsp scan"
echo `date`

../venv/bin/python3 ../dump_grep_csv.py "&nbsp[^;}]" | grep -vP 'https?:[^ ]+&nbsp' | perl -pe 's/^(.*?):.*/$1/' | uniq | sort > beland-broken-nbsp.txt

# --- MOS:LOGICAL ---

# Run time for this segment: ~10 min (8-core parallel)

echo "Beginning MOS:LOGICAL scan"
echo `date`
../venv/bin/python3 ../dump_grep_csv.py '"[a-z ,:\-;]+[,\.]"' | perl -pe 's/^(.*?):.*/$1/' | uniq | sort | uniq > beland-MOS-LOGICAL.txt

# --- MOS:DOUBLE ---

# Run time for this segment: ~20 min

echo "Beginning MOS:DOUBLE scan"
echo `date`
../venv/bin/python3 ../dump_grep_csv.py " '[A-Za-z ,:\-;]+'[,\. \}\)]" | grep -v '"' | grep -vP "{{([Ll]ang|[Tt]ransl|IPA)" | perl -pe 's/^(.*?):.*/$1/' > tmp-MOS-double.txt
cat tmp-MOS-double.txt | perl ../count.pl | sort -rn > tmp-double-most.txt
grep -vP "(grammar|languag|species| words)" tmp-double-most.txt | perl -pe "s/^\d+\t//" | head -1000 > jwb-double-most.txt


# --- MAIN SPELL CHECK ---

# Run time for this segment: ~4 h 10 min (8-core parallel)

echo "Beginning main spell check"
echo `date`

../venv/bin/python3 ../moss_spell_check.py > tmp-output.txt

# --- SPELL CHECK WORD CATEGORIZATION AND PARSE FAILURE POST-PROCESSING ---

echo "Beginning word categorization run 1"
echo `date`

# Run time for this segment: ~25 min (8-core parallel)
grep ^@ tmp-output.txt | sort -nr -k2 > /tmp/sorted_by_article.txt
# Sort takes ~37sec
cat /tmp/sorted_by_article.txt | ../venv/bin/python3 ../by_article_processor.py > tmp-articles-linked-words.txt
rm -rf /tmp/sorted_by_article.txt
# TODO: Can this run as one line, or is that the source of the .py command not found error?
# grep ^@ tmp-output.txt | sort -nr -k2 | ../venv/bin/python3 ../by_article_processor.py > tmp-articles-linked-words.txt

grep -P '^!\t' tmp-output.txt | perl -pe 's/.*?\t//' | sort > err-parse-failures.txt
grep -P '^\!Q' tmp-output.txt | perl -pe 's/^\!Q\t\* \[\[(.*?)\]\].*$/$1/' | sort | ../venv/bin/python3 ../sectionalizer.py LARGE > jwb-straight-quotes-unbalanced.txt
grep ^G tmp-output.txt | ../venv/bin/python3 ../rollup_ignored.py | sort -nr -k2 > debug-spellcheck-ignored.txt

echo "Beginning word categorization run 2"
echo `date`

# Run time for this line: ~20 min (8-core parallel)
tac tmp-output.txt | grep '^*' | ../venv/bin/python3 ../word_categorizer.py > tmp-words-with-articles.txt

# --- BY ARTICLE ---

echo "Beginning by-article post-processing"
echo `date`

# Run time for here to beginning of readability report: ~50 min

cat tmp-articles-linked-words.txt | ../venv/bin/python3 ../make_main_listings.py > post-main-listings.txt

# Dealing with the remaining pile of typos:
# * Improve transliterate.py
#  * Valid word + hyphen + invalid word - probably a typo especially
#    if the invalid one is T1.  Maybe classify both sides?
# * Refine "A" category to require {{math}} be tagged but otherwise
#   allow forms in compliance with the Manual of Style?

# Also helps stats a lot:
# * Tagging articles for {{cleanup HTML}} from the appropriate report
# * Tagging articles with the most misspelled words with:
#   {{cleanup |reason=Need to use {{tl|lang}} to tag non-English words for consistent formatting, screen readers, and automated spell checkers}}
#   (probably the top 3000 or so articles with the most misspellings,
#   down to about 20 or so, though there are many mixed in at lower
#   frequencies)

head -50 tmp-articles-linked-words.txt | perl -pe 's/.*?\t//' > beland-articles-most-typos-raw.txt
head -10000 tmp-articles-linked-words.txt | perl -pe 's/.*?\t//' | grep -P '^[\[\] \-\w\*,:]+$' | grep -v "List of drugs" | head -50 > beland-articles-most-typos-refined.txt

grep BW,BW,BW,BW,BW tmp-articles-linked-words.txt | grep wikt:you | head -50 | perl -pe 's/.*?\t//' > post-you.txt

grep TF+la tmp-articles-linked-words.txt | grep species | perl -pe 's/^.*?\t\*/*/' | perl -pe 's/ - \[\[/ - \[\[w:/' | perl -pe 's/\[\[wikt:/\[\[/g' > beland-species1.txt
grep TF+la,TF+la tmp-articles-linked-words.txt | grep -v species | perl -pe 's/^.*?\t\*/*/' | grep -P "^[A-Za-z0-9,\[\]\*:\- \']+$" | perl -pe 's/ - \[\[/ - \[\[w:/' | perl -pe 's/\[\[wikt:/\[\[/g' > beland-species2.txt

# --- BY FREQUENCY ---

echo "Beginning by-frequency post-processing"
echo `date`

# Lots of correctly-classified typos have been fixed, so the below algorithms now are unreliable classifiers.
# grep -P '^(TS|ME)' tmp-words-with-articles.txt | grep -vP 'wikt:[^\]]+[\(\[\),\.]' | grep -vP "\w\]\w" | head -200 | perl -pe 's/.*?\t//' | ../venv/bin/python3 ../summarizer.py --find-all > tmp-most-common-compound.txt
# grep ^T1 tmp-words-with-articles.txt | head -200 | perl -pe 's/.*?\t//' | ../venv/bin/python3 ../summarizer.py --find-all > tmp-most-common-edit1.txt
# grep -P '^(?!T1|TS|TE|P|D|C|H|U|BC|BW|N|Z|A|T/|L)' tmp-words-with-articles.txt | head -200 | perl -pe 's/.*?\t//' | ../venv/bin/python3 ../summarizer.py --find-all > tmp-most-common-new-words.txt
# So, just make one big pile...
grep -P '^(?!BC|BW|H|TS|A|Z|L|U|N|T/)' tmp-words-with-articles.txt | head -200 | perl -pe 's/.*?\t//' | ../venv/bin/python3 ../summarizer.py --find-all > tmp-most-common-all-words.txt

echo "===Known bad HTML tags (HB) ===" > post-html-by-freq.txt
echo "These are also included in the main listings." >> post-html-by-freq.txt
grep ^HB tmp-words-with-articles.txt | perl -pe 's/^HB\t//' | ../venv/bin/python3 ../summarizer.py --find-all >> post-html-by-freq.txt

echo >> post-html-by-freq.txt
echo "===Bad link formatting (HL) ===" >> post-html-by-freq.txt
echo "These are also included in the main listings." >> post-html-by-freq.txt
echo 'Angle brackets are not used for external links (per {{section link|Wikipedia:Manual of Style/Computing|Exposed_URLs}}); "tags" like <nowiki><https> and <www></nowiki> are actually just bad link formatting.' >> post-html-by-freq.txt
echo "See [[Wikipedia:External links#How to link]] for external link syntax; use {{tl|cite web}} for footnotes." >> post-html-by-freq.txt
grep ^HL tmp-words-with-articles.txt | perl -pe 's/^HL\t//' | ../venv/bin/python3 ../summarizer.py --find-all >> post-html-by-freq.txt

echo >> post-html-by-freq.txt
echo "===Unsorted (H) ===" >> post-html-by-freq.txt
echo "Many of these can be replaced by {{tl|var}} (for text to be replaced) or {{tl|angbr}} (e.g. for linguistic notation). Enclose in {{tag|code}} for inline software source code." >> post-html-by-freq.txt
grep -P '^H\t' tmp-words-with-articles.txt | perl -pe 's/^H\t//' | ../venv/bin/python3 ../summarizer.py --find-all | head -50 >> post-html-by-freq.txt

# TODO: Search for bad attributes on HTML tags:
#  https://en.wikipedia.org/wiki/Wikipedia:HTML_5#Table_attributes
#  https://en.wikipedia.org/wiki/Wikipedia:HTML_5#Other_obsolete_attributes


# Dealing with these types without posting, since they can all be
# fixed in one sitting
grep ^P tmp-words-with-articles.txt | perl -pe 's/^P\t//' > beland-pattern-by-freq.txt
grep ^D tmp-words-with-articles.txt | perl -pe 's/^D\t//' > beland-dna-by-freq.txt
grep ^N tmp-words-with-articles.txt | perl -pe 's/^N\t//'| grep -vP 'wikt:[\w-]+\]' > beland-punct-weirdness-by-freq.txt

# --- COLLECTION FOR POSTING ---

echo "Beginning collection"
echo `date`

# This just automates the collection of some of the above output files
# into a single file for posting to the moss project page.

../venv/bin/python3 ../collect.py > collected_by_article_and_freq.txt

# --- PARSE FAILURE FIXES ---

echo "Beginning foot/inch conversion scan"
echo `date`

# Feet and inches - [[MOS:UNITNAMES]]

grep -P "[0-9\.]+(&nbsp;| )?'[0-9\.]+(&nbsp;| ) ?\"[^0-9\.]" err-parse-failures.txt | grep -v ° > tmp-feet-inches1.txt
grep -P '[0-9\.]+"(&nbsp;| )?(x|by|×)(&nbsp;| )?[0-9\./]+"' err-parse-failures.txt > tmp-feet-inches2.txt
grep -P '[0-9\.]+"' err-parse-failures.txt > tmp-feet-inches3.txt
cat tmp-feet-inches2.txt tmp-feet-inches1.txt tmp-feet-inches3.txt | perl -pe 's/^\* \[\[(.*?)\]\] - .*$/$1/' | uniq > jwb-feet-inches.txt
../venv/bin/python3 ../dump_grep_csv.py "[0-9\.]+(&nbsp;| )?'[0-9\.]+(&nbsp;| ) ?\"[^0-9\.]" > tmp-feet-inches-all1.txt
../venv/bin/python3 ../dump_grep_csv.py '[0-9\.]+"(&nbsp;| )?(x|by|×)(&nbsp;| )?[0-9\./]+"' > tmp-feet-inches-all2.txt
../venv/bin/python3 ../dump_grep_csv.py ' [^"][0-9]"' tmp-feet-inches-all3.txt | perl -pe 's/<.*?>//g' | perl -pe 's/[\( \|]"[a-zA-Z][^"]*[0-9]"//g' | perl -pe 's/"[0-9\.]+"//g' | grep -P '[0-9]"' > tmp-feet-inches-all3.txt
cat tmp-feet-inches-all2.txt tmp-feet-inches-all1.txt tmp-feet-inches-all3.txt | perl -pe 's/^(.*?):.*/$1/' | uniq >> jwb-feet-inches.txt

# Units of arc - [[MOS:UNITNAMES]]
grep -P "[0-9]+° ?[0-9]+' ?[0-9]+\"" err-parse-failures.txt | perl -pe 's/^\* \[\[(.*?)\]\] - .*$/$1/' | sort | uniq > jwb-arc-units.txt
../venv/bin/python3 ../dump_grep_csv.py "[0-9]+° ?[0-9]+' ?[0-9]+\"" > tmp-arc-units-all.txt
cat tmp-arc-units-all.txt | perl -pe 's/^(.*?):.*/$1/' | sort | uniq >> jwb-arc-units.txt

# See also: jwb-straight-quotes-unbalanced.txt

# TODO (enhances semantic web, gives readers a clickable link, but doesn't resolve parse failures):
# Consider scanning for lat/lon with:
#  ([0-9]+)° ?([0-9]+)(′|\{\{prime\}\}) ?([0-9]+)(″|\{\{pprime\}\}) ?(N|S) ([0-9]+)° ?([0-9]+)(′|\{\{prime\}\}) ?([0-9]+)(″|\{\{pprime\}\}) ?(E|W)
# and substituting:
#  {{coord|$1|$2|$4|$6|$7|$8|$10|$12|display=inline}}

# --- ARTICLES THAT NEED {{copyedit}} ---

grep -v "TF+" tmp-articles-linked-words.txt | grep -vP "(U|BC|Z)," | grep -v "&gt;" | grep -P "[a-z][\,\.][A-z]" | grep -v "* [0123456] -" | perl -pe 's/\[\[wikt:(.*?)\]\]/"\1"/g' | perl -pe 's/.*?\t//' | grep -vP '[a-zA-Z][\(\)\[\]][A-Za-z]' > post-copyedit.txt

# --- BY WORD LENGTH ---

echo "Beginning by-length post-processing"
echo `date`

cat tmp-words-with-articles.txt | ../venv/bin/python3 ../charlen_extractor.py | sort -k3 -nr > tmp-misspelled-words-charlen-cat.txt

echo "=== Possible typos by length ==="  > collected_by_length.txt
echo "Longest or shortest in certain categories are shown, sometimes just for fun and sometimes because they form a useful group. Feel free to delete articles that are fixed or tagged." >> collected_by_length.txt
echo "" >> collected_by_length.txt

echo "==== Likely chemistry words ====" >> collected_by_length.txt
echo "These need to be checked by a chemist and marked as {{tl|not a typo}}." >> collected_by_length.txt
grep ^C tmp-misspelled-words-charlen-cat.txt | perl -pe 's/^C\t//' | head -20 >> collected_by_length.txt
echo "" >> collected_by_length.txt

echo "==== Missing articles on single characters ====" >> collected_by_length.txt
echo "" >> collected_by_length.txt
echo "Every character should either have a Wikipedia article, redirect to a Wikipedia article, or Wiktionary entry." >> collected_by_length.txt
echo "" >> collected_by_length.txt
grep -P '^I\t\* 1 -' tmp-misspelled-words-charlen-cat.txt | perl -pe 's/^I\t//' >> collected_by_length.txt
echo "" >> collected_by_length.txt

# --- STATS ---

echo "Beginning stats"
echo `date`

echo "Possible typos per article: " > post-stats.txt
cat tmp-articles-linked-words.txt | perl -pe 's/.*?\t//' | ../venv/bin/python3 ../histogram_text.py >> post-stats.txt
echo "Parse errors: " >> post-stats.txt
wc -l err-parse-failures.txt >> post-stats.txt
echo "Parse errors with [[MOS:STRAIGHT]] violations:" >> post-stats.txt
wc -l jwb-straight-quotes-unbalanced.txt >> post-stats.txt
echo "Possible typos by type: " >> post-stats.txt
cat tmp-words-with-articles.txt | ../venv/bin/python3 ../count_by_rating.py >> post-stats.txt


# --- DASHES ---

echo "Beginning dash report"
echo `date`

grep ^D tmp-output.txt | perl -pe 's/^D\t'// | sort -k3 | ../venv/bin/python3 ../sectionalizer.py > debug-dashes.txt
# TODO: Are spaced emdashes more common than unspaced?  I like them
# better but they go against the style guide. -- Beland
#
# grep line counts from enwiki-latest-pages-articles-multistream.xml:
# "—"      4148695
# " — "    1340803
# "\w—\w"   486271
#
# -> Write some code to run a report that accumulates info on what
#    characters exactly are before and after (count before and after
#    separately, or else there are too many combinations)


# --- READABILITY ---

echo "Beginning readability check"
echo `date`

# Run time for this segment: ~1h (8-core parallel)

../venv/bin/python3 ../moss_readability_check.py > tmp-readability.txt
sort -k2 -n tmp-readability.txt > post-readability.txt
rm tmp-readability.txt

# --- SUPERSCRIPTS AND SUBSCRIPTS ---

# Run time for this segment: ~30 min (8-core parallel)

echo "Beginning superscript/subscript audit"
../superscripts.sh

echo "Done"
echo `date`

# --- CHEMICAL FORMULAS ---

# Run time: About 3 h 20 min

echo "Starting chemical formulas report"
echo `date`
echo "====Possible chemical formulas that don't use subscripts====" > post-chemical-formulas.txt
grep -P ' ((H|He|Li|Be|B|C|N|O|F|Ne|Na|Mg|Al|Si|P|S|Cl|Ar|K|Ca|Sc|Ti|V|Cr|Mn|Fe|Co|Ni|Cu|Zn|Ga|Ge|As|Se|Br|Kr|Rb|Sr|Y|Zr|Nb|Mo|Tc|Ru|Rh|Pd|Ag|Cd|In|Sn|Sb|Te|I|Xe|Cs|Ba|La|Ce|Pr|Nd|Pm|Sm|Eu|Gd|Tb|Dy|Ho|Er|Tm|Yb|Lu|Hf|Ta|W|Re|Os|Ir|Pt|Au|Hg|Tl|Pb|Bi|Po|At|Rn|Fr|Ra|Ac|Th|Pa|U|Np|Pu|Am|Cm|Bk|Cf|Es|Fm|Md|No|Lr|Rf|Db|Sg|Bh|Hs|Mt|Ds|Rg|Cn|Nh|Fl|Mc|Lv|Ts|Og|R)([2-9]|[1-9][0-9]))+$' debug-spellcheck-ignored.txt | grep -vP ' [KQRBNP][a-h][1-8]$' | grep -vP ' [A-Z]\d\d$' | head -100 >> post-chemical-formulas.txt
# [KQRBNP][a-h][1-8] is to exclude [[Algebraic notation (chess)]]

echo "" >> post-chemical-formulas.txt
echo "====Known chemical formulas that don't use subscripts====" >> post-chemical-formulas.txt
../venv/bin/python3 ../chemical_formula_report.py >> post-chemical-formulas.txt

# --- RHYME SCHEMES ---

# Run time: About 2 h

echo "Starting rhyme scheme report"
echo `date`

../venv/bin/python3 ../dump_grep_regex.py "[Rr]hym|[Pp]oem|[Ss]tanza|[Vv]erse|[Ll]yric" > tmp-rhyme-dump.xml

cat tmp-rhyme-dump.xml | ../venv/bin/python3 ../dump_grep_inline.py "[^a-z0-9\-A-Zí][Aa]-[Bb][^a-zA-Z]" | perl -pe '<math.*?(</math>|<\/nowiki>/ig)' | perl -pe '<ref.*?(/ ?>|</ref>|<\/nowiki>/ig)' | perl -pe 's/\{\{cite.*?(\}\}|<\/nowiki>)//ig' | grep -i "a-b" | grep -v "A-B-C-D-E-F-G" | sort > tmp-rhyme-a-b.txt
cat tmp-rhyme-dump.xml | ../venv/bin/python3 ../dump_grep_inline.py "[^,]AB,[ABC]|AA,AB|AA,B|AB,[ABC]" | grep -v "<math" | grep -vP "^(Rhyme scheme:|The Raven:)" | sort > tmp-rhyme-AB-comma.txt
cat tmp-rhyme-dump.xml | ../venv/bin/python3 ../dump_grep_inline.py "[^A-Za-z0-9\./%#=_\-](aa|ab|aaa|aab|aba|abb|abc|aaaa|aaba|aabb|aabc|abaa|abab|abba|abca|abcb|abcc|abcd)[^a-z0-9/]" | perl -pe '<ref.*?(/ ?>|</ref>|<\/nowiki>/ig)' | grep -P "(aa|ab)"  | sort > tmp-rhyme-masked-words.txt

cat tmp-rhyme-dump.xml | ../venv/bin/python3 ../dump_grep_inline.py "([^a-z\+/]a\.b\.[^d-z]|[^a-z\+/]a\. b\. [^d-z])" | grep -v "Exemplum:"  | sort > tmp-rhyme-a.b.txt

# These may need to be relaxed in the future
cat tmp-rhyme-AB-comma.txt > tmp-rhyme.txt
grep --no-filename -iP "rhym|form|poem" tmp-rhyme-a-b.txt tmp-rhyme-a.b.txt >> tmp-rhyme.txt
grep -iP "rhym" tmp-rhyme-masked-words.txt >> tmp-rhyme.txt
cat tmp-rhyme.txt | perl -pe 's/^(.*?):(.*)$/* [[$1]] - <nowiki>$2<\/nowiki>/' > beland-rhyme.txt

rm -f tmp-rhyme-dump.xml

# --- OTHER PROJECTS ---

cd ..
./run_not_english.sh

cd $RUN_NAME
../run_wiktionary_spell_check.sh

# --- x to times symbol ---

echo "Starting x-to-times"
echo `date`

../venv/bin/python3 ../dump_grep_csv.py '[0-9]x[^a-zA-Z]' | grep -vP '[a-zA-Z\-_][0-9]+x' | grep -vP 'x[a-zA-Z]' | grep -vP '( 4x4 | 6x6 )' | grep -vP '[0-9]+x[0-9]+px' | grep -v '<math' | grep -vP '[^0-9]0x[0-9]+' | grep -P '[0-9]+x[0-9]*' > x-correct-nospace-with-article.txt
../venv/bin/python3 ../dump_grep_csv.py " x " > x-correct-space-with-article.txt

# --- l to L for liters ---
echo "Starting liters style check"
echo `date`

# Per April 2021 RFC that updated [[MOS:UNITSYMBOLS]]

export NON_ASCII_LETTERS=ạàÁáÂâÃãÄäầåấæɑ̠āÇçÈèÉéÊêËëēÌìÍíÎîÏïĭīʝÑñÒòÓóÔôÕõÖöớộøŠšÚúùÙÛûÜüũưÝýŸÿŽžəþɛ

# Run time: 9-22 min per regex
../venv/bin/python3 ../dump_grep_csv.py "[0-9] l" | perl -pe "s%<math.*?>.*?</math>%%g" | perl -pe "s/(File|Image):.*?\|//g" | grep -P "[^p][^.]\s?[0-9]+ l[^a-zA-Z0-9'’${NON_ASCII_LETTERS}]" | grep -vi " l.jpg" | grep -v "AD-1 l" | sort > liters-fixme1.txt
../venv/bin/python3 ../dump_grep_csv.py "[rBbMm]illion l[^a-zA-Z0-9']" | sort > liters-fixme2.txt
../venv/bin/python3 ../dump_grep_csv.py '([Ll]iter|[Ll]itre)s?\|l]]' | sort > liters-fixme3.txt
../venv/bin/python3 ../dump_grep_csv.py "[0-9]&nbsp;l[^A-Za-z'0-9]" | sort > liters-fixme4.txt
../venv/bin/python3 ../dump_grep_csv.py "/l" | perl -pe "s/{{not a typo.*?}}//" | perl -pe "s%<math>.*?</math>%%g" | perl -pe "s/(File|Image):.*?\|//g" | grep -P "[^A-Za-z\./][A-Za-z]{1,4}/l[^a-zA-Z${NON_ASCII_LETTERS}'0-9/\-_]" | grep -vP "w/l(-[0-9])? *=" | grep -vP "(https?://|data:)[A-Za-z0-9_\-\./,\+%~;]+/l[^a-zA-Z'’]" | grep -vP "[^a-zA-Z0-9]r/l" | grep -vP "[^a-zA-Z0-9]d/l[^a-zA-Z0-9]" | grep -vP "\[\[(\w+ )+a/l [\w ]+\]\]" | grep -v "Length at the waterline|w/l" | grep -v "Waterline length|w/l" | sort > liters-fixme5.txt
# TODO for fixme5:
# expand "m/l" to "music and lyrics" or drop
# expand "w/l" to "win/loss"
# expand "s/l" to "sideline" "l/b" to "sideline" (line ball)
# change "a/l" to "[[Malaysian names#Indian names|a/l]]"
../venv/bin/python3 ../dump_grep_csv.py '{{(convert|cvt)\|[^\}]+\|l(\||}|/)' | sort > liters-fixme6.txt
../venv/bin/python3 ../dump_grep_csv.py ' [0-9,\.]+( |&nbsp;)?l/[a-zA-Z0-9]' | sort > liters-fixme7.txt
cat liters-fixme* | perl -pe 's/(.*?):.+/$1/' | uniq > liters-all.txt

echo "Done"
echo `date`
