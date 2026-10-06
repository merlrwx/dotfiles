-- Use the provider selected before LazyVim loads so ordinary yanks reach the
-- Windows/terminal clipboard. LazyVim leaves this unset for SSH by default.
if vim.g.clipboard ~= nil then
    vim.opt.clipboard = "unnamedplus"
end
