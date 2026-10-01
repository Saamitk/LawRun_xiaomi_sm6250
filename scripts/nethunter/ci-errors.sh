#!/usr/bin/env bash
# Print the first compiler/linker errors of a build log as ONE GitHub annotation
# (so they can be read from the check-run page / API without downloading logs).
LOG=${1:-build.log}
[ -f "$LOG" ] || exit 0
msg=$(grep -E "error:|undefined reference|undefined symbol|No rule to make target|Error 127|command not found|not found|fatal" "$LOG" \
      | grep -v "Wno-\|-Werror" | sed 's|/home/runner/work/[^/]*/[^/]*/||' | awk '!s[$0]++' | head -n 40 | cut -c1-300 \
      | sed ':a;N;$!ba;s/%/%25/g;s/\r//g;s/\n/%0A/g')
[ -n "$msg" ] && echo "::error title=First build errors::${msg}"
exit 0
