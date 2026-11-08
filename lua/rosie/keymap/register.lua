local function macro_reg()
        local msg = 'Macro register [a-z, A-Z, 0-9]: '
        vim.api.nvim_echo({ { msg } }, false, { })

        local ok, reg = pcall(vim.fn.getcharstr, -1, { cursor = 'msg' })

        vim.cmd('redraw')

        if not ok then
                if tostring(reg):lower():find('interrupt', 1, true) then
                        return nil
                end

                error(reg, 0)
        end

        if reg == vim.keycode('<Esc>')
           or reg == vim.keycode('<C-c>') then
                return nil
        end

        if reg:match('^[a-zA-Z0-9]$') then
                return reg
        end

        vim.notify(
                'Invalid macro register: ' .. vim.fn.keytrans(reg),
                vim.log.levels.ERROR
        )

        return nil
end

local function with_macro_reg(callback)
        local reg = macro_reg()
        if reg == nil then
                return
        end
        callback(reg)
end

local function macro_put(text)
        local lines = vim.split(text, '\n', { plain = true });
        vim.api.nvim_put(lines, 'l', true, false)
end

-- "Registry Set"
vim.keymap.set('n', '<leader>rs', function()
        with_macro_reg(function(reg)
                vim.fn.setreg(
                        reg,
                        vim.keycode(vim.api.nvim_get_current_line()),
                        'c'
                )
        end)
end, { desc = 'Use current line as TEXT macro definition' })

-- "Registry Print"
vim.keymap.set('n', '<leader>rp', function()
        with_macro_reg(function(reg)
                macro_put(vim.fn.keytrans(vim.fn.getreg(reg)))
        end)
end, { desc = 'Print TEXT version of macro to buffer' })

-- "Registry Clear"
vim.keymap.set('n', '<leader>rClear', function()
        local all = 'abcdefghijklmnopqrstuvwxyz0123456789'

        local ok, input = pcall(
                vim.fn.input,
                'Registers to clear [!][a-z, 0-9, *]: '
        )

        if not ok or input == '' then
                return
        end

        if input == '!*' then
                vim.notify(
                        'Cannot exclude all registers!',
                        vim.log.levels.WARN
                )
                return
        end

        local exclude = input:sub(1, 1) == '!'
        local spec = exclude and input:sub(2) or input

        if spec ~= '*' and not spec:match('^[a-z0-9]+$') then
                vim.notify(
                        'Invalid register specification: ' .. input,
                        vim.log.levels.ERROR
                )
                return
        end

        local selected = {}

        for reg in spec:gmatch('.') do
                selected[reg] = true
        end

        local count = 0

        for reg in all:gmatch('.') do
                if spec == '*' or selected[reg] ~= exclude then
                        vim.fn.setreg(reg, '', 'c')
                        count = count + 1
                end
        end

        vim.notify(
                string.format('Cleared %d register%s!',
                        count, count == 1 and '' or 's')
        )
end, { desc = 'Clear selected registers or their complement' })
vim.keymap.set('n', '<leader>rclear', function()
        local ok, input = pcall(
                vim.fn.input,
                'Type CLEAR to erase registers [a-z, 0-9]: '
        )

        if not ok or input ~= 'CLEAR' then
                return
        end

        for reg in ('0123456789abcdefghijklmnopqrstuvwxyz'):gmatch('.') do
                vim.fn.setreg(reg, '', 'c')
        end

        vim.notify('Cleared all 36 registers!')
end, {
        desc = 'Clear all named and numbered registers'
})
