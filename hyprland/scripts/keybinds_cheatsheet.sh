#!/usr/bin/env bash
# Show all (non-hidden) Hyprland keybindings in a searchable fuzzel menu.
#
# Parses the keybind config files using the dots' own convention:
#   "##! Section"       -> section heading
#   line ending "# [hidden]"  -> not shown
#   trailing "# Description"   -> shown as the description (falls back to the dispatcher+args)
#
# Usage:
#   keybinds_cheatsheet.sh            # show in fuzzel
#   keybinds_cheatsheet.sh --print    # print to stdout (for testing)

FILES=(
    "$HOME/.config/hypr/hyprland/keybinds.conf"
    "$HOME/.config/hypr/custom/keybinds.conf"
)

trim() { sed 's/^[[:space:]]*//; s/[[:space:]]*$//'; }

parse() {
    local section="General"
    local line rest desc mods key combo
    local -a f
    for file in "${FILES[@]}"; do
        [ -f "$file" ] || continue
        while IFS= read -r line; do
            # Section heading: ##! Name
            if [[ "$line" =~ ^[[:space:]]*##![[:space:]]*(.+) ]]; then
                section="$(printf '%s' "${BASH_REMATCH[1]}" | trim)"
                continue
            fi
            # Skip comments and non-bind lines
            [[ "$line" =~ ^[[:space:]]*# ]] && continue
            [[ "$line" =~ ^[[:space:]]*bind ]] || continue
            # Skip hidden binds
            [[ "$line" == *"# [hidden]"* ]] && continue

            # Drop the "bindXXX =" prefix
            rest="${line#*=}"

            # Split off the "# description" (first # wins)
            if [[ "$rest" == *"#"* ]]; then
                desc="$(printf '%s' "${rest#*#}" | trim)"
                rest="${rest%%#*}"
            else
                desc=""
            fi

            # Fields are comma separated: MODS, KEY, [desc,] dispatcher, args...
            IFS=',' read -r -a f <<< "$rest"
            mods="$(printf '%s' "${f[0]:-}" | trim)"
            key="$(printf '%s' "${f[1]:-}" | trim)"
            [ -z "$key" ] && continue

            # If there was no "# description", fall back to the dispatcher + args
            if [ -z "$desc" ]; then
                desc="$(printf '%s' "${f[*]:2}" | sed 's/,/ /g' | trim)"
            fi

            # Pretty key combo
            mods="${mods//+/ + }"
            if [ -n "$mods" ]; then
                combo="$mods + $key"
            else
                combo="$key"
            fi

            printf '%-28s  %s   ·  %s\n' "$combo" "$desc" "$section"
        done < "$file"
    done
}

if [ "${1:-}" = "--print" ]; then
    parse
else
    # Toggle: if a fuzzel is already open, close it instead of stacking another
    pkill fuzzel 2>/dev/null && exit 0
    parse | fuzzel --dmenu --prompt "⌨  keybinds: " --width 110 --lines 30 >/dev/null 2>&1 || true
fi
