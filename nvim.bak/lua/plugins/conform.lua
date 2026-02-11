-- ============================================================================
-- conform.nvim Configuration
-- ============================================================================
-- This file configures conform.nvim, the formatter plugin used by LazyVim.
--
-- Purpose:
--   Customize which formatters are used for different file types and control
--   automatic formatting behavior on save.
--
-- Default Behavior (LazyVim):
--   - Auto-formats files on save via BufWritePre autocmd
--   - Falls back to LSP formatting if no explicit formatter is configured
--   - Can be toggled globally with <leader>uf or per-buffer with <leader>uF
--
-- Current Configuration:
--   - Python: Auto-formatting DISABLED (empty formatter list)
--     * Prevents automatic code reformatting on save
--     * Manual formatting still available via <leader>cf
--   - Other languages: Use default LazyVim formatters
--
-- How to Add Formatters:
--   formatters_by_ft = {
--     javascript = { "prettier" },
--     python = { "black", "isort" },  -- Example: enable multiple formatters
--     lua = { "stylua" },
--   }
--
-- How to Disable Auto-Format Globally:
--   Add to lua/config/options.lua: vim.g.autoformat = false
--
-- Useful Commands:
--   :LazyFormatInfo     - Show active formatters and auto-format status
--   <leader>uf          - Toggle auto-format globally
--   <leader>uF          - Toggle auto-format for current buffer
--   <leader>cf          - Manually format current buffer
-- ============================================================================

return {
  "stevearc/conform.nvim",
  opts = {
    formatters_by_ft = {
      python = {
        -- To fix auto-fixable lint errors.
        "ruff_fix",
        -- To run the Ruff formatter.
        "ruff_format",
        -- To organize the imports.
        "ruff_organize_imports",
      },
    },
  },
}
