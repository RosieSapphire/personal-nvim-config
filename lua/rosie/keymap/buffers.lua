-- Buffer helpers. Never force-delete user content.
-- Preserve the original keybindings while making deletion explicit and safe.
local M = {}
local uv = vim.uv or vim.loop

local function warn(msg)
        vim.notify(msg, vim.log.levels.WARN)
end

local function is_normal_buffer(buf)
        return vim.api.nvim_buf_is_valid(buf) and vim.bo[buf].buftype == ''
end

-- Keep the old policy: only auto-write modified, named, existing files.
-- If we cannot write them, or if a buffer is new/unnamed, DON'T DELETE IT.
local function prepare_to_delete(buf)
        if not is_normal_buffer(buf) then
                warn('Buffer ' .. buf .. ' is not a normal file buffer; left untouched.')
                return false
        end

        if not vim.bo[buf].modified then
                return true
        end

        local name = vim.api.nvim_buf_get_name(buf)
        if name == '' then
                warn('Buffer ' .. buf .. ' has unsaved contents and no filename; left untouched.')
                return false
        end

        local stat = uv.fs_stat(name)
        if not stat or stat.type ~= 'file' then
                warn('File does not exist on disk; save it explicitly before closing: ' .. name)
                return false
        end

        local ok, err = pcall(vim.api.nvim_buf_call, buf, function()
                vim.cmd('write')
        end)

        if not ok then
                vim.notify('Unable to save ' .. name .. ':\n' .. tostring(err), vim.log.levels.ERROR)
                return false
        end

        -- A BufWritePost autocmd could in principle modify the buffer again.
        if not vim.api.nvim_buf_is_valid(buf) or vim.bo[buf].modified then
                warn('Buffer ' .. buf .. ' is still modified after writing; left untouched.')
                return false
        end

        return true
end

local function delete_buffer(buf)
        -- Deliberately not :bdelete! (which discards changes).
        local ok, err = pcall(vim.cmd, 'bdelete ' .. tostring(buf))
        if not ok then
                vim.notify('Failed to delete buffer ' .. buf .. ':\n' .. tostring(err), vim.log.levels.ERROR)
                return false
        end
        return vim.fn.buflisted(buf) == 0
end

local function visible_windows(buf)
        local result = {}
        for _, win in ipairs(vim.api.nvim_list_wins()) do
                if vim.api.nvim_win_is_valid(win)
                    and vim.api.nvim_win_get_buf(win) == buf then
                        result[#result + 1] = win
                end
        end
        return result
end

local function scratch_buffer()
        local buf = vim.api.nvim_create_buf(false, true)
        vim.bo[buf].bufhidden = 'wipe'
        vim.bo[buf].swapfile = false
        return buf
end

-- <leader>bD: delete the buffer but leave all its windows open.
function M.close_keep_windows()
        local buf = vim.api.nvim_get_current_buf()
        if not prepare_to_delete(buf) then
                return false
        end

        local original_win = vim.api.nvim_get_current_win()
        local replaced = {}
        for _, win in ipairs(visible_windows(buf)) do
                local replacement = scratch_buffer()
                vim.api.nvim_win_set_buf(win, replacement)
                replaced[#replaced + 1] = win
        end

        if not delete_buffer(buf) then
                -- An autocmd may reject deletion. Restore the windows if possible.
                for _, win in ipairs(replaced) do
                        if vim.api.nvim_win_is_valid(win) and vim.api.nvim_buf_is_valid(buf) then
                                pcall(vim.api.nvim_win_set_buf, win, buf)
                        end
                end
                return false
        end

        if vim.api.nvim_win_is_valid(original_win) then
                vim.api.nvim_set_current_win(original_win)
        end
        return true
end

-- <leader>bd: delete the buffer AND close its window(s) where possible.
-- Do not quit the editor by closing its final window.
function M.close_with_windows()
        local buf = vim.api.nvim_get_current_buf()
        if not prepare_to_delete(buf) then
                return false
        end

        local wins = visible_windows(buf)
        if not delete_buffer(buf) then
                return false
        end

        for _, win in ipairs(wins) do
                if vim.api.nvim_win_is_valid(win) then
                        local tab = vim.api.nvim_win_get_tabpage(win)
                        if #vim.api.nvim_tabpage_list_wins(tab) > 1 then
                                local ok, err = pcall(vim.api.nvim_win_close, win, false)
                                if not ok then
                                        vim.notify('Could not close window: ' .. tostring(err), vim.log.levels.ERROR)
                                end
                        end
                end
        end
        return true
end

-- <leader>caec: keep all buffers that are displayed in ANY window.
function M.close_all_except_visible()
        local shown = {}
        for _, win in ipairs(vim.api.nvim_list_wins()) do
                if vim.api.nvim_win_is_valid(win) then
                        shown[vim.api.nvim_win_get_buf(win)] = true
                end
        end

        local removed = 0
        local skipped = 0
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if is_normal_buffer(buf) and vim.bo[buf].buflisted and not shown[buf] then
                        if prepare_to_delete(buf) and delete_buffer(buf) then
                                removed = removed + 1
                        else
                                skipped = skipped + 1
                        end
                end
        end
        vim.notify(string.format('Closed %d hidden buffers; skipped %d.', removed, skipped))
        return removed, skipped
end

local function is_truly_empty(buf)
        if not is_normal_buffer(buf) or not vim.bo[buf].buflisted then
                return false
        end
        if vim.bo[buf].modified or vim.api.nvim_buf_get_name(buf) ~= '' then
                return false
        end
        return vim.api.nvim_buf_line_count(buf) == 1
            and vim.api.nvim_buf_get_lines(buf, 0, 1, false)[1] == ''
end

-- <leader>caeb: an unnamed buffer is NOT necessarily an empty buffer!
function M.close_empty()
        local removed = 0
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if is_truly_empty(buf) and delete_buffer(buf) then
                        removed = removed + 1
                end
        end
        vim.notify(string.format('Closed %d genuinely empty buffers.', removed))
        return removed
end

vim.keymap.set('n', '<leader>bD', M.close_keep_windows, {
        desc = 'Save existing file and delete buffer; keep windows open',
})
vim.keymap.set('n', '<leader>bd', M.close_with_windows, {
        desc = 'Save existing file and close buffer and its windows',
})
vim.keymap.set('n', '<leader>caec', M.close_all_except_visible, {
        desc = 'Close hidden buffers without losing unsaved changes',
})
vim.keymap.set('n', '<leader>caeb', M.close_empty, {
        desc = 'Close genuinely empty, unmodified, unnamed buffers',
})

return M
