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

        -- Now restore our previous window view so it looks like nothing
        -- happened! But also make sure that it stays within the bounds of
        -- the file. For example, if the file was formatted is of a shorter
        -- length than the original and the cursor head happens to be at the
        -- bottom of the file. This doesn't happen very often, but it's
        -- extremely annoying when it does, so it's nice to just fix up! :D
        local line_cnt_new = vim.api.nvim_buf_line_count(0)
        local cursor_new   = {
                math.min(cursor_pos[1], line_cnt_new),
                cursor_pos[2]
        }

        vim.api.nvim_win_set_cursor(0, cursor_new)
end

vim.keymap.set('n', '<leader>fr', function()
        clang_format_current_buffer()
end, { desc = "Format current file with clang-format." })

vim.keymap.set('n', '<leader>fw', function()
        clang_format_current_buffer()
        if vim.bo.modified then
                vim.cmd('write')
        end
end, { desc = "Format current file with clang-format and save if changed." })
