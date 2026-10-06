#!/usr/bin/env bash
#
# Run every check and report PASS / FAIL / DID NOT RUN.
#
# Why this exists (2026-10-05): eleven of the twenty-three checks shell out to
# the luau binary, and when that binary is missing they print "skipping" and
# **exit 0**. There was no runner, so the checks were run by hand and eleven
# silent greens looked exactly like eleven real ones. A check that could not
# execute is not a check that passed, and this is the thing that says so.
#
# Exit codes:  0 = everything ran and passed (known failures aside)
#              1 = something failed, or something could not run
#
# Usage:  bash tools/verify/suite.sh
#         bash tools/verify/suite.sh --quiet     # one line per check, no bodies
set -u

cd "$(dirname "$0")/../.." || exit 1
QUIET=0
[ "${1:-}" = "--quiet" ] && QUIET=1

# Checks known to fail on a clean tree. Listed so a NEW failure is visible
# instead of being lost in the noise of an old one. Shrink this list; never
# grow it to make a run look clean.
#
# ladder-climbable was listed here while ORE_DMAX still came off Depth.SECTIONS'
# retired last row and 53 of 82 ores could never roll. That is fixed, so it is
# OFF the list and is expected to stay green -- it now guards both ends at once:
# the forge ladder must reach tier 82, and the Exotic band must stay rare while
# doing it.
KNOWN_FAIL="trap"

# Not checks. luau-balance.js is a utility that balance-scans ONE chunk given
# as argv[2] -- run it as `node tools/verify/luau-balance.js <file.luau>`.
# Invoked bare it crashes on readFileSync(undefined), which is why it reads as
# a failure if you loop over the directory naively. It could use an arg guard.
UTILITIES="luau-balance"

pass=0; fail=0; norun=0; knownfail=0
failed=""; didnotrun=""

for f in tools/verify/*.js; do
  name=$(basename "$f" .js)
  case " $UTILITIES " in *" $name "*) continue ;; esac
  case "$name" in _*) continue ;; esac   # _luau.js and friends are helpers
  out=$(timeout 180 node "$f" 2>&1); code=$?

  # "Did not run" beats the exit code, because the whole point is that a
  # skipped check exits 0. Matched on the skip wording the checks print.
  if printf '%s' "$out" | grep -qiE 'luau not present|skipping|cannot run|not runnable'; then
    verdict="DID NOT RUN"; norun=$((norun + 1))
    didnotrun="$didnotrun $name"
  elif [ $code -eq 0 ]; then
    verdict="pass"; pass=$((pass + 1))
  elif printf '%s' " $KNOWN_FAIL " | grep -q " $name "; then
    verdict="FAIL (known)"; knownfail=$((knownfail + 1))
  else
    verdict="FAIL"; fail=$((fail + 1))
    failed="$failed $name"
  fi

  printf '  %-14s %s\n' "$name" "$verdict"
  if [ "$verdict" != "pass" ] && [ $QUIET -eq 0 ]; then
    printf '%s\n' "$out" | sed 's/^/        /' | tail -12
  fi
done

echo
echo "  ${pass} passed, ${fail} failed, ${norun} did not run, ${knownfail} known failure(s)"

if [ $norun -gt 0 ]; then
  echo
  echo "  DID NOT RUN:$didnotrun"
  echo "  These need the luau binary. Run:  bash tools/verify/syntax.sh"
  echo "  Until then they assert nothing. Do not read their silence as green."
fi

if [ $fail -gt 0 ]; then
  echo "  FAILED:$failed"
fi

# A skip is not a pass, so it fails the run too.
if [ $fail -gt 0 ] || [ $norun -gt 0 ]; then
  exit 1
fi
exit 0
