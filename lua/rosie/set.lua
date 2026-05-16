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

local snip_dir = '$HOME/.config/nvim/snippets/'

-- Pragma warning diagnostics for GCC
vim.keymap.set('n', ',pgcc', function()
	local file = vim.fn.expand(snip_dir .. 'pragma_gcc')
	vim.cmd('read ' .. file)
	vim.api.nvim_feedkeys('j$i', 'n', false)
end, { noremap = true, silent = true })

-- Pragma warning diagnostics for clang
vim.keymap.set('n', ',pcla', function()
	local file = vim.fn.expand(snip_dir .. 'pragma_clang')
	vim.cmd('read ' .. file)
	vim.api.nvim_feedkeys('j$i', 'n', false)
end, { noremap = true, silent = true })

-- Just a simple hello world program in C
vim.keymap.set('n', ',hello', function()
	local file = vim.fn.expand(snip_dir .. 'hello_world')
	vim.cmd("read " .. file)
end, { noremap = true, silent = true })

-- Debug macro for a specific module
vim.keymap.set('n', ',dbm', function()
	local file = vim.fn.expand(snip_dir .. 'debug_macro')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-------------------------------------------------------------
-- SNIPPETS FOR INCLUDE HEADER AND SOURCE SECTION COMMENTS --
-------------------------------------------------------------

-- Defines
vim.keymap.set('n', ',cdef', function()
	local file = vim.fn.expand(snip_dir .. 'com/defines')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Enums
vim.keymap.set('n', ',cenu', function()
	local file = vim.fn.expand(snip_dir .. 'com/enums')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Inline Functions
vim.keymap.set('n', ',cfuni', function()
	local file = vim.fn.expand(snip_dir .. 'com/func_inl')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Private Function Prototypes
vim.keymap.set('n', ',cfunprp', function()
	local file = vim.fn.expand(snip_dir .. 'com/func_prv_pro')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Private Function Implementations
vim.keymap.set('n', ',cfunpri', function()
	local file = vim.fn.expand(snip_dir .. 'com/func_prv_imp')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Public Function Prototypes
vim.keymap.set('n', ',cfunpup', function()
	local file = vim.fn.expand(snip_dir .. 'com/func_pub_pro')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Public Function Definitions
vim.keymap.set('n', ',cfunpui', function()
	local file = vim.fn.expand(snip_dir .. 'com/func_pub_imp')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Include Headers
vim.keymap.set('n', ',cinc', function()
	local file = vim.fn.expand(snip_dir .. 'com/include')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Macros
vim.keymap.set('n', ',cmac', function()
	local file = vim.fn.expand(snip_dir .. 'com/macros')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Structures
vim.keymap.set('n', ',cstru', function()
	local file = vim.fn.expand(snip_dir .. 'com/structs')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Typedefs
vim.keymap.set('n', ',ctyp', function()
	local file = vim.fn.expand(snip_dir .. 'com/typedefs')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Public Variable Prototypes
vim.keymap.set('n', ',cvarpup', function()
	local file = vim.fn.expand(snip_dir .. 'com/var_pub_dec')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Public Variable Implementations
vim.keymap.set('n', ',cvarpui', function()
	local file = vim.fn.expand(snip_dir .. 'com/var_pub_imp')
	vim.cmd('read ' .. file)
end, { noremap = true, silent = true })

-- Private Variables
vim.keymap.set('n', ',cvarpr', function()
	local file = vim.fn.expand(snip_dir .. 'com/var_prv')
	vim.cmd('read ' .. file)
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

----------------------------------
-- SNIPPETS FOR CODE GENERATION --
----------------------------------

-- Include setup with quotation marks
vim.keymap.set('n', ',inc', function()
	local file = vim.fn.expand(snip_dir .. '/inc_setup_quote')
	vim.cmd('read ' .. file)
	vim.api.nvim_feedkeys('$hhi', 'n', false)
end, { noremap = true, silent = true })

-- Include setup with angled brackets
vim.keymap.set('n', ',binc', function()
	local file = vim.fn.expand(snip_dir .. '/inc_setup_angle')
	vim.cmd('read ' .. file)
	vim.api.nvim_feedkeys('$hhi', 'n', false)
end, { noremap = true, silent = true })

-- Named header guard
vim.keymap.set('n', ',hg', function()
	local guard = vim.fn.input('Header Guard Name: ')
	local view      = vim.fn.winsaveview()

	vim.fn.append(0, {
		'#ifndef ' .. guard,
		'#define ' .. guard,
		''
	})

	vim.fn.append(vim.fn.line('$'), {
		'',
		'#endif /* #ifndef ' .. guard .. ' */'
	})

	vim.fn.winrestview(view)
end, { noremap = true, silent = true })

-- #ifdef & #ifndef with names
local function ifdef_mode_normal(guard, do_else)
	return function()
		local name      = vim.fn.input(guard .. ': ')
		local real_g = ''

		-- Exception for `#if 0`
		if name == '0' then
			real_g = '#if'
		else
			real_g = guard
		end

		vim.fn.append(vim.fn.line('.') - 1,
			real_g .. ' ' .. name
		)

		if do_else then
			vim.fn.append(vim.fn.line('.') - 1,
				'#else /* ' .. real_g .. ' ' .. name .. ' */'
			)

			vim.fn.append(vim.fn.line('.') - 1,
				'#endif /* ' .. real_g .. ' ' .. name .. ' #else */'
			)
		else
			vim.fn.append(vim.fn.line('.') - 1,
				'#endif /* ' .. real_g .. ' ' .. name .. ' */'
			)
		end
	end
end

local function ifdef_mode_visual(guard, do_else)
	return function()
		local line_a     = vim.fn.line('v')
		local line_b     = vim.fn.line('.')
		local name      = vim.fn.input(guard .. ': ')
		local real_g = ''

		-- Exception for `#if 0`
		if name == '0' then
			real_g = '#if'
		else
			real_g = guard
		end
	
		if line_a > line_b then
			line_a, line_b = line_b, line_a
		end
	
		if do_else == true then
			vim.fn.append(line_b, {
				'#else /* ' .. real_g .. ' ' .. name .. ' */',
				'#endif /* ' .. real_g .. ' ' .. name .. ' #else */'
			})
		else
			vim.fn.append(line_b, {
				'#endif /* ' .. real_g .. ' ' .. name .. ' */'
			})
		end
	
		vim.fn.append(line_a - 1, {
			real_g .. ' ' .. name
		})
	
		-- vim.api.nvim_win_set_cursor(0, { line_a, 0 })
	end
end

-- #ifdef (normal)
vim.keymap.set(
	'n',
	',ifd',
	ifdef_mode_normal('#ifdef', false),
	{ silent = true }
)

-- #ifdef #else (normal)
vim.keymap.set(
	'n',
	',ifed',
	ifdef_mode_normal('#ifdef', true),
	{ silent = true }
)

-- #ifdef (visual)
vim.keymap.set(
	'x',
	',ifd',
	ifdef_mode_visual('#ifdef', false),
	{ silent = true }
)

-- #ifdef #else (visual)
vim.keymap.set(
	'x',
	',ifed',
	ifdef_mode_visual('#ifdef', true),
	{ silent = true }
)

-- #ifndef (normal)
vim.keymap.set(
	'n',
	',ifnd',
	ifdef_mode_normal('#ifndef', false),
	{ silent = true }
)

-- #ifndef #else (normal)
vim.keymap.set(
	'n',
	',ifned',
	ifdef_mode_normal('#ifndef', true),
	{ silent = true }
)

-- #ifndef (visual)
vim.keymap.set(
	'x',
	',ifnd',
	ifdef_mode_visual('#ifndef', false),
	{ silent = true }
)

-- #ifndef #else (visual)
vim.keymap.set(
	'x',
	',ifned',
	ifdef_mode_visual('#ifndef', true),
	{ silent = true }
)

-- Encase the current line in a comment block
vim.keymap.set('n', ',ec', function()
	local line    = vim.api.nvim_get_current_line()
	local indent  = line:match('^%s*')
	local content = line:sub(#indent + 1)

	vim.api.nvim_set_current_line(
		indent .. '/* ' .. content .. ' */'
	)
end, { noremap = true, silent = true })

-- Un-encase the current line from a comment block
vim.keymap.set('n', ',uc', function()
	local line = vim.api.nvim_get_current_line()
	local ucom = line:gsub('^(%s*)/%*%s?(.-)%s?%*/$', '%1%2')

	vim.api.nvim_set_current_line(ucom)
end, { noremap = true, silent = true })

-- Encase an entire visual block with a comment
vim.keymap.set('x', ',ec', function()
	local line_a = vim.fn.line('v')
	local line_b = vim.fn.line('.')

	if line_a > line_b then
		line_a, line_b = line_b, line_a
	end

	local lines = vim.api.nvim_buf_get_lines(0, line_a - 1, line_b, false)
	local indent = lines[1]:match('^%s*') or ''
	local commented = { indent .. '/*' }

	for _, line in ipairs(lines) do
		table.insert(commented, indent .. ' * ' .. line:sub(#indent + 1))
	end

	table.insert(commented, indent .. ' */')

	vim.api.nvim_buf_set_lines(0, line_a - 1, line_b, false, commented)

	-- vim.api.nvim_win_set_cursor(0, { line_a, 0 })
	-- vim.cmd('normal! zz')
	
	vim.api.nvim_feedkeys(
		vim.api.nvim_replace_termcodes('<Esc>', true, false, true),
		'n',
		false
	)
end, { noremap = true, silent = true })

-----------------------------------------------------------------------
-- FORMATTING THE CURRENT FILE AND RETURNING TO THE CURSOR POSITION! --
-----------------------------------------------------------------------

vim.api.nvim_create_user_command('FormatFileWithClang', function()
	if 0 == vim.fn.executable('clang-format') then
		vim.notify("ERROR: `clang-format` not found on system! " ..
			   "Please install via your distro's package manager",
			   vim.log.levels.ERROR)
		return
	end

	local view      = vim.fn.winsaveview()
	local lines     = vim.api.nvim_buf_get_lines(0, 0, -1, false)
	local formatted = vim.fn.systemlist(
		'clang-format --assume-filename=file.c --style=file --fallback-style=none 2>&1',
		lines
	)

	if 0 ~= vim.v.shell_error then
		vim.notify(table.concat(formatted, vim.log.levels.ERROR))
		return
	end

	vim.api.nvim_buf_set_lines(0, 0, -1, false, formatted)
	vim.fn.winrestview(view)
end, {})

-- Lines & Numbers --
vim.opt.number	 = true
vim.opt.relativenumber = true
vim.opt.wrap	   = true

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
	signs	= true,
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
