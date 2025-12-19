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
})

vim.lsp.enable('lua_ls')

-- Clang --
vim.lsp.config('clangd', {
	cmd = { 'clangd' },
	filetypes = { 'c', 'cpp', 'objc', 'objcpp', 'cuda' },
	root_markers = {
		'.clangd',
		'.clang-tidy',
		'.clang-format',
		'compile_commands.json',
		'compile_flags.txt',
		'configure.ac',
		'.git',
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
	on_attach = function(client, bufnr)
		vim.api.nvim_buf_create_user_command(bufnr, 'LspClangdSwitchSourceHeader', function()
			switch_source_header(bufnr, client)
		end, { desc = 'Switch between source/header' })

		vim.api.nvim_buf_create_user_command(bufnr, 'LspClangdShowSymbolInfo', function()
			symbol_info(bufnr, client)
		end, { desc = 'Show symbol info' })
	end,
})

vim.lsp.enable('clangd')

-- CMake --
--[[
vim.lsp.config('cmake', {
	cmd = { 'cmake-language-server' },
	filetypes = { 'cmake' },
	root_markers = { 'CMakePresets.json', 'CTestConfig.cmake', '.git', 'build', 'cmake' },
	init_options = {
		buildDirectory = 'build',
	},
})

vim.lsp.enable('cmake')
]]-- This one doesn't work because I can't use pip (fucking trash) to install
