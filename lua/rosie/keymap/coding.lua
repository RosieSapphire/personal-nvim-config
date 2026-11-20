local tags_job = nil

local function add_project_buffers_of_type(exts)
        local patterns = {}

        if 0 == vim.fn.executable('fdfind') then
                vim.notify("ERROR: `fdfind` not found on system! " ..
                           "Please install via your distro's package manager (apt: fd-find)",
                           vim.log.levels.ERROR)
                return
        end

        for _, ext in ipairs(exts) do
                table.insert(patterns, string.format('-e %s', ext))
        end

        local cmd = 'fdfind -t f ' .. table.concat(patterns, ' ')

        local files = vim.fn.systemlist(cmd)

        for _, file in ipairs(files) do
                vim.cmd('badd ' .. vim.fn.fnameescape(file))
        end

        print('Opened ' .. #files .. ' files into buffers!')
end

local function encase_visual_select(left, right)
        local pos_a = vim.fn.getpos("'<")
        local pos_b = vim.fn.getpos("'>")

        if pos_a[2] ~= pos_b[2] then
                return
        end

        local row = pos_a[2]

        local col_a = pos_a[3]
        local col_b = pos_b[3]

        if col_a > col_b then
                col_a, col_b = col_b, col_a
        end

        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]

        local before   = line:sub(1, col_a - 1)
        local selected = line:sub(col_a, col_b)
        local after    = line:sub(col_b + 1)

        local updated = before .. left .. selected .. right .. after

        vim.api.nvim_buf_set_lines(0, row - 1, row, false, { updated })
end

local function unencase_visual_select(left, right)
        local pos_a = vim.fn.getpos("'<")
        local pos_b = vim.fn.getpos("'>")

        if pos_a[2] ~= pos_b[2] then
                return
        end

        local row = pos_a[2]

        local col_a = pos_a[3]
        local col_b = pos_b[3]

        if col_a > col_b then
                col_a, col_b = col_b, col_a
        end

        local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]

        local len_left  = #left
        local len_right = #right

        local real_left  = line:sub(col_a - len_left, col_a - 1)
        local real_right = line:sub(col_b + 1, col_b + len_right)

        -- Verify wrappers actually exist
        if real_left ~= left or real_right ~= right then
                return
        end

        local before = line:sub(1, col_a - len_left - 1)
        local middle = line:sub(col_a, col_b)
        local after  = line:sub(col_b + len_right + 1)

        local updated = before .. middle .. after

        vim.api.nvim_buf_set_lines(0, row - 1, row, false, { updated })
end

local function todo_search(path)
        local cmd =
                "silent grep! -i -w -g '!.git/' -e TODO -e FIXME -- " .. path;
        local ok, err = pcall(vim.cmd, cmd);

        if not ok and not tostring(err):find("E480:", 1, true) then
                vim.notify(tostring(err), vim.log.levels.ERROR);
                return;
        end

        if #vim.fn.getqflist() == 0 then
                vim.cmd.cclose();
                vim.notify(
                        "No TODO/FIXME matches found",
                        vim.log.levels.INFO
                );
                return;
        end

        vim.cmd.copen();
end

local function is_function_declarator(node)
        while node do
                if node:type() == 'function_declarator' then
                        local name = node:field('declarator')[1]

                        while name and name:type() == 'pointer_declarator' do
                                name = name:field('declarator')[1]
                        end

                        return name ~= nil and name:type() == 'identifier'
                end

                node = node:field('declarator')[1]
        end

        return false
end

local function find_bare_signature()
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local cursor = vim.api.nvim_win_get_cursor(0)[1] - 1

        for sr = cursor, math.max(0, cursor - 63), -1 do
                local line = lines[sr + 1]
                local open = line:find('(', 1, true)

                if open then
                        local head = line:sub(1, open - 1)

                        local valid = head:match('^%s*[%w_%s%*]+$')
                                and head:match('%s+%**[%a_][%w_]*%s*$')
                                and not head:match('^%s*return%s+')

                        if valid then
                                local chunk = table.concat(
                                        vim.api.nvim_buf_get_lines(
                                                0,
                                                sr,
                                                math.min(#lines, sr + 64),
                                                false
                                        ),
                                        '\n'
                                )

                                local a, b = chunk:find('%b()', open)

                                if a == open then
                                        local before = chunk:sub(1, b)
                                        local newlines = select(2, before:gsub('\n', ''))
                                        local er = sr + newlines
                                        local ec = #(before:match('[^\n]*$') or '')
                                        local tail = lines[er + 1]:sub(ec + 1)

                                        if cursor <= er and tail:match('^%s*$') then
                                                -- Don't misidentify a body on the next line.
                                                local next_line

                                                for i = er + 2, #lines do
                                                        if lines[i]:match('%S') then
                                                                next_line = lines[i]
                                                                break
                                                        end
                                                end

                                                if not next_line
                                                        or not next_line:match('^%s*[{;]') then
                                                        return {
                                                                kind = 'bare',
                                                                range = {
                                                                        sr,
                                                                        (line:find('%S') or 1) - 1,
                                                                        er,
                                                                        ec,
                                                                },
                                                        }
                                                end
                                        end
                                end
                        end
                end
        end

        return nil, 'No C function signature under cursor'
end

local function find_function_signature()
        local ok, parser = pcall(vim.treesitter.get_parser, 0, 'c')

        if ok then
                parser:parse()

                local cursor = vim.api.nvim_win_get_cursor(0)
                local row = cursor[1] - 1
                local col = cursor[2]
                local node = vim.treesitter.get_node({ bufnr = 0, lang = 'c' })

                while node do
                        local kind = node:type()

                        if kind == 'function_definition' or kind == 'declaration' then
                                local declarators = node:field('declarator')

                                if #declarators == 1
                                        and is_function_declarator(declarators[1]) then
                                        if kind == 'declaration' then
                                                local text = vim.treesitter.get_node_text(node, 0)

                                                if not node:has_error() and text:match(';%s*$') then
                                                        return {
                                                                kind = kind,
                                                                node = node,
                                                                range = { node:range() },
                                                        }
                                                end
                                        else
                                                local body = node:field('body')[1]

                                                if body and not body:missing() then
                                                        local br, bc = body:start()

                                                        if row < br or (row == br and col < bc) then
                                                                return {
                                                                        kind = kind,
                                                                        node = node,
                                                                        range = { node:range() },
                                                                }
                                                        end
                                                end
                                        end
                                end
                        end

                        node = node:parent()
                end
        end

        return find_bare_signature()
end

local function has_following_body(er, ec)
        local lines = vim.api.nvim_buf_get_lines(0, er, -1, false)

        if #lines == 0 then
                return false
        end

        -- `ec` is zero-based; Lua string indices are one-based.
        local tail = lines[1]:sub(ec + 1)

        if tail:match('^%s*{') then
                return true
        end

        if tail:match('%S') then
                return false
        end

        for i = 2, #lines do
                if lines[i]:match('%S') then
                        return lines[i]:match('^%s*{') ~= nil
                end
        end

        return false
end

local function convert_signature(to_proto)
        local found, err = find_function_signature()

        if not found then
                vim.notify(err, vim.log.levels.WARN)
                return
        end

        local kind = found.kind
        local node = found.node
        local sr, sc, er, ec = unpack(found.range)

        if node then
                local check_node = node

                if kind == 'function_definition' then
                        check_node = node:field('declarator')[1]
                end

                if check_node and check_node:has_error() then
                        vim.notify('C signature parse errors; refusing conversion',
                                   vim.log.levels.ERROR)
                        return
                end
        end

        local signature

        if kind == 'function_definition' then
                local body = node:field('body')[1]
                local br, bc = body:start()

                signature = table.concat(
                        vim.api.nvim_buf_get_text(0, sr, sc, br, bc, {}),
                        '\n'
                )
        else
                signature = table.concat(
                        vim.api.nvim_buf_get_text(0, sr, sc, er, ec, {}),
                        '\n'
                )

                if kind == 'declaration' then
                        signature = signature:gsub(';%s*$', '')
                end
        end

        signature = signature:gsub('%s+$', '')

        local lines = vim.split(signature, '\n', { plain = true })
        local has_extern = lines[1]:match('^extern%s+') ~= nil

        if to_proto then
                if not has_extern then
                        if lines[1]:match('^static%s+') then
                                vim.notify('Cannot export a static function',
                                           vim.log.levels.WARN)
                                return
                        end

                        lines[1] = 'extern ' .. lines[1]

                        for i = 2, #lines do
                                lines[i] = '       ' .. lines[i]
                        end
                end

                lines[#lines] = lines[#lines] .. ';'
        else
                if kind == 'function_definition' then
                        vim.notify('Already a function definition')
                        return
                end

                local body_exists =
                        kind == 'declaration'
                        and has_following_body(er, ec)

                if has_extern then
                        for i = 2, #lines do
                                if not lines[i]:match('^       ') then
                                        vim.notify('Unexpected continuation indentation',
                                                   vim.log.levels.WARN)
                                        return
                                end
                        end

                        lines[1] = lines[1]:gsub('^extern%s+', '', 1)

                        for i = 2, #lines do
                                lines[i] = lines[i]:sub(8)
                        end
                end

                if not body_exists then
                        local first_line = vim.api.nvim_buf_get_lines(
                                0, sr, sr + 1, false
                        )[1]

                        local indent = first_line:sub(1, sc)

                        lines[#lines + 1] = indent .. '{'
                        lines[#lines + 1] = indent .. '}'
                end
        end

        vim.api.nvim_buf_set_text(0, sr, sc, er, ec, lines)
end

local function flip_header_source()
        local current = vim.api.nvim_buf_get_name(0)
        local ext = current:match('%.([ch])$')

        if not ext then
                vim.notify('Current buffer is not a .c or .h file', vim.log.levels.WARN)
                return
        end

        local new_ext = ext == 'c' and 'h' or 'c'
        local target = current:gsub('%.[ch]$', '.' .. new_ext)

        local function open(path)
                vim.cmd.edit(vim.fn.fnameescape(path))
        end

        -- Fast path: corresponding file in the same directory.
        if vim.fn.filereadable(target) == 1 then
                open(target)
                return
        end

        -- Fallback: search recursively from the current working directory.
        local root = vim.fn.getcwd()

        if not vim.fs.relpath(root, current) then
                vim.notify('Current file is outside the working directory', vim.log.levels.WARN)
                return
        end

        local filename = vim.fs.basename(target)

        local result = vim.system({
                'rg', '--files',
                '-g', filename,
                '-g', '!**/data/**',
                '-g', '!**/build/**',
                '-g', '!**/.git/**',
        }, {
                cwd = root,
                text = true,
        }):wait()

        if result.code ~= 0 and result.code ~= 1 then
                vim.notify(result.stderr or 'File search failed', vim.log.levels.ERROR)
                return
        end

        local matches = vim.split(result.stdout or '', '\n', { trimempty = true })

        if #matches == 0 then
                vim.notify('Could not find ' .. filename, vim.log.levels.WARN)
                return
        end

        if #matches == 1 then
                open(vim.fs.joinpath(root, matches[1]))
                return
        end

        -- Multiple matches: let the user choose.
        vim.ui.select(matches, {
                prompt = 'Choose ' .. filename .. ':',
        }, function(choice)
                if choice then
                        open(vim.fs.joinpath(root, choice))
                end
        end)
end

vim.api.nvim_create_user_command('TagsMake', function()
        if 0 == vim.fn.executable('ctags-universal') then
                vim.notify("ERROR: `ctags-universal` is not an " ..
                           "executable on this system. Please install " ..
                           "it via your distro's package manager!",
                           vim.log.levels.ERROR);
                return;
        end

        if nil ~= tags_job then
                vim.notify(
                        "CTags generation is already running! " ..
                        "Wait, you fucking impatient invalid!",
                        vim.log.levels.WARN
                )
                return
        end

        local cwd = vim.fn.getcwd();

        tags_job = vim.fn.jobstart({'ctags-universal', '-R', '.'}, {
                cwd     = cwd,
                on_exit = function(_, code)
                        tags_job = nil;

                        if 0 ~= code then
                                vim.notify("ERROR: Failed to generate CTags!",
                                           vim.log.levels.ERROR)
                                return;
                        end

                        vim.notify("CTags generated successfully in: " .. cwd,
                                   vim.log.levels.INFO)
                end,
        })

        if tags_job <= 0 then
                tags_job = nil;
                vim.notify("ERROR: Failed to start CTags!",
                           vim.log.levels.ERROR)
        end
end, {})

vim.api.nvim_set_keymap("n", "K", "<cmd>lua vim.lsp.buf.hover()<CR>", {
        noremap = true, silent = true
})

vim.keymap.set('n', '<leader>hs', flip_header_source, {
        desc = 'Switch between C source and header',
})

vim.keymap.set('n', '<leader>rn', vim.lsp.buf.rename, {
        desc = 'Rename symbol with LSP',
})

vim.keymap.set('n', '<leader>cmk', function()
        vim.cmd('set makeprg?')
end, { desc = "Print the currently set 'makeprg' command.", silent = true })

vim.keymap.set('n', '<leader>smk', function()
        local ok, mkprg = pcall(
                vim.fn.input,
                'Make Command Input: ',
                '',
                'file'
        )

        if not ok or mkprg == '' then
                return
        end

        vim.opt.makeprg = mkprg;
end, { desc = "Set new 'makeprg' command via prompt.", silent = true })

vim.keymap.set('n', '<leader>mk', function()
        vim.cmd('wa') -- Make sure to save all open files before running!
        vim.cmd('make')
end, { desc = "Run the 'makeprg' cmd (save all first).", silent = true })

vim.keymap.set('n', '<leader>oahcf', function()
        add_project_buffers_of_type({ 'c', 'h' })
end, { desc = "Opens all *.h & *.c files in pwd.", silent = false  })

vim.keymap.set('n', '<leader>oahf', function()
        add_project_buffers_of_type({ 'h' })
end, { desc = "Opens all *.h files in pwd.", silent = false  })

vim.keymap.set('n', '<leader>oacf', function()
        add_project_buffers_of_type({ 'c' })
end, { desc = "Opens all *.c files in pwd.", silent = false  })

---------------------------------------------------------------
-- TODO: These should probably have their own wrappers, too. --
---------------------------------------------------------------

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
end, { desc = "Add /* */ (visual).", noremap = true, silent = true })

vim.keymap.set('x', ',ep', function()
        vim.api.nvim_input('<Esc>')

        vim.schedule(function()
                encase_visual_select('(', ')')
        end)
end, { desc = "Add ( ) (visual).", noremap = true, silent = true })

vim.keymap.set('x', ',uc', function()
        vim.api.nvim_input('<Esc>')

        vim.schedule(function()
                unencase_visual_select('/* ', ' */')
        end)
end, { desc = "Remove /* */ (visual).", noremap = true, silent = true })

vim.keymap.set('x', ',up', function()
        vim.api.nvim_input('<Esc>')

        vim.schedule(function()
                unencase_visual_select('(', ')')
        end)
end, { desc = "Remove ( ) (visual).", noremap = true, silent = true })

vim.keymap.set('n', '<leader>todoc', function()
        if vim.api.nvim_buf_get_name(0) == "" then
                vim.notify(
                        "Current buffer has no filename",
                        vim.log.levels.WARN
                );
                return;
        end

        todo_search("%");
end, { desc = "Show TODO/FIXME for current file", silent = true })

vim.keymap.set('n', '<leader>todoa', function()
        todo_search(".");
end, { desc = "Show TODO/FIXME for working directory", silent = true })

vim.keymap.set('n', '<leader>top', function()
        convert_signature(true)
end, { desc = 'Convert function signature to prototype' })

vim.keymap.set('n', '<leader>toi', function()
        convert_signature(false)
end, { desc = 'Convert prototype to implementation signature' })
