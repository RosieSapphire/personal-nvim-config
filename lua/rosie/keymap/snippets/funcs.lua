local dir = vim.fn.stdpath('config') .. '/snippets/'

local M = {}

function M.bind_create(mode, keybind, path, keys_bef, keys_aft)
        vim.keymap.set(mode, keybind, function()
                local file = dir .. path
                if vim.fn.filereadable(file) == 0 then
                        vim.notify('Snippet not found: ' .. file, vim.log.levels.ERROR)
                        return
                end

                if keys_bef ~= '' then
                        vim.api.nvim_feedkeys(keys_bef, 'n', true)
                end

                vim.cmd('read ' .. vim.fn.fnameescape(file))

                if keys_aft ~= '' then
                        vim.api.nvim_feedkeys(keys_aft, 'n', true)
                end
        end, { noremap = true, silent = true })
end

function M.get_dir()
	return dir
end

return M
