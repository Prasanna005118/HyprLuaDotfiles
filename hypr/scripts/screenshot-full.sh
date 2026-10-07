#!/usr/bin/env bash

screenshot_dir="$HOME/Pictures/Screenshots"

mkdir -p "$screenshot_dir"

grim "$screenshot_dir/$(date +'%Y-%m-%d_%H-%M-%S').png"
