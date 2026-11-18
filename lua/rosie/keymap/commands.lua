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

-- "E[X]ecute (in) Editor"
vim.keymap.set('n', '<leader>xe', function()
        execute_line(false)
end, { desc = 'Execute current line as Ex command' })

-- "E[X]ecute (in) Shell"
vim.keymap.set('n', '<leader>xs', function()
        execute_line(true)
end, { desc = 'Execute current line as shell command' })

-- Helper function for evaluating—what could be a—multi-line math expression!
local function calc_get_expr()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local last = vim.api.nvim_buf_line_count(0)

        -- Find the beginning of the expression.
        while row > 1 do
                local prev = vim.fn.getline(row - 1)

                if not prev:match('\\%s*$') then
                        break
                end

                row = row - 1
        end

        local lines = {}

        -- Collect all continued lines.
        while true do
                local line = vim.fn.getline(row)
                local text, continued = line:gsub('\\%s*$', '')

                lines[#lines + 1] = text

                if continued == 0 then
                        break
                end

                if row == last then
                        error('Unterminated calculator expression!')
                end

                row = row + 1
        end

        return table.concat(lines, ''), row
end

-- "Execute [through] Calculator" (equal whatever math you want with 'calc'!)
vim.keymap.set('n', '<leader>xc', function()
        local count = vim.v.count1
        local buf   = vim.api.nvim_get_current_buf()

        local ok, expr, row = pcall(calc_get_expr)

        if not ok then
                vim.notify(expr, vim.log.levels.ERROR)
                return
        end

        if expr:match('^%s*$') then
                return
        end

        local seed = math.floor(vim.uv.hrtime() % 2147483647)
        local results = {}

        for i = 1, count do
                local input = string.format(
                        'srand(%d),\n%s\n',
                        (seed + i) % 2147483647 + 1,
                        expr
                )

                local output = vim.fn.systemlist(
                        { 'calc', '-p' }, input
                )

                if vim.v.shell_error ~= 0 then
                        vim.notify(
                                table.concat(output, '\n'),
                                vim.log.levels.ERROR
                        )
                        return
                end

                results[i] = output
        end

        local lines = {}

        -- Reverse the order of evaluations, not their contents.
        for i = #results, 1, -1 do
                for _, line in ipairs(results[i]) do
                        lines[#lines + 1] = line
                end
        end

        if #lines == 0 then
                return
        end

        vim.api.nvim_buf_set_lines(
                buf, row, row, true, lines
        )
end, { desc = 'Evaluate current expression with calc' })
