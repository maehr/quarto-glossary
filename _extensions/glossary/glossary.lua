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

-- Function to escape JSON strings
local function escapeJson(str)
    if str == nil then return "null" end
    str = tostring(str)
    -- Replace backslashes first to avoid double escaping
    str = str:gsub("\\", "\\\\")
    -- Replace quotes
    str = str:gsub('"', '\\"')
    -- Replace control characters
    str = str:gsub("\n", "\\n")
    str = str:gsub("\r", "\\r")
    str = str:gsub("\t", "\\t")
    -- Replace form feed and backspace (rare but possible)
    str = str:gsub("\f", "\\f")
    str = str:gsub("\b", "\\b")
    return '"' .. str .. '"'
end

-- Function to generate JSON data for Quarto listing
local function generateGlossaryJson(glossaryTable)
    local jsonItems = {}
    local sortedTable = sortByKeys(glossaryTable)
    
    for term, definition in pairs(sortedTable) do
        local jsonItem = '{"term": ' .. escapeJson(term) .. ', "definition": ' .. escapeJson(definition) .. '}'
        table.insert(jsonItems, jsonItem)
    end
    
    return '[' .. table.concat(jsonItems, ', ') .. ']'
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
    -- Generate JSON data for the glossary
    local jsonData = generateGlossaryJson(globalGlossaryTable)
    
    -- Generate Quarto listing div with proper attributes
    local listingHtml = [[
<div id="glossary-listing" data-listing-type="default">
  <div class="listing-search">
    <input type="search" placeholder="Search terms..." class="form-control search" id="listing-search">
  </div>
  <div class="listing-container">
    <div class="listing-header">
      <div class="listing-sort">
        <button class="listing-sort-btn btn btn-outline-secondary" data-sort="term">Term</button>
        <button class="listing-sort-btn btn btn-outline-secondary" data-sort="definition">Definition</button>
      </div>
    </div>
    <div class="listing-content">
      <div class="listing-items">
        <!-- Items will be populated by JavaScript -->
      </div>
    </div>
  </div>
</div>

<script>
// Initialize glossary listing
(function() {
  const glossaryData = ]] .. jsonData .. [[;
  let filteredData = [...glossaryData];
  let sortField = 'term';
  let sortOrder = 'asc';
  
  function renderItems() {
    const container = document.querySelector('#glossary-listing .listing-items');
    if (!container) return;
    
    container.innerHTML = filteredData.map(item => 
      `<div class="listing-item glossary-item">
        <div class="glossary-term">${escapeHtml(item.term)}</div>
        <div class="glossary-definition">${escapeHtml(item.definition)}</div>
      </div>`
    ).join('');
  }
  
  function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
  }
  
  function sortData(field) {
    if (sortField === field) {
      sortOrder = sortOrder === 'asc' ? 'desc' : 'asc';
    } else {
      sortField = field;
      sortOrder = 'asc';
    }
    
    filteredData.sort((a, b) => {
      const valA = a[field].toLowerCase();
      const valB = b[field].toLowerCase();
      const comparison = valA.localeCompare(valB);
      return sortOrder === 'asc' ? comparison : -comparison;
    });
    
    // Update button states
    document.querySelectorAll('.listing-sort-btn').forEach(btn => {
      btn.classList.remove('active', 'asc', 'desc');
      if (btn.dataset.sort === field) {
        btn.classList.add('active', sortOrder);
      }
    });
    
    renderItems();
  }
  
  function filterData(searchTerm) {
    const term = searchTerm.toLowerCase();
    filteredData = glossaryData.filter(item => 
      item.term.toLowerCase().includes(term) || 
      item.definition.toLowerCase().includes(term)
    );
    renderItems();
  }
  
  // Initialize when DOM is ready
  function init() {
    // Set up search
    const searchInput = document.querySelector('#listing-search');
    if (searchInput) {
      searchInput.addEventListener('input', (e) => filterData(e.target.value));
    }
    
    // Set up sorting
    document.querySelectorAll('.listing-sort-btn').forEach(btn => {
      btn.addEventListener('click', () => sortData(btn.dataset.sort));
    });
    
    // Initial sort and render
    sortData('term');
  }
  
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', init);
  } else {
    init();
  }
})();
</script>
]]

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
