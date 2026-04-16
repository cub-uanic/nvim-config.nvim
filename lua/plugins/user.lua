return {
  {
    "nvim-telescope/telescope.nvim",
    opts = function(_, opts)
      opts = opts or {}
      opts.defaults = vim.tbl_deep_extend("force", opts.defaults or {}, {
        sorting_strategy = "ascending",
        layout_strategy = "horizontal",
        layout_config = { horizontal = { prompt_position = "top", preview_width = 0.6 } },
      })
      return opts
    end,
  },

  { "folke/snacks.nvim", priority = 1000, opts = { scroll = { enabled = false } } },
  { "folke/persistence.nvim", event = "BufReadPre", opts = { need = 0 } },
  { "akinsho/bufferline.nvim", enabled = false },

  { "EdenEast/nightfox.nvim" },
  { "rose-pine/neovim" },

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
}

-- vim: ts=2 sts=2 sw=2 et
