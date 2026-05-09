--------------------------------------
-- MACROS FOR BETTER PATH SEARCHING --
--------------------------------------

vim.opt.path:append("**")
vim.opt.wildmenu = true

-- Find item in all header files
vim.keymap.set('n', '<leader>*h', function()
	local word = vim.fn.expand('<cword>')
	vim.cmd('vimgrep /\\<' .. word .. '\\>/gj **/*.h')
	vim.cmd('copen')
end, { silent = true })

-- Find item in all source files
vim.keymap.set('n', '<leader>*c', function()
	local word = vim.fn.expand('<cword>')
	vim.cmd('vimgrep /\\<' .. word .. '\\>/gj **/*.c')
	vim.cmd('copen')
end, { silent = true })

-- Find item in all header and source files
vim.keymap.set('n', '<leader>*a', function()
	local word = vim.fn.expand('<cword>')
	vim.cmd('vimgrep /\\<' .. word .. '\\>/gj **/*.{c,h}')
	vim.cmd('copen')
end, { silent = true })

-- Find item in all header files (imprecise)
vim.keymap.set('n', '<leader>*ih', function()
	local word = vim.fn.expand('<cword>')
	vim.cmd('vimgrep /' .. word .. '/gj **/*.h')
	vim.cmd('copen')
end, { silent = true })

-- Find item in all source files (imprecise)
vim.keymap.set('n', '<leader>*ic', function()
	local word = vim.fn.expand('<cword>')
	vim.cmd('vimgrep /' .. word .. '/gj **/*.c')
	vim.cmd('copen')
end, { silent = true })

-- Find item in all header and source files (imprecise)
vim.keymap.set('n', '<leader>*ia', function()
	local word = vim.fn.expand('<cword>')
	vim.cmd('vimgrep /' .. word .. '/gj **/*.{c,h}')
	vim.cmd('copen')
end, { silent = true })

-- Find item in all header and source files (imprecise)
vim.keymap.set('n', '<leader>*h', function()
	local word = vim.fn.expand('<cword>')
	vim.cmd('vimgrep /\\<' .. word .. '\\>/gj **/*.h')
	vim.cmd('copen')
end, { silent = true })

vim.api.nvim_create_autocmd("FileType", {
	pattern = "qf",
	callback = function()
		vim.keymap.set("n", "<CR>", function()
			local idx = vim.fn.line(".") -- current line in qf list
			vim.cmd("wincmd p")	     -- go back to  orig window
			vim.cmd("cc " .. idx)	     -- jump to THAT entry
			vim.cmd("cclose")						-- close quickfix
		end, { buffer = true })
	end,
})

-------------------------------
-- SNIPPETS FOR GENERAL SHIT --
-------------------------------

-- Pragma warning diagnostics for GCC
vim.keymap.set('n', ',pgcc', function()
	local file = vim.fn.expand('$HOME/.config/nvim/snippets/pragma_gcc')
	vim.cmd('read ' .. file)
	vim.api.nvim_feedkeys('j$i', 'n', false)
end, { noremap = true, silent = true })

-- Pragma warning diagnostics for clang
vim.keymap.set('n', ',pcla', function()
	local file = vim.fn.expand('$HOME/.config/nvim/snippets/pragma_clang')
	vim.cmd('read ' .. file)
	vim.api.nvim_feedkeys('j$i', 'n', false)
end, { noremap = true, silent = true })

-- Just a simple hello world program in C
vim.keymap.set('n', ',hello', function()
	local file = vim.fn.expand('$HOME/.config/nvim/snippets/hello_world')
	vim.cmd("read " .. file)
end, { noremap = true, silent = true })

-- Debug macro for a specific module
vim.keymap.set('n', ',dbm', function()
	local file = vim.fn.expand('$HOME/.config/nvim/snippets/debug_macro')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- If `N64` is NOT defined
vim.keymap.set('n', ',nif64', function()
	local file = vim.fn.expand('$HOME/.config/nvim/snippets/ifn_n64')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- If `N64` IS defined
vim.keymap.set('n', ',if64', function()
	local file = vim.fn.expand('$HOME/.config/nvim/snippets/if_n64')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

--------------------------------------------------
-- SNIPPETS FOR INCLUDE HEADER SECTION COMMENTS --
--------------------------------------------------

-- Includes
vim.keymap.set('n', ',iinc', function()
	local file = vim.fn.expand('$HOME/.config/nvim/snippets/inc_includes')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Defines
vim.keymap.set('n', ',idef', function()
	local file = vim.fn.expand('$HOME/.config/nvim/snippets/inc_defines')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Macros
vim.keymap.set('n', ',imac', function()
	local file = vim.fn.expand('$HOME/.config/nvim/snippets/inc_macros')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Enums
vim.keymap.set('n', ',ienu', function()
	local file = vim.fn.expand('$HOME/.config/nvim/snippets/inc_enums')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Typedefs
vim.keymap.set('n', ',ityp', function()
	local file = vim.fn.expand('$HOME/.config/nvim/snippets/inc_typedefs')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Structures
vim.keymap.set('n', ',istru', function()
	local file = vim.fn.expand('$HOME/.config/nvim/snippets/inc_structs')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- External Variables
vim.keymap.set('n', ',ivex', function()
	local file = vim.fn.expand('$HOME/.config/nvim/snippets/inc_var_ext')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Static Variables
vim.keymap.set('n', ',ivst', function()
	local file = vim.fn.expand('$HOME/.config/nvim/snippets/inc_var_stat')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Function Declarations
vim.keymap.set('n', ',ifun', function()
	local file = vim.fn.expand('$HOME/.config/nvim/snippets/inc_functions')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Inline Functions
vim.keymap.set('n', ',iinl', function()
	local file = vim.fn.expand('$HOME/.config/nvim/snippets/inc_func_inl')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

--------------------
-- OTHER SNIPPETS --
--------------------

-- Include setup
vim.keymap.set('n', ',inc', function()
	local file = vim.fn.expand('$HOME/.config/nvim/snippets/include_setup')
	vim.cmd('read ' .. file)
	vim.api.nvim_feedkeys('$hhi', 'n', false)
end, { noremap = true, silent = true })
--
-- Include setup (with brackets, instead)
vim.keymap.set('n', ',binc', function()
	local file = vim.fn.expand('$HOME/.config/nvim/snippets/include_setupb')
	vim.cmd('read ' .. file)
	vim.api.nvim_feedkeys('$hhi', 'n', false)
end, { noremap = true, silent = true })

-- Generating CTags for code --
vim.api.nvim_create_user_command('MakeTags', function()
	if 0 == vim.fn.executable('ctags') then
		vim.notify("ERROR: `ctags` is not an executable " ..
			   "on this system. Please install it via " ..
			   "your distro's package manager!",
			   vim.log.levels.ERROR);
		return;
	end
	
	vim.fn.jobstart({'ctags', '-R', '.'}, {
  on_exit = function(_, code) if 0 ~= code then vim.notify(
      "ERROR: Failed to generate CTags!", vim.log.levels.ERROR) end end
	})
end, {})

-- Formatting the current file and returning to the cursor position! --
vim.api.nvim_create_user_command('FormatFileWithClang', function()
	if 0 == vim.fn.executable('clang-format') then
		vim.notify("ERROR: `clang-format` not found on system! " ..
			   "Please install via your distro's package manager",
			   vim.log.levels.ERROR)
		return
	end

	local view      = vim.fn.winsaveview()
	local lines     = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local formatted = vim.fn.systemlist('clang-format', lines)

	if 0 ~= vim.v.shell_error then
		vim.notify("ERROR: Failed to format the " ..
			   "current file using `clang-format`!",
			   vim.log.levels.ERROR)
		return
	end

	vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted)
	vim.fn.winrestview(view)
end, {})

-- Lines & Numbers --
vim.opt.number         = true
vim.opt.relativenumber = true
vim.opt.wrap           = true

-- Tabs --
vim.opt.expandtab   = false
vim.opt.tabstop     = 8
vim.opt.softtabstop = 8
vim.opt.shiftwidth  = 8
vim.opt.smartindent = true
vim.opt.autoindent  = true

-- Columns --
vim.opt.scrolloff   = 8
vim.opt.signcolumn  = 'yes' -- Figure out what this does
vim.opt.colorcolumn = '80'

-- Diagnostics --
vim.diagnostic.config({
        virtual_text = false,
        signs        = true,
        underline    = true,
        float = { border = 'rounded', focusable = false }
})

vim.api.nvim_create_autocmd({ 'CursorHold', 'CursorHoldI' }, {
        pattern  = '*',
        callback = function()
                vim.diagnostic.open_float(nil, { focus = false })
        end
})

vim.api.nvim_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", {
        noremap = true, silent = true
})

-- Etc --
vim.opt.updatetime = 250
vim.opt.cinoptions:append({':0'})
