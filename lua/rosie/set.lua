-- Better path searching --
vim.opt.path:append("**")
vim.opt.wildmenu = true

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
		on_exit = function(_, code)
			if 0 ~= code then
				vim.notify("ERROR: Failed to generate CTags!",
					   vim.log.levels.ERROR)
			end
		end
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
