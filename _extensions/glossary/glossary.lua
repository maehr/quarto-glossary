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

  -- this will only run for HTML documents
  if not quarto.doc.isFormat("html:js") then
    return pandoc.Null()
  end

  addHTMLDeps()

  -- create glossary table
  if kwExists(kwargs, "table") then
    -- Generate a Quarto listing instead of a simple HTML table
    local sortedTable = sortByKeys(globalGlossaryTable)
    
    -- Create JSON data for the listing manually
    local jsonItems = {}
    for key, value in pairs(sortedTable) do
        -- Escape JSON strings
        local escapedKey = key:gsub('"', '\\"'):gsub('\n', '\\n')
        local escapedValue = value:gsub('"', '\\"'):gsub('\n', '\\n')
        table.insert(jsonItems, string.format('{"term":"%s","definition":"%s"}', escapedKey, escapedValue))
    end
    local itemsJson = '[' .. table.concat(jsonItems, ',') .. ']'
    
    -- Create the listing HTML with embedded data
    local listingHtml = string.format([[
<div id="glossary-listing" class="quarto-listing">
<script type="application/json" data-glossary-items>%s</script>
<div class="listing-controls mb-3">
  <div class="row">
    <div class="col-md-8">
      <input type="text" id="glossary-search" class="form-control" placeholder="Search terms..." />
    </div>
    <div class="col-md-4">
      <select id="glossary-sort" class="form-control">
        <option value="term-asc">Term (A-Z)</option>
        <option value="term-desc">Term (Z-A)</option>
      </select>
    </div>
  </div>
</div>
<div id="glossary-items" class="list-group">
  <!-- Items will be populated by JavaScript -->
</div>
</div>
]], itemsJson)
    
    return pandoc.RawBlock('html', listingHtml)
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

}
