-- LuaLS --
vim.lsp.config('lua_ls', {
	cmd = { 'lua-language-server' },
	filetypes = { 'lua' },
	root_markers = {
		'.luarc.json',
		'.luarc.jsonc',
		'.luacheckrc',
		'.stylua.toml',
		'selene.toml',
		'selene.yml',
		'.git',
	},
        settings = {
                Lua = {
                        diagnostics = {
                                globals = { 'vim' }
                        }
                }
        }
})

vim.lsp.enable('lua_ls')

-- Prefer the existing Mason installation, but don't require Mason merely
-- to run clangd in an isolated NVIM_APPNAME profile.
local clangd = vim.fn.stdpath('data') .. '/mason/bin/clangd'
if vim.fn.executable(clangd) == 0 then
        local system_clangd = vim.fn.exepath('clangd')
        clangd = system_clangd ~= '' and system_clangd or 'clangd'
end

-- Clang --
vim.lsp.config('clangd', {
	cmd = {
                clangd,
                -- Only authorizes querying this compiler when it appears in
                -- compile_commands.json; does not select it for other projects.
                '--query-driver=/opt/libdragon/bin/mips64-elf-gcc'
        },
	filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
        -- The compilation database determines the useful workspace. A nested
        -- .clang-format should not take precedence over it.
        root_markers = {
                'compile_commands.json',
                '.clangd',
                'compile_flags.txt',
                '.git',
                '.clang-tidy',
                '.clang-format',
                'configure.ac',
        },
	capabilities = {
		textDocument = {
			completion = {
				editsNearCursor = true,
			},
		},
		offsetEncoding = { 'utf-8', 'utf-16' },
	},
	on_init = function(client, init_result)
		if init_result.offsetEncoding then
			client.offset_encoding = init_result.offsetEncoding
		end
	end,

})

vim.lsp.enable('clangd')

-- :checkhealth checks the configuration, but does not guarantee that a
-- client actually attached to the buffer currently being edited.
vim.api.nvim_create_user_command('RosieLspInfo', function()
        local buf = vim.api.nvim_get_current_buf()
        local cfg = vim.lsp.config.clangd
        local attached = vim.lsp.get_clients({ bufnr = buf })
        local output = {
                'File: ' .. vim.api.nvim_buf_get_name(buf),
                'Filetype: ' .. vim.bo[buf].filetype,
                'Buftype: ' .. vim.bo[buf].buftype,
                'clangd command: ' .. table.concat(cfg.cmd or {}, ' '),
                'clangd executable: ' .. tostring(vim.fn.executable((cfg.cmd or {})[1] or 'clangd') == 1),
                'Detected root: ' .. tostring(vim.fs.root(buf, cfg.root_markers or {})),
                'Attached LSP clients: ' .. tostring(#attached),
        }
        for _, client in ipairs(attached) do
                output[#output + 1] = string.format('  %s (root: %s)',
                        client.name, tostring(client.config.root_dir))
        end
        vim.api.nvim_echo({ { table.concat(output, '\n') } }, false, {})
end, { desc = 'Report LSP attachment and clangd project root' })
