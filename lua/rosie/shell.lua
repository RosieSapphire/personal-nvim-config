local fish_shell_bin = vim.fn.exepath('fish')

if fish_shell_bin ~= '' then
        vim.opt.shell = fish_shell_bin
        vim.opt.shellcmdflag = '-c'
else
        vim.notify('\n\nERROR: Fish terminal required, fuck you. `sudo apt install fish` if you\'re on a Debian-based distro. NO BASH ALLOWED!\n', vim.log.levels.ERROR)
        return
end
