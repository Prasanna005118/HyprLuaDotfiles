#!/usr/bin/env bash

dir="$HOME/.config/clipboard/type-2"
theme='style-1'

cliphist list | rofi -dmenu \
  -p "Clipboard" \
  -theme "${dir}/${theme}.rasi" |
  cliphist decode | wl-copy
