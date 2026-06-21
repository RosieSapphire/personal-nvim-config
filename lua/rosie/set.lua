-- Lines & Numbers --
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.wrap           = true

-- Tabs --
vim.opt.expandtab   = true -- Cringe imo, but it makes files more consistent
vim.opt.tabstop     = 8
vim.opt.softtabstop = 8
vim.opt.shiftwidth  = 8
vim.opt.smartindent = true
vim.opt.autoindent  = true

-- Columns --
vim.opt.scrolloff   = 8
vim.opt.signcolumn  = 'yes' -- Figure out what this does
vim.opt.colorcolumn = '78'

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

-- Etc --
vim.opt.updatetime = 250
vim.opt.cinoptions:append({':0'})

-- Overwrite original shitty fucking quickfix menu formatting.
function _G.quickfix_custom_format(info)
        local qflist = vim.fn.getqflist({ id = info.id, items = 0, title = 0 })
        local lines = {}

        if qflist.title ~= 'Buffers' then
                return nil
        end

        for i = info.start_idx, info.end_idx do
                local item = qflist.items[i]

                local long_name = vim.api.nvim_buf_get_name(item.bufnr)
                if long_name == '' then
                        long_name = '[No Name]'
                end

                local formatted
                local short_name = long_name
                if short_name == 'bash' then
                        short_name = '[Terminal]'
                end

                if long_name ~= '[No Name]' then
                        short_name = vim.fn.fnamemodify(short_name, ':t')
                        if short_name == 'bash' then
                                short_name = '[TERMINAL]'
                        end
                        formatted = string.format(
                                '%d: \"%s\" [ln: %d | abs: %s]',
                                item.bufnr,
                                short_name,
                                item.lnum,
                                long_name
                        )
                else
                        formatted = string.format(
                                '%d: %s',
                                item.bufnr,
                                long_name -- Should just be '[No Name]'. lel
                        )
                end

                table.insert(lines, formatted)
        end

        return lines
end

vim.o.quickfixtextfunc = '{info -> v:lua.quickfix_custom_format(info)}'
