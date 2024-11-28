#!/bin/bash

escape_char=$(printf "\u1b")
config_file_path="$HOME/.config/alacritty/alacritty.toml"
theme_path="$HOME/.config/alacritty/themes/themes"
print_colors="$HOME/.config/alacritty/themes/print_colors.sh"

check_config_file_exists() {
    if [[ ! -f $config_file_path ]]; then
        echo "Could not find alacritty.toml in $config_file_path."
        read -rp 'Generate a sample one? [Y/n] ' generate_config
        if [[ ${generate_config,,} == "n" ]]; then
            echo "Quitting. Create a config file in $config_file_path if you dont'have one, or change the config_file_path variable to your config file, then run the script again."
            exit 1
        fi
        mkdir -p "$HOME/.config/alacritty"
        echo -e '[general]\nimport = ["'"$theme_path"'/argonaut.toml"]' > "$config_file_path"
        echo "Done. You should open a new Alacritty window and run this script again to see the theme update while scrolling options."
        exit 0
    fi
}

check_previous_theme() {
    if [[ ! -f $previous_theme ]]; then
        echo "Could not parse any existing theme from current config file, will not be able to restore it on exit (if asked to)."
        echo "Parsed previous_theme: $previous_theme"
        read -rp 'Continue? [Y/n] ' continue_anyways
        if [[ ${continue_anyways,,} == "n" ]]; then
            echo "Quitting. A backup of your current config has been made in $config_file_path.themeswitch.bak"
            exit 1
        fi
    fi
}

update_alacritty_themes() {
    download_themes_if_not_exist
    echo "Updating themes..."
    pushd "$theme_path" || exit 1
    git pull
    popd || exit 1
    echo "Done updating"
}

download_themes_if_not_exist() {
    if [[ ! -d $theme_path ]]; then
        if [[ ! $(which git) ]]; then
            echo "Git not found, cannot download themes... Install it and run the script again."
            exit 1
        fi
        echo "Theme folder not found in $theme_path, downloading them..."
        mkdir -p "$HOME/.config/alacritty/themes"
        git clone https://github.com/alacritty/alacritty-theme ~/.config/alacritty/themes
    fi
}

make_config_backup() {
	# Backup file name could also be "$config_file_path$(date +%d-%m-%Y_%H-%M-%S)"
	[[ -f $config_file_path ]] && cp "$config_file_path" "$config_file_path.themeswitch.bak" || echo "$config_file_path not found, cannot make backup."
}

update_theme() {
    new_theme_full_path=$1
    perl -0777 -i -pe 's:^\s*import\s*=\s*\[\s*.*?\s*\]:import = ["'"$new_theme_full_path"'"]:gsm' "$config_file_path"
}

revert_theme_and_exit() {
    update_theme "$previous_theme"
    echo -e "\n---\n"
    echo "Restored previous theme: $(basename "$previous_theme")"
    exit 0
}

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
        read -rsn1 -p 'Up/down arrows to navigate, "p" to print color scheme, Enter to select, CTRL-C to revert to previous theme, "u" to update alacritty themes via git' input
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
        # Tasto p
        "p")
            clear
            $print_colors
            read -rsn1 -p 'Press any key to continue...'
            print_menu
            ;;
        # Tasto u
        "u")
            clear
            update_alacritty_themes
            read -rsn1 -p 'Press any key to continue...'
            print_menu
            ;;
        *)  
            print_menu
            ;;
        esac
    done
}

check_config_file_exists
previous_theme="$(perl -0777 -ne 'print "$1" if /^\s*import\s*=\s*\[\s*(.*?)\s*\]/gsm' "$config_file_path" | perl -pe 's/#.*//' | tr -d '\r\n"\ ')"
download_themes_if_not_exist
OPTIONS=("$theme_path"/*)
make_config_backup
check_previous_theme

trap 'revert_theme_and_exit' INT
MENU
