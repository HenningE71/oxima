# AUSFÜHRUNG · Ein Verfahren

Quellen und Bauanlage des Romans *AUSFÜHRUNG. Ein Verfahren* von Henning Ehlert. Aus diesem Repository entsteht die Ausgabe **R 1.0 F** als PDF (A5, 246 Seiten: Umschlag und 245 Seiten Buchblock) und als Markdown.

Der Roman steht als PDF auf [aoxima.com](https://aoxima.com) bereit, erreichbar unter anderem über ausfuehrung.com.

## Inhalt

```
build_roman.sh           Gesamtbau: Quelltext zusammensetzen, Umschlag, Buchblock, Prüfung, Metadaten
make_roman.py            setzt Romantext und Nachwort zur Ausgabe zusammen
body.sh                  Buchblock (Pandoc + pdfLaTeX)
errata_check.py          prüft die Errata-Stellen gegen den Satz
errata_stellen.json      Seite und Zeile der Errata-Stellen
meta_he.py               PDF-Metadaten: Titel, Autor, Lizenz, TDM-Vorbehalt
protokoll/protokoll.md   Dokumentation der maßgeblichen Entscheidungen. Kein Versuchsbericht
quellen/
  roman.md               Romantext
  nachwort.md            Nachwort, Quellen, Impressum
satz/
  header.tex             LaTeX-Präambel
  filter.lua             Pandoc-Filter: Terminalsatz, Artefakte, Trenner, Umbrüche, Links
  umbruch.lua            Feinsatz einzelner Absätze
  umbruch_roman.tsv      Liste dazu
titelblatt/
  titelblatt.tex         Umschlag (XeLaTeX + TikZ)
LICENSE                  Lizenz
```

## Schriften

Die Schriften des Umschlags sind nicht Teil dieses Repositorys. Vor dem ersten Bau gehören sie nach `titelblatt/fonts/`; der Ordner ist von Git ausgenommen.

**TeX Gyre Termes** (GUST Font License) ist in TeX Live enthalten:

```
mkdir -p titelblatt/fonts
for s in regular bold italic bolditalic; do cp "$(kpsewhich texgyretermes-$s.otf)" titelblatt/fonts/; done
```

**IBM Plex Mono**, Regular und Medium (SIL Open Font License 1.1), in der Fassung von Google Fonts:

```
G=https://raw.githubusercontent.com/google/fonts/023eedd8780dd254e5905901473ed55e5475ee73/ofl/ibmplexmono
curl -L -o titelblatt/fonts/IBMPlexMono-Regular.ttf $G/IBMPlexMono-Regular.ttf
curl -L -o titelblatt/fonts/IBMPlexMono-Medium.ttf $G/IBMPlexMono-Medium.ttf
```

Mit genau diesen Dateien ist der Umschlag geprüft. Die TrueType-Dateien aus den Releases von IBM sind andere Builds derselben Schrift. Fehlt eine Datei, bricht `build_roman.sh` mit einem Hinweis ab.

## Bauen

Voraussetzungen (Ubuntu/Debian):

```
apt-get install -y pandoc qpdf poppler-utils python3-pikepdf \
  texlive-xetex texlive-latex-base texlive-latex-recommended texlive-latex-extra \
  texlive-fonts-recommended texlive-plain-generic texlive-pictures \
  texlive-lang-german lmodern fonts-texgyre
```

Ohne `texlive-lang-german` bricht der Text anders um (247 statt 245 Seiten), und die Errata stimmen nicht mehr. Unter macOS entsprechend MacTeX, dazu `pandoc`, `qpdf`, `poppler` (Homebrew) und `pikepdf` (pip).

Aufruf im Hauptordner:

```
sh build_roman.sh
```

Ergebnis: `out_ROMAN/AUSFUEHRUNG_Roman_R1.0F.pdf`. Der zusammengesetzte Quelltext liegt als `AUSFUEHRUNG_Roman_R1.0F.md` im Hauptordner. Beides sowie `titelblatt/titelblatt.pdf` entsteht bei jedem Lauf neu und wird von Git ignoriert.

## Prüfen

Nach jedem Bau:

1. Errata-Ausgabe: Alle Zeilen müssen `OK` zeigen. Der Bau bricht bei `FEHLT` nicht ab; das Protokoll steht in `out_ROMAN/errata_*.log`.
2. Seitenzahl: `Pages: 246`.
3. `sha256sum AUSFUEHRUNG_Roman_R1.0F.md` (macOS: `shasum -a 256 …`) beginnt mit `d940df9415de888b`. Dann ist der Quelltext zeichengleich mit der Ausgabe R 1.0 F.

Das PDF selbst ist nicht bytegleich reproduzierbar (Zeitstempel und Kennung). Maßgeblich sind die md, die Seitenzahl und die Errata.

## Neue Ausgabe

- In `build_roman.sh` den Dateinamen (`R=…`) und die Thema-Zeile für `meta_he.py` anpassen.
- Ändert sich der Umbruch: `errata_stellen.json` und die Errata-Zeilen im Text nachziehen. `errata_check.py` zeigt, wo die Stellen stattdessen stehen.
- Im README die Prüfsumme unter *Prüfen* auf die neue md setzen.
- Release mit Tag ohne Datum (`R1.0F`, später `R1.1F` usw.), das PDF als Anhang.

## Lizenz

Alle Dateien dieses Repositorys stehen unter **CC BY-NC 4.0**: Teilen und Bearbeiten sind erlaubt, wenn Urheber (Henning Ehlert) und Titel (*AUSFÜHRUNG*) genannt werden und die Nutzung nicht kommerziell ist. Die Nutzung für Text und Data Mining zum Training von KI-Systemen ist zusätzlich ausdrücklich vorbehalten (§ 44b Abs. 3 UrhG). Einzelheiten und Lizenztext: `LICENSE`.
