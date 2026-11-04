#!/bin/sh
# AUSFÜHRUNG · Gesamtbau der Ausgabe R 1.0 F.
# Außen Henning Ehlert (Umschlag), innen A. Oxima (Titelei im Quelltext).
# Aufruf im Hauptordner:  sh build_roman.sh  [ROMAN.md NACHWORT.md]
# Voraussetzung: TeX Live mit soul (texlive-plain-generic) und deutscher Silbentrennung (texlive-lang-german);
# ohne die Muster bricht der Text anders um (247 statt 245 Seiten).
set -e
FQ="${1:-quellen/roman.md}"; NWQ="${2:-quellen/nachwort.md}"
R=AUSFUEHRUNG_Roman_R1.0F
for s in texgyretermes-regular.otf texgyretermes-bold.otf texgyretermes-italic.otf \
         texgyretermes-bolditalic.otf IBMPlexMono-Regular.ttf IBMPlexMono-Medium.ttf; do
  [ -f "titelblatt/fonts/$s" ] || { echo "Schrift fehlt: titelblatt/fonts/$s (siehe README, Abschnitt Schriften)"; exit 1; }
done
python3 -I make_roman.py "$FQ" "$NWQ" $R.md
mkdir -p out_ROMAN
( cd titelblatt && xelatex -interaction=nonstopmode titelblatt.tex >/dev/null )
UMBRUCH_TSV=satz/umbruch_roman.tsv SHRINK=0.12 sh body.sh $R.md out_ROMAN/body_$R.pdf
python3 -I errata_check.py out_ROMAN/body_$R.pdf errata_stellen.json $R.md | tee out_ROMAN/errata_$R.log
qpdf --empty --pages titelblatt/titelblatt.pdf out_ROMAN/body_$R.pdf -- out_ROMAN/$R.pdf
python3 -I meta_he.py out_ROMAN/$R.pdf "AUSFÜHRUNG. Ein Verfahren" "Roman. Fassung R 1.0 F mit Nachwort des Autors (Stand 04.11.2026)."
pdfinfo out_ROMAN/$R.pdf | grep Pages
