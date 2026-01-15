return {
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    cmd = "Mason",
    config = function()
      require("mason").setup()
      -- Notify user about required tools
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyDone",
        callback = function()
          vim.schedule(function()
            local mr = require("mason-registry")
            local required_tools = {"rust-analyzer", "codelldb"}
            local missing_tools = {}
            for _, tool in ipairs(required_tools) do
              if not mr.is_installed(tool) then
                table.insert(missing_tools, tool)
              end
            end
            if #missing_tools > 0 then
              vim.notify(
                "Some required tools are not installed. Please run:\n" ..
                ":MasonInstall " .. table.concat(missing_tools, " "),
                vim.log.levels.WARN
              )
            end
          end)
        end,
      })
    end,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    opts = {
      ensure_installed = {
        "rust_analyzer",
      },
      automatic_installation = true,
    },
  },

  "chrisgrieser/nvim-rip-substitute",
  keys = {
    {
      "g/",
      function()
        require("rip-substitute").sub()
      end,
      mode = { "n", "x" },
      desc = "Rip Substitute",
    },
  },

  {
    "stevearc/conform.nvim",
    event = 'BufWritePre', -- uncomment for format on save
    opts = require "configs.conform",
  },

  -- These are some examples, uncomment them if you want to see them work!
  {
    "neovim/nvim-lspconfig",
    config = function()
      require "configs.lspconfig"
    end,
  },

  {
    'mrcjkb/rustaceanvim',
    version = 'v6.3.1',
    lazy = false,
    ft = "rust",
    config = function()
      vim.g.rustaceanvim = {
        -- Server settings
        server = {
          on_attach = function(client, bufnr)
            -- Enable inlay hints
            vim.lsp.inlay_hint.enable(true, { bufnr = bufnr })
            
            -- Enable format on save
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({ bufnr = bufnr })
              end,
            })
          end,
          settings = {
            -- Enable rustfmt on save
            ['rust-analyzer'] = {
              checkOnSave = true,
              -- Automatic format on save
              format = {
                enable = true,
              },
            },
          },
        },
        -- Tools settings
        tools = {
          hover_actions = {
            auto_focus = true,
          },
        },
      }

      -- Set up format on save
      vim.g.rustfmt_autosave = 1
      vim.g.rustfmt_emit_files = 1
      vim.g.rustfmt_fail_silently = 0

      -- Set up DAP if codelldb is available
      vim.api.nvim_create_autocmd("User", {
        pattern = "LazyDone",
        callback = function()
          vim.schedule(function()
            local mr = require("mason-registry")
            if not mr.is_installed("codelldb") then
              vim.notify("Rustaceanvim: 'codelldb' is not installed via Mason. Please install it using :MasonInstall codelldb for Rust debugging.", vim.log.levels.WARN)
            else
              -- Get package details into a distinct variable
              local codelldb_pkg = mr.get_package("codelldb")
              if not codelldb_pkg then
                vim.notify("Rustaceanvim: 'codelldb' is installed but Mason could not provide package details. Rust DAP setup skipped. You might need to run :MasonUpdate or check Mason's health.", vim.log.levels.WARN)
              else
                -- Now it's safe to use codelldb_pkg
                local extension_path = vim.fn.stdpath("data") .. "/mason/packages/codelldb/extension/"
                local codelldb_path = extension_path .. "adapter/codelldb"
                local liblldb_path = extension_path .. "lldb/lib/liblldb.so"
                -- vim.notify("Rustaceanvim DAP: CodeLLDB extension path: " .. extension_path, vim.log.levels.INFO)
                -- vim.notify("Rustaceanvim DAP: CodeLLDB adapter path: " .. codelldb_path, vim.log.levels.INFO)
                -- vim.notify("Rustaceanvim DAP: CodeLLDB library path: " .. liblldb_path, vim.log.levels.INFO)
                local cfg_rustacean = require('rustaceanvim.config')
                if not cfg_rustacean or type(cfg_rustacean.get_codelldb_adapter) ~= "function" then
                  vim.notify("Rustaceanvim: Error loading rustaceanvim.config or get_codelldb_adapter function missing. DAP setup skipped.", vim.log.levels.ERROR)
                else
                  vim.g.rustaceanvim = vim.tbl_deep_extend("force", vim.g.rustaceanvim, {
                    dap = {
                      adapter = cfg_rustacean.get_codelldb_adapter(codelldb_path, liblldb_path),
                    },
                  })
                  -- vim.notify("Rustaceanvim: Successfully configured DAP for codelldb.", vim.log.levels.INFO) -- Added success notification
                end
              end
            end
          end)
        end,
      })
    end
  },

  {
    'mfussenegger/nvim-dap',
    config = function()
      local dap, dapui = require("dap"), require("dapui")
      dap.listeners.before.attach.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.launch.dapui_config = function()
        dapui.open()
      end
      dap.listeners.before.event_terminated.dapui_config = function()
        dapui.close()
      end
      dap.listeners.before.event_exited.dapui_config = function()
        dapui.close()
      end
    end,
  },

  {
    'rcarriga/nvim-dap-ui', 
    dependencies = {"mfussenegger/nvim-dap", "nvim-neotest/nvim-nio"},
    config = function()
      require("dapui").setup()
    end,
  },

  {
    'saecki/crates.nvim',
    ft = {"toml"},
    config = function()
      require("crates").setup {
        completion = {
          cmp = {
            enabled = true
          },
        },
      }
      -- cmp.setup.buffer call removed
    end
  },
  { import = "custom.configs.cmp" },
}
