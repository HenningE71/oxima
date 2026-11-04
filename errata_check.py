"""Prüft die Errata-Stellen im Buchblock (ohne Umschlag).

Zählung: nichtleere Zeilen, Kolumnentitel = Zeile 0.
Seite = gedruckte Seitenzahl im Kolumnentitel (Buchblock, Titelseite = 1).
Aufruf: python3 -I errata_check.py BODY.pdf [STELLEN.json] [QUELLE.md]
Standard: die Stellen der Ausgabe R 1.0 F. Eine JSON-Datei ersetzt sie, wenn sich der Umbruch ändert:
  {"nacht": [Seite, Zeile], "maske": [Seite, Zeile], "satz": [Seite, Zeile], "kap32": Seite}
Optional die Markdown-Quelle des Satzes. Dann wird zusätzlich geprüft, dass die Errata-Zeilen im Text
genau diese Stellen nennen („S. 96, Z. 13: …“). Das fängt eine Quelle ab, deren Errata noch auf einen
anderen Umbruch zeigen. Die Argumente werden an der Endung erkannt (.json / .md).
"""
import json, subprocess, sys

pdf = sys.argv[1]
pos = {"nacht": [96, 13], "maske": [185, 30], "satz": [220, 28], "kap32": 207}
src = None
for arg in sys.argv[2:]:
    if arg.endswith(".json"):
        pos.update(json.load(open(arg, encoding="utf-8")))
    elif arg.endswith(".md"):
        src = arg
    else:
        sys.exit(f"ABBRUCH: unbekanntes Argument {arg!r} (erwartet .json oder .md)")
txt = subprocess.run(["pdftotext", "-layout", pdf, "-"], capture_output=True, text=True).stdout
pages = txt.split("\f")

CHECKS = [
    (pos["nacht"][0], pos["nacht"][1], "drei Nächte"),
    (pos["maske"][0], pos["maske"][1], "Die Maske lief weiter"),
    (pos["satz"][0], pos["satz"][1], "Es gibt keinen Satz"),
]
ok = True
for page, line, needle in CHECKS:
    lines = [l for l in pages[page - 1].split("\n") if l.strip()]
    head = lines[0].strip()
    got = lines[line] if line < len(lines) else ""
    hit = needle in got
    ok &= hit
    print(f"S. {page} Z. {line}: {'OK ' if hit else 'FEHLT'} | Kopf: {head[:50]!r} | Zeile: {got.strip()[:70]!r}")
    if not hit:
        for k, l in enumerate(lines):
            if needle in l:
                print(f"    gefunden in Zeile {k}: {l.strip()[:70]!r}")

p32 = pos["kap32"]
lines_kap = [l for l in pages[p32 - 1].split("\n") if l.strip()]
hit = any(l.strip() == "14 · Der Andere" for l in lines_kap[1:])  # Kapitel beginnt ggf. mitten auf der Seite
ok &= hit
print(f"S. {p32} Beginn »14 · Der Andere«: {'OK' if hit else 'FEHLT'} | {lines_kap[:3]}")

if src:
    t = open(src, encoding="utf-8").read()
    WANT = [
        f"S. {pos['nacht'][0]}, Z. {pos['nacht'][1]}: Es muss heißen »drei Nächte«",
        f"S. {pos['maske'][0]}, Z. {pos['maske'][1]}: Der Satz »Sie hat es nicht gewusst«",
        f"S. {pos['satz'][0]}, Z. {pos['satz'][1]}: Der letzte Satz des Kapitels",
        f"S. {p32}: Das dort beginnende Kapitel",
    ]
    for w in WANT:
        hit = t.count(w) == 1
        ok &= hit
        print(f"Errata-Text {'OK ' if hit else 'FEHLT'}: {w[:60]!r}")
    if not ok:
        print("Hinweis: Stimmen die Errata-Zeilen der Quelle nicht, ist die Quelle veraltet "
              "oder der Umbruch hat sich geändert.")
print("Seiten Buchblock:", len(pages) - 1)
sys.exit(0 if ok else 1)
