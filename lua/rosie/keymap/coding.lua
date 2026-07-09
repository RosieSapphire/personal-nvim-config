----------------------------------------------------------
-- TODO: I REALLY fucking want a rename variable macro! --
----------------------------------------------------------

vim.api.nvim_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", {
        noremap = true, silent = true
})

vim.keymap.set('n', '<leader>cmk', function()
        vim.cmd('set makeprg?')
end, { desc = "Print the currently set 'makeprg' command.", silent = true })

vim.keymap.set('n', '<leader>smk', function()
        local ok, mkprg = pcall(
                vim.fn.input,
                'Make Command Input: ',
                '',
                'file'
        )

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
