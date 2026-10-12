-- Neovim 0.11.5 ships native C and Lua Tree-sitter parsers.
local augroup = vim.api.nvim_create_augroup('RosieTreesitter', { clear = true })
vim.api.nvim_create_autocmd('FileType', {
        group = augroup,
        pattern = { 'c', 'lua' },
        callback = function(args)
                vim.treesitter.start(args.buf)
        end,
})
