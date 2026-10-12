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

        vim.keymap.set('n', '<leader>t' .. mv_key, function()
                -- Only create a new window if we don't want it in the
                -- window we already have selected in the program.
                if mv_key ~= 'c' then
                        vim.cmd('wincmd n')
                        vim.cmd('wincmd ' .. string.upper(mv_key))
                end

                vim.cmd('terminal')                   -- Spawn the terminal.
                vim.api.nvim_feedkeys('A', 'n', true) -- Enter into it.

                vim.notify(
                        "Created a new terminal window " .. rel_pos_str,
                        vim.log.levels.INFO
                )

                -- Extra step for a _VERY_ specific fucking reason. See, 99%
                -- of what I use NeoVim (or just Vim at all for that matter)
                -- is for fucking coding in C! God's motherfucking language!
                -- Now, the thing about my workflow is that I have code on the
                -- left and then a terminal on the right for compiling and
                -- reading debug log outputs and all that fucken' lovely shit.
                --
                -- The thing about that is, I have an 80-char column bar at
                -- the right of my code thing, and I always perfer to have
                -- that lined up with the edge of my terminal so that I can
                -- maximize space usage for all my motherfucking shit to get
                -- better outputs! >:D
                --
                -- Now, the problem with doing it this retarded-ass fucking
                -- way is that this _only_ works on the screen that I am
                -- currently writing _this_ fucking crap on, so the absolutely
                -- last thing it is is portable.
                --
                -- That being said, it's good enough for me for now, so I'm
                -- not gonna bitch about it too much, and neither should you!
                --
                -- :D <3

                if mv_key ~= 'l' then
                        return
                end

                vim.api.nvim_feedkeys(
                        vim.keycode([[<C-\><C-n><C-w>10>A]]), 'n', true
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
        vim.cmd('botright copen')
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
