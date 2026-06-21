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

local function bind_cmd_simple(keys, cmd)
        vim.keymap.set('n', keys, function() vim.cmd(cmd) end, {})
end

bind_cmd_simple('<leader>w', 'write')
bind_cmd_simple('<leader>bd', 'bd!')

vim.keymap.set('n', '<leader>caec', function()
        local curbuf = vim.api.nvim_get_current_buf()

        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
                if buf ~= curbuf
                and vim.bo[buf].buflisted
                and vim.bo[buf].buftype == ''
                then
                        -- Make sure to save the buffer if we need to.
                        if vim.bo[buf].modified then
                                vim.api.nvim_buf_call(buf, function()
                                        vim.cmd('write')
                                end)
                        end

                        -- Delete the buffer itself
                        vim.api.nvim_buf_delete(buf, { force = false })
                end
        end
end, { desc = "Closes all buffers except the one focused.", silent = true })
