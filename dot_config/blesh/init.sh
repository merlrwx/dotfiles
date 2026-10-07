# Completion
bleopt complete_menu_complete=1
bleopt complete_menu_filter=1
bleopt complete_auto_complete=1
bleopt complete_auto_delay=250

# Keep Vim editing without the extra mode banner below the prompt.
blehook/eval-after-load keymap_vi 'bleopt keymap_vi_mode_show='

# Gruvbox Material Dark palette shared with starship.toml and Alacritty.
# background #1d2021, surface #32302f, foreground #d4be98, muted #a89984,
# subtle #928374, red #d2746e, green #9eaa72, amber #c1a06d,
# blue #718b91, aqua #89a58e, purple #b88c9b.
ble-face -s syntax_default fg=#c1b89f
ble-face -s syntax_command fg=#9eaa72
ble-face -s syntax_quoted fg=#a9aa88
ble-face -s syntax_quotation fg=#c1a06d
ble-face -s syntax_escape fg=#b88c9b
ble-face -s syntax_expr fg=#718b91
ble-face -s syntax_error fg=#d2746e,bg=#322827
ble-face -s syntax_varname fg=#b88c9b
ble-face -s syntax_param_expansion fg=#b88c9b
ble-face -s syntax_history_expansion fg=#c1a06d
ble-face -s syntax_function_name fg=#89a58e
ble-face -s syntax_comment fg=#928374
ble-face -s syntax_glob fg=#c1a06d
ble-face -s syntax_brace fg=#89a58e
ble-face -s syntax_tilde fg=#c1a06d
ble-face -s syntax_document fg=#9eaa72
ble-face -s syntax_document_begin fg=#9eaa72
ble-face -s command_builtin fg=#9eaa72
ble-face -s command_builtin_dot fg=#9eaa72
ble-face -s command_alias fg=#718b91
ble-face -s command_function fg=#89a58e
ble-face -s command_file fg=#9eaa72
ble-face -s command_keyword fg=#c1a06d
ble-face -s command_jobs fg=#b88c9b
ble-face -s command_directory fg=#718b91
ble-face -s filename_directory fg=#718b91
ble-face -s filename_directory_sticky fg=#c1b89f,bg=#3c3836
ble-face -s auto_complete fg=#928374,bg=#32302f
ble-face -s menu_complete_match fg=#c1ac83
ble-face -s menu_complete_selected fg=#d4be98,bg=#504945
ble-face -s menu_filter_input fg=#c1b89f,bg=#32302f

# Starship already presents command duration and failure status.
bleopt exec_elapsed_mark=
bleopt exec_errexit_mark=
bleopt prompt_eol_mark=''
