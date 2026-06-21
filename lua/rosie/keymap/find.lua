-- Make sure we can find everything in the `pwd`.
vim.opt.path:append("**")
vim.opt.wildmenu = true

local function grep_find_normal(opts)
        opts = opts or {}

        local word = vim.fn.expand('<cword>')

        if not opts.imprecise then
                word = '\\<' .. word .. '\\>'
        end

        local pattern = opts.pattern or '**/*'

        -- Push the the mark stack
        vim.cmd("normal! m'")

        -- Perform the fucken grep
        vim.cmd('silent! vimgrep /' .. word .. '/gj ' .. pattern)

        -- Open up the quickfix panel with the results. If
        -- there are no results, print a message saying so!
        if not vim.tbl_isempty(vim.fn.getqflist()) then
                -- This is the success condition!
                vim.cmd('copen')
                return
        end

        -- This is the "failure" (we couldn't find anything) condition! :D
        local pat_labels = {
                ['**/*.c']        = 'this directory\'s C Source files',
                ['**/*.h']        = 'this directory\'s C Header files',
                ['**/*.c **/*.h'] = 'this directory\'s C Source and Header files',
        }

        local fmt = 'No matches found for "%s" in %s'
        local pat = pat_labels[pattern] or pattern

        vim.notify(string.format(fmt, word, pat), vim.log.levels.INFO)
end

vim.keymap.set('n', '<leader>*h', function()
        grep_find_normal({ pattern = '**/*.h', imprecise = false })
end, { desc = "Find <cword> in all *.h files (normal, strict)." })

vim.keymap.set('n', '<leader>*c', function()
        grep_find_normal({ pattern = '**/*.c', imprecise = false })
end, { desc = "Find <cword> in all *.c files (normal, strict)." })

vim.keymap.set('n', '<leader>*a', function()
        grep_find_normal({ pattern = '**/*.c **/*.h', imprecise = false })
end, { desc = "Find <cword> in all *.h & *.c files (normal, strict)." })

vim.keymap.set('n', '<leader>*ih', function()
        grep_find_normal({ pattern = '**/*.h', imprecise = true })
end, { desc = "Find <cword> in all *.h files (normal, loose)." })

vim.keymap.set('n', '<leader>*ic', function()
        grep_find_normal({ pattern = '**/*.c', imprecise = true })
end, { desc = "Find <cword> in all *.c files (normal, loose)." })

vim.keymap.set('n', '<leader>*ia', function()
        grep_find_normal({ pattern = '**/*.{c,h}', imprecise = true })
end, { desc = "Find <cword> in all *.h & *.c files (normal, loose)." })

vim.keymap.set('n', '<C-e>', function()
        local qf = {}

        for _, bufnr in ipairs(vim.api.nvim_list_bufs()) do
                ------------------------------------------------------------
                -- FIXME: This indentation is ugly and I'd like to invert --
                --        the conditional statement to be prettier. qwq   --
                ------------------------------------------------------------
                if 0 ~= vim.fn.buflisted(bufnr) then
                        -- Get the name of the buffer from the number
                        local name = vim.fn.fnamemodify(
                                vim.api.nvim_buf_get_name(bufnr),
                                ':t'
                        )

                        -- If the file has no name, make sure we can see it. lol
                        if '' == name then
                                name = '[No Name]'
                        end

                        -- Get the line we were on upon this buffers last access
                        local line = vim.api.nvim_buf_get_mark(bufnr, '"')[1]

                        -- Make sure we didn't somehow get a fucked up line num
                        if 0 == line then
                                line = 1
                        end

                        -- Add this element to the Quickfix buffer! Make sure
                        -- that when we open it, it puts us on the same line
                        -- we were on when we last accessed it! :D
                        table.insert(qf, {
                                bufnr = bufnr,
                                lnum  = line,
                                col   = 1,
                                text  = name
                        })
                end
        end

        vim.fn.setqflist({}, 'r', { title = 'Buffers', items = qf })
        vim.cmd('copen')
end, { desc = "List all open buffers in quickfix window." })

vim.api.nvim_create_autocmd("FileType", {
        pattern = "qf",
        callback = function()
                vim.keymap.set("n", "<CR>", function()
                        local idx = vim.fn.line(".") -- current line in qf list
                        vim.cmd("wincmd p")          -- go back to orig window
                        vim.cmd("cc " .. idx)        -- jump to THAT entry
                        vim.cmd("cclose")            -- close quickfix
                end, { desc = "Open file in quickfix menu.", buffer = true })
        end,
})
