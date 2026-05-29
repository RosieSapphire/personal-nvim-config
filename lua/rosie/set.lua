--------------------------------------
-- MACROS FOR BETTER PATH SEARCHING --
--------------------------------------

vim.opt.path:append("**")
vim.opt.wildmenu = true

-- Function for finding stuff with grep (normal mode)
local function grep_find_normal(opts)
        opts = opts or {}

        local word = vim.fn.expand('<cword>')

        if not opts.imprecise then
                word = '\\<' .. word .. '\\>'
        end

        local pattern = opts.pattern or '**/*'

        -- Push the the mark stack
        vim.cmd("normal! m'")

        -- Perform the fucken grep
        vim.cmd('vimgrep /' .. word .. '/gj ' .. pattern)

        -- Open up the quickfix panel with the results
        vim.cmd('copen')
end

--------------------------------------------------------------------------------
-- FIXME: This is broken, so I disabled it. I wanna add it eventually tho. :c --
--------------------------------------------------------------------------------

--[[
local function get_visual_selection()
        local line_a = vim.fn.line("'<")
        local line_b = vim.fn.line("'>")

        local col_a = vim.fn.col("'<")
        local col_b = vim.fn.col("'>")

        local lines = vim.api.nvim_buf_get_lines(0, line_a - 1, line_b, false)

        if 0 == #lines then
                return ""
        end

        lines[#lines] = string.sub(lines[#lines], 1, col_b)
        lines[1] = string.sub(lines[1], col_a)

        return table.concat(lines, '\n')
end

-- Function for finding stuff with grep (visual mode)
local function grep_find_visual(opts)
        -----------------------------------------------------------------------
        -- FIXME: This doesn't seem to work either. It misses, like 90% of   --
        --        the fucking results and usually just finds nothing at all. --
        -----------------------------------------------------------------------
        opts = opts or {}

        local text = get_visual_selection()

        if text == '' then
                return
        end

        local pattern = opts.pattern or '**/*'

        vim.cmd("normal! m'")
        if 0 == vim.fn.executable('rg') then
                vim.notify("ERROR: `rg` not found on system! " ..
                           "Please install via your distro's package manager (apt: ripgrep)",
                           vim.log.levels.ERROR)
                return
        end
        vim.cmd('grep! "' .. vim.fn.escape(text, '"') .. '" ' .. pattern)

        -- Open up the quickfix panel with the results
        vim.cmd('copen')
end
]]--

-- Keybinds for finding a pattern in a file (normal)
vim.keymap.set('n', '<leader>*h', function() grep_find_normal({ pattern = '**/*.h', imprecise = false }) end)
vim.keymap.set('n', '<leader>*c', function() grep_find_normal({ pattern = '**/*.c', imprecise = false }) end)
vim.keymap.set('n', '<leader>*a', function() grep_find_normal({ pattern = '**/*.{c,h}', imprecise = false }) end)
vim.keymap.set('n', '<leader>*ih', function() grep_find_normal({ pattern = '**/*.h', imprecise = true }) end)
vim.keymap.set('n', '<leader>*ic', function() grep_find_normal({ pattern = '**/*.c', imprecise = true }) end)
vim.keymap.set('n', '<leader>*ia', function() grep_find_normal({ pattern = '**/*.{c,h}', imprecise = true }) end)

--[[
-- Keybinds for finding a pattern in a file (visual)
vim.keymap.set('v', '<leader>*h', function() grep_find_visual({ pattern = '**/*.h', imprecise = false }) end)
vim.keymap.set('v', '<leader>*c', function() grep_find_visual({ pattern = '**/*.c', imprecise = false }) end)
vim.keymap.set('v', '<leader>*a', function() grep_find_visual({ pattern = '**/*.{c,h}', imprecise = false }) end)
vim.keymap.set('v', '<leader>*ih', function() grep_find_visual({ pattern = '**/*.h', imprecise = true }) end)
vim.keymap.set('v', '<leader>*ic', function() grep_find_visual({ pattern = '**/*.c', imprecise = true }) end)
vim.keymap.set('v', '<leader>*ia', function() grep_find_visual({ pattern = '**/*.{c,h}', imprecise = true }) end)
]]--

-- Overwrite hte original quickfix formatting so I can make it look less shitty
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

-- Handy-dandy mouse-ka-tool for listing buffers so I don't have to press
-- an extra fucking key. Such is the way of VIM after all, right? lmao
vim.keymap.set('n', '<leader>ls', function()
        local qf = {}

        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                ------------------------------------------------------------
                -- FIXME: This indentation is ugly and I'd like to invert --
                --        the conditional statement to be prettier. qwq   --
                ------------------------------------------------------------
                if 0 ~= vim.fn.buflisted(bufnr) then
                        -- Get the name of the buffer from the number
                        local name = vim.fn.fnamemodify(
                                vim.api.nvim_buf_get_name(bufnr),
                                ':t'
                        )

                        -- If the file has no name, make sure we can see it. lol
                        if '' == name then
                                name = '[No Name]'
                        end

                        -- Get the line we were on upon this buffers last access
                        local line = vim.api.nvim_buf_get_mark(bufnr, '"')[1]

                        -- Make sure we didn't somehow get a fucked up line num
                        if 0 == line then
                                line = 1
                        end

                        -- Add this element to the Quickfix buffer! Make sure
                        -- that when we open it, it puts us on the same line
                        -- we were on when we last accessed it! :D
                        table.insert(qf, {
                                bufnr = bufnr,
                                lnum  = line,
                                col   = 1,
                                text  = name
                        })
                end
        end

        vim.fn.setqflist({}, 'r', { title = 'Buffers', items = qf })
        vim.cmd('copen')
end, { desc = 'List currently opened buffers in quickfix' })

----------------------------------------------------------
-- TODO: I REALLY fucking want a rename variable macro! --
----------------------------------------------------------

-- And another one for opening and closing the quick-fix panel faster!
vim.keymap.set('n', '<leader>qo', function() vim.cmd('copen') end)
vim.keymap.set('n', '<leader>qc', function() vim.cmd('cclose') end)

-- Sourcing the current file
vim.keymap.set('n', '<leader>so', function() vim.cmd('source|:f') end)

----------------------------------------
-- TODO: Make this work properly. lol --
----------------------------------------

--[[
-- Going to help page for what's currently under the cursor
vim.keymap.set('n', '<leader>gh', function() vim.cmd('help|<cword>') end)
]]--

-----------------------------------------------------------------------
-- FORMATTING THE CURRENT FILE AND RETURNING TO THE CURSOR POSITION! --
-----------------------------------------------------------------------
local function clang_format_current_buffer()
        -- Make sure we actually *have* clang-format, or we're fucked. lol
        if 0 == vim.fn.executable('clang-format') then
                vim.notify("ERROR: `clang-format` not found on system! " ..
                           "Please install via your distro's package manager",
                           vim.log.levels.ERROR)
                return
        end

        -- Save the previous cursor position, 'cuz shit's gonna move around
        local cursor_pos = vim.api.nvim_win_get_cursor(0)

        -- Get all the lines in the file
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

        -- Perform the clang-format shenanigans on them
        local formatted = vim.fn.systemlist(
                'clang-format --assume-filename=file.c --style=file --fallback-style=none 2>&1',
                lines
        )

        -- Make sure it actually ran successfully, otherwise print an error
        if 0 ~= vim.v.shell_error then
                vim.notify(table.concat(formatted, '\n'), vim.log.levels.ERROR)
                return
        end

        -- Make sure that we don't modify it if it hasn't changed.
        -- This makes it much easier to know when we actually updated.
        local og_text = table.concat(lines, '\n'):gsub('%s+$', '')
        local new_text = table.concat(formatted, '\n'):gsub('%s+$', '')
        if og_text == new_text then
                vim.notify('No changes to file after formatting.', vim.log.levels.INFO)
                return
        end

        -- Put the new data for the current buffer
        vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted)

        -- Now restore our previous window view
        -- so it looks like nothing happened!
        vim.api.nvim_win_set_cursor(0, cursor_pos)
end

vim.keymap.set('n', '<leader>fr', function() clang_format_current_buffer() end)

-- Save the current buffer to a file
vim.keymap.set('n', '<leader>w', function() vim.cmd('write') end)

-- Shut down the current buffer
vim.keymap.set('n', '<leader>bd', function() vim.cmd('bd!') end)

-- Save the current buffer to a file right after formatting it with clang! :D
vim.keymap.set('n', '<leader>fw', function()
        clang_format_current_buffer()
        vim.cmd('write')
end)

-- Check the make command
vim.keymap.set('n', '<leader>cmk', function()
        vim.cmd('set makeprg?')
end, { silent = true })

-- Set the make command
vim.keymap.set('n', '<leader>smk', function()
        local ok, mkprg = pcall(vim.fn.input, 'Make Command Input: ')

        if not ok or mkprg == '' then
                return
        end

        vim.opt.makeprg = mkprg;
end, { silent = true })

-- Run the make command
vim.keymap.set('n', '<leader>mk', function()
        vim.cmd('wa') -- Make sure to save all open files before running!
        vim.cmd('make')
end, { silent = true })

-- Close all buffers except current one
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
end, { silent = true })

-- Function for opening all files of (a) certain type(s)
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

-- Shortcuts for opening all files of a given type
vim.keymap.set('n', '<leader>oahcf', function() add_project_buffers_of_type({ 'c', 'h' }) end, { silent = false })
vim.keymap.set('n', '<leader>oahf', function() add_project_buffers_of_type({ 'h' }) end, { silent = false })
vim.keymap.set('n', '<leader>oacf', function() add_project_buffers_of_type({ 'c' }) end, { silent = false })

vim.api.nvim_create_autocmd("FileType", {
        pattern = "qf",
        callback = function()
                vim.keymap.set("n", "<CR>", function()
                        local idx = vim.fn.line(".") -- current line in qf list
                        vim.cmd("wincmd p")             -- go back to  orig window
                        vim.cmd("cc " .. idx)             -- jump to THAT entry
                        vim.cmd("cclose")                                                -- close quickfix
                end, { buffer = true })
        end,
})

local snip_dir = '$HOME/.config/nvim/snippets/'

-- Pragma warning diagnostics for GCC
vim.keymap.set('n', ',pgcc', function()
        local file = vim.fn.expand(snip_dir .. 'pragma_gcc')
        vim.cmd('read ' .. file)
        vim.api.nvim_feedkeys('j$i', 'n', false)
end, { noremap = true, silent = true })

-- Pragma warning diagnostics for clang
vim.keymap.set('n', ',pcla', function()
        local file = vim.fn.expand(snip_dir .. 'pragma_clang')
        vim.cmd('read ' .. file)
        vim.api.nvim_feedkeys('j$i', 'n', false)
end, { noremap = true, silent = true })

-- Just a simple hello world program in C
vim.keymap.set('n', ',hello', function()
        local file = vim.fn.expand(snip_dir .. 'hello_world')
        vim.cmd("read " .. file)
end, { noremap = true, silent = true })

-- Debug macro for a specific module
vim.keymap.set('n', ',dbm', function()
        local file = vim.fn.expand(snip_dir .. 'debug_macro')
        vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-------------------------------------------------------------
-- SNIPPETS FOR INCLUDE HEADER AND SOURCE SECTION COMMENTS --
-------------------------------------------------------------

local function snippet_bind_create(keybind, path)
        vim.keymap.set('n', keybind, function()
                local file = vim.fn.expand(path)
                vim.cmd('read ' .. file)
        end, { noremap = true, silent = true })
end

snippet_bind_create(',cmain', snip_dir .. 'com/main')
snippet_bind_create(',cdef', snip_dir .. 'com/defines')
snippet_bind_create(',cenu', snip_dir .. 'com/enums')
snippet_bind_create(',cfuni', snip_dir .. 'com/func_inl')
snippet_bind_create(',cfunprp', snip_dir .. 'com/func_prv_pro')
snippet_bind_create(',cfunpri', snip_dir .. 'com/func_prv_imp')
snippet_bind_create(',cfunpup', snip_dir .. 'com/func_pub_pro')
snippet_bind_create(',cfunpui', snip_dir .. 'com/func_pub_imp')
snippet_bind_create(',cinc', snip_dir .. 'com/include')
snippet_bind_create(',cmac', snip_dir .. 'com/macros')
snippet_bind_create(',cstru', snip_dir .. 'com/structs')
snippet_bind_create(',ctyp', snip_dir .. 'com/typedefs')
snippet_bind_create(',cvarpup', snip_dir .. 'com/var_pub_dec')
snippet_bind_create(',cvarpui', snip_dir .. 'com/var_pub_imp')
snippet_bind_create(',cvarpr', snip_dir .. 'com/var_prv')

-- Generating CTags for code --
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

----------------------------------
-- SNIPPETS FOR CODE GENERATION --
----------------------------------

-- Include setup with quotation marks
vim.keymap.set('n', ',inc', function()
        local file = vim.fn.expand(snip_dir .. '/inc_setup_quote')
        vim.cmd('read ' .. file)
        vim.api.nvim_feedkeys('$hhi', 'n', false)
end, { noremap = true, silent = true })

-- Include setup with angled brackets
vim.keymap.set('n', ',binc', function()
        local file = vim.fn.expand(snip_dir .. '/inc_setup_angle')
        vim.cmd('read ' .. file)
        vim.api.nvim_feedkeys('$hhi', 'n', false)
end, { noremap = true, silent = true })

-- Named header guard
vim.keymap.set('n', ',hg', function()
        local ok, guard = pcall(vim.fn.input, 'Header Guard Name: ')
        local view      = vim.fn.winsaveview()

        if not ok or guard == '' then
                return
        end

        vim.fn.append(0, {
                '#ifndef ' .. guard,
                '#define ' .. guard,
                ''
        })

        vim.fn.append(vim.fn.line('$'), {
                '',
                '#endif /* #ifndef ' .. guard .. ' */'
        })

        vim.fn.winrestview(view)
end, { noremap = true, silent = true })

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

-- #ifdef (normal)
vim.keymap.set(
        'n',
        ',ifd',
        ifdef_mode_normal('#ifdef', false),
        { silent = true }
)

-- #ifdef #else (normal)
vim.keymap.set(
        'n',
        ',ifed',
        ifdef_mode_normal('#ifdef', true),
        { silent = true }
)

-- #ifdef (visual)
vim.keymap.set(
        'x',
        ',ifd',
        ifdef_mode_visual('#ifdef', false),
        { silent = true }
)

-- #ifdef #else (visual)
vim.keymap.set(
        'x',
        ',ifed',
        ifdef_mode_visual('#ifdef', true),
        { silent = true }
)

-- #ifndef (normal)
vim.keymap.set(
        'n',
        ',ifnd',
        ifdef_mode_normal('#ifndef', false),
        { silent = true }
)

-- #ifndef #else (normal)
vim.keymap.set(
        'n',
        ',ifned',
        ifdef_mode_normal('#ifndef', true),
        { silent = true }
)

-- #ifndef (visual)
vim.keymap.set(
        'x',
        ',ifnd',
        ifdef_mode_visual('#ifndef', false),
        { silent = true }
)

-- #ifndef #else (visual)
vim.keymap.set(
        'x',
        ',ifned',
        ifdef_mode_visual('#ifndef', true),
        { silent = true }
)

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

---------------------------------
-- ENCASING FUNCTIONS (NORMAL) --
---------------------------------

-- Comment
vim.keymap.set('n', ',ec', function()
        encase_current_line('/* ', ' */')
end, { silent = true })

-- Parenthesis
vim.keymap.set('n', ',ep', function()
        encase_current_line('(', ')')
end, { silent = true })

----------------------------------
-- UN-ENCASE FUNCTIONS (NORMAL) --
----------------------------------

vim.keymap.set('n', ',uc', function()
        unencase_current_line('/* ', ' */')
end, { noremap = true, silent = true })

vim.keymap.set('n', ',up', function()
        unencase_current_line('(', ')')
end, { noremap = true, silent = true })

---------------------------------
-- ENCASING FUNCTIONS (VISUAL) --
---------------------------------

-- Comment
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
end, { noremap = true, silent = true })

-------------------------------
-- PARTIAL ENCASING (VISUAL) --
-------------------------------

--[[
vim.keymap.set('x', ',ec', function()
        vim.api.nvim_input('<Esc>')

        vim.schedule(function()
                encase_visual_select('/* ', ' */')
        end)
end, { noremap = true, silent = true })
]]--

vim.keymap.set('x', ',ep', function()
        vim.api.nvim_input('<Esc>')

        vim.schedule(function()
                encase_visual_select('(', ')')
        end)
end, { noremap = true, silent = true })

---------------------------------
-- PARTIAL UNENCASING (VISUAL) --
---------------------------------

vim.keymap.set('x', ',uc', function()
        vim.api.nvim_input('<Esc>')

        vim.schedule(function()
                unencase_visual_select('/* ', ' */')
        end)
end, { noremap = true, silent = true })

vim.keymap.set('x', ',up', function()
        vim.api.nvim_input('<Esc>')

        vim.schedule(function()
                unencase_visual_select('(', ')')
        end)
end, { noremap = true, silent = true })

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

vim.api.nvim_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", {
        noremap = true, silent = true
})

-- Etc --
vim.opt.updatetime = 250
vim.opt.cinoptions:append({':0'})
