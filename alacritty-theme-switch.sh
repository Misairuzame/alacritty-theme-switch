#!/bin/bash

escape_char=$(printf "\u1b")
config_file_path="$HOME/.config/alacritty/alacritty.toml"
theme_path="$HOME/.config/alacritty/themes/themes"
previous_theme="$(grep -i import "$config_file_path" | perl -ne 'print "$1" if /^.+"(.+)".+$/')"

make_config_backup() {
	#cp "$config_file_path" "$config_file_path$(date +%d-%m-%Y_%H-%M-%S)"
	cp "$config_file_path" "$config_file_path.themeswitch.bak"
}

delete_import_lines() {
    sed -Ei '/^\s*import.+/d' "$config_file_path"
}

update_theme() {
    new_theme_full_path=$1
    delete_import_lines
    sed -i "1i import = [\"$new_theme_full_path\"]" "$config_file_path"
}

revert_theme_and_exit() {
    update_theme "$previous_theme"
    echo -e "\n---\n"
    echo "Restored previous theme: $(basename "$previous_theme")"
    exit 0
}

trap 'revert_theme_and_exit' INT

SCROLL_START=0

print_menu() {
    YELLOW="\033[1;33m"
    NC="\033[0m"
    INDICATOR="<"
    update_theme "${OPTIONS[$SELECTED]}"
    clear
    # Righe visibili (meno alcune per lasciare spazio), le ricalcolo
    # ogni volta per adattarmi se la dimensione del terminale cambia
    term_lines=$(stty size | awk '{print $1}')
    VISIBLE_LINES=$((term_lines - 3))
    local end=$((SCROLL_START + VISIBLE_LINES))
    if [[ $end -gt $LENGTH ]]; then
        end=$LENGTH
    fi

    for ((i = SCROLL_START; i < end; i++)); do
        #this_option="$i  -  $(basename "${OPTIONS[$i]}")"
        this_option="${OPTIONS[$i]}"
        if [[ $SELECTED -eq $i ]]; then
            echo -e "$this_option $YELLOW$INDICATOR$NC"
        else
            echo "$this_option"
        fi
    done
    echo ""
}

function MENU() {
    SELECTED=0
    LENGTH=${#OPTIONS[@]}

    print_menu

    LAST_ITEM=$((LENGTH - 1))

    while true; do
        read -rsn1 -p 'Up/down arrows to navigate, Enter to select, CTRL-C to revert to previous theme' input
        if [[ $input == "$escape_char" ]]; then
            read -rsn2 input
        fi
        case $input in
        # Freccia Su
        "[A")
            if [[ $SELECTED -lt 1 ]]; then
                SELECTED=$LAST_ITEM
                SCROLL_START=$((LENGTH - VISIBLE_LINES < 0 ? 0 : LENGTH - VISIBLE_LINES))
            else
                SELECTED=$((SELECTED - 1))
                if [[ $SELECTED -lt $SCROLL_START ]]; then
                    SCROLL_START=$((SCROLL_START - 1))
                fi
            fi
            print_menu
            ;;
        # Freccia Giù
        "[B")
            if [[ $SELECTED -ge $LAST_ITEM ]]; then
                SELECTED=0
                SCROLL_START=0
            else
                SELECTED=$((SELECTED + 1))
                if [[ $SELECTED -ge $((SCROLL_START + VISIBLE_LINES)) ]]; then
                    SCROLL_START=$((SCROLL_START + 1))
                fi
            fi
            print_menu
            ;;
        # Invio
        "")
            echo -e "\n---\n"
            echo "Selected theme: $(basename "${OPTIONS[$SELECTED]}" | sed 's/.toml//')"
            break
            ;;
        esac
    done
}

OPTIONS=("$theme_path"/*)
make_config_backup
MENU
