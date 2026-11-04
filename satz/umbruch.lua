-- umbruch.lua: Feinsatz einzelner Absätze, nur für den PDF-Satz.
-- Liest satz/umbruch_roman.tsv: je Zeile  Anfang-des-Absatzes <TAB> LaTeX-Befehl.
-- Der Befehl steht als eigener Block unmittelbar vor dem passenden Absatz. Der Text bleibt unverändert;
-- DOCX und MD sind nicht betroffen.
local fixes = {}
-- Eine andere Liste lässt sich über die Umgebungsvariable UMBRUCH_TSV angeben.
local f = io.open(os.getenv("UMBRUCH_TSV") or "satz/umbruch_roman.tsv", "r")
if f then
  for line in f:lines() do
    local k, c = line:match("^(.-)\t(.+)$")
    if k then fixes[#fixes + 1] = {k = k, c = c} end
  end
  f:close()
end

function Pandoc(doc)
  if not FORMAT:match("latex") then return doc end
  local out = {}
  for _, b in ipairs(doc.blocks) do
    if b.t == "Para" then
      local s = pandoc.utils.stringify(b)
      for _, fx in ipairs(fixes) do
        if s:sub(1, #fx.k) == fx.k then
          out[#out + 1] = pandoc.RawBlock("latex", fx.c)
          break
        end
      end
    end
    out[#out + 1] = b
  end
  doc.blocks = out
  return doc
end
