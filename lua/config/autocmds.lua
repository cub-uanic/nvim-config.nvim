-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

--
-- Autosave logic
--

local autosave_dir = vim.fn.expand("~/.local/state/nvim/autosave/")
if vim.fn.isdirectory(autosave_dir) == 0 then vim.fn.mkdir(autosave_dir, "p") end

local save_timer = nil
local uv = vim.uv or vim.loop

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "FocusLost" }, {
  group = vim.api.nvim_create_augroup("DebouncedAutoSaveStrict", { clear = true }),
  callback = function(event)
    if not vim.api.nvim_buf_is_valid(event.buf) or not vim.bo[event.buf].modified or vim.b[event.buf].autoformat == false then
      -- vim.notify("Autosave by autocmd/DebouncedAutoSaveStrict skipped")
      return
    end

    if save_timer then
      save_timer:stop()
      save_timer:close()
      save_timer = nil
    end

    save_timer = uv.new_timer()

    if save_timer then
      save_timer:start(
        vim.o.updatetime,
        0,
        vim.schedule_wrap(function()
          save_timer = nil
          if not vim.api.nvim_buf_is_valid(event.buf) or not vim.bo[event.buf].modified or vim.b[event.buf].autoformat == false then
            -- vim.notify("Autosave by timer/DebouncedAutoSaveStrict skipped")
            return
          end
          local buf_name = vim.api.nvim_buf_get_name(event.buf)

          if buf_name == "" then
            local timestamp = os.date("%Y%m%d_%H%M%S")
            local tmp_name = autosave_dir .. "untitled_" .. timestamp .. ".txt"
            vim.api.nvim_buf_set_name(event.buf, tmp_name)
            vim.cmd("silent! write")
            vim.notify("Autosaved by DebouncedAutoSaveStrict (Untitled): " .. vim.fn.fnamemodify(tmp_name, ":t"), vim.log.levels.INFO)
          else
            if vim.bo[event.buf].buftype == "" then
              vim.cmd("silent! write")
              vim.notify("Autosaved by DebouncedAutoSaveStrict: " .. vim.fn.fnamemodify(buf_name, ":t"), vim.log.levels.INFO)
            end
          end
        end)
      )
    end
  end,
})

--
-- make diagnostics more visible
--
vim.diagnostic.config({
  float = {
    border = "rounded", -- "single", "double", "rounded", "solid", "shadow"
  },
})

--
-- by default, no autoformat and diagnostics for some filetypes
--
vim.api.nvim_create_autocmd("FileType", {
  group = (vim.api.nvim_create_augroup("CustomSettings", { clear = true })),
  pattern = { "perl", "javascript", "markdown" },
  callback = function(event)
    vim.b[event.buf].autoformat = false
    vim.diagnostic.enable(false, { bufnr = event.buf })
  end,
})

--
-- support for lua modelines
--
vim.api.nvim_create_autocmd({ "BufReadPost", "BufNewFile" }, {
  pattern = "*",
  callback = function()
    local max_lines = vim.o.modelines
    if max_lines <= 0 then return end

    local bufnr = vim.api.nvim_get_current_buf()
    local line_count = vim.api.nvim_buf_line_count(bufnr)
    local lines_to_check = {}

    local top_end = math.min(max_lines, line_count)
    if top_end > 0 then
      local top_lines = vim.api.nvim_buf_get_lines(bufnr, 0, top_end, false)
      for _, l in ipairs(top_lines) do
        table.insert(lines_to_check, l)
      end
    end

    if line_count > top_end then
      local bot_start = math.max(top_end, line_count - max_lines)
      local bot_lines = vim.api.nvim_buf_get_lines(bufnr, bot_start, line_count, false)
      for _, l in ipairs(bot_lines) do
        table.insert(lines_to_check, l)
      end
    end

    -- support: "lua option=value" or "lua: set option=value:"
    for _, line in ipairs(lines_to_check) do
      local match = line:match("%slua%s+(.+)$") or line:match("%slua%s*:%s*(.+)$")

      if match then
        match = match:gsub(":%s*$", "")
        match = match:gsub("^set%s+", "")

        for item in string.gmatch(match, "[^%s:]+") do
          local key, val = item:match("([^=]+)=([^=]+)")
          if key and val then
            local typed_val = val
            if val == "true" then
              typed_val = true
            elseif val == "false" then
              typed_val = false
            elseif tonumber(val) then
              typed_val = tonumber(val)
            end

            if key:match("^vim%.b%.") then
              local clean_key = key:gsub("^vim%.b%.", "")
              vim.b[clean_key] = typed_val
            elseif key:match("^vim%.g%.") then
              local clean_key = key:gsub("^vim%.g%.", "")
              vim.g[clean_key] = typed_val
            else
              vim.b[key] = typed_val
            end
          end
        end
      end
    end
  end,
})

--
-- load last session
--
vim.schedule(function()
  local ok, persistence = pcall(require, "persistence")
  if ok and vim.fn.argc() == 0 then
    persistence.load()
    vim.notify("Session loaded from " .. persistence.current(), vim.log.levels.INFO)
  end
end)

-- vim: ts=2 sts=2 sw=2 et
