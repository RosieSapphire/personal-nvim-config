-- Better path searching --
vim.opt.path:append("**")

-- Lines & Numbers --
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.wrap           = true

-- Tabs --
vim.opt.expandtab   = false
vim.opt.tabstop     = 8
vim.opt.softtabstop = 8
vim.opt.shiftwidth  = 8
vim.opt.smartindent = true
vim.opt.autoindent  = true

-- Columns --
vim.opt.scrolloff   = 8
vim.opt.signcolumn  = 'yes' -- Figure out what this does
vim.opt.colorcolumn = '80'

-- Diagnostics --
vim.diagnostic.config({
        virtual_text = false,
        signs        = true,
        underline    = true,
        float = { border = 'rounded', focusable = false }
})

vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        pattern  = '*',
        callback = function()
                vim.diagnostic.open_float(nil, { focus = false })
        end
})

vim.api.nvim_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", {
        noremap = true, silent = true
})

-- Etc --
vim.opt.updatetime = 250
vim.opt.cinoptions:append({':0'})
