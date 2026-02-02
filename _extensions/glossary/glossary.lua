-- Glossary.lua
-- Author: Lisa DeBruine

-- Global glossary table
globalGlossaryTable = {}

-- Helper Functions

local function addHTMLDeps()
  -- add the HTML requirements for the library used
    quarto.doc.add_html_dependency({
    name = 'glossary',
    stylesheets = {'glossary.css'},
    scripts = {'glossary.js'}
  })
end

local function kwExists(kwargs, keyword)
    for key, value in pairs(kwargs) do
        if key == keyword then
            return true
        end
    end
    return false
end

-- Function to sort a Lua table by keys
function sortByKeys(tbl)
    local sortedKeys = {}

    -- Extract keys from the table and store them in the 'sortedKeys' array
    for key, _ in pairs(tbl) do
        table.insert(sortedKeys, key)
    end

    -- Sort the keys alphabetically
    table.sort(sortedKeys)

    -- Create a new table with the sorted keys
    local sortedTable = {}
    for _, key in pairs(sortedKeys) do
        sortedTable[key] = tbl[key]
    end

    return sortedTable
end

local function read_metadata_file(fname)
  local metafile = io.open(fname, 'r')
  local content = metafile:read("*a")
  metafile:close()
  local metadata = pandoc.read(content, "markdown").meta
  return metadata
end

local function readGlossary(path)
  local f = io.open(path, "r")
  if not f then
    io.stderr:write("Cannot open file " .. path)
  else
    local lines = f:read("*all")
    f:close()
    return(lines)
  end
end

local function parseInlines(text)
  if text == nil or text == "" then
    return {}
  end
  local ok, doc = pcall(pandoc.read, text, "markdown")
  if ok and doc ~= nil and #doc.blocks > 0 then
    local first = doc.blocks[1]
    if first.t == "Para" or first.t == "Plain" then
      return first.content
    end
  end
  return { pandoc.Str(text) }
end

local function parseBlocks(text)
  if text == nil or text == "" then
    return {}
  end
  local ok, doc = pcall(pandoc.read, text, "markdown")
  if ok and doc ~= nil and doc.blocks ~= nil then
    return doc.blocks
  end
  return { pandoc.Para({ pandoc.Str(text) }) }
end

local function copyInlines(inlines)
  local clone = pandoc.utils and pandoc.utils.clone
  if clone then
    local cloned = {}
    for _, inline in ipairs(inlines) do
      table.insert(cloned, clone(inline))
    end
    return cloned
  end

  local function deep_copy_table(value)
    if type(value) ~= "table" then
      return value
    end
    local copied = {}
    for index, item in ipairs(value) do
      copied[index] = deep_copy_table(item)
    end
    for key, item in pairs(value) do
      if type(key) ~= "number" then
        copied[key] = deep_copy_table(item)
      end
    end
    return setmetatable(copied, getmetatable(value))
  end

  return deep_copy_table(inlines)
end

---Merge user provided options with defaults
---@param userOptions table
local function mergeOptions(userOptions, meta)
  local defaultOptions = {
    path = "glossary.yml",
    popup = "click",
    show = true,
    add_to_table = true
  }

  -- override with meta values first
  if meta.glossary ~= nil then
    for k, v in pairs(meta.glossary) do
      local value = pandoc.utils.stringify(v)
      if value == 'true' then value = true end
      if value == 'false' then value = false end
      defaultOptions[k] = value
    end
  end

  -- then override with function keyword values
  if userOptions ~= nil then
    for k, v in pairs(userOptions) do
      local value = pandoc.utils.stringify(v)
      if value == 'true' then value = true end
      if value == 'false' then value = false end
      defaultOptions[k] = value
    end
  end

  return defaultOptions
end


-- Main Glossary Function Shortcode

return {

["glossary"] = function(args, kwargs, meta)

  local is_html = quarto.doc.isFormat("html:js")

  if is_html then
    addHTMLDeps()
  end

  -- create glossary table
  if kwExists(kwargs, "table") then
    local sortedTable = sortByKeys(globalGlossaryTable)

    if is_html then
      local gt = "<table class='glossary_table'>\n"
      gt = gt .. "<tr><th> Term </th><th> Definition </th></tr>\n"

      for key, value in pairs(sortedTable) do
          gt = gt .. "<tr><td>" .. key
          gt = gt .. "</td><td>" .. value .. "</td></tr>\n"
      end
      gt = gt .. "</table>"

      return pandoc.RawBlock('html', gt)
    end

    local entries = {}
    for key, value in pairs(sortedTable) do
      local termInlines = parseInlines(key)
      local definitionBlocks = parseBlocks(value)
      -- DefinitionList expects a list of definition block lists.
      local definitions = { definitionBlocks }
      table.insert(entries, { termInlines, definitions })
    end

    return pandoc.DefinitionList(entries)
  end

  -- or set up in-text term
  local options = mergeOptions(kwargs, meta)

  local display = pandoc.utils.stringify(args[1])
  local term = string.lower(display)

  if kwExists(kwargs, "display") then
    display = pandoc.utils.stringify(kwargs.display)
  end

  -- get definition
  local def = ""
  if kwExists(kwargs, "def") then
    def = pandoc.utils.stringify(kwargs.def)
  else
    local metafile = io.open(options.path, 'r')
    local content = "---\n" .. metafile:read("*a") .. "\n---\n"
    metafile:close()
    local glossary = pandoc.read(content, "markdown").meta
    for key, value in pairs(glossary) do
      glossary[string.lower(key)] = value
    end
    -- quarto.log.output()
    if kwExists(glossary, term) then
      def = pandoc.utils.stringify(glossary[term])
    end
  end

  -- add to global table
  if options.add_to_table then
    globalGlossaryTable[term] = def
  end

  if is_html then
    -- Generate unique ID for this glossary term (still needed for potential future use)
    local glossary_id = "glossary-" .. term:gsub("%s+", "-"):gsub("[^%w%-]", "") .. "-" .. math.random(1000, 9999)

    if options.popup == "click" then
      -- Use Bootstrap popover with accessible attributes
      glosstext = "<button class='glossary' " ..
                  "id='" .. glossary_id .. "' " ..
                  "data-bs-toggle='popover' " ..
                  "data-bs-content='" .. def:gsub("'", "&apos;") .. "' " ..
                  "data-bs-trigger='click' " ..
                  "data-bs-placement='top' " ..
                  "tabindex='0' " ..
                  "data-glossary-term='" .. term .. "'>" ..
                  display .. "</button>"
    elseif options.popup == "none" then
      glosstext = "<span class='glossary'>" .. display .. "</span>"
    else
      -- Default to click behavior for any other option (including former "hover")
      glosstext = "<button class='glossary' " ..
                  "id='" .. glossary_id .. "' " ..
                  "data-bs-toggle='popover' " ..
                  "data-bs-content='" .. def:gsub("'", "&apos;") .. "' " ..
                  "data-bs-trigger='click' " ..
                  "data-bs-placement='top' " ..
                  "tabindex='0' " ..
                  "data-glossary-term='" .. term .. "'>" ..
                  display .. "</button>"
    end

    return pandoc.RawInline("html", glosstext)
  end

  local inlines = parseInlines(display)
  local defBlocks = parseBlocks(def)
  if options.popup == "none" or #defBlocks == 0 then
    return pandoc.Span(inlines)
  end

  -- Copy inlines so appending a note does not mutate the base term content.
  local noteInlines = copyInlines(inlines)
  table.insert(noteInlines, pandoc.Note(defBlocks))
  return pandoc.Span(noteInlines)

end

}
