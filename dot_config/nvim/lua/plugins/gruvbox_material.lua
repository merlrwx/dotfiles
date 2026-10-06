return {
    {
        "sainnhe/gruvbox-material",
        lazy = false,
        priority = 1000,
        init = function()
            vim.opt.background = "dark"
            vim.g.gruvbox_material_background = "medium"
            vim.g.gruvbox_material_foreground = "material"
            vim.g.gruvbox_material_better_performance = 1
        end,
    },
    {
        "LazyVim/LazyVim",
        opts = { colorscheme = "gruvbox-material" },
    },
}
