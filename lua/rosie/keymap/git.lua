local git = require 'rosie.git'

local function git_keymap(cmd, func)
        vim.keymap.set( 'n', '<leader>g' .. cmd, function()
                func()
        end)
end

git_keymap('aa', git.add_all)
git_keymap('ac', git.add_current)
git_keymap('ap', git.add_patch)
git_keymap('bl', git.blame_line)
git_keymap('da', git.diff)
git_keymap('dc', git.diff_current)
git_keymap('cm', git.commit_prompt)
git_keymap('dC', git.diff_cached)
git_keymap('lc', git.log_current)
git_keymap('la', git.log)
git_keymap('st', git.status)
git_keymap('sh', git.show)
git_keymap('up', git.unstage_patch)
git_keymap('t',  git.tracked)
git_keymap('ut', git.untracked)
git_keymap('us', git.unstage_current)
