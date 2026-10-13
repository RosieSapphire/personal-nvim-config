local dir = vim.fn.stdpath('config') .. '/snippets/'

local M = {}

function M.bind_create(mode, keybind, path, keys)
        vim.keymap.set(mode, keybind, function()
                local file = dir .. path
                if vim.fn.filereadable(file) == 0 then
                        vim.notify('Snippet not found: ' .. file, vim.log.levels.ERROR)
                        return
                end
                vim.cmd('read ' .. vim.fn.fnameescape(file))
                if keys ~= '' then
                        vim.api.nvim_feedkeys(keys, 'n', true)
                end
        end, { noremap = true, silent = true })
end

function M.get_dir()
	return dir
end

return M
