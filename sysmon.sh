#!/usr/bin/env bash
# sysmon.sh - Simple system monitor for Linux (Ubuntu)
# Captures snapshots of CPU load, memory, disk, network, and top processes.
# Minimal dependencies: uptime, free, df, ip, ps
#
# Usage:
#   ./sysmon.sh                 # log to /var/log/sysmon.log or $HOME/sysmon.log every 30s
#   ./sysmon.sh -i 60           # change interval to 60s
#   ./sysmon.sh -o ./sysmon.log # choose a custom log file
#   ./sysmon.sh --once          # run a single snapshot and exit

set -u

INTERVAL=30
LOG_FILE=""
RUN_ONCE=0

usage() {
  cat <<EOF
Usage: $0 [options]
  -i, --interval SEC   Sampling interval (default: 30)
  -o, --output FILE    Log file path (default: /var/log/sysmon.log or \$HOME/sysmon.log)
      --once           Take one snapshot and exit
  -h, --help           Show this help and exit
EOF
}

# Parse arguments (simple)
while [[ $# -gt 0 ]]; do
  case "$1" in
    -i|--interval)
      INTERVAL=${2:-}
      shift 2
      ;;
    -o|--output)
      LOG_FILE=${2:-}
      shift 2
      ;;
    --once)
      RUN_ONCE=1
      shift
      ;;
    -h|--help)
      usage; exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage; exit 1
      ;;
  esac
done

# Determine a writable log file
if [[ -z "$LOG_FILE" ]]; then
  if [[ -w /var/log ]]; then
    LOG_FILE="/var/log/sysmon.log"
  else
    LOG_FILE="$HOME/sysmon.log"
  fi
fi

# Ensure log directory exists if needed
mkdir -p "$(dirname "$LOG_FILE")" 2>/dev/null || true

now() { date -u +%Y-%m-%dT%H:%M:%SZ; }

trap 'echo "Exiting..." >&2; exit 0' INT TERM

snapshot() {
  echo "===== $(now) ====="
  echo "HOST     : $(hostname)"
  echo "KERNEL   : $(uname -r)"
  echo "UPTIME   : $(uptime -p 2>/dev/null || uptime)"

  # CPU load averages
  echo "\nCPU LOAD : $(uptime | awk -F'load average: ' '{print $2}')"

  # Memory
  echo "\nMEMORY"
  free -h || echo "(free not available)"

  # Disk
  echo "\nDISK (/ and top usage)"
  df -h /
  WARN=$(df -P | awk 'NR>1 {gsub(/%/,"",$5); if ($5+0 >= 85) printf "%s=%s%% ", $6,$5 }')
  if [[ -n "${WARN:-}" ]]; then
    echo "WARNING: High disk usage: $WARN"
  fi

  # Network
  echo "\nNETWORK (IPv4 addresses)"
  ip -o -4 addr show scope global 2>/dev/null | awk '{printf "%-10s %s\n", $2, $4}'
  ip route show default 2>/dev/null | awk '/default/ {print "Default:", $0; exit}'

  # Top processes (CPU)
  echo "\nTOP PROCESSES (by CPU)"
  if ps -eo pid,comm,%cpu,%mem --sort=-%cpu >/dev/null 2>&1; then
    ps -eo pid,comm,%cpu,%mem --sort=-%cpu | head -n 6
  else
    ps -Ao pid,comm,%cpu,%mem -r | head -n 6
  fi
}

# Main loop
while :; do
  snapshot | tee -a "$LOG_FILE"
  if [[ "$RUN_ONCE" -eq 1 ]]; then
    break
  fi
  sleep "$INTERVAL"
done
