"""Setzt die PDF-Metadaten der Ausgabe: Info-Wörterbuch plus XMP mit Autor, Lizenz und TDM-Vorbehalt.
Aufruf: python3 -I meta_he.py DATEI.pdf "TITEL" "THEMA"
"""
import sys

import pikepdf

pdf_path, TITLE, SUBJECT = sys.argv[1], sys.argv[2], sys.argv[3]
AUTHOR = "Henning Ehlert"
KEYWORDS = "Roman; Nachwort; Sprachmodelle; CC BY-NC 4.0"
LIC = "https://creativecommons.org/licenses/by-nc/4.0/deed.de"
RIGHTS = (f"{AUTHOR}. Lizenz: CC BY-NC 4.0 ({LIC}). Die Nutzung für Text und Data "
          "Mining zum Training von KI-Systemen ist zusätzlich ausdrücklich vorbehalten "
          "(§ 44b Abs. 3 UrhG).")

pdf = pikepdf.open(pdf_path, allow_overwriting_input=True)
for k in list(pdf.docinfo.keys()):
    del pdf.docinfo[k]
pdf.docinfo["/Title"] = TITLE
pdf.docinfo["/Author"] = AUTHOR
pdf.docinfo["/Subject"] = SUBJECT
pdf.docinfo["/Keywords"] = KEYWORDS
if "/Metadata" in pdf.Root:
    del pdf.Root["/Metadata"]
with pdf.open_metadata(set_pikepdf_as_editor=False, update_docinfo=False) as m:
    m.register_xml_namespace("http://creativecommons.org/ns#", "cc")
    m.register_xml_namespace("http://www.w3.org/ns/tdmrep/", "tdm")
    m["dc:title"] = TITLE
    m["dc:creator"] = [AUTHOR]
    m["dc:description"] = SUBJECT
    m["dc:language"] = {"de"}
    m["dc:rights"] = RIGHTS
    m["pdf:Keywords"] = KEYWORDS
    m["xmpRights:Marked"] = "True"
    m["xmpRights:WebStatement"] = LIC
    m["cc:license"] = "https://creativecommons.org/licenses/by-nc/4.0/"
    m["tdm:reservation"] = "1"
pdf.save(pdf_path)
print("Metadaten gesetzt:", pdf_path)
