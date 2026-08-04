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
local delay = 1000 -- 1 second

local uv = vim.uv or vim.loop

vim.api.nvim_create_autocmd({ "TextChanged", "TextChangedI", "FocusLost" }, {
  group = vim.api.nvim_create_augroup("DebouncedAutoSaveStrict", { clear = true }),
  callback = function()
    if not vim.bo.modified then return end

    if save_timer then
      save_timer:stop()
      save_timer:close()
      save_timer = nil
    end

    save_timer = uv.new_timer()

    if save_timer then
      save_timer:start(
        delay,
        0,
        vim.schedule_wrap(function()
          save_timer = nil
          if not vim.api.nvim_buf_is_valid(0) or not vim.bo.modified then return end
          local buf_name = vim.api.nvim_buf_get_name(0)

          if buf_name == "" then
            local timestamp = os.date("%Y%m%d_%H%M%S")
            local tmp_name = autosave_dir .. "untitled_" .. timestamp .. ".txt"
            vim.api.nvim_buf_set_name(0, tmp_name)
            vim.cmd("silent! write")
            vim.notify("Autosave: " .. vim.fn.fnamemodify(tmp_name, ":t"), vim.log.levels.INFO)
          else
            if vim.bo.buftype == "" then vim.cmd("silent! write") end
          end
        end)
      )
    end
  end,
})

--
-- by default, no autoformat and diagnostics for markdown
--
vim.api.nvim_create_autocmd("FileType", {
  group = (vim.api.nvim_create_augroup("MarkdownSettings", { clear = true })),
  pattern = "markdown",
  callback = function(event)
    vim.b[event.buf].autoformat = false
    vim.diagnostic.enable(false, { bufnr = event.buf })
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
