local function map_lookup()
        local msg = 'Map mode [n/v/x/s/o/i/c/t/l/*]: '
        vim.api.nvim_echo({ { msg } }, false, {})

        local ok, mode = pcall(
                vim.fn.getcharstr, -1, { cursor = 'msg' }
        )

        vim.cmd('redraw')

        if not ok or mode == vim.keycode('<Esc>')
                or mode == vim.keycode('<C-c>') then
                return
        end

        local modes = {
                n = { 'nmap' },
                v = { 'vmap' },
                x = { 'xmap' },
                s = { 'smap' },
                o = { 'omap' },
                i = { 'imap' },
                c = { 'cmap' },
                t = { 'tmap' },
                l = { 'lmap' },

                ['*'] = { 'map', 'map!', 'tmap', 'lmap' }
        }

        if not modes[mode] then
                vim.notify('Invalid mapping mode!', vim.log.levels.ERROR)
                return
        end

        local ok_input, lhs = pcall(vim.fn.input, 'Mapping: ')

        if not ok_input or lhs == '' then
                return
        end

        if lhs:find('[|\r\n]') then
                vim.notify('Invalid mapping query!', vim.log.levels.ERROR)
                return
        end

        local lines = {}

        for _, cmd in ipairs(modes[mode]) do
                local result = vim.fn.execute(
                        'verbose ' .. cmd .. ' ' .. lhs
                )

                if not result:find('No mapping found', 1, true) then
                        table.insert(lines, '[' .. cmd .. ']')

                        for _, line in ipairs(vim.split(
                                result:gsub('^\n+', ''), '\n',
                                { plain = true, trimempty = true }
                        )) do
                                table.insert(lines, line)
                        end
                end
        end

        if #lines == 0 then
                vim.notify('No matching mappings found.')
                return
        end

        vim.fn.setqflist({}, ' ', {
                title = 'Mappings: ' .. lhs,
                lines = lines,
                efm   = '%m'
        })

        vim.cmd('copen')
end

vim.keymap.set('n', '<leader>mapl', map_lookup, {
        desc = 'List verbose key mappings in quickfix'
})
