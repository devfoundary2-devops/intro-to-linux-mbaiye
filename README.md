[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/NENsd3bP)
[![Open in Visual Studio Code](https://classroom.github.com/assets/open-in-vscode-2e0aaae1b6195c2367325f4f02e2d04e9abb55f0b24a779b69b11b9e10269abc.svg)](https://classroom.github.com/online_ide?assignment_repo_id=20397797&assignment_repo_type=AssignmentRepo)

# SysMon (Ubuntu) – Simple System Monitor

A lightweight snapshot-style system monitor for Ubuntu that logs CPU load, memory, disk, network, and top processes. Includes a systemd unit and an installer script to run it as a background service.

## Files in this directory
- `sysmon.sh` – the monitoring script (Linux/Ubuntu only)
- `sysmon.service` – systemd unit file to run the monitor as a service
- `install_sysmon_service.sh` – installer to copy files to system locations, enable and start the service

## Requirements
- Ubuntu with systemd
- Common utilities available by default: `uptime`, `free`, `df`, `ip`, `ps`
- Root privileges to install and manage the service

## Quick start (manual run)
- Default: logs every 30s to `/var/log/sysmon.log` if writable, else to `~/sysmon.log`:
```bash path=null start=null
./sysmon.sh
```
- Change interval to 60s:
```bash path=null start=null
./sysmon.sh -i 60
```
- One-off snapshot and exit:
```bash path=null start=null
./sysmon.sh --once
```
- Custom log file:
```bash path=null start=null
./sysmon.sh -o ./sysmon.log
```

## Install as a background service (systemd)
Run on your Ubuntu host:
```bash path=null start=null
sudo bash install_sysmon_service.sh
```
This will:
- Copy `sysmon.sh` to `/usr/local/bin/sysmon.sh`
- Install `sysmon.service` to `/etc/systemd/system/sysmon.service`
- Enable and start the service
- Print recent log lines from `/var/log/sysmon.log`

## Verify it’s running
```bash path=null start=null
systemctl --no-pager status sysmon.service
```

## Capture a snapshot of recent output into this repo
```bash path=null start=null
sudo tail -n 120 /var/log/sysmon.log | tee sysmon_snapshot.txt
```

## One-off snapshot without the service
```bash path=null start=null
sudo /usr/local/bin/sysmon.sh --once -o /var/log/sysmon.log | tee sysmon_once_snapshot.txt
```

## Service management
- Stop:
```bash path=null start=null
sudo systemctl stop sysmon.service
```
- Start:
```bash path=null start=null
sudo systemctl start sysmon.service
```
- Restart:
```bash path=null start=null
sudo systemctl restart sysmon.service
```
- View logs live:
```bash path=null start=null
sudo tail -f /var/log/sysmon.log
```

## Uninstall
```bash path=null start=null
sudo systemctl disable --now sysmon.service
sudo rm -f /etc/systemd/system/sysmon.service
sudo systemctl daemon-reload
sudo rm -f /usr/local/bin/sysmon.sh
```
(Optional) Remove the log file:
```bash path=null start=null
sudo rm -f /var/log/sysmon.log
```

## Git workflow (example)
```bash path=null start=null
git checkout -b feat/sysmon-service
git add sysmon.sh sysmon.service install_sysmon_service.sh README.md
git commit -m "feat(sysmon): add Ubuntu systemd service, installer, and docs"
git push -u origin feat/sysmon-service
```
Open a PR against `main`.

## Notes
- The service runs `sysmon.sh -i 30` by default. To change the interval, edit `sysmon.service` and update the `ExecStart` line, then run:
```bash path=null start=null
sudo systemctl daemon-reload
sudo systemctl restart sysmon.service
```
- The script warns when any filesystem usage is ≥ 85%.
- If `/var/log` is not writable, run the script manually with a user-writable `-o` path or via the service (which runs as root by default).
