# Alacritty Theme Switch
Simple Bash script to easily switch your Alacritty theme. Will download themes from https://github.com/alacritty/alacritty-theme if not found, and place a sample alacritty.toml config file if not found on the specified path. By default these paths are:
```
config_file_path="$HOME/.config/alacritty/alacritty.toml"
theme_path="$HOME/.config/alacritty/themes/themes"
```

## Installing
Run `sudo make install`

## Usage
Run `alacritty-theme-switch`, an interactive menu will allow you to select your theme.
