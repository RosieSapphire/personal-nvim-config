-------------------------------
-- lua/rosie/set.lua (START) --
-------------------------------

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

-----------------------------
-- lua/rosie/set.lua (END) --
-----------------------------

---------------------------------------------------
-- lua/rosie/keymap/snippets/comments.lua (START) --
---------------------------------------------------

snip_bind_create(',cmain', 'com/main')
snip_bind_create(',cdef', 'com/defines')
snip_bind_create(',cenu', 'com/enums')
snip_bind_create(',cfuni', 'com/func_inl')
snip_bind_create(',cfunprp', 'com/func_prv_pro')
snip_bind_create(',cfunpri', 'com/func_prv_imp')
snip_bind_create(',cfunpup', 'com/func_pub_pro')
snip_bind_create(',cfunpui', 'com/func_pub_imp')
snip_bind_create(',cinc', 'com/include')
snip_bind_create(',cmac', 'com/macros')
snip_bind_create(',cstru', 'com/structs')
snip_bind_create(',ctyp', 'com/typedefs')
snip_bind_create(',cvarpup', 'com/var_pub_dec')
snip_bind_create(',cvarpui', 'com/var_pub_imp')
snip_bind_create(',cvarpr', 'com/var_prv')

local function comment_generate(prefix, is_inline)
        -- Get the indentation level at the current line
        local line   = vim.api.nvim_get_current_line()
        local indent = line:match('^%s*') or ''
        local pfx    = prefix or ''

        -- Append the comment block skeleton to the lines above us
        -- (with the correct indentation-level of course!)
        if is_inline then
                local crs  = vim.api.nvim_win_get_cursor(0)
                local row  = crs[1]
                local prow = row - 1
                local text = indent .. '/* ' .. pfx .. ' */'

                -- Inline comment
                vim.api.nvim_buf_set_lines(0, prow, prow, false, { text })
                vim.api.nvim_win_set_cursor(0, { row, #text - 3 })
                vim.cmd('startinsert')
        else
                -- Block comment
                local crs  = vim.api.nvim_win_get_cursor(0)
                local row  = crs[1]
                local prow = row - 1

                vim.api.nvim_buf_set_lines(0, prow, prow, false, {
                        indent .. '/*',
                        indent .. ' * ' .. pfx,
                        indent .. ' */'
                })
                vim.api.nvim_win_set_cursor(0, {
                        row + 1,
                        #indent + 3 + #pfx
                })
                vim.cmd('startinsert!')
        end
end

local function comment_generate_mapper(mapping, prefix, is_inline)
        vim.keymap.set('n', mapping, function()
                comment_generate(prefix, is_inline)
        end, { noremap = true, silent = true })
end

comment_generate_mapper(',cbe', '', false)
comment_generate_mapper(',cbt', 'TODO: ', false)
comment_generate_mapper(',cbf', 'FIXME: ', false)
comment_generate_mapper(',cie', '', true)
comment_generate_mapper(',cit', 'TODO: ', true)
comment_generate_mapper(',cif', 'FIXME: ', true)

-------------------------------------------------
-- lua/rosie/keymap/snippets/comments.lua (END) --
-------------------------------------------------
