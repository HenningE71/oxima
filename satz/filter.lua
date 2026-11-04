-- Satz des Buchblocks. Zwei getrennte Durchgänge, weil die
-- Verwaisten-Erkennung noch echte HorizontalRule-Elemente braucht:
-- würde Pass 1 sie vorher in RawBlock verwandeln, wäre die Nachbarschaft
-- zu Überschriften nicht mehr prüfbar.

-- Nur Artefakte mit Kennung ‹…› (Überschrift Ebene 3) tragen den Vermerk
-- „Fiktives Artefakt“: die neun eingelegten Fremdtexte. Aktenvermerke und
-- das eingelegte Blatt bleiben ohne.
local function hat_kennung(div)
  for _, b in ipairs(div.content) do
    if b.t == 'Header' and b.level == 3
       and pandoc.utils.stringify(b):match('^‹') then
      return true
    end
  end
  return false
end

-- Pass 1: Artefakt-Divs in LaTeX-Umgebungen. Bleiben im Textfluss,
-- werden aber nicht über einen Seitenumbruch zerrissen.
local pass1 = {
  Div = function(el)
    local env = nil
    if el.classes:includes('artefakt') then
      env = 'artefakt'
    elseif el.classes:includes('artefaktkeep') then
      env = 'artefaktkeep'
    elseif el.classes:includes('artefaktbreak') then  -- darf umbrechen (nur ‹7337›)
      env = 'artefaktbreak'
    end
    if env == nil then return nil end

    local out = {}
    table.insert(out, pandoc.RawBlock('latex', '\\begin{' .. env .. '}'))
    for _, b in ipairs(el.content) do
      table.insert(out, b)
    end
    -- Vermerk „Fiktives Artefakt“ am Strich (Makro in header.tex)
    if hat_kennung(el) then
      table.insert(out, pandoc.RawBlock('latex', '\\artefaktvermerk'))
    end
    table.insert(out, pandoc.RawBlock('latex', '\\end{' .. env .. '}'))
    return out
  end
}

-- DOCX: Word kann den Vermerk nicht gedreht neben den Rahmen setzen.
-- Dort steht er rechtsbündig in kleinen Kapitälchen unter dem Artefakt.
local VERMERK_OPENXML = '<w:p><w:pPr><w:jc w:val="right"/></w:pPr>'
  .. '<w:r><w:rPr><w:smallCaps/><w:sz w:val="16"/></w:rPr>'
  .. '<w:t>Fiktives Artefakt</w:t></w:r></w:p>'

local pass1_docx = {
  Div = function(el)
    if (el.classes:includes('artefakt') or el.classes:includes('artefaktkeep')
        or el.classes:includes('artefaktbreak'))
       and hat_kennung(el) then
      el.content:insert(pandoc.RawBlock('openxml', VERMERK_OPENXML))
      return el
    end
  end
}

-- Pass 2: (a) verwaiste Trennzeichen entfernen -- eine HorizontalRule
-- unmittelbar vor einer Überschrift trennt nichts und wird gestrichen,
-- alle übrigen werden zum zentrierten Sternchen; (b) vor jeder
-- Akt-Überschrift (Header Ebene 1) den Kolumnentitel für diese eine
-- Seite unterdrücken, weil er die große Überschrift direkt darunter
-- nur verdoppeln würde -- die Seitenzahl bleibt (Stil "aktseite",
-- in header.tex definiert). Direkt im Filter statt per \section-Patch,
-- weil Hyperref/Bookmark \section nach der Präambel erneut anfasst und
-- einen \pretocmd-Patch dort sonst wieder verwirft.
local function is_rule(b)
  return b ~= nil and b.t == 'HorizontalRule'
end

local function is_header(b)
  return b ~= nil and b.t == 'Header'
end

local function is_comment(b)
  return b ~= nil and b.t == 'RawBlock' and b.format == 'html'
end

-- Eine Folge von Trennern, auch wenn nur unsichtbare Kommentare (die
-- Artefakt-Kennzeichnungen) dazwischenstehen, ergibt höchstens EIN
-- Sternchen.
local pass2 = {
  Blocks = function(blocks)
    local out = pandoc.List()
    local n = #blocks
    local after_akt = false
    local i = 1
    while i <= n do
      local b = blocks[i]
      if is_rule(b) then
        local j = i + 1
        local comments = pandoc.List()
        while j <= n and (is_rule(blocks[j]) or is_comment(blocks[j])) do
          if is_comment(blocks[j]) then comments:insert(blocks[j]) end
          j = j + 1
        end
        if j <= n and is_header(blocks[j]) then
          -- verwaist vor Überschrift: ersatzlos streichen
        elseif j > n then
          -- am Ende eines Blocks: ebenfalls streichen
        else
          out:insert(pandoc.RawBlock('latex',
            '\\begin{center}\\vspace{0.4\\baselineskip}*'
            .. '\\vspace{0.4\\baselineskip}\\end{center}'))
        end
        out:extend(comments)
        if #comments > 0 then after_akt = false end
        i = j
      else
        if is_header(b) and b.level == 1 then
          out:insert(pandoc.RawBlock('latex', '\\clearpage'))
          out:insert(pandoc.RawBlock('latex', '\\thispagestyle{aktseite}'))
          after_akt = true
        elseif is_header(b) and b.level == 2 then
          if after_akt then
            -- kein \needspace direkt nach Akt-Überschrift
          else
            out:insert(pandoc.RawBlock('latex', '\\needspace{13\\baselineskip}'))
          end
          after_akt = false
        else
          after_akt = false
        end
        out:insert(b)
        i = i + 1
      end
    end
    return out
  end
}

-- Pass 3: Perspektivmarker und erster Absatz zusammenhalten.
local function marker_letter(b)
  if b == nil or b.t ~= 'Para' then return nil end
  local inl = b.content
  if #inl ~= 1 or inl[1].t ~= 'Strong' then return nil end
  local inner = inl[1].content
  if #inner ~= 1 or inner[1].t ~= 'Str' then return nil end
  local text = inner[1].text
  local letter = text:match('^%[([RCMOX])%]$')
  return letter
end

local pass3 = {
  Blocks = function(blocks)
    local out = pandoc.List()
    local n = #blocks
    local i = 1
    while i <= n do
      local b = blocks[i]
      if marker_letter(b) ~= nil and i < n and blocks[i + 1].t == 'Para' then
        out:insert(pandoc.RawBlock('latex', '\\needspace{5\\baselineskip}'))
        out:insert(b)
        out:insert(blocks[i + 1])
        i = i + 2
      else
        out:insert(b)
        i = i + 1
      end
    end
    return out
  end
}

-- Pass 4: DOIs im Quellenverzeichnis als Link setzen. Umbrochen wird nur
-- nach einem Schrägstrich; die Abschnitte dazwischen bleiben ganz, damit
-- kein Bindestrich der DOI am Zeilenende steht und beim Kopieren als
-- Silbentrennung verloren geht. Der Text im Manuskript bleibt unverändert.
-- Durchgestrichene Einträge (soul) werden übersprungen, weil \st keine
-- Links verträgt.
local function tex_escape(t)
  return (t:gsub('([%%#&_])', '\\%1'))
end

local function arxiv_parts(text)
  return text:match('^arXiv:(%d+%.%d+)([%.,;]?)$')
end

local pass4 = {
  traverse = 'topdown',
  Strikeout = function(el) return el, false end,
  -- Webadressen (<https://…>) nach derselben Regel wie DOIs: Umbruch nur
  -- nach einem Schrägstrich, nie mitten in einem Abschnitt.
  Link = function(el)
    local target = el.target
    if pandoc.utils.stringify(el) ~= target then return nil end
    local prefix, rest = target:match('^(https?://)(.+)$')
    if prefix == nil then return nil end
    local parts = {}
    for seg in (rest .. '/'):gmatch('([^/]*)/') do
      table.insert(parts, seg)
    end
    -- ein abschließender Schrägstrich ergibt ein leeres letztes Glied
    if rest:sub(-1) == '/' then table.remove(parts) end
    local shown = {}
    for k, seg in ipairs(parts) do
      local p = (k == 1) and prefix or ''
      table.insert(shown, '\\mbox{' .. tex_escape(p .. seg) .. '}')
    end
    local tail = (rest:sub(-1) == '/') and '/' or ''
    return pandoc.RawInline('latex',
      '\\href{' .. target:gsub('%%', '\\%%'):gsub('#', '\\#') .. '}{'
      .. table.concat(shown, '/\\allowbreak{}') .. tail .. '}'), false
  end,
  Str = function(el)
    -- arXiv-Nummern ebenfalls als Link, damit alle Kennungen gleich funktionieren
    local ax, axtrail = arxiv_parts(el.text)
    if ax ~= nil then
      return pandoc.RawInline('latex',
        '\\href{https://arxiv.org/abs/' .. ax .. '}{arXiv:' .. ax .. '}' .. axtrail)
    end
    local doi, trail = el.text:match('^doi:(.-)([%.,;]?)$')
    if doi == nil or doi == '' then return nil end
    local parts = {}
    for seg in (doi .. '/'):gmatch('([^/]*)/') do
      table.insert(parts, seg)
    end
    local shown = {}
    for k, seg in ipairs(parts) do
      local prefix = (k == 1) and 'doi:' or ''
      -- sehr lange Abschnitte (SICI-DOIs) zusätzlich nach ) und > umbrechbar
      local piece = tex_escape(seg):gsub('([%)>])', '%1}\\allowbreak{}\\mbox{')
      table.insert(shown, '\\mbox{' .. prefix .. piece .. '}')
    end
    -- spitze Klammern (ältere SICI-DOIs) für den Link-URL kodieren
    local url = doi:gsub('<', '%%3C'):gsub('>', '%%3E')
    return pandoc.RawInline('latex',
      '\\href{https://doi.org/' .. url .. '}{'
      .. table.concat(shown, '/\\allowbreak{}') .. '}' .. trail)
  end
}

-- DOCX: DOIs und arXiv-Nummern als normale Hyperlinks (Text unverändert).
local pass4_docx = {
  traverse = 'topdown',
  Strikeout = function(el) return el, false end,
  Str = function(el)
    local ax, axtrail = arxiv_parts(el.text)
    if ax ~= nil then
      return { pandoc.Link('arXiv:' .. ax, 'https://arxiv.org/abs/' .. ax),
               pandoc.Str(axtrail) }, false
    end
    local doi, trail = el.text:match('^doi:(.-)([%.,;]?)$')
    if doi == nil or doi == '' then return nil end
    local url = (doi:gsub('<', '%%3C'):gsub('>', '%%3E'))
    return { pandoc.Link('doi:' .. doi, 'https://doi.org/' .. url),
             pandoc.Str(trail) }, false
  end
}

-- Pass 0: Terminalabsätze. Alles, was eine Maschine ausgibt oder am Terminal
-- eingegeben wird (Befragung, Freigabeformulare, Systemvermerke, Gates im
-- Nachwort), steht im Manuskript als [Text]{.term .q|.a|.f|.g} und wird in
-- Courier gesetzt, ohne Kursiv und ohne Silbentrennung.
--   .q Eingabe/Frage     bündig            .a Ausgabe/Antwort  um 1,2 em eingerückt
--   .f Formular, System  bündig, Folgezeilen um 1,2 em hängend
--   .g Gate (Nachwort)   wie .f; ein Formular steht immer ungeteilt auf einer Seite
-- Frage und Antwort stehen eng beieinander und brechen nicht auseinander,
-- zwischen den Paaren steht eine halbe Zeile. Kein \needspace: es bricht auf
-- Seiten ohne Dehnung zu früh um; stattdessen \nopagebreak und interlinepenalty.
local TERM_CLASSES = { 'q', 'a', 'f', 'g' }

local function term_class(b)
  if b == nil or b.t ~= 'Para' then return nil end
  local cls, n = nil, 0
  for _, inl in ipairs(b.content) do
    if inl.t == 'Span' and inl.classes:includes('term') then
      for _, c in ipairs(TERM_CLASSES) do
        if cls == nil and inl.classes:includes(c) then cls = c end
      end
      n = n + 1
    elseif inl.t ~= 'SoftBreak' then
      return nil
    end
  end
  if n == 0 then return nil end
  return cls
end

local function term_inlines(b)
  local out = pandoc.List()
  for _, inl in ipairs(b.content) do
    if inl.t == 'Span' then
      out:extend(inl.content)
    elseif inl.t == 'SoftBreak' then
      out:insert(pandoc.LineBreak())
    end
  end
  return out
end

-- Läufe aufeinanderfolgender Terminalabsätze; ruft fn(run) je Lauf auf
local function term_runs(blocks, fn)
  local out = pandoc.List()
  local n = #blocks
  local i = 1
  while i <= n do
    if term_class(blocks[i]) ~= nil then
      local run = pandoc.List()
      while i <= n and term_class(blocks[i]) ~= nil do
        run:insert(blocks[i])
        i = i + 1
      end
      -- eine kurze Überleitung direkt vor einem Formular bleibt bei ihm
      local prev = out[#out]
      if prev ~= nil and prev.t == 'Para' and term_class(run[1]) == 'g'
         and utf8.len(pandoc.utils.stringify(prev)) <= 60 then
        out:insert(pandoc.RawBlock('latex', '\\nopagebreak[4]'))
      end
      out:extend(fn(run))
    else
      out:insert(blocks[i])
      i = i + 1
    end
  end
  return out
end

local function term_latex(run)
  local raw = function(s) return pandoc.RawBlock('latex', s) end
  local out = pandoc.List()
  local dialog = false
  for _, b in ipairs(run) do
    local c = term_class(b)
    if c == 'q' or c == 'a' then dialog = true end
  end
  if dialog then
    out:insert(raw('\\begin{term}{0pt}{0pt}{10}'))
    local prev_q = false
    for i, b in ipairs(run) do
      local is_q = (term_class(b) == 'q')
      if is_q then
        if i > 1 then out:insert(raw('\\vspace{0.5\\baselineskip}')) end
        out:insert(raw('\\leftskip=0pt\\relax'))
      else
        if i > 1 and not prev_q then out:insert(raw('\\vspace{0.5\\baselineskip}')) end
        if prev_q then out:insert(raw('\\nopagebreak[4]')) end
        out:insert(raw('\\leftskip=1.2em\\relax'))
      end
      prev_q = is_q
      out:insert(pandoc.Para(term_inlines(b)))
    end
    out:insert(raw('\\end{term}'))
  else
    out:insert(raw('\\begin{term}{0pt}{0.3\\baselineskip}{10}'))
    out:insert(raw('\\everypar{\\hangindent=1.2em\\hangafter=1\\relax}'))
    for i, b in ipairs(run) do
      if i > 1 then out:insert(raw('\\nopagebreak[4]')) end
      out:insert(pandoc.Para(term_inlines(b)))
    end
    out:insert(raw('\\end{term}'))
  end
  return out
end

local pass0 = {
  Blocks = function(blocks)
    return term_runs(blocks, term_latex)
  end
}

-- DOCX: je Absatz ein Word-Absatz in Courier New 10 pt, gleiche Regeln wie im PDF
local function xml_escape(t)
  return (t:gsub('&', '&amp;'):gsub('<', '&lt;'):gsub('>', '&gt;'))
end

local function term_docx_para(b, cls, before)
  local runs = {}
  local rpr = '<w:rPr><w:rFonts w:ascii="Courier New" w:hAnsi="Courier New" w:cs="Courier New"/>'
    .. '<w:sz w:val="20"/><w:szCs w:val="20"/></w:rPr>'
  local text = {}
  local function flush()
    if #text > 0 then
      table.insert(runs, '<w:r>' .. rpr .. '<w:t xml:space="preserve">'
        .. xml_escape(table.concat(text)) .. '</w:t></w:r>')
      text = {}
    end
  end
  for _, inl in ipairs(b.content) do
    if inl.t == 'Span' then
      table.insert(text, pandoc.utils.stringify(inl))
    elseif inl.t == 'SoftBreak' then
      flush()
      table.insert(runs, '<w:r>' .. rpr .. '<w:br/></w:r>')
    end
  end
  flush()
  local ind = ''
  if cls == 'a' then
    ind = '<w:ind w:left="240"/>'
  elseif cls == 'f' or cls == 'g' then
    ind = '<w:ind w:left="240" w:hanging="240"/>'
  end
  local keep = (cls == 'q') and '<w:keepNext/>' or ''
  return pandoc.RawBlock('openxml', '<w:p><w:pPr>' .. keep
    .. '<w:spacing w:before="' .. before .. '" w:after="0"/>' .. ind .. '</w:pPr>'
    .. table.concat(runs) .. '</w:p>')
end

local function term_docx(run)
  local out = pandoc.List()
  local prev_q = false
  for i, b in ipairs(run) do
    local c = term_class(b)
    local before
    if c == 'q' then
      before = (i == 1) and 120 or 120
    elseif c == 'a' then
      before = prev_q and 0 or 120
    else
      before = (i == 1) and 120 or 60
    end
    prev_q = (c == 'q')
    out:insert(term_docx_para(b, c, before))
  end
  return out
end

local pass0_docx = {
  Blocks = function(blocks)
    return term_runs(blocks, term_docx)
  end
}

-- Für DOCX der Vermerk und die Links; Sternchen und \needspace sind
-- reine Satzregeln für das PDF.
if FORMAT:match('latex') then
  return { pass0, pass1, pass2, pass3, pass4 }
elseif FORMAT:match('docx') then
  return { pass0_docx, pass1_docx, pass4_docx }
else
  return {}
end
