return {
  -- {
  --   "nvim-telescope/telescope.nvim",
  --   opts = {
  --     defaults = {
  --       sorting_strategy = "ascending",
  --       layout_strategy = "horizontal",
  --       layout_config = { horizontal = { prompt_position = "top", preview_width = 0.6 } },
  --     },
  --   },
  -- },

  {
    "folke/snacks.nvim",
    priority = 1000,
    opts = {
      notifier = { enabled = true, timeout = 5000 },
      scroll = { enabled = false },
    },
  },

  { "folke/persistence.nvim", event = "BufReadPre", opts = { need = 0 } },
  { "akinsho/bufferline.nvim", enabled = false },

  { "Yu-Leo/blame-column.nvim" },

  {
    "nvim-mini/mini.hipatterns",
    opts = {
      highlighters = {
        tab_after_nontab = { group = "ExtraWhitespace", pattern = "[^\t]()\t+()" },
        trailing_whspace = { group = "ExtraWhitespace", pattern = "%f[%s]%s*$" },
        spaces_befor_tab = { group = "ExtraWhitespace", pattern = " +\t%s*" },
        tab_before_space = { group = "ExtraWhitespace", pattern = "\t+ %s*" },
        line_over_length = { group = "OverLength", pattern = "^" .. (("."):rep(160)) .. "().+" },

        fixm = { pattern = "%f[%w]()FIXME()%f[%W]", group = "MiniHipatternsFixme" },
        hack = { pattern = "%f[%w]()HACK()%f[%W]", group = "MiniHipatternsHack" },
        todo = { pattern = "%f[%w]()TODO()%f[%W]", group = "MiniHipatternsTodo" },
        note = { pattern = "%f[%w]()NOTE()%f[%W]", group = "MiniHipatternsNote" },
      },
    },
  },

  -- additional colorschemes
  { "EdenEast/nightfox.nvim" },
  { "rose-pine/neovim" },
}

-- vim: ts=2 sts=2 sw=2 et
