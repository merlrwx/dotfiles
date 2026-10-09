return {
    -- Use fzf-lua as LazyVim's picker; the fzf executable comes from Mise.
    { import = "lazyvim.plugins.extras.editor.fzf" },

    -- Small editing helpers from mini.nvim.
    { import = "lazyvim.plugins.extras.coding.mini-surround" },
    { import = "lazyvim.plugins.extras.ui.mini-indentscope" },

    -- Common file formats are useful on both the host and in DevPod.
    { import = "lazyvim.plugins.extras.lang.json" },
    { import = "lazyvim.plugins.extras.lang.markdown" },
    { import = "lazyvim.plugins.extras.lang.toml" },
    { import = "lazyvim.plugins.extras.lang.yaml" },
}
