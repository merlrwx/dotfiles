# Neovim with LazyVim

This config uses the upstream [LazyVim starter](https://github.com/LazyVim/starter)
for its bootstrap and defaults. Chezmoi refreshes the starter archive every seven
days. The local `init.lua` and `options.lua` keep the clipboard integration and
personal settings; upstream owns the remaining starter files.

## Start with the built-in keys

LazyVim's leader key is Space. Press Space and pause to see the available
key groups, or run `:Lazy` to inspect plugins. The explorer and buffer list are
available with:

- `Space e`: open the project file explorer. Press `?` inside it for its help.
- `Space f f`: find a file in the project.
- `Space b`: browse buffers.
- `Space n`: show notification history.
- `Ctrl s`: save the current file.

`Ctrl d` and `Ctrl u` scroll half a screen down or up, then center the cursor.
`scrolloff = 8` keeps eight lines between the cursor and the viewport edge when
possible. The other defaults are documented in
[LazyVim's keymap reference](https://www.lazyvim.org/keymaps).

## Search with fzf-lua

fzf-lua is the active LazyVim picker. The Mise toolset provides `fzf` and
`ripgrep`, which power its fuzzy file and text searches.

- `Space f f`: search files under the project root.
- `Space f F`: search files under Neovim's current working directory.
- `Space f g`: search Git-tracked files.
- `Space s g` or `Space /`: search text under the project root.

Type a filename or text fragment to narrow results, then select a result to
open it. You can also run `:FzfLua files` or `:FzfLua live_grep` directly. In a
picker, `Alt h` toggles hidden files and `Alt i` toggles ignored files. See the
[LazyVim fzf extra](https://www.lazyvim.org/extras/editor/fzf) for the full
mapping list.

## Optional plugins

- NoNeckPain starts automatically and centers the current editing window. Run
  `:NoNeckPain` to return to the normal layout or center it again. `Space n`
  remains LazyVim's notification history.
- Open a Markdown, Org, or AsciiDoc file and run `:Presenting` to show it as
  slides. Use `n`/`p` for next/previous slide, `f`/`l` for first/last, and `q`
  to exit.
- `mini.pairs` stays disabled, so typing an opening bracket or quote does not
automatically insert its closing pair.

Run `:LazyHealth` to load plugins and check Neovim's health reports.

## Add language support per project

JSON, Markdown, TOML, and YAML support is enabled globally. Keep language
runtimes and language-server extras local to projects that need them. Add a
`.lazy.lua` file at the project root with a LazyVim extra import, for example:

```lua
return {
  { import = "lazyvim.plugins.extras.lang.python" },
}
```

When Neovim opens a file in that project, lazy.nvim discovers the project spec
and adds Python support. Add the needed Python version to that project's
`mise.toml` too. Check the project's `.gitignore` before committing `.lazy.lua`;
keep credentials and machine-specific settings out of version control.

## Update the shared Mise tools

The global Mise config pins exact versions and records download URLs and
checksums in `dot_config/mise/mise.lock`. To update the whole shared set after
the dotfiles have been applied, run from your home directory:

```bash
mise upgrade --bump --minimum-release-age=7d --cd "$HOME"
mise lock --global --platform linux-x64,linux-arm64 --minimum-release-age=7d
chezmoi re-add ~/.config/mise/config.toml ~/.config/mise/mise.lock
```

Review both Mise files before committing. `mise upgrade --bump` changes the
pinned versions; `mise lock` refreshes the lock entries for both supported
Linux architectures. Installs use `mise install --locked`, so a missing lock
entry fails instead of silently resolving a different artifact.
