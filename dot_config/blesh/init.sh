# Completion
bleopt complete_menu_complete=1
bleopt complete_menu_filter=1
bleopt complete_auto_complete=1
bleopt complete_auto_delay=250

# Keep Vim editing without the extra mode banner below the prompt.
blehook/eval-after-load keymap_vi 'bleopt keymap_vi_mode_show='

# Gruvbox Material Dark palette shared with starship.toml and Alacritty.
# background #1d2021, surface #32302f, foreground #d4be98, muted #a89984,
# subtle #928374, red #ea6962, green #a9b665, amber #d8a657,
# blue #7daea3, aqua #89b482, purple #d3869b.
ble-face -s syntax_default fg=#d4be98
ble-face -s syntax_command fg=#a9b665
ble-face -s syntax_quoted fg=#a9b665
ble-face -s syntax_quotation fg=#d8a657,bold
ble-face -s syntax_escape fg=#d3869b
ble-face -s syntax_expr fg=#7daea3
ble-face -s syntax_error fg=#ea6962,bg=#3c1f1e
ble-face -s syntax_varname fg=#d3869b
ble-face -s syntax_param_expansion fg=#d3869b
ble-face -s syntax_history_expansion fg=#d8a657
ble-face -s syntax_function_name fg=#83a598,bold
ble-face -s syntax_comment fg=#928374
ble-face -s syntax_glob fg=#d8a657
ble-face -s syntax_brace fg=#83a598
ble-face -s syntax_tilde fg=#d8a657
ble-face -s syntax_document fg=#a9b665
ble-face -s syntax_document_begin fg=#a9b665,bold
ble-face -s command_builtin fg=#a9b665
ble-face -s command_builtin_dot fg=#a9b665,bold
ble-face -s command_alias fg=#7daea3
ble-face -s command_function fg=#83a598
ble-face -s command_file fg=#a9b665
ble-face -s command_keyword fg=#d8a657
ble-face -s command_jobs fg=#d3869b
ble-face -s command_directory fg=#7daea3,underline
ble-face -s auto_complete fg=#a89984,bg=#32302f
ble-face -s menu_complete_selected fg=#d4be98,bg=#504945
ble-face -s menu_filter_input fg=#d4be98,bg=#32302f

# Starship already presents command duration and failure status.
bleopt exec_elapsed_mark=
bleopt exec_errexit_mark=
bleopt prompt_eol_mark=''
