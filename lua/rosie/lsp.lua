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

})

vim.lsp.enable('clangd')
