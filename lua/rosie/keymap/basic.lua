vim.g.mapleader = ' '

vim.keymap.set('n', '<leader>pv', function()
        vim.cmd.Ex()
end, { desc="Open Vim's file browser (newrt)." })

vim.keymap.set({ 'n', 'x' }, '<leader>cp', function()
        vim.api.nvim_feedkeys('"+y', 'n', true)
end, { desc = "Yank some shit into the system's clipboard." })

vim.keymap.set('n', '<leader>mason', function()
        vim.cmd('Mason')
end, { desc = "Open the Mason window (rarely-used, hence long name)." })

vim.keymap.set('n', '<leader>lr', function()
        vim.cmd('registers')
end, { desc = "List contents of all registers." })

vim.keymap.set('n', '<leader>qo', function()
        vim.cmd('copen')
end, { desc = "Open quickfix window." })

vim.keymap.set('n', '<leader>qc', function()
        vim.cmd('cclose')
end, { desc = "Close quickfix window." })

vim.keymap.set('n', '<leader>so', function()
        vim.cmd('so')
end, { desc = "Source the current file (used for all *.lua file changes)." })

vim.keymap.set('n', '<leader>msg', '<cmd>messages<CR>', {
        desc   = "Bring up the 'message history' menu.",
        silent = true
})

vim.keymap.set('n', '<leader>cms', '<cmd>messages clear<CR>', {
        desc   = "Clear out the 'message history' menu.",
        silent = true
})

local function bind_cmd_simple(keys, cmd)
        vim.keymap.set('n', keys, function() vim.cmd(cmd) end, {})
end

bind_cmd_simple('<leader>w', 'write')

------------------------------------------------------------------------------

local function buf_is_existing_file(buf)
        if not vim.api.nvim_buf_is_valid(buf) then
                return false
        end

        -- Skip anything that's not a file buffer.
        if vim.bo[buf].buftype ~= '' then
                return false
        end

        local name = vim.api.nvim_buf_get_name(buf)
        if name == '' then
                return false
        end

        local uv   = vim.uv or vim.loop
        local stat = uv.fs_stat(name)

        return stat and stat.type == 'file'
end

local function buf_save_if_existing_file(buf)
        if not vim.api.nvim_buf_is_valid(buf) then
                return true
        end

        if not vim.bo[buf].modified then
                return true
        end

        if not buf_is_existing_file(buf) then
                return true
        end

        local name = vim.api.nvim_buf_get_name(buf)

        local ok, err = pcall(function()
                vim.api.nvim_buf_call(buf, function()
                        vim.cmd('write')
                end)
        end)

        if not ok then
                vim.notify(
                        string.format(
                                'Failed to write buffer before deleting:\n%s\n\n%s',
                                name,
                                err
                        ),
                        vim.log.levels.ERROR
                )
                return false
        end

        return true
end

local function buf_del_force(buf)
        local ok, err = pcall(vim.cmd, string.format('bdelete! %d', buf))

        if ok then
                return true
        end

        vim.notify(err, vim.log.levels.ERROR)
        return false
end

local function buf_new_empty()
        local buf = vim.api.nvim_create_buf(false, true)

        vim.bo[buf].bufhidden = 'wipe'
        vim.bo[buf].swapfile  = false

        return buf
end

local function get_windows_using_buf(buf)
        local wins = {}

        for _, win in ipairs(vim.api.nvim_list_wins()) do
                if vim.api.nvim_win_is_valid(win)
                   and vim.api.nvim_win_get_buf(win) == buf then
                        table.insert(wins, win)
                end
        end

        return wins
end

local function get_bufs_used_in_open_windows()
        local shown = {}

        for _, win in ipairs(vim.api.nvim_list_wins()) do
                if vim.api.nvim_win_is_valid(win) then
                        shown[vim.api.nvim_win_get_buf(win)] = true
                end
        end

        return shown
end

local function buf_cur_and_window_cur_del()
        local buf = vim.api.nvim_get_current_buf()

        if buf_save_if_existing_file(buf) then
                buf_del_force(buf)
        end
end

local function buf_cur_del_keep_window()
        local buf = vim.api.nvim_get_current_buf()
        local win = vim.api.nvim_get_current_win()

        if not buf_save_if_existing_file(buf) then
                return
        end

        -- Replace all windows using this buffer with an empty scratch buf.
        for _, w in ipairs(get_windows_using_buf(buf)) do
                if vim.api.nvim_win_is_valid(w) then
                        vim.api.nvim_win_set_buf(w, buf_new_empty())
                end
        end

        if vim.api.nvim_win_is_valid(win) then
                vim.api.nvim_set_current_win(win)
        end

        buf_del_force(buf)
end

vim.keymap.set('n', '<leader>bD', buf_cur_del_keep_window, {
        desc = "Save buf to existing file, close it, but keep window(s) open."
})

vim.keymap.set('n', '<leader>bd', buf_cur_and_window_cur_del, {
        desc = "Save buf to existing file, close it AND it's window(s) too."
})

vim.keymap.set('n', '<leader>caec', function()
        --------------------------------------------------------
        -- Create a set of "protected" buffers that don't get --
        -- deleted when the rest of them get fucken' nuked.   --
        --------------------------------------------------------
        local bufs_keep = get_bufs_used_in_open_windows()

        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                local buf_is_normal =
                        vim.api.nvim_buf_is_valid(buf)
                    and vim.bo[buf].buflisted
                    and vim.bo[buf].buftype == ''

                -- Only delete NORMAL buffers that are NOT protected.
                if buf_is_normal and not bufs_keep[buf] then
                        if buf_save_if_existing_file(buf) then
                                buf_del_force(buf)
                        end
                end
        end
end, { desc = "Closes all buffers except visible ones.", silent = true })
