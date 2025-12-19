vim.api.nvim_create_autocmd('FileType', {
        pattern = { 'c', 'lua' },
        callback = function() vim.treesitter.start() end,
})
