local default_filetypes = {
  { text = "css" },
  { text = "html" },
  { text = "javascript" },
  { text = "javascriptreact" },
  { text = "lua" },
  { text = "markdown" },
  { text = "python" },
  { text = "typescript" },
  { text = "typescriptreact" },
  { text = "java" },
  { text = "kotlin" },
}

local M = {}

local function reset_column_widths() return { 0, 0, 0, 0 } end

local function safe_str(value)
  if value == nil then return "" end
  return tostring(value)
end

local function get_icon(ft)
  local ok, icon = pcall(Snacks.util.icon, ft, "filetype")
  if ok and icon and icon ~= "" then return icon end
  return ""
end

local function normalize_item(item)
  item = item or {}

  item.file = safe_str(item.file)
  item.ft = safe_str(item.ft)
  if item.ft == "" then item.ft = "text" end

  item.name = safe_str(item.name)
  if item.name == "" and item.file ~= "" then item.name = vim.fn.fnamemodify(item.file, ":t:r") end
  if item.name == "" then item.name = "[scratch]" end

  item.cwd = item.cwd and vim.fn.fnamemodify(item.cwd, ":p:~") or ""
  item.cwd = safe_str(item.cwd)

  item.branch = item.branch and ("branch:%s"):format(item.branch) or ""
  item.branch = safe_str(item.branch)

  item.icon = safe_str(item.icon)
  if item.icon == "" then item.icon = get_icon(item.ft) end

  item._path = item.file
  item.preview = { text = item.file }

  return item
end

local function update_column_widths(widths, item)
  widths[1] = math.max(widths[1], vim.api.nvim_strwidth(item.cwd or ""))
  widths[2] = math.max(widths[2], vim.api.nvim_strwidth(item.icon or ""))
  widths[3] = math.max(widths[3], vim.api.nvim_strwidth(item.name or ""))
  widths[4] = math.max(widths[4], vim.api.nvim_strwidth(item.branch or ""))
end

local function format_item_text(item, widths)
  local parts = {
    safe_str(item.cwd),
    safe_str(item.icon),
    safe_str(item.name),
    safe_str(item.branch),
  }

  for i, part in ipairs(parts) do
    local padding = math.max(0, (widths[i] or 0) - vim.api.nvim_strwidth(part))
    parts[i] = part .. string.rep(" ", padding)
  end

  return table.concat(parts, " ")
end

local function load_scratch_items()
  local ok, items = pcall(Snacks.scratch.list)
  if not ok or type(items) ~= "table" then return {} end

  local widths = reset_column_widths()
  local normalized = {}

  for _, item in ipairs(items) do
    local entry = normalize_item(item)
    update_column_widths(widths, entry)
    table.insert(normalized, entry)
  end

  for _, item in ipairs(normalized) do
    item.text = format_item_text(item, widths)
  end

  return normalized
end

function M.select_scratch()
  local items = load_scratch_items()

  if #items == 0 then
    vim.notify("No scratch buffers found", vim.log.levels.INFO)
    return
  end

  Snacks.picker.pick({
    source = "scratch",
    items = items,
    format = "text",
    layout = {
      layout = { title = " Select Scratch Buffer: " },
      preview = "main",
      preset = function() return vim.o.columns >= 120 and "default" or "vertical" end,
    },
    on_change = function() vim.cmd.startinsert() end,
    transform = function(item)
      item = normalize_item(item)
      return item
    end,
    win = {
      input = {
        keys = {
          ["<c-x>"] = { "delete", mode = { "i", "n" } },
        },
      },
    },
    actions = {
      delete = function(picker, item)
        if not item or not item.file or item.file == "" then return end

        local ok, err = os.remove(item.file)
        if not ok and err then
          vim.notify(("Failed to delete scratch: %s"):format(err), vim.log.levels.ERROR)
          return
        end

        picker:close()
        vim.schedule(function() M.select_scratch() end)
      end,
    },
    confirm = function(_, item)
      if not item or not item.file or item.file == "" then return end

      -- Открываем только по file — НЕ трогаем ft/name/icon, чтобы избежать E474
      Snacks.scratch.open({ file = item.file })
    end,
  })
end

function M.new_scratch(filetypes)
  local items = filetypes or default_filetypes

  Snacks.picker.pick({
    source = "scratch",
    items = items,
    format = "text",
    layout = {
      preset = "vscode",
      preview = "main",
      layout = { title = " Select a filetype: " },
    },
    actions = {
      confirm = function(picker, item)
        picker:close()

        vim.schedule(function()
          local ft = item and item.text or nil

          if not ft or ft == "" then
            local filter = picker.filter and picker:filter() or nil
            ft = filter and filter.pattern or ""
          end

          if ft ~= "" then
            Snacks.scratch.open({ ft = ft })
          else
            Snacks.scratch.open()
          end
        end)
      end,
    },
  })
end

return M

-- vim: ts=2 sts=2 sw=2 et
