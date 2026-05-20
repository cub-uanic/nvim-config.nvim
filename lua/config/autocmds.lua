-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- load last session
vim.schedule(function()
  local ok, persistence = pcall(require, "persistence")
  if ok and vim.fn.argc() == 0 then
    persistence.load()
    vim.notify("Session loaded", vim.log.levels.INFO)
  end
end)

-- vim: ts=2 sts=2 sw=2 et
