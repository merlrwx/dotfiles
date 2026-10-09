-- ~~~~~~~~~~~~~~~ LazyVim behavior ~~~~~~~~~~~~~~~~~~~~~~~~

vim.g.snacks_animate = false
vim.g.lazyvim_check_order = false
vim.g.lazyvim_picker = "fzf"
-- Future option: use "auto" here to let LazyVim choose an installed picker.

-- ~~~~~~~~~~~~~~~ Display ~~~~~~~~~~~~~~~~~~~~~~~~

vim.opt.ignorecase = true
vim.opt.number = false
vim.opt.relativenumber = false
vim.opt.scrolloff = 8
-- Future option: set number and relativenumber to true if line numbers help.

-- ~~~~~~~~~~~~~~~ Clipboard ~~~~~~~~~~~~~~~~~~~~~~~~

-- Keep the provider chosen by config.clipboard for ordinary yanks.
if vim.g.clipboard ~= nil then
    vim.opt.clipboard = "unnamedplus"
end
