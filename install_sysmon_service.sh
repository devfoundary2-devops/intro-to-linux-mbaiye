#!/usr/bin/env bash
set -euo pipefail

if [[ $(id -u) -ne 0 ]]; then
  echo "Please run as root: sudo $0" >&2
  exit 1
fi

# Locate sources relative to this script
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

SYSMon_SRC="$SCRIPT_DIR/sysmon.sh"
SERVICE_SRC="$SCRIPT_DIR/sysmon.service"

if [[ ! -f "$SYSMon_SRC" ]]; then
  echo "sysmon.sh not found at $SYSMon_SRC" >&2
  exit 1
fi
if [[ ! -f "$SERVICE_SRC" ]]; then
  echo "sysmon.service not found at $SERVICE_SRC" >&2
  exit 1
fi

# Install binaries and service
install -D -m 0755 "$SYSMon_SRC" /usr/local/bin/sysmon.sh
install -D -m 0644 "$SERVICE_SRC" /etc/systemd/system/sysmon.service

# Prepare log file (script writes to /var/log/sysmon.log by default when run as root)
mkdir -p /var/log
: >/var/log/sysmon.log || true
chmod 0644 /var/log/sysmon.log || true

# Enable and start service
systemctl daemon-reload
systemctl enable --now sysmon.service

# Show quick status and a snapshot of the latest log entries
echo "--- sysmon.service status ---"
systemctl --no-pager --no-legend status sysmon.service || true

echo "--- Recent /var/log/sysmon.log entries ---"
tail -n 80 /var/log/sysmon.log || true

