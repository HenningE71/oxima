#!/bin/sh
# body.sh QUELLE.md ZIEL.pdf: setzt den Buchblock (Pandoc + pdfLaTeX, A5).
# Absatzabstand mit Schrumpfreserve (Umgebungsvariable SHRINK, Standard 0.12) und satz/umbruch.lua
# gegen Kurzseiten am Kapitelende; Satzspiegel, Schrift und Text bleiben unverändert.
GEO="a5paper,top=2cm,bottom=2cm,inner=2cm,outer=1.8cm,headsep=1.2em"
SRC="$1"; OUT="$2"; SHRINK="${SHRINK:-0.12}"
cat > satz/absatz.tex <<TEX
% Absatzabstand, erzeugt von body.sh
\setlength{\parskip}{0.5\baselineskip minus ${SHRINK}\baselineskip}
TEX
pandoc "$SRC" -o "$OUT" --pdf-engine=pdflatex -H satz/header.tex -H satz/absatz.tex \
  -L satz/filter.lua -L satz/umbruch.lua -V papersize=a5 -V fontsize=11pt -V documentclass=article \
  -V geometry:"$GEO" -V lang=de
