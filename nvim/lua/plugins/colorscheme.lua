return {
  -- add gruvbox
  { "ellisonleao/gruvbox.nvim" },

  { "nvim-tree/nvim-web-devicons", lazy = true },
  -- Configure LazyVim to load gruvbox
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "gruvbox",
    },
  },
}
