local snip = require 'rosie.keymap.snippets.funcs'
local dir  = snip.get_dir()

snip.bind_create('n', ',dbm', 'debug_macro', '')
snip.bind_create('n', ',hello', 'hello_world', '')
snip.bind_create('n', ',bast', 'basic_types', '')
snip.bind_create('n', ',pgcc', 'pragma_gcc', 'j$i')
snip.bind_create('n', ',pcla', 'pragma_clang', 'j$i')
snip.bind_create('n', ',inc', 'inc_setup_quote', '$hhi')
snip.bind_create('n', ',binc', 'inc_setup_angle', '$hhi')

vim.keymap.set('n', ',hg', function()
        local ok, guard = pcall(vim.fn.input, 'Header Guard Name: ')

        local view = vim.fn.winsaveview()

        if not ok or guard == '' then
                return
        end

        vim.fn.append(0, { '#ifndef ' .. guard, '#define ' .. guard, '' })
        vim.fn.append(vim.fn.line('$'), { '',
                '#endif /* #ifndef ' .. guard .. ' */'
        })

        vim.fn.winrestview(view)
end, { desc = "Generate named header-guard.", noremap = true, silent = true })

local function ifdef_mapper(mode, prefix, do_else)
        return function()
                local first = vim.fn.line('.')
                local last  = first

                if mode == 'x' then
                        first = vim.fn.line('v')

                        if first > last then
                                first, last = last, first
                        end
                end

                local ok, expr = pcall(vim.fn.input, prefix)

                if not ok or expr:match('^%s*$') then
                        return
                end

                local directive = prefix .. expr
                local closing   = {}

                if do_else then
                        closing[#closing + 1] =
                                '#else /* ' .. directive .. ' */'
                end

                closing[#closing + 1] =
                        '#endif /* ' .. directive ..
                        (do_else and ' #else' or '') .. ' */'

                vim.api.nvim_buf_set_lines(0, last, last, false, closing)
                vim.api.nvim_buf_set_lines(0, first - 1, first - 1,
                        false, { directive })
        end
end

local ifdef_maps = {
        -- Pre-existing `#ifdef <X>`/`#ifndef <X>` macros.
        {   ',ifd',  '#ifdef ', false },
        {  ',ifed',  '#ifdef ',  true },
        {  ',ifnd', '#ifndef ', false },
        { ',ifned', '#ifndef ',  true },

        -- Additional `#if <X>`/`#if !<X>`, with respective `#else` stuff! :D
        {   ',ifx',     '#if ', false },
        {  ',ifex',     '#if ',  true },
        {  ',ifnx',    '#if !', false },
        { ',ifnex',    '#if !',  true },
}

for _, map in ipairs(ifdef_maps) do
        for _, mode in ipairs({ 'n', 'x' }) do
                vim.keymap.set(mode, map[1],
                        ifdef_mapper(mode, map[2], map[3]),
                        { silent = true })
        end
end
