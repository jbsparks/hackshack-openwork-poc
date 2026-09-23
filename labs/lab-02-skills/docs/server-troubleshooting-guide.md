# Server Troubleshooting Guide

## Overview
This guide covers common Linux server issues and diagnostic steps for production environments.

## Issue 1: High CPU Usage (>90% sustained)

### Diagnostic Steps
1. Check which processes are consuming CPU:
   - Run `top -o %CPU` or `htop`
   - Look for runaway processes or zombie processes
2. Check system load averages:
   - Run `uptime` -- load should be below the number of CPU cores
   - If load > 2x cores, the system is overloaded
3. Check for CPU throttling:
   - Run `cat /proc/cpuinfo | grep MHz`
   - Compare current MHz to maximum -- thermal throttling reduces speed

### Resolution
- If a single process is the cause: restart the service or investigate the application
- If system-wide: check for resource contention, consider scaling horizontally
- If thermal: check fan status and ambient temperature in the data center

## Issue 2: Memory Pressure

### Diagnostic Steps
1. Check memory usage:
   - Run `free -h` -- look at "available" column, not "free"
   - Available < 500MB on a server with 64GB+ RAM = investigate
2. Check for memory leaks:
   - Run `ps aux --sort=-%mem | head -20`
   - If a process grows continuously over time, it may have a memory leak
3. Check swap usage:
   - Run `swapon --show`
   - Any swap usage on a server with 64GB+ RAM = something is wrong

### Resolution
- Kill or restart leaking processes
- Add swap as a temporary buffer: `fallocate -l 8G /swapfile && mkswap /swapfile && swapon /swapfile`
- Long-term: increase physical RAM or fix the application leak

## Issue 3: Disk Space Exhaustion

### Diagnostic Steps
1. Check disk usage:
   - Run `df -h` -- look for filesystems at >90%
2. Find large files:
   - Run `du -sh /* | sort -rh | head -10`
   - Common culprits: `/var/log`, `/tmp`, core dumps
3. Check for deleted-but-open files:
   - Run `lsof +L1` -- these files consume space but don't show in `du`

### Resolution
- Rotate or truncate logs: `truncate -s 0 /var/log/large-log-file.log`
- Clean package caches: `apt clean` or `yum clean all`
- Remove old kernels: `apt autoremove`
- If deleted-but-open: restart the service holding the file handle

## Issue 4: Network Connectivity Problems

### Diagnostic Steps
1. Check interface status:
   - Run `ip link show` -- all interfaces should be UP
   - Run `ethtool <interface>` -- check link speed and duplex
2. Check routing:
   - Run `ip route show` -- verify default gateway exists
   - Run `ping <gateway-ip>` -- verify gateway is reachable
3. Check DNS:
   - Run `nslookup google.com` or `dig google.com`
   - If DNS fails: check `/etc/resolv.conf`
4. Check for packet loss:
   - Run `mtr <destination>` -- shows hop-by-hop packet loss

### Resolution
- Interface down: `ip link set <interface> up`
- Wrong gateway: `ip route add default via <gateway-ip>`
- DNS failure: add working nameserver to `/etc/resolv.conf`
- Packet loss at a specific hop: contact network team with MTR output

## Escalation

If none of the above resolves the issue:
1. Collect system logs: `journalctl --since "1 hour ago" > /tmp/syslog-export.txt`
2. Capture hardware diagnostics: `dmidecode > /tmp/hw-info.txt`
3. Open a support ticket with the logs and diagnostic output
