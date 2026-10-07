#!/usr/bin/env bash

screenshot_dir="$HOME/Pictures/Screenshots"

mkdir -p "$screenshot_dir"

grim -g "$(slurp)" \
  "$screenshot_dir/$(date +'%Y-%m-%d_%H-%M-%S').png"
