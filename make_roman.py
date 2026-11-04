"""Setzt die Ausgabe aus Romantext und Nachwort zusammen.
Außen Henning Ehlert (Umschlag), innen A. Oxima (Titelei im Quelltext).
Ausgabe = Romantext bis zum Platzhalter für das Nachwort, dann die Trennseite, dann Nachwort, Quellen
und Impressum ab der Überschrift »## Nachwort des Autors«.
Aufruf: python3 -I make_roman.py ROMAN.md NACHWORT.md ZIEL.md"""
import sys
fq, nw, ziel = sys.argv[1:4]
f = open(fq, encoding="utf-8").read()
n = open(nw, encoding="utf-8").read()
PH = "```{=latex}\n\\clearpage\n```\n\n[Platzhalter Nachwort]"
if f.count(PH) != 1: sys.exit("Platzhalter")
H = "## Nachwort des Autors\n"
trenn = """```{=latex}
\\clearpage
\\setlength{\\parskip}{0.5\\baselineskip}
\\thispagestyle{empty}
\\vspace*{\\fill}
\\begin{center}
\\rmfamily\\itshape\\footnotesize
Das folgende Nachwort ist nicht erfunden. Der als Verfasser genannte Autor ebenfalls.
\\end{center}
\\vspace*{5em}
\\clearpage
```

```{=openxml}
<w:p><w:r><w:br w:type="page"/></w:r></w:p>
<w:p><w:pPr><w:jc w:val="center"/><w:spacing w:before="9000"/></w:pPr><w:r><w:rPr><w:i/><w:sz w:val="18"/></w:rPr><w:t>Das folgende Nachwort ist nicht erfunden. Der als Verfasser genannte Autor ebenfalls.</w:t></w:r></w:p>
<w:p><w:r><w:br w:type="page"/></w:r></w:p>
```

"""
k = n.index(H)
if n.count(H) != 1: sys.exit("Nachwortüberschrift")
rest = n[k:]
if "######" in rest: sys.exit("Platzhalter im Nachwort")
b = f[:f.index(PH)] + trenn + rest
# Satz der Titelseiten: jede Ersetzung muss genau einmal treffen.
def rep(t, alt, neu):
    if t.count(alt) != 1: sys.exit("ABBRUCH Titelseite: " + repr(alt[:50]) + " %dx" % t.count(alt))
    return t.replace(alt, neu)
b = rep(b, "sind frei erfunden. Die Autorschaft des folgenden Manuskripts ebenfalls.\\par\\medskip",
           "sind frei erfunden.\\\\\nDie Autorschaft des folgenden Manuskripts ebenfalls.\\par\\medskip")
b = rep(b, "{\\large A. Oxima}\\\\[1em]\n{\\normalsize Kollwitz \\& Reineke Verlag \\textperiodcentered\\ Berlin}\n\\end{center}\n",
           "{\\large A. Oxima}\n\\end{center}\n\\vfill\n\\begin{center}\n{\\normalsize Kollwitz \\& Reineke Verlag \\textperiodcentered\\ Berlin}\n\\end{center}\n\\vspace*{5em}\n")
open(ziel, "w", encoding="utf-8").write(b)
print("geschrieben:", ziel, len(b), "Zeichen")
