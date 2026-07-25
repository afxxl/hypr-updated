#!/usr/bin/env bash
# Wallpaper picker for the caelestia shell.
# Shows the wallpapers in $WALLDIR as thumbnails in a fuzzel menu and applies
# the chosen one via `caelestia wallpaper -f`.
#
# Usage: wallpaper_picker.sh [dir]   (defaults to ~/Wallpapers)

WALLDIR="${1:-$HOME/Wallpapers}"

# Toggle: if a fuzzel is already open, just close it
pkill fuzzel 2>/dev/null && exit 0

[ -d "$WALLDIR" ] || { notify-send "Wallpaper picker" "Folder not found: $WALLDIR"; exit 1; }

# Collect top-level image files (case-insensitive), no external `find` needed
shopt -s nullglob nocaseglob
files=("$WALLDIR"/*.jpg "$WALLDIR"/*.jpeg "$WALLDIR"/*.png "$WALLDIR"/*.webp "$WALLDIR"/*.bmp)
shopt -u nullglob nocaseglob

[ ${#files[@]} -eq 0 ] && { notify-send "Wallpaper picker" "No images in $WALLDIR"; exit 1; }

# Feed entries to fuzzel: "basename \0 icon \x1f fullpath" so each row shows a thumbnail
sel="$(
    for f in "${files[@]}"; do
        printf '%s\0icon\x1f%s\n' "${f##*/}" "$f"
    done | sort | fuzzel --dmenu --prompt "🖼  wallpaper: " --width 45 --lines 15
)"

[ -z "$sel" ] && exit 0

caelestia wallpaper -f "$WALLDIR/$sel"
