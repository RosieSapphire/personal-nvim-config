local dir = '$HOME/.config/nvim/snippets/'

local M = {}

function M.bind_create(mode, keybind, path, keys)
        vim.keymap.set(mode, keybind, function()
                local file = vim.fn.expand(dir .. path)
                vim.cmd("read " .. file)
                if keys ~= '' then
                        vim.api.nvim_feedkeys(keys, 'n', false)
                end
        end, { noremap = true, silent = true })
end

function M.get_dir()
	return dir
end

return M
