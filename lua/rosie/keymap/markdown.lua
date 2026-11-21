local function markdown_wrap(mark)
        -- Characterwise Visual mode ONLY.
        if vim.fn.mode() ~= 'v' then
                return
        end

        local first = vim.fn.getpos('v')
        local last  = vim.fn.getpos('.')

        local selected = vim.fn.getregion(first, last, {
                type = 'v',
        })

        local positions = vim.fn.getregionpos(first, last, {
                type = 'v',
                eol = true,
        })

        if #selected == 0 or #positions == 0 then
                return
        end

        local start = positions[1][1]
        local finish = positions[#positions][2]

        local sr = start[2] - 1
        local sc = start[3] - 1
        local er = finish[2] - 1
        local ec = finish[3] - 1

        -- getregionpos() identifies the last selected character.
        -- nvim_buf_set_text() requires an exclusive byte offset.
        local line = vim.api.nvim_buf_get_lines(
                0, er, er + 1, false
        )[1]

        local char = vim.fn.strcharpart(
                line:sub(ec + 1), 0, 1
        )

        ec = math.min(ec + #char, #line)

        -- Wrap the selected text without modifying any registers.
        selected[1] = mark .. selected[1]
        selected[#selected] = selected[#selected] .. mark

        vim.api.nvim_buf_set_text(
                0, sr, sc, er, ec, selected
        )

        -- Return to Normal mode.
        vim.api.nvim_feedkeys(
                vim.keycode('<Esc>'), 'n', false
        )
end

vim.keymap.set('x', '<leader>mi', function()
        markdown_wrap('*')
end, { desc = 'Markdown: italic' })

vim.keymap.set('x', '<leader>mb', function()
        markdown_wrap('**')
end, { desc = 'Markdown: bold' })

vim.keymap.set('x', '<leader>mB', function()
        markdown_wrap('***')
end, { desc = 'Markdown: bold italic' })

vim.keymap.set('x', '<leader>mt', function()
        markdown_wrap('`')
end, { desc = 'Markdown: inline code' })
