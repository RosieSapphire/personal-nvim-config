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

----------------------------------------------------------
-- TODO: I REALLY fucking want a rename variable macro! --
----------------------------------------------------------

----------------------------------------
-- lua/rosie/keymap/basic.lua (START) --
----------------------------------------

local function bind_cmd_simple(keys, cmd)
        vim.keymap.set('n', keys, function() vim.cmd(cmd) end, {})
end

bind_cmd_simple('<leader>w', 'write')
bind_cmd_simple('<leader>bd', 'bd!')

vim.keymap.set('n', '<leader>caec', function()
        local curbuf = vim.api.nvim_get_current_buf()

        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if buf ~= curbuf
                and vim.bo[buf].buflisted
                and vim.bo[buf].buftype == ''
                then
                        -- Make sure to save the buffer if we need to.
                        if vim.bo[buf].modified then
                                vim.api.nvim_buf_call(buf, function()
                                        vim.cmd('write')
                                end)
                        end

                        -- Delete the buffer itself
                        vim.api.nvim_buf_delete(buf, { force = false })
                end
        end
end, { desc = "Closes all buffers except the one focused.", silent = true })

--------------------------------------
-- lua/rosie/keymap/basic.lua (END) --
--------------------------------------

-----------------------------------------
-- lua/rosie/keymap/coding.lua (START) --
-----------------------------------------

vim.api.nvim_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", {
        noremap = true, silent = true
})

vim.keymap.set('n', '<leader>cmk', function()
        vim.cmd('set makeprg?')
end, { desc = "Print the currently set 'makeprg' command.", silent = true })

vim.keymap.set('n', '<leader>smk', function()
        local ok, mkprg = pcall(vim.fn.input, 'Make Command Input: ')

        if not ok or mkprg == '' then
                return
        end

        vim.opt.makeprg = mkprg;
end, { desc = "Set new 'makeprg' command via prompt.", silent = true })

vim.keymap.set('n', '<leader>mk', function()
        vim.cmd('wa') -- Make sure to save all open files before running!
        vim.cmd('make')
end, { desc = "Run the 'makeprg' cmd (save all first).", silent = true })

local function add_project_buffers_of_type(exts)
        local patterns = {}

        if 0 == vim.fn.executable('fdfind') then
                vim.notify("ERROR: `fdfind` not found on system! " ..
                           "Please install via your distro's package manager (apt: fd-find)",
                           vim.log.levels.ERROR)
                return
        end

        for _, ext in ipairs(exts) do
                table.insert(patterns, string.format('-e %s', ext))
        end

        local cmd = 'fdfind -t f ' .. table.concat(patterns, ' ')

        local files = vim.fn.systemlist(cmd)

        for _, file in ipairs(files) do
                vim.cmd('badd ' .. vim.fn.fnameescape(file))
        end

        print('Opened ' .. #files .. ' files into buffers!')
end

vim.keymap.set('n', '<leader>oahcf', function()
        add_project_buffers_of_type({ 'c', 'h' })
end, { desc = "Opens all *.h & *.c files in pwd.", silent = false  })

vim.keymap.set('n', '<leader>oahf', function()
        add_project_buffers_of_type({ 'h' })
end, { desc = "Opens all *.h files in pwd.", silent = false  })

vim.keymap.set('n', '<leader>oacf', function()
        add_project_buffers_of_type({ 'c' })
end, { desc = "Opens all *.c files in pwd.", silent = false  })

vim.api.nvim_create_user_command('TagsMake', function()
        if 0 == vim.fn.executable('ctags') then
                vim.notify("ERROR: `ctags` is not an executable " ..
                           "on this system. Please install it via " ..
                           "your distro's package manager!",
                           vim.log.levels.ERROR);
                return;
        end
        
        vim.fn.jobstart({'ctags', '-R', '.'}, {
        on_exit =
                function(_, code) if 0 ~= code then vim.notify("ERROR: Failed to generate CTags!",
                                                               vim.log.levels.ERROR) end end
        })
end, {})

local function escape_lua_pattern(str)
        return str:gsub('([^%w])', '%%%1')
end

local function encase_current_line(left, right)
        local line = vim.api.nvim_get_current_line()

        local indent  = line:match('^%s*') or ''
        local content = line:sub(#indent + 1)

        vim.api.nvim_set_current_line(
                indent .. left .. content .. right
        )
end

local function encase_visual_select(left, right)
        local pos_a = vim.fn.getpos("'<")
        local pos_b = vim.fn.getpos("'>")

        if pos_a[2] ~= pos_b[2] then
                return
        end

        local row = pos_a[2]

        local col_a = pos_a[3]
        local col_b = pos_b[3]

        if col_a > col_b then
                col_a, col_b = col_b, col_a
        end

        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]

        local before   = line:sub(1, col_a - 1)
        local selected = line:sub(col_a, col_b)
        local after    = line:sub(col_b + 1)

        local updated = before .. left .. selected .. right .. after

        vim.api.nvim_buf_set_lines(0, row - 1, row, false, { updated })
end

local function unencase_visual_select(left, right)
        local pos_a = vim.fn.getpos("'<")
        local pos_b = vim.fn.getpos("'>")

        if pos_a[2] ~= pos_b[2] then
                return
        end

        local row = pos_a[2]

        local col_a = pos_a[3]
        local col_b = pos_b[3]

        if col_a > col_b then
                col_a, col_b = col_b, col_a
        end

        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]

        local len_left  = #left
        local len_right = #right

        local real_left  = line:sub(col_a - len_left, col_a - 1)
        local real_right = line:sub(col_b + 1, col_b + len_right)

        -- Verify wrappers actually exist
        if real_left ~= left or real_right ~= right then
                return
        end

        local before = line:sub(1, col_a - len_left - 1)
        local middle = line:sub(col_a, col_b)
        local after  = line:sub(col_b + len_right + 1)

        local updated = before .. middle .. after

        vim.api.nvim_buf_set_lines(0, row - 1, row, false, { updated })
end

local function unencase_current_line(left, right)
        local line = vim.api.nvim_get_current_line()

        local pat_left  = escape_lua_pattern(left)
        local pat_right = escape_lua_pattern(right)

        local pattern = '^(%s*)' .. pat_left .. '(.-)' .. pat_right .. '%s*$'

        local updated = line:gsub(pattern, '%1%2')

        vim.api.nvim_set_current_line(updated)
end

local function bind_encase_func_normal(bind, open, close)
        vim.keymap.set('n', bind, function()
                encase_current_line(open, close)
        end, { silent = true })
end

local function bind_unencase_func_normal(bind, open, close)
        vim.keymap.set('n', bind, function()
                unencase_current_line(open, close)
        end, { silent = true })
end

bind_encase_func_normal(',ec', '/* ', ' */')
bind_encase_func_normal(',ep', '(', ')')
bind_unencase_func_normal(',uc', '/* ', ' */')
bind_unencase_func_normal(',up', '(', ')')

---------------------------------------------------------------
-- TODO: These should probably have their own wrappers, too. --
---------------------------------------------------------------

vim.keymap.set('x', ',ec', function()
        local line_a = vim.fn.line('v')
        local line_b = vim.fn.line('.')

        if line_a > line_b then
                line_a, line_b = line_b, line_a
        end

        local lines = vim.api.nvim_buf_get_lines(0, line_a - 1, line_b, false)
        local indent = lines[1]:match('^%s*') or ''
        local commented = { indent .. '/*' }

        for _, line in ipairs(lines) do
                table.insert(commented, indent .. ' * ' .. line:sub(#indent + 1))
        end

        table.insert(commented, indent .. ' */')

        vim.api.nvim_buf_set_lines(0, line_a - 1, line_b, false, commented)

        -- vim.api.nvim_win_set_cursor(0, { line_a, 0 })
        -- vim.cmd('normal! zz')

        vim.api.nvim_feedkeys(
                vim.api.nvim_replace_termcodes('<Esc>', true, false, true),
                'n',
                false
        )
end, { desc = "Add /* */ (visual).", noremap = true, silent = true })

vim.keymap.set('x', ',ep', function()
        vim.api.nvim_input('<Esc>')

        vim.schedule(function()
                encase_visual_select('(', ')')
        end)
end, { desc = "Add ( ) (visual).", noremap = true, silent = true })

vim.keymap.set('x', ',uc', function()
        vim.api.nvim_input('<Esc>')

        vim.schedule(function()
                unencase_visual_select('/* ', ' */')
        end)
end, { desc = "Remove /* */ (visual).", noremap = true, silent = true })

vim.keymap.set('x', ',up', function()
        vim.api.nvim_input('<Esc>')

        vim.schedule(function()
                unencase_visual_select('(', ')')
        end)
end, { desc = "Remove ( ) (visual).", noremap = true, silent = true })

---------------------------------------
-- lua/rosie/keymap/coding.lua (END) --
---------------------------------------

-------------------------------------------------
-- lua/rosie/keymap/snippets/funcs.lua (START) --
-------------------------------------------------

local snip_dir = '$HOME/.config/nvim/snippets/'

local function snip_bind_create(keybind, path)
        vim.keymap.set('n', keybind, function()
                local file = vim.fn.expand(snip_dir .. path)
                vim.cmd("read " .. file)
        end, { noremap = true, silent = true })
end

local function snip_bind_create_pragma(keybind, path)
        vim.keymap.set('n', keybind, function()
                local file = vim.fn.expand(snip_dir .. path)
                vim.cmd("read " .. file)
                vim.api.nvim_feedkeys('j$i', 'n', false)
        end, { noremap = true, silent = true })
end

-----------------------------------------------
-- lua/rosie/keymap/snippets/funcs.lua (END) --
-----------------------------------------------

---------------------------------------------------
-- lua/rosie/keymap/snippets/codegen.lua (START) --
---------------------------------------------------

snip_bind_create_pragma(',pgcc', 'pragma_gcc')
snip_bind_create_pragma(',pcla', 'pragma_clang')
snip_bind_create(',dbm', 'debug_macro')
snip_bind_create(',hello', 'hello_world')
snip_bind_create(',bast', 'basic_types')

----------------------------------------------------------------------------
-- TODO: Create mapper functions for all these too so they clean as FUCK! --
----------------------------------------------------------------------------

vim.keymap.set('n', ',inc', function()
        local file = vim.fn.expand(snip_dir .. '/inc_setup_quote')
        vim.cmd("read " .. file)
        vim.api.nvim_feedkeys('$hhi', 'n', false)
end, { desc = "Generate #include quotes.", noremap = true, silent = true })

vim.keymap.set('n', ',binc', function()
        local file = vim.fn.expand(snip_dir .. '/inc_setup_angle')
        vim.cmd("read " .. file)
        vim.api.nvim_feedkeys('$hhi', 'n', false)
end, { desc = "Generate #include angles.", noremap = true, silent = true })

vim.keymap.set('n', ',hg', function()
        local ok, guard = pcall(vim.fn.input, 'Header Guard Name: ')
        local view      = vim.fn.winsaveview()

        if not ok or guard == '' then
                return
        end

        vim.fn.append(0, { '#ifndef ' .. guard, '#define ' .. guard, '' })
        vim.fn.append(vim.fn.line('$'), { '',
                '#endif /* #ifndef ' .. guard .. ' */'
        })

        vim.fn.winrestview(view)
end, { desc = "Generate named header-guard.", noremap = true, silent = true })

-- #ifdef & #ifndef with names
local function ifdef_mode_normal(guard, do_else)
        return function()
                local ok, name = pcall(vim.fn.input, guard .. ': ')
                local real_g   = ''

                if not ok or name == '' then
                        return
                end

                -- Exception for `#if 0`
                if name == '0' then
                        real_g = '#if'
                else
                        real_g = guard
                end

                vim.fn.append(vim.fn.line('.') - 1,
                        real_g .. ' ' .. name
                )

                if do_else then
                        vim.fn.append(vim.fn.line('.') - 1,
                                '#else /* ' .. real_g .. ' ' .. name .. ' */'
                        )

                        vim.fn.append(vim.fn.line('.') - 1,
                                '#endif /* ' .. real_g .. ' ' .. name .. ' #else */'
                        )
                else
                        vim.fn.append(vim.fn.line('.') - 1,
                                '#endif /* ' .. real_g .. ' ' .. name .. ' */'
                        )
                end
        end
end

local function ifdef_mode_visual(guard, do_else)
        return function()
                local line_a     = vim.fn.line('v')
                local line_b     = vim.fn.line('.')
                local ok, name   = pcall(vim.fn.input, guard .. ': ')
                local real_g     = ''

                if not ok or name == '' then
                        return
                end

                -- Exception for `#if 0`
                if name == '0' then
                        real_g = '#if'
                else
                        real_g = guard
                end
        
                if line_a > line_b then
                        line_a, line_b = line_b, line_a
                end
        
                if do_else == true then
                        vim.fn.append(line_b, {
                                '#else /* ' .. real_g .. ' ' .. name .. ' */',
                                '#endif /* ' .. real_g .. ' ' .. name .. ' #else */'
                        })
                else
                        vim.fn.append(line_b, {
                                '#endif /* ' .. real_g .. ' ' .. name .. ' */'
                        })
                end
        
                vim.fn.append(line_a - 1, {
                        real_g .. ' ' .. name
                })
        
                -- vim.api.nvim_win_set_cursor(0, { line_a, 0 })
        end
end

local function ifdef_macro_mapper(mode, input, guard, do_else)
        local func

        if mode == 'n' then
                func = ifdef_mode_normal
        elseif mode == 'x' then
                func = ifdef_mode_visual
        end

        vim.keymap.set(mode, input, func(guard, do_else), { silent = true })
end

ifdef_macro_mapper('n', ',ifd', '#ifdef', false)
ifdef_macro_mapper('n', ',ifed', '#ifdef', true)
ifdef_macro_mapper('n', ',ifnd', '#ifndef', false)
ifdef_macro_mapper('n', ',ifned', '#ifndef', true)

ifdef_macro_mapper('x', ',ifd', '#ifdef', false)
ifdef_macro_mapper('x', ',ifed', '#ifdef', true)
ifdef_macro_mapper('x', ',ifnd', '#ifndef', false)
ifdef_macro_mapper('x', ',ifned', '#ifndef', true)

-------------------------------------------------
-- lua/rosie/keymap/snippets/codegen.lua (END) --
-------------------------------------------------

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
