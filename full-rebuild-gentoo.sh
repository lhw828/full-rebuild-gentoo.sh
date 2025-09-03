#!/usr/bin/env bash
# full-rebuild-gentoo.sh
# Rebuild the entire Gentoo system with logging and safety checks.

set -euo pipefail

# ---------- Config ----------
LOG_DIR="/var/log/gentoo-rebuild"
STEP_STATE="/var/tmp/full-rebuild.step"        # progress marker
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"
LOG_FILE="${LOG_DIR}/full-rebuild-${TIMESTAMP}.log"

# Emerge tuning (auto-parallel based on CPUs)
CPUS="$(nproc || echo 1)"
JOBS="${JOBS:-$CPUS}"
LOAD_AVG="${LOAD_AVG:-$CPUS}"

# Default emerge options for robustness
EMERGE_OPTS=(
  --ask=n
  --verbose
  --with-bdeps=y
  --keep-going=y
  --backtrack=100
  --jobs="${JOBS}"
  --load-average="${LOAD_AVG}"
  --color=y
)

# ---------- Helpers ----------
need_root() {
  if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
    echo "Please run as root." >&2
    exit 1
  fi
}

prepare_env() {
  mkdir -p "$LOG_DIR"
  echo "### Full rebuild started at $(date) ###" | tee -a "$LOG_FILE"
  eselect profile show | tee -a "$LOG_FILE" || true
  echo -e "\n### emerge --info (snapshot) ###" | tee -a "$LOG_FILE"
  emerge --info | tee -a "$LOG_FILE" || true

  # Back up useful files
  mkdir -p /var/backups/gentoo-rebuild
  cp -a /etc/portage/make.conf /var/backups/gentoo-rebuild/make.conf.${TIMESTAMP} 2>/dev/null || true
  cp -a /var/lib/portage/world /var/backups/gentoo-rebuild/world.${TIMESTAMP} 2>/dev/null || true

  # Ensure tools exist
  emerge -1q dev-util/ccache app-portage/gentoolkit app-portage/eix || true
}

step() {
  local name="$1"
  echo -e "\n===== STEP: ${name} =====" | tee -a "$LOG_FILE"
}

mark_done() {
  echo "$1" > "$STEP_STATE"
}

done_upto() {
  [[ -f "$STEP_STATE" ]] && cat "$STEP_STATE" || echo ""
}

run_or_skip() {
  local name="$1"; shift
  local last_done
  last_done="$(done_upto)"
  if [[ "$last_done" == "$name" ]]; then
    # Already completed; move on
    return 0
  fi
  step "$name"
  # shellcheck disable=SC2068
  { "$@" 2>&1 | tee -a "$LOG_FILE"; }
  mark_done "$name"
}

trap 'echo "ERROR: Rebuild aborted at step: $(done_upto)"; echo "See log: $LOG_FILE"' ERR

need_root
prepare_env

# ---------- Pipeline ----------

# 0) Quick disk space & temperature reminder
run_or_skip "00-prerun" bash -c '
  echo "Disk usage:"; df -h / /var/cache/distfiles /var/db/pkg || true
  echo "Tip: run inside tmux/screen to avoid disconnects."
'

# 1) Sync repositories
run_or_skip "01-sync" bash -c '
  (command -v emaint >/dev/null && emaint sync -a) || emerge --sync
'

# 2) Update world (new USE/versions)
run_or_skip "02-update-world" bash -c '
  emerge -uDUN @world '"${EMERGE_OPTS[@]}"'
'

# 3) Depclean
run_or_skip "03-depclean" bash -c '
  emerge --depclean '"${EMERGE_OPTS[@]}"'
'

# 4) Revdep fix after update/depclean
run_or_skip "04-revdep-1" bash -c '
  revdep-rebuild -i -v 2>&1
'

# 5) Clean distfiles and old binpkgs
run_or_skip "05-clean" bash -c '
  eclean-dist -d || true
  eclean-pkg  -d || true
'

# 6) Rebuild @system from source
run_or_skip "06-emerge-e-system" bash -c '
  emerge -e @system '"${EMERGE_OPTS[@]}"'
'

# 7) Rebuild @world from source
run_or_skip "07-emerge-e-world" bash -c '
  emerge -e @world '"${EMERGE_OPTS[@]}"'
'

# 8) Final revdep check
run_or_skip "08-revdep-2" bash -c '
  revdep-rebuild -i -v 2>&1
'

# 9) Final summary
run_or_skip "09-summary" bash -c '
  echo -e "\n### Final world set ###"
  wc -l /var/lib/portage/world || true
  echo -e "\n### Outdated packages (should be none) ###"
  emerge -puD @world || true
  echo -e "\n### Done at $(date). Log: '"$LOG_FILE"'"
'

echo "All steps completed. Full log: $LOG_FILE"
