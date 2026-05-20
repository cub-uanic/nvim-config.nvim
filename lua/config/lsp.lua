-- vim.lsp.config()

require("lspconfig").lua_ls.setup({
  settings = {
    Lua = {
      diagnostics = {
        globals = {
          "vim",
          "require",
          "Lazy",
          "LazyVim",
          "Snacks",
        },
      },
    },
  },
})

-- vim: ts=2 sts=2 sw=2 et
