# Completion
bleopt complete_menu_complete=1
bleopt complete_menu_filter=1
bleopt complete_auto_complete=1
bleopt complete_auto_delay=250

# Keep Vim editing without the extra mode banner below the prompt.
blehook/eval-after-load keymap_vi 'bleopt keymap_vi_mode_show='

# Ctrl+C cancels the current command line in both vi insert and command modes.
ble-bind -m vi_imap -f 'C-c' discard-line
ble-bind -m vi_nmap -f 'C-c' discard-line

# Gruvbox Material Dark Hard accents, coordinated with the Alacritty palette.
ble-face -s syntax_default fg=#d4be98
ble-face -s syntax_command fg=#a9b665
ble-face -s syntax_quoted fg=#89b482
ble-face -s syntax_quotation fg=#d8a657
ble-face -s syntax_escape fg=#d3869b
ble-face -s syntax_expr fg=#7daea3
ble-face -s syntax_error fg=#ea6962,bg=#442e2d
ble-face -s syntax_varname fg=#d3869b
ble-face -s syntax_param_expansion fg=#d3869b
ble-face -s syntax_history_expansion fg=#d8a657
ble-face -s syntax_function_name fg=#89b482
ble-face -s syntax_comment fg=#a89984
ble-face -s syntax_glob fg=#d8a657
ble-face -s syntax_brace fg=#89b482
ble-face -s syntax_tilde fg=#d8a657
ble-face -s syntax_document fg=#a9b665
ble-face -s syntax_document_begin fg=#a9b665
ble-face -s command_builtin fg=#a9b665
ble-face -s command_builtin_dot fg=#a9b665
ble-face -s command_alias fg=#7daea3
ble-face -s command_function fg=#89b482
ble-face -s command_file fg=#a9b665
ble-face -s command_keyword fg=#e78a4e
ble-face -s command_jobs fg=#d3869b
ble-face -s command_directory fg=#7daea3
ble-face -s filename_directory fg=#7daea3
ble-face -s filename_directory_sticky fg=#d4be98,bg=#32302f
ble-face -s auto_complete fg=#928374,bg=#282828
ble-face -s menu_complete_match fg=#d8a657
ble-face -s menu_complete_selected fg=#d4be98,bg=#504945
ble-face -s menu_filter_input fg=#d4be98,bg=#282828

# Starship already presents command duration and failure status.
bleopt exec_elapsed_mark=
bleopt exec_errexit_mark=
bleopt exec_exit_mark=
bleopt prompt_eol_mark=''
