return {
    -- Keep the editing window centered by default; :NoNeckPain toggles it.
    {
        "shortcuts/no-neck-pain.nvim",
        version = "*",
        lazy = false,
        opts = {
            autocmds = {
                enableOnVimEnter = "safe",
                enableOnTabEnter = true,
            },
        },
    },

    -- Turn Markdown, Org, or AsciiDoc files into terminal slides with :Presenting.
    { "sotte/presenting.nvim", cmd = "Presenting" },
}
