-- lua/user/git.lua

local M = {}

local uv = vim.uv or vim.loop

local function start_dir()
        local name = vim.api.nvim_buf_get_name(0)

        if name ~= '' then
                return vim.fn.fnamemodify(name, ':p:h')
        end

        return uv.cwd()
end

local function lines(str)
        if not str or str == '' then
                return {}
        end

        str = str:gsub('\r\n', '\n')

        return vim.split(str, '\n', { trimempty = true })
end

local function repo_root()
        local out = vim.system(
                { 'git', 'rev-parse', '--show-toplevel' },
                { text = true, cwd = start_dir() }
        ):wait()

        if out.code ~= 0 then
                vim.notify(vim.trim(out.stderr), vim.log.levels.ERROR)
                return nil
        end

        return vim.trim(out.stdout)
end

local function git(args, cb)
        local root = repo_root()

        if not root then
                return
        end

        local cmd = { 'git' }

        vim.list_extend(cmd, args)

        vim.system(cmd, { text = true, cwd = root }, function(out)
                vim.schedule(function()
                        if cb then
                                cb(out, root)
                                return
                        end

                        if out.code ~= 0 then
                                vim.notify(vim.trim(out.stderr), vim.log.levels.ERROR)
                        elseif out.stdout ~= '' then
                                vim.notify(vim.trim(out.stdout))
                        end
                end)
        end)
end

local function qf(title, items)
        vim.fn.setqflist({}, 'r', {
                title = title,
                items = items,
        })

        vim.cmd('copen')
end

local function scratch(title, filetype, text)
        local out_lines = lines(text)

        if #out_lines == 0 then
                out_lines = { '(no output)' }
        end

        vim.cmd('botright new')

        local buf = vim.api.nvim_get_current_buf()

        vim.api.nvim_buf_set_name(buf, title)
        vim.bo[buf].buftype = 'nofile'
        vim.bo[buf].bufhidden = 'wipe'
        vim.bo[buf].swapfile = false
        vim.bo[buf].filetype = filetype or ''
        vim.bo[buf].modifiable = true

        vim.api.nvim_buf_set_lines(buf, 0, -1, false, out_lines)

        vim.bo[buf].modifiable = false

        vim.keymap.set('n', 'q', '<cmd>bd!<cr>', {
                buffer = buf,
                silent = true,
                desc = 'Close git buffer',
        })

        return buf
end

local function current_file()
        local name = vim.api.nvim_buf_get_name(0)

        if name == '' then
                vim.notify('No current file', vim.log.levels.WARN)
                return nil
        end

        return vim.fn.fnamemodify(name, ':p')
end

local function status_char_name(c)
        local names = {
                ['M'] = 'modified',
                ['A'] = 'added',
                ['D'] = 'deleted',
                ['R'] = 'renamed',
                ['C'] = 'copied',
                ['U'] = 'unmerged',
                ['?'] = 'untracked',
                ['!'] = 'ignored',
        }

        return names[c] or c
end

local function status_label(xy)
        local x = xy:sub(1, 1)
        local y = xy:sub(2, 2)

        if xy == '??' then
                return 'untracked'
        end

        if xy == '!!' then
                return 'ignored'
        end

        local parts = {}

        if x ~= ' ' then
                table.insert(parts, 'staged: ' .. status_char_name(x))
        end

        if y ~= ' ' then
                table.insert(parts, 'unstaged: ' .. status_char_name(y))
        end

        if #parts == 0 then
                return 'clean'
        end

        return table.concat(parts, ', ')
end

local function status_items(stdout, root)
        local raw     = stdout:gsub('%z$', '')
        local records = vim.split(raw, '\0', { plain = true, trimempty = true })

        local branch    = {}
        local staged    = {}
        local unstaged  = {}
        local untracked = {}
        local conflicted = {}

        local i = 1

        while i <= #records do
                local rec = records[i]

                if rec:sub(1, 2) == '##' then
                        table.insert(branch, {
                                text = rec,
                                valid = 0,
                        })
                else
                        local xy       = rec:sub(1, 2)
                        local x        = xy:sub(1, 1)
                        local y        = xy:sub(2, 2)
                        local path     = rec:sub(4)
                        local filename = path
                        local label    = status_label(xy)
                        local text     = string.format('%-28s %s', '[' .. label .. ']', path)

                        if xy:find('[RC]') then
                                local old = records[i + 1]

                                if old then
                                        text = string.format(
                                                '%-28s %s -> %s',
                                                '[' .. label .. ']',
                                                old,
                                                path
                                        )

                                        i = i + 1
                                end
                        end

                        local deleted = xy:find('D') ~= nil

                        local item = {
                                filename = root .. '/' .. filename,
                                lnum = 1,
                                col = 1,
                                text = text,
                                type = xy:find('U') and 'E' or 'I',
                                valid = deleted and 0 or 1,
                                user_data = {
                                        path = filename,
                                        status = xy,
                                },
                        }

                        if xy == '??' then
                                table.insert(untracked, item)
                        elseif xy:find('U') then
                                table.insert(conflicted, item)
                        elseif x ~= ' ' and y ~= ' ' then
                                table.insert(staged, item)
                                table.insert(unstaged, vim.tbl_extend('force', item, {
                                        text = string.format('%-28s %s', '[also unstaged: ' .. status_char_name(y) .. ']', path),
                                }))
                        elseif x ~= ' ' then
                                table.insert(staged, item)
                        elseif y ~= ' ' then
                                table.insert(unstaged, item)
                        end
                end

                i = i + 1
        end

        local items = {}

        vim.list_extend(items, branch)

        if #conflicted > 0 then
                table.insert(items, { text = '--- conflicted ---', valid = 0 })
                vim.list_extend(items, conflicted)
        end

        if #staged > 0 then
                table.insert(items, { text = '--- staged ---', valid = 0 })
                vim.list_extend(items, staged)
        end

        if #unstaged > 0 then
                table.insert(items, { text = '--- unstaged ---', valid = 0 })
                vim.list_extend(items, unstaged)
        end

        if #untracked > 0 then
                table.insert(items, { text = '--- untracked ---', valid = 0 })
                vim.list_extend(items, untracked)
        end

        return items
end

function M.status()
        git({ 'status', '--porcelain=v1', '-z', '-b' }, function(out, root)
                if out.code ~= 0 then
                        vim.notify(vim.trim(out.stderr), vim.log.levels.ERROR)
                        return
                end

                local items = status_items(out.stdout, root)

                if #items == 0 then
                        vim.notify('Git status clean')
                        return
                end

                qf('git status', items)
        end)
end

function M.tracked()
        git({ 'ls-files' }, function(out, root)
                if out.code ~= 0 then
                        vim.notify(vim.trim(out.stderr), vim.log.levels.ERROR)
                        return
                end

                local items = {}

                for _, path in ipairs(lines(out.stdout)) do
                        table.insert(items, {
                                filename = root .. '/' .. path,
                                lnum = 1,
                                col = 1,
                                text = path,
                        })
                end

                qf('git tracked files', items)
        end)
end

function M.untracked()
        git({ 'ls-files', '--others', '--exclude-standard' }, function(out, root)
                if out.code ~= 0 then
                        vim.notify(vim.trim(out.stderr), vim.log.levels.ERROR)
                        return
                end

                local items = {}

                for _, path in ipairs(lines(out.stdout)) do
                        table.insert(items, {
                                filename = root .. '/' .. path,
                                lnum = 1,
                                col = 1,
                                text = '?? ' .. path,
                        })
                end

                if #items == 0 then
                        vim.notify('No untracked files')
                        return
                end

                qf('git untracked files', items)
        end)
end

function M.add_all()
        git({ 'add', '-A' }, function(out)
                if out.code ~= 0 then
                        vim.notify(vim.trim(out.stderr), vim.log.levels.ERROR)
                        return
                end

                vim.notify('Git: staged all changes')
                M.status()
        end)
end

function M.add_current()
        local file = current_file()

        if not file then
                return
        end

        git({ 'add', '--', file }, function(out)
                if out.code ~= 0 then
                        vim.notify(vim.trim(out.stderr), vim.log.levels.ERROR)
                        return
                end

                vim.notify('Git: staged current file')
                M.status()
        end)
end

function M.add_prompt()
        vim.ui.input({
                prompt = 'Git add: ',
                completion = 'file',
                default = vim.fn.expand('%'),
        }, function(path)
                if not path or path == '' then
                        return
                end

                git({ 'add', '--', path }, function(out)
                        if out.code ~= 0 then
                                vim.notify(vim.trim(out.stderr), vim.log.levels.ERROR)
                                return
                        end

                        vim.notify('Git: staged ' .. path)
                        M.status()
                end)
        end)
end

function M.unstage_current()
        local file = current_file()

        if not file then
                return
        end

        git({ 'restore', '--staged', '--', file }, function(out)
                if out.code ~= 0 then
                        vim.notify(vim.trim(out.stderr), vim.log.levels.ERROR)
                        return
                end

                vim.notify('Git: unstaged current file')
                M.status()
        end)
end

function M.diff()
        git({ 'diff' }, function(out)
                if out.code ~= 0 then
                        vim.notify(vim.trim(out.stderr), vim.log.levels.ERROR)
                        return
                end

                scratch('git diff', 'diff', out.stdout)
        end)
end

function M.diff_cached()
        git({ 'diff', '--cached' }, function(out)
                if out.code ~= 0 then
                        vim.notify(vim.trim(out.stderr), vim.log.levels.ERROR)
                        return
                end

                scratch('git diff --cached', 'diff', out.stdout)
        end)
end

function M.diff_current()
        local file = current_file()

        if not file then
                return
        end

        git({ 'diff', '--', file }, function(out)
                if out.code ~= 0 then
                        vim.notify(vim.trim(out.stderr), vim.log.levels.ERROR)
                        return
                end

                scratch('git diff current file', 'diff', out.stdout)
        end)
end

function M.log()
        git({
                'log',
                '--oneline',
                '--decorate',
                '--graph',
                '--all',
                '-n',
                '100',
        }, function(out)
                if out.code ~= 0 then
                        vim.notify(vim.trim(out.stderr), vim.log.levels.ERROR)
                        return
                end

                local buf = scratch('git log', 'git', out.stdout)

                vim.keymap.set('n', '<cr>', function()
                        local line = vim.api.nvim_get_current_line()
                        local hash = line:match('%x%x%x%x%x%x+')

                        if hash then
                                M.show(hash)
                        end
                end, {
                        buffer = buf,
                        silent = true,
                        desc = 'Git show commit',
                })
        end)
end

function M.log_current()
        local file = current_file()

        if not file then
                return
        end

        git({
                'log',
                '--oneline',
                '--decorate',
                '--follow',
                '--',
                file,
        }, function(out)
                if out.code ~= 0 then
                        vim.notify(vim.trim(out.stderr), vim.log.levels.ERROR)
                        return
                end

                scratch('git log current file', 'git', out.stdout)
        end)
end

function M.show(rev)
        if not rev or rev == '' then
                vim.ui.input({ prompt = 'Git show: ' }, function(input)
                        if input and input ~= '' then
                                M.show(input)
                        end
                end)

                return
        end

        git({ 'show', '--stat', '--patch', rev }, function(out)
                if out.code ~= 0 then
                        vim.notify(vim.trim(out.stderr), vim.log.levels.ERROR)
                        return
                end

                scratch('git show ' .. rev, 'diff', out.stdout)
        end)
end

function M.blame_line()
        local file = current_file()

        if not file then
                return
        end

        local line = tostring(vim.fn.line('.'))

        git({ 'blame', '-L', line .. ',' .. line, '--', file }, function(out)
                if out.code ~= 0 then
                        vim.notify(vim.trim(out.stderr), vim.log.levels.ERROR)
                        return
                end

                scratch('git blame line', 'git', out.stdout)
        end)
end

function M.commit_prompt()
        vim.ui.input({ prompt = 'Commit message: ' }, function(msg)
                if not msg or msg == '' then
                        return
                end

                git({ 'commit', '-m', msg }, function(out)
                        local text = out.stdout .. out.stderr

                        if out.code ~= 0 then
                                scratch('git commit failed', 'git', text)
                                return
                        end

                        scratch('git commit', 'git', text)
                end)
        end)
end

local function git_tui(args, title)
        local root = repo_root()

        if not root then
                return
        end

        local width  = math.max(40, math.floor(vim.o.columns * 0.85))
        local height = math.max(10, math.floor(vim.o.lines   * 0.80))
        local row    = math.floor((vim.o.lines   - height) / 2)
        local col    = math.floor((vim.o.columns - width)  / 2)

        local buf = vim.api.nvim_create_buf(false, true)

        local win = vim.api.nvim_open_win(buf, true, {
                relative = 'editor',
                style    = 'minimal',
                border   = 'rounded',
                title    = ' ' .. title .. ' ',
                title_pos = 'center',

                width  = width,
                height = height,
                row    = row,
                col    = col,
        })

        vim.bo[buf].bufhidden = 'wipe'
        vim.bo[buf].swapfile  = false

        local job = vim.fn.jobstart(args, {
                cwd  = root,
                term = true,

                on_exit = function(_, code)
                        vim.schedule(function()
                                if code ~= 0 then
                                        vim.notify(
                                                title .. ' exited with status ' .. code,
                                                vim.log.levels.ERROR
                                        )
                                        return
                                end

                                if vim.api.nvim_win_is_valid(win) then
                                        vim.api.nvim_win_close(win, true)
                                end

                                M.status()
                        end)
                end,
        })

        if job <= 0 then
                if vim.api.nvim_win_is_valid(win) then
                        vim.api.nvim_win_close(win, true)
                end

                vim.notify(
                        'Unable to start ' .. title,
                        vim.log.levels.ERROR
                )

                return
        end

        vim.cmd.startinsert()
end

function M.add_patch()
        git_tui({ 'git', 'add', '-p' }, 'git add -p')
end

function M.unstage_patch()
        git_tui({ 'git', 'reset', '-p' }, 'git reset -p')
end

return M
