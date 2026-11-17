local function copy_markdown_html()
        local clipboard

        if vim.env.WAYLAND_DISPLAY
                and vim.fn.executable("wl-copy") == 1 then
                clipboard = {
                        "wl-copy", "--type", "text/html"
                }
        elseif vim.fn.executable("xclip") == 1 then
                clipboard = {
                        "xclip", "-selection", "clipboard",
                        "-t", "text/html"
                }
        else
                vim.notify(
                        "No HTML clipboard utility found",
                        vim.log.levels.ERROR
                )
                return
        end

        if vim.fn.executable("pandoc") ~= 1 then
                vim.notify(
                        "Pandoc not found",
                        vim.log.levels.ERROR
                )
                return
        end

        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local markdown = table.concat(lines, "\n") .. "\n"

        local html = vim.system({
                "pandoc", "-f", "gfm", "-t", "html",
                "--no-highlight"
        }, {
                stdin = markdown,
                text = true
        }):wait()

        if html.code ~= 0 then
                vim.notify(
                        html.stderr or "Pandoc failed",
                        vim.log.levels.ERROR
                )
                return
        end

        local result = vim.system(
                clipboard,
                { stdin = html.stdout, stdout = false, stderr = false }
        ):wait()

        if result.code ~= 0 then
                vim.notify(
                        "Clipboard operation failed",
                        vim.log.levels.ERROR
                )
                return
        end

        vim.notify("Markdown copied as HTML")
end

vim.keymap.set("n", "<leader>mcp", copy_markdown_html, {
        desc = "Yank Markdown as formatted HTML"
})
