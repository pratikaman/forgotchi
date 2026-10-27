#!/bin/sh
# Claude Code hook: `hook.sh work` marks this session busy, `hook.sh idle` clears it.
# Forgotchi animates while any file in /tmp/claude-tama is fresh.
# session_id is the first field of the hook's JSON input; escaped quotes inside prompts can't match.
id=$(grep -o '"session_id" *: *"[^"]*"' | head -1 | cut -d'"' -f4)
[ -n "$id" ] || exit 0
d=/tmp/claude-tama
if [ "$1" = work ]; then mkdir -p "$d" && touch "$d/$id"; else rm -f "$d/$id"; fi
exit 0
