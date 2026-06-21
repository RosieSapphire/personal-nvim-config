local snip = require('rosie.keymap.snippets.funcs')
local dir  = snip.get_dir()

snip.bind_create_pragma(',pgcc', 'pragma_gcc')
snip.bind_create_pragma(',pcla', 'pragma_clang')
snip.bind_create(',dbm', 'debug_macro')
snip.bind_create(',hello', 'hello_world')
snip.bind_create(',bast', 'basic_types')

----------------------------------------------------------------------------
-- TODO: Create mapper functions for all these too so they clean as FUCK! --
----------------------------------------------------------------------------

vim.keymap.set('n', ',inc', function()
        local file = vim.fn.expand(dir .. '/inc_setup_quote')
        vim.cmd("read " .. file)
        vim.api.nvim_feedkeys('$hhi', 'n', false)
end, { desc = "Generate #include quotes.", noremap = true, silent = true })

vim.keymap.set('n', ',binc', function()
        local file = vim.fn.expand(dir .. '/inc_setup_angle')
        vim.cmd("read " .. file)
        vim.api.nvim_feedkeys('$hhi', 'n', false)
end, { desc = "Generate #include angles.", noremap = true, silent = true })

vim.keymap.set('n', ',hg', function()
        local ok, guard = pcall(vim.fn.input, 'Header Guard Name: ')
        local view      = vim.fn.winsaveview()

        if not ok or guard == '' then
                return
        end

        vim.fn.append(0, { '#ifndef ' .. guard, '#define ' .. guard, '' })
        vim.fn.append(vim.fn.line('$'), { '',
                '#endif /* #ifndef ' .. guard .. ' */'
        })

        vim.fn.winrestview(view)
end, { desc = "Generate named header-guard.", noremap = true, silent = true })

-- #ifdef & #ifndef with names
local function ifdef_mode_normal(guard, do_else)
        return function()
                local ok, name = pcall(vim.fn.input, guard .. ': ')
                local real_g   = ''

                if not ok or name == '' then
                        return
                end

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
                local ok, name   = pcall(vim.fn.input, guard .. ': ')
                local real_g     = ''

                if not ok or name == '' then
                        return
                end

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

local function ifdef_macro_mapper(mode, input, guard, do_else)
        local func

        if mode == 'n' then
                func = ifdef_mode_normal
        elseif mode == 'x' then
                func = ifdef_mode_visual
        end

        vim.keymap.set(mode, input, func(guard, do_else), { silent = true })
end

ifdef_macro_mapper('n', ',ifd', '#ifdef', false)
ifdef_macro_mapper('n', ',ifed', '#ifdef', true)
ifdef_macro_mapper('n', ',ifnd', '#ifndef', false)
ifdef_macro_mapper('n', ',ifned', '#ifndef', true)

ifdef_macro_mapper('x', ',ifd', '#ifdef', false)
ifdef_macro_mapper('x', ',ifed', '#ifdef', true)
ifdef_macro_mapper('x', ',ifnd', '#ifndef', false)
ifdef_macro_mapper('x', ',ifned', '#ifndef', true)
