#!/usr/bin/env bash
#
# Real syntax check for every Luau file in src/.
#
# tools/verify/luau-balance.js counts braces and keywords. That catches most
# damage and it is fast, but it is a heuristic: it cannot tell an `end` that
# closes the wrong block from one that closes the right one, and it passes files
# that will not load. This runs the actual Luau front end instead.
#
# Worth having because a structural edit -- removing an `elseif` arm, splicing a
# merge, deleting a branch out of a chain -- is exactly the case where brace
# counting agrees and the parser does not.
#
# Usage:  tools/verify/syntax.sh [path ...]      (default: everything under src/)
#
# The binary is not committed (7 MB, platform-specific). It is fetched on first
# run into .luau-bin/, which .gitignore covers.
set -uo pipefail
cd "$(dirname "$0")/../.." || exit 1

BIN_DIR=".luau-bin"

# Which release asset, and what the binary is called once unzipped. Windows
# ships .exe; an ELF binary sitting at the extensionless name is what a Linux
# container left behind, and it exists without being runnable here.
case "$(uname -s 2>/dev/null || echo unknown)" in
  MINGW*|MSYS*|CYGWIN*|Windows_NT) LUAU_ZIP="luau-windows.zip"; EXE=".exe" ;;
  Darwin)                          LUAU_ZIP="luau-macos.zip";   EXE=""     ;;
  *)                               LUAU_ZIP="luau-ubuntu.zip";  EXE=""     ;;
esac
ANALYZE="$BIN_DIR/luau-analyze$EXE"

if [ ! -x "$ANALYZE" ]; then
  echo "luau-analyze not present; fetching $LUAU_ZIP into $BIN_DIR/ ..."
  mkdir -p "$BIN_DIR" || exit 1
  if ! curl -sSL -o "$BIN_DIR/luau.zip" \
      "https://github.com/luau-lang/luau/releases/latest/download/$LUAU_ZIP"; then
    echo "could not download luau; skipping the syntax check" >&2
    exit 0   # soft-fail: never block work because a download failed
  fi
  ( cd "$BIN_DIR" && unzip -o -q luau.zip && rm -f luau.zip ) || exit 0
  chmod +x "$BIN_DIR"/luau* 2>/dev/null
fi

if [ ! -x "$ANALYZE" ]; then
  echo "luau-analyze still not runnable after fetching $LUAU_ZIP; skipping" >&2
  echo "  (if .luau-bin holds binaries for another OS, delete it and re-run)" >&2
  exit 0
fi

if [ "$#" -gt 0 ]; then
  FILES=$(for p in "$@"; do
    if [ -d "$p" ]; then find "$p" -name '*.luau'; else echo "$p"; fi
  done)
else
  FILES=$(find src -name '*.luau')
fi

total=0
bad=0
# SyntaxError only. Type errors are noise here: this repo is not type-clean and
# a TypeError does not stop a file loading in Studio.
for f in $FILES; do
  total=$((total + 1))
  out=$("$ANALYZE" --mode=nonstrict "$f" 2>&1 | grep 'SyntaxError')
  if [ -n "$out" ]; then
    bad=$((bad + 1))
    echo "FAIL $f"
    echo "$out" | head -5 | sed 's/^/     /'
  fi
done

if [ "$bad" -eq 0 ]; then
  echo ">>> $total files, no syntax errors"
  exit 0
fi
echo ">>> $bad of $total files have syntax errors"
exit 1
