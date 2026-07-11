vim.g.mapleader = ' '

local function bind_term_gen_cmd(mv_key, rel_pos_str)
        -------------------------------------------------------------
        -- FIXME: Looks fucken' cringe, but I don't care too much. --
        -------------------------------------------------------------
        if mv_key ~= 'h' and
           mv_key ~= 'j' and
           mv_key ~= 'k' and
           mv_key ~= 'l' and
           mv_key ~= 'c' then
                vim.notify(
                        "ERROR: Bad move_key input: \"" .. mv_key .."\".",
                        vim.log.levels.ERROR
                )
                return
        end

        vim.keymap.set('n', '<C-t>' .. mv_key, function()
                -- Only create a new window if we don't want it in the
                -- window we already have selected in the program.
                if mv_key ~= 'c' then
                        vim.cmd('wincmd n')
                        vim.cmd('wincmd ' .. string.upper(mv_key))
                end

                vim.cmd('terminal')

                vim.notify(
                        "Created a new terminal window " .. rel_pos_str,
                        vim.log.levels.INFO
                )
        end, { desc = "Open new terminal " .. rel_pos_str .. "." })
end

bind_term_gen_cmd('h', 'to the left')
bind_term_gen_cmd('l', 'to the right')
bind_term_gen_cmd('j', 'down below')
bind_term_gen_cmd('k', 'up above')
bind_term_gen_cmd('c', 'in current window')

-- It's fucking retarded that Vim doesn't fucking do this already.
vim.keymap.set('n', '<C-w>N', function()
        vim.cmd('wincmd n')
        vim.cmd('wincmd L') -- Right is most common placement for me at least.
end, { desc = "Open new window horizontally" })

vim.keymap.set('n', '<leader>pv', function()
        vim.cmd.Ex()
end, { desc = "Open Vim's file browser (newrt)." })

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

vim.keymap.set('n', '<leader>msgo', '<cmd>messages<CR>', {
        desc   = "Bring up the 'message history' menu.",
        silent = true
})

vim.keymap.set('n', '<leader>msgc', '<cmd>messages clear<CR>', {
        desc   = "Clear out the 'message history' menu.",
        silent = true
})

vim.keymap.set('n', '<leader>pwd', '<cmd>pwd<CR>', {
        desc   = "Print out the user's current working directory.",
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

------------------------------------------------------------------------------
-- FIXME: I actually just fucken' realized that what I _actually_ want is --
--        for this function to return if the file actually saved! xD      --
------------------------------------------------------------------------------
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
         vim.notify(
                 "[CLOSE ALL EXCEPT CURRENT] <leader>caec:",
                 vim.log.levels.INFO
         )

        --------------------------------------------------------
        -- Create a set of "protected" buffers that don't get --
        -- deleted when the rest of them get fucken' nuked.   --
        --------------------------------------------------------
        local bufs_keep = get_bufs_used_in_open_windows()
        local nuked     = {}

        vim.notify(
                "\tNuking all buffers not currently used by an open window.",
                 vim.log.levels.INFO
        )

        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                local buf_is_normal = vim.api.nvim_buf_is_valid(buf)
                                  and vim.bo[buf].buflisted
                                  and vim.bo[buf].buftype == ''

                -- Only delete VISIBLE, NORMAL buffers that are NOT protected.

                --------------------------------------------------------------
                -- FIXME: Is this fucken indentation _really_ necessary?    --
                --------------------------------------------------------------
                if buf_is_normal then
                        if not bufs_keep[buf] then
                                ----------------------------------------------
                                -- TODO: Add ability to tell which files    --
                                --       were actually saved or not.        --
                                ----------------------------------------------
                                if buf_save_if_existing_file(buf) then
                                        table.insert(nuked, buf)
                                        buf_del_force(buf)
                                        vim.notify(
                                                "\t\tRemoved buffer " ..
                                                buf .. ".",
                                                vim.log.levels.INFO
                                        );
                                end
                        end
                end
        end

        if #nuked ~= 0 then
                vim.notify(
                        "Removed " .. #nuked .. " unfocused buffers.",
                        vim.log.levels.INFO
                );
        else
                vim.notify(
                        "No unfocused buffers to remove.",
                        vim.log.levels.INFO
                );
        end
end, { desc = "Closes all buffers except visible ones.", silent = true })

------------------------------------------------------------------------------
-- FIXME: There is one caveat with this. See, this specifically targets     --
--        no-name buffers to delete them. However, if I'm using one as a    --
--        fucking scratch pad and accidentally run this command without     --
--        saving it first, I will lose everything I wrote in that fucken'   --
--        buffer.
--
--        That really _shouldn't_ be a problem (said everbody whom it ended --
--        up being a problem for ever), but if I were to fix this, I would  --
--        just ALSO check— in addition to the buffer having no name— that   --
--        the actual buffer's contents are empty.                           --
------------------------------------------------------------------------------
vim.keymap.set('n', '<leader>caeb', function()
        vim.notify("[CLOSE ALL EMPTY BUFFERS] <leader>caeb:", vim.log.levels.INFO)

        local empty = {}

        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                local is_valid = vim.api.nvim_buf_is_valid(buf) and
                                 vim.bo[buf].buftype == '' and
                                 vim.bo[buf].buflisted

                if is_valid then
                        local name  = vim.api.nvim_buf_get_name(buf)

                        -- Only append buffers with no names.
                        if name == '' then
                                vim.notify(
                                        "\t\tBuffer " .. buf .. " is empty.",
                                        vim.log.levels.INFO
                                )
                                table.insert(empty, buf)
                        end
                end
        end

        for _, buf in ipairs(empty) do
                buf_del_force(buf)
        end

        vim.notify(
                "Removed " .. #empty .. " empty buffers!",
                vim.log.levels.INFO
        )
end, { desc = "Closes all empty buffers, visible or not", silent = true })
