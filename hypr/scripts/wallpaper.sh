#!/usr/bin/env bash

wallpaper_dir="$HOME/Pictures/Wallpapers"

dir="$HOME/.config/hypr/type-2"
theme="style-1"

selected=$(find "$wallpaper_dir" -maxdepth 1 -type f \
  \( -iname "*.jpg" -o -iname "*.jpeg" -o -iname "*.png" -o -iname "*.webp" \) |
while read -r file; do
echo -en "${file##*/}\0icon\x1f${file}\n"
done |
rofi -dmenu \
    -p "Wallpaper" \
    -show-icons \
    -theme "${dir}/${theme}.rasi")

[ -z "$selected" ] && exit 0

wallpaper="$wallpaper_dir/$selected"

# Apply wallpaper
awww img "$wallpaper" \
  --transition-type grow \
  --transition-duration 1

# Generate the complete Matugen theme
# Automatically select the first extracted source color
matugen image "$wallpaper" -m dark --source-color-index 0
