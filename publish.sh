#!/usr/bin/env bash
#
# publish.sh — push your latest writings to the live site.
#
# Your posts live in the `writings` repo (e.g. ~/Documents/writings). Write,
# commit, and push THERE first. Then run this from the website repo to pull
# those posts into the site's `_directory` submodule and deploy them.
#
#   ./publish.sh        bump to the latest writings, commit, and push (deploys)
#   ./publish.sh -n     dry run — show what would publish, change nothing
#
set -euo pipefail

SUBMODULE="_directory"
SITE_URL="https://jffypak.com"

# Operate from the repo root, no matter where this is invoked from.
ROOT="$(git rev-parse --show-toplevel 2>/dev/null)" || {
  echo "✗ Not inside a git repo — run this from the personal-website repo." >&2
  exit 1
}
cd "$ROOT"

if [[ ! -e "$SUBMODULE/.git" ]]; then
  echo "✗ '$SUBMODULE' submodule not found — are you in the website repo?" >&2
  exit 1
fi

DRY_RUN=false
case "${1:-}" in
  -n|--dry-run) DRY_RUN=true ;;
  "")           ;;
  *)            echo "Usage: ./publish.sh [-n|--dry-run]" >&2; exit 1 ;;
esac

echo "→ Fetching latest writings…"
BEFORE="$(git -C "$SUBMODULE" rev-parse HEAD)"
git submodule update --remote --quiet "$SUBMODULE"
AFTER="$(git -C "$SUBMODULE" rev-parse HEAD)"

if [[ "$BEFORE" == "$AFTER" ]]; then
  echo "✓ Already up to date — nothing new to publish."
  exit 0
fi

echo
echo "New writings to publish:"
git -C "$SUBMODULE" log --oneline "$BEFORE..$AFTER" | sed 's/^/  /'
echo

# Lint: _plugins/future_publish.rb silently DROPS any post that lacks a
# publish_date (or whose date is in the future). Warn before we ship.
TODAY="$(date +%Y-%m-%d)"
WARN=""
shopt -s nullglob
for f in "$SUBMODULE"/*.md; do
  name="$(basename "$f")"
  line="$(grep -m1 -E '^[[:space:]]*publish_date:' "$f" 2>/dev/null || true)"
  if [[ -z "$line" ]]; then
    WARN+="  • $name — no publish_date → will NOT appear"$'\n'
    continue
  fi
  pd="${line#*:}"          # strip "publish_date:"
  pd="${pd//[\"\' ]/}"     # strip quotes and spaces
  if [[ "$pd" > "$TODAY" ]]; then
    WARN+="  • $name — publish_date $pd is in the future → hidden until then"$'\n'
  fi
done
if [[ -n "$WARN" ]]; then
  echo "⚠  Heads up — these posts won't show on the site:"
  printf '%s' "$WARN"
  echo
fi

if $DRY_RUN; then
  git submodule update --quiet "$SUBMODULE"   # restore pointer; change nothing
  echo "(dry run) Nothing committed or pushed."
  exit 0
fi

git add "$SUBMODULE"
git commit --quiet -m "chore: publish latest writings (${AFTER:0:7})"
echo "→ Pushing — this triggers the Netlify deploy…"
git push --quiet
echo
echo "✓ Done. Should be live in ~30s at $SITE_URL"
