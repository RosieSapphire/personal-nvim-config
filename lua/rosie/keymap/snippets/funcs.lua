local dir = '$HOME/.config/nvim/snippets/'

local M = {}

function M.bind_create(keybind, path)
        vim.keymap.set('n', keybind, function()
                local file = vim.fn.expand(dir .. path)
                vim.cmd("read " .. file)
        end, { noremap = true, silent = true })
end

function M.bind_create_pragma(keybind, path)
        vim.keymap.set('n', keybind, function()
                local file = vim.fn.expand(dir .. path)
                vim.cmd("read " .. file)
                vim.api.nvim_feedkeys('j$i', 'n', false)
        end, { noremap = true, silent = true })
end

function M.get_dir()
	return dir
end

return M
