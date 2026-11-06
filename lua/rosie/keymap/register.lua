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

-- "Registry Set Text (e.g. esc = <Esc>, space = <Space>)"
vim.keymap.set('n', '<leader>rst', function()
        with_macro_reg(function(reg)
                vim.fn.setreg(
                        reg,
                        vim.keycode(vim.api.nvim_get_current_line()),
                        'c'
                )
        end)
end, { desc = 'Use current line as TEXT macro definition' })

-- "Registry Set Binary (e.g. esc = , space = ' ')"
vim.keymap.set('n', '<leader>rsb', function()
        with_macro_reg(function(reg)
                vim.fn.setreg(
                        reg,
                        vim.api.nvim_get_current_line(),
                        'c'
                )
        end)
end, { desc = 'Use current line as BINARY macro definition' })

-- "Registry Print Text (e.g. esc = <Esc>, space = <Space>)"
vim.keymap.set('n', '<leader>rpt', function()
        with_macro_reg(function(reg)
                macro_put(vim.fn.keytrans(vim.fn.getreg(reg)))
        end)
end, { desc = 'Print TEXT version of macro to buffer' })

-- "Registry Print Binary (e.g. esc = , space = ' ')"
vim.keymap.set('n', '<leader>rpb', function()
        with_macro_reg(function(reg)
                macro_put(vim.fn.getreg(reg))
        end)
end, { desc = 'Print BINARY version of macro to buffer' })
