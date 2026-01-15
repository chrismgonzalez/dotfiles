-- lua/custom/configs/cmp.lua
local cmp = require("cmp")
local types = require("cmp.types")
local luasnip = require("luasnip") -- Assuming NvChad includes LuaSnip or it's added separately

return {
  {
    "Exafunction/codeium.nvim",
    event = "BufEnter",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "hrsh7th/nvim-cmp", -- Ensure cmp is a dependency
    },
  },
  {
    "hrsh7th/nvim-cmp",
    event = "InsertEnter", -- Load cmp when entering insert mode
    dependencies = {
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
      "hrsh7th/cmp-nvim-lsp",
      "L3MON4D3/LuaSnip", -- NvChad often includes this or a similar snippet engine
      "saadparwaiz1/cmp_luasnip", -- Snippet source for cmp
      -- Potentially: "rafamadriz/friendly-snippets" for a set of snippets
    },
    config = function()
      local cmp_config = require("nvchad.configs.cmp") -- Start with NvChad's base cmp config

      -- Augment NvChad's cmp config
      cmp_config.sources = cmp.config.sources({
        { name = "codeium", priority = 100, group_index = 1 }, -- High priority for Codeium
        { name = "nvim_lsp", group_index = 1 },
        { name = "luasnip", group_index = 1 },
        { name = "buffer", group_index = 2 },
        { name = "path", group_index = 2 },
        -- { name = "crates" } -- This will be handled in the next step
      })

      -- Customize behavior: e.g., auto-select first item, complete as you type
      cmp_config.preselect = cmp.PreselectMode.Item
      cmp_config.completion = {
        completeopt = "menu,menuone,noinsert,noselect",
        autocomplete = { cmp.TriggerEvent.InsertEnter, cmp.TriggerEvent.TextChanged }
      }

      -- Ensure NvChad's mapping setup is preserved or enhanced
      -- NvChad's default mappings are generally good. We are modifying the sources
      -- and adding autocompletion. If specific mappings are needed, they'd go here.
      -- For example, to ensure <CR> confirms and Tab/S-Tab navigate:
      cmp_config.mapping = cmp.mapping.preset.insert(vim.tbl_extend("force", cmp_config.mapping, {
        ["<CR>"] = cmp.mapping.confirm({ select = true }), -- Confirm with Enter
        ["<Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_next_item()
          elseif luasnip.expand_or_jumpable() then
            luasnip.expand_or_jump()
          else
            fallback()
          end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
          if cmp.visible() then
            cmp.select_prev_item()
          elseif luasnip.jumpable(-1) then
            luasnip.jump(-1)
          else
            fallback()
          end
        end, { "i", "s" }),
      }))

      -- Configure 'crates' source for TOML files (Cargo.toml)
      cmp.setup.filetype({ "toml" }, {
        sources = cmp.config.sources({
          { name = "crates" },
        }, {
          { name = "nvim_lsp" }, -- other sources for toml if needed
          { name = "luasnip" },
          { name = "buffer" },
          { name = "path" },
        }),
      })

      cmp.setup(cmp_config)
    end,
  },
  -- Add LuaSnip and its cmp source if not already part of NvChad's defaults
  -- or if a specific version/configuration is needed.
  -- NvChad usually has a snippet solution, so this might be redundant
  -- if NvChad's cmp_config already sets up luasnip.
  -- For now, we list them as dependencies for nvim-cmp.
  -- { "L3MON4D3/LuaSnip", dependencies = { "rafamadriz/friendly-snippets" }, build = "make install_jsregexp" },
  -- { "saadparwaiz1/cmp_luasnip" },
}
