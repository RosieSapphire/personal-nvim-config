local function execute_line(shell)
        local buf = vim.api.nvim_get_current_buf()
        local row = vim.api.nvim_win_get_cursor(0)[1] - 1
        local cmd = vim.api.nvim_get_current_line()

        local ok, lines = pcall(function()
                if shell then
                        local output = vim.fn.systemlist(cmd)

                        if vim.v.shell_error ~= 0 then
                                error(
                                        'Shell command failed: '
                                        .. table.concat(output, '\n')
                                )
                        end

                        return output
                end

                local output = vim.fn.execute(cmd)
                output = output:gsub('^\n', '')

                return vim.split(output, '\n', {
                        plain     = true,
                        trimempty = true
                })
        end)

        if not ok then
                vim.notify(tostring(lines), vim.log.levels.ERROR)
                return
        end

        if #lines == 0 or (#lines == 1 and lines[1] == '') then
                vim.notify('Command produced no output.')
                return
        end

        vim.api.nvim_buf_set_lines(buf, row, row + 1, true, lines)
end

vim.keymap.set('n', '<leader>xe', function()
        execute_line(false)
end, { desc = 'Execute current line as Ex command' })

vim.keymap.set('n', '<leader>xs', function()
        execute_line(true)
end, { desc = 'Execute current line as shell command' })
