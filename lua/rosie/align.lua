vim.api.nvim_create_user_command("AlignRight", function(opts)
        local width = tonumber(opts.args)
                or (vim.bo.textwidth > 0 and vim.bo.textwidth or 78)

        local lines = vim.api.nvim_buf_get_lines(
                0, opts.line1 - 1, opts.line2, false
        )

        for i, line in ipairs(lines) do
                local lhs, rhs = line:match("^(%s*%S+)%s+(%S.-)%s*$")

                if lhs and rhs then
                        local padding = math.max(2,
                                width -
                                vim.fn.strdisplaywidth(lhs) -
                                vim.fn.strdisplaywidth(rhs)
                        )

                        lines[i] = lhs .. string.rep(" ", padding) .. rhs
                end
        end

        vim.api.nvim_buf_set_lines(
                0, opts.line1 - 1, opts.line2, false, lines
        )
end, {
        range = true,
        nargs = "?",
        desc = "Right-align the second column of text"
})
