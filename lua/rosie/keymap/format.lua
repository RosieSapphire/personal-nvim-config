local M = {}

local format_filetypes = {
        c = true,
        cpp = true,
        objc = true,
        objcpp = true,
        cuda = true,
}

local function format_filename(buf)
        local name = vim.api.nvim_buf_get_name(buf)
        if name ~= '' then
                return name
        end

        -- For an unnamed C buffer, locate .clang-format relative to :pwd.
        local ext = vim.bo[buf].filetype == 'c' and '.c' or '.cpp'
        return vim.fn.getcwd() .. '/__nvim_unsaved' .. ext
end

local function split_output(text)
        -- Neovim stores lines without newline terminators.  Remove *only*
        -- the final terminator; keep intentional blank lines and whitespace.
        if text:sub(-1) == '\n' then
                text = text:sub(1, -2)
        end
        return vim.split(text, '\n', { plain = true })
end

local function replace_changed_lines(buf, old, new)
        local first = 0
        while first < #old and first < #new and old[first + 1] == new[first + 1] do
                first = first + 1
        end
        if first == #old and first == #new then
                return false
        end

        local last = 0
        while last < #old - first and last < #new - first
                and old[#old - last] == new[#new - last] do
                last = last + 1
        end

        local replacement = {}
        for i = first + 1, #new - last do
                replacement[#replacement + 1] = new[i]
        end

        vim.api.nvim_buf_set_lines(buf, first, #old - last, false, replacement)
        return true
end

-- Return false on any failure.  In particular, <leader>fw must never save
-- a buffer when formatting failed or timed out.
function M.format_current_buffer()
        local buf = vim.api.nvim_get_current_buf()
        if vim.bo[buf].buftype ~= '' or not vim.bo[buf].modifiable then
                vim.notify('This buffer is not an editable file.', vim.log.levels.WARN)
                return false
        end
        if not format_filetypes[vim.bo[buf].filetype] then
                vim.notify('clang-format is only enabled for C-family buffers.', vim.log.levels.WARN)
                return false
        end
        if vim.fn.executable('clang-format') == 0 then
                vim.notify('clang-format executable not found.', vim.log.levels.ERROR)
                return false
        end

        local old = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
        local input = table.concat(old, '\n')
        if vim.bo[buf].endofline then
                input = input .. '\n'
        end

        -- argv is passed directly, without invoking Fish/Bash or requiring
        -- quoting of filenames containing spaces, quotes, etc.
        local cmd = {
                'clang-format',
                '--assume-filename=' .. format_filename(buf),
                '--style=file',
                '--fallback-style=none',
        }
        local started, proc = pcall(vim.system, cmd, { stdin = input, text = true })
        if not started then
                vim.notify('Unable to start clang-format: ' .. tostring(proc), vim.log.levels.ERROR)
                return false
        end

        local result = proc:wait(15000)
        if result.code ~= 0 then
                local problem = result.code == 124 and 'clang-format timed out'
                        or ('clang-format failed (exit ' .. result.code .. ')')
                local details = (result.stderr or ''):gsub('%s+$', '')
                if details ~= '' then
                        problem = problem .. ':\n' .. details
                end
                vim.notify(problem, vim.log.levels.ERROR)
                return false
        end

        local new = split_output(result.stdout or '')
        local win = vim.api.nvim_get_current_win()
        local view = vim.fn.winsaveview()
        local changed = replace_changed_lines(buf, old, new)
        if changed and vim.api.nvim_win_is_valid(win)
                and vim.api.nvim_win_get_buf(win) == buf then
                pcall(vim.fn.winrestview, view)
        end

        if not changed then
                vim.notify('No changes after clang-format.', vim.log.levels.INFO)
        end
        return true
end

function M.format_and_write_current_buffer()
        if not M.format_current_buffer() then
                return false
        end
        if vim.bo.modified then
                local ok, err = pcall(vim.cmd, 'write')
                if not ok then
                        vim.notify('Unable to save buffer: ' .. tostring(err), vim.log.levels.ERROR)
                        return false
                end
        end
        return true
end

vim.keymap.set('n', '<leader>fr', M.format_current_buffer, {
        desc = 'Format C-family buffer with clang-format',
})
vim.keymap.set('n', '<leader>fw', M.format_and_write_current_buffer, {
        desc = 'Format C-family buffer, then save on success',
})

-- These deliberate text wrappers are not replaced by native comment toggles:
-- they also provide parenthesization with your existing keybindings.
local function encase_current_line(left, right)
        local line = vim.api.nvim_get_current_line()
        local indent = line:match('^%s*') or ''
        local content = line:sub(#indent + 1)
        vim.api.nvim_set_current_line(indent .. left .. content .. right)
end

local function escape_lua_pattern(str)
        return str:gsub('([^%w])', '%%%1')
end

local function unencase_current_line(left, right)
        local line = vim.api.nvim_get_current_line()
        local pattern = '^(%s*)' .. escape_lua_pattern(left)
                .. '(.-)' .. escape_lua_pattern(right) .. '%s*$'
        local updated = line:gsub(pattern, '%1%2')
        if updated ~= line then
                vim.api.nvim_set_current_line(updated)
        end
end

vim.keymap.set('n', ',ec', function() encase_current_line('/* ', ' */') end)
vim.keymap.set('n', ',ep', function() encase_current_line('(', ')') end)
vim.keymap.set('n', ',uc', function() unencase_current_line('/* ', ' */') end)
vim.keymap.set('n', ',up', function() unencase_current_line('(', ')') end)

return M
