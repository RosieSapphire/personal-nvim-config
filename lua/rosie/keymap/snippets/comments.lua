local snip = require 'rosie.keymap.snippets.funcs'

snip.bind_create('n', ',cmain', 'com/main', '')
snip.bind_create('n', ',cdef', 'com/defines', '')
snip.bind_create('n', ',cenu', 'com/enums', '')
snip.bind_create('n', ',cfuni', 'com/func_inl', '')
snip.bind_create('n', ',cfunprp', 'com/func_prv_pro', '')
snip.bind_create('n', ',cfunpri', 'com/func_prv_imp', '')
snip.bind_create('n', ',cfunpup', 'com/func_pub_pro', '')
snip.bind_create('n', ',cfunpui', 'com/func_pub_imp', '')
snip.bind_create('n', ',cinc', 'com/include', '')
snip.bind_create('n', ',cmac', 'com/macros', '')
snip.bind_create('n', ',cstru', 'com/structs', '')
snip.bind_create('n', ',ctyp', 'com/typedefs', '')
snip.bind_create('n', ',cvarpup', 'com/var_pub_dec', '')
snip.bind_create('n', ',cvarpui', 'com/var_pub_imp', '')
snip.bind_create('n', ',cvarpr', 'com/var_prv', '')

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
