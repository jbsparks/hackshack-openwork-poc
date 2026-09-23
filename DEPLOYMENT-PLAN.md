# WoD Deployment Plan — Stock Install on Proxmox

**Status:** DRAFT FOR REVIEW — nothing executed
**Approach:** Stock Workshops-on-Demand, three VMs, one tier each, per upstream docs
**Scope:** Single user (1 concurrent student) proof-of-concept
**Host:** Proxmox `pve91-1` @ `192.168.10.8:8006` (root@pam)

---

## 1. Decision summary

| Item | Decision |
|---|---|
| Method | **Stock WoD install**, unmodified, per upstream docs |
| Topology | **3 VMs, one tier each** — the only layout the installer supports |
| QScale | **Not used.** Student containers run on the WoD backend via Docker. |
| Scale | **1 concurrent user** |
| WoD admin user | `wodmgr` (admin's preference; `wodadmin` also acceptable) |
| Local OS user | `bill` on all three VMs |

### Why three VMs, not one

`install.sh` is one-tier-per-host by design:

```bash
userdel -f -r $WODUSER      # install.sh:42 — deletes the WoD user AND its home
rm -rf $WODHDIR             # install.sh:46
```

then `install-system-common.sh` clones **only** the current type's repos. On a single host:
api-db → frontend **wipes api-db** → backend **wipes frontend**. Only the backend survives,
and `/etc/wod.sh` holds a single `WODTYPE`, so all derived paths resolve to it.

---

## 2. Allocated environment (per admin email)

### 2.1 Hypervisor budget
| Resource | Available | This plan uses |
|---|---|---|
| RAM | 256 GB | 28 GB |
| CPU | 32 cores | 14 |
| **VM disk** | **180 GB total** | **160 GB** (see §2.3) |

### 2.2 VM assignments — fixed by admin

| VM | FQDN | IP | Role |
|---|---|---|---|
| `bill-wod-backend` | `bill-wod-backend.hpedevlab.local` | 192.168.10.61 | JupyterHub / backend |
| `bill-wod-apidb` | `bill-wod-apidb.hpedevlab.local` | 192.168.10.62 | API + PostgreSQL |
| `bill-wod-frontend` | `bill-wod-frontend.hpedevlab.local` | 192.168.10.63 | Portal |

Gateway `192.168.10.250` · DNS `192.168.10.120` · Netmask assumed `/24`

> **❓ Confirm with admin:** the email reads `.hpedevlab.localgre` — assumed a typo for
> `.hpedevlab.local`. Getting this wrong means reinstalling, since WoD bakes FQDNs into
> config at install time.

### 2.3 ⚠️ Disk is the binding constraint

Admin allows **40 GB per VM** (180 GB total pool). The backend is the problem:

| Consumer | Approx |
|---|---|
| Ubuntu 24.04 minimized | 3 GB |
| conda | 3 GB |
| texlive-xetex + fonts | 2-4 GB |
| rust/cargo, golang, clang, cmake, JDK/JRE | 4-5 GB |
| nodejs/npm, firefox, misc | 2 GB |
| JupyterHub venv + pip packages | 2-3 GB |
| **Subtotal — stock WoD backend** | **~18-22 GB** |
| Docker + tutorial image (1.6 GB + layers) | 4-5 GB |
| Student home dirs, logs, apt cache | 2-3 GB |
| **Total** | **~26-32 GB of 40 GB** |

Workable but with little headroom, and an install that runs out of disk 90 minutes in is a
painful failure.

**Decision (2026-09-15): backend stays at 40 GB.** Estimated usage ~26-32 GB leaves
~8-14 GB headroom — workable. The pool has 60 GB unallocated (3 × 40 = 120 of 180), so
expansion is available if needed.

**Disk can be grown live — this decision is not final.** On the Proxmox host:
```bash
qm resize <vmid> scsi0 +20G          # safe while the VM is running
```
then inside the VM (Ubuntu uses LVM by default):
```bash
sudo growpart /dev/sda 3
sudo pvresize /dev/sda3
sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
```

**Mitigations while at 40 GB:**
- `WODUSERMAX: 10` (Phase 3) — avoids 100 unused student home dirs
- Run `watch -n30 df -h /` in a second session during Phase 4
- `sudo apt clean` after install
- If usage crosses ~85%, expand mid-flight rather than letting the install fail
- Build the tutorial Docker image elsewhere and `docker load` it, avoiding build-layer
  overhead on the backend (saves 2-3 GB)

### 2.4 VM specs

| VM | vCPU | RAM | Disk | Service port |
|---|---|---|---|---|
| `bill-wod-backend` | 8 | 16 GB | **40 GB** | 8000 + postfix 10025 |
| `bill-wod-apidb` | 4 | 8 GB | 40 GB | 8021 |
| `bill-wod-frontend` | **4** | 4 GB | 40 GB | 8080 |
| **Total** | **16 / 32** | **28 / 256 GB** | **120 / 180 GB** (60 GB spare) | |

RAM and CPU are generous — the hypervisor has ample headroom, and disk is the only squeeze.
Frontend uses 8080 because backend and frontend both default to 8000.

> **Note (applied 2026-09-15):** frontend raised 2 → 4 vCPU. At 2 vCPU it was too slow —
> the portal is a React/Grommet app and both `npm install` and the production bundle build
> are CPU-bound. 4 vCPU is the practical floor for any Node-build tier here.
>
> **If `bill-wod-apidb` also feels slow, raise it to 6-8 vCPU** — it runs `npm install` too.
> At 16/32 cores used there is ample headroom; CPU is not the scarce resource, disk is.
> Proxmox allows changing vCPU on a stopped VM at any time, so this is cheap to adjust.

### 2.5 Access path
```
Laptop ──RDP──▶ 16.1.32.223:10500 (Windows jump box) ──Chrome──▶ 192.168.10.8:8006
                                                              └─▶ 192.168.10.61/62/63
```
Single user → workshop driven from the jump box browser. No external exposure needed.

---

## 3. Phases

### Phase 1 — Ubuntu template (30 min)
Admin has already uploaded Ubuntu Server ISOs to `local`.

1. **Create VM**: Ubuntu ISO · Linux 6.x · Qemu Agent ✓ · 40 GB · 2 cores · 4096 MB ·
   bridge `vmbr0` · VirtIO
2. Install **Ubuntu Server (minimized)**, enable **OpenSSH server**, create user **`bill`**
   with sudo
3. First boot:
   ```bash
   sudo apt update && sudo apt install -y git qemu-guest-agent
   ```
4. Shut down → right-click → **Convert to template**

### Phase 2 — Clone and configure (20 min)
Full-clone ×3. For each, set hostname, resize CPU/RAM/disk per §2.4, and apply netplan:

```yaml
# /etc/netplan/00-wod.yaml   (backend shown; .62 / .63 for the others)
network:
  version: 2
  ethernets:
    ens18:
      addresses: [192.168.10.61/24]
      routes:
        - to: default
          via: 192.168.10.250
      nameservers:
        addresses: [192.168.10.120]
        search: [hpedevlab.local]
```
```bash
sudo netplan apply
sudo hostnamectl set-hostname bill-wod-backend.hpedevlab.local
```

Add all three to `/etc/hosts` on **every** VM (belt and braces — `install.sh` resolves the
backend FQDN by `ping`):
```
192.168.10.61  bill-wod-backend.hpedevlab.local  bill-wod-backend
192.168.10.62  bill-wod-apidb.hpedevlab.local    bill-wod-apidb
192.168.10.63  bill-wod-frontend.hpedevlab.local bill-wod-frontend
```

**Gate — all three VMs must pass:**
```bash
hostname -f                                   # full FQDN
ping -c1 bill-wod-backend.hpedevlab.local     # and the other two
for u in https://github.com https://pypi.org https://registry.npmjs.org \
         https://repo.anaconda.com https://apt.releases.hashicorp.com \
         https://opencode.ai ; do
  curl -sS -o /dev/null -w "$u %{http_code}\n" --max-time 10 "$u"; done
df -h /
```
`opencode.ai` matters because these VMs have **no GPU** — the workshop needs external Zen models.

**📸 Snapshot all three VMs here.** Failed install → 30-second rollback.

### Phase 3 — Pre-install config (10 min, each VM)
```bash
git clone https://github.com/Workshops-on-Demand/wod-install
cd wod-install/install
cat > install.priv <<'EOF'
source "$EXEPATH/install.repo"
export WODPGPASSWD='<strong-unique>'
export WODAPIDBUSERPWD='<strong-unique>'
export WODAPIDBADMINPWD='<strong-unique>'
EOF
chmod 600 install.priv
```
> Installer ships weak hardcoded defaults for `WODPGPASSWD` / `WODAPIDBADMINPWD` and admin
> names `moderator` / `hackshack`. Override them.

Edit `wod-install/ansible/group_vars/all.yml`:
```yaml
WODUSERMAX: 10        # default 100 — pointless for one user, slow, and eats disk
```

### Phase 4 — Install in order (2-3 hr)

```bash
# ── 1. On bill-wod-apidb (192.168.10.62) ──
sudo ./install.sh -t api-db \
  -a bill-wod-apidb.hpedevlab.local:8021 \
  -f bill-wod-frontend.hpedevlab.local:8080 \
  -b bill-wod-backend.hpedevlab.local:8000 \
  -g test -u wodmgr -p 10025 \
  -s wodmailer@bill-wod-backend.hpedevlab.local

# ── 2. On bill-wod-frontend (192.168.10.63) ──
sudo ./install.sh -t frontend \
  -a bill-wod-apidb.hpedevlab.local:8021 \
  -f bill-wod-frontend.hpedevlab.local:8080 \
  -g test -u wodmgr -p 10025 \
  -s wodmailer@bill-wod-backend.hpedevlab.local

# ── 3. On bill-wod-backend (192.168.10.61) — longest, 1-2 hr ──
sudo ./install.sh -t backend \
  -a bill-wod-apidb.hpedevlab.local:8021 \
  -f bill-wod-frontend.hpedevlab.local:8080 \
  -b bill-wod-backend.hpedevlab.local:8000 -n 1 \
  -i 192.168.10.61 \
  -g test -u wodmgr -p 10025 \
  -s wodmailer@bill-wod-backend.hpedevlab.local
```

`-i 192.168.10.61` is included because `install.sh` otherwise derives the backend IP by
`ping`; passing it explicitly avoids any DNS ambiguity.

Watch disk on the backend during install: `watch -n30 df -h /`

**Gate:** `systemctl status jupyterhub postfix` on backend · API on `:8021` ·
portal on `:8080` · `~/.wodinstall/` holds logs + the generated `wodmgr` password.

### Phase 5 — Smoke test with a STOCK workshop (30 min)
From the jump box, browse `http://bill-wod-frontend.hpedevlab.local:8080`, register for
e.g. `WKSHP-Python101`, and confirm: student assigned → emails → notebook deployed →
JupyterHub login → CLEANUP on expiry.

**Validate stock WoD before adding WKSHP-OpenWork** — it isolates WoD problems from
workshop problems. Debugging both at once is miserable.

### Phase 6 — Add WKSHP-OpenWork (separate — see §5)

---

## 4. Risks

| Risk | Sev | Mitigation |
|---|---|---|
| **Backend runs out of disk at 40 GB** | **Med** | ~26-32 GB est. of 40. Monitor `df -h` in Phase 4; `qm resize` grows it live (§2.3). 60 GB spare in pool. |
| Wrong FQDN domain (`.local` vs `.localgre`) | **High** | Confirm with admin before Phase 2 — baked in at install time. |
| Installer re-run wipes a prior tier | High | One tier per VM. Never run twice on a host. |
| No internet egress from VMs | High | Phase 2 gate. |
| Backend install fails midway | Med | Snapshot before Phase 4. |
| Weak default secrets | Med | `install.priv` (Phase 3). |
| `opencode.ai` unreachable | Med | Tested in Phase 2. No GPU on these VMs, so Zen is required for the workshop. |
| DNS lacks the FQDNs | Low | `/etc/hosts` on all three + `-i` flag. |

---

## 5. WKSHP-OpenWork integration (after Phase 5 passes)

Current repo files will not work as-is:

| Action | File | Reason |
|---|---|---|
| DELETE | `WKSHP-OpenWork/wod.conf` | Not a WoD format. Real workshops ship `wod.yml` + `import.json`. Keys like `YOURWKSHPAPPLIANCE_*` exist nowhere in WoD. |
| ADD | `WKSHP-OpenWork/wod.yml` | YAML 1.1; `range: [1,5]`, `capacity: 5`, `duration: 2` (**hours**) |
| ADD | `WKSHP-OpenWork/import.json` | DB seeder record |
| DELETE | `wod-scripts/{create,cleanup,reset}-appliance.sh` | **Names collide with core WoD scripts.** |
| ADD | `create-WKSHP-OpenWork.sh.j2` + `cleanup-`/`reset-` → `~wodmgr/wod-backend/scripts/` | `procmail-action.sh` discovers by filename `create-$ws.sh` |
| FIX | `0-ReadMeFirst.ipynb` | `{{ YOURWKSHPBE }}` isn't real — use `{{ WODBEEXTFQDN }}` / `{{ HTTPPORT }}` |

**Interface contract** (from upstream source): appliance scripts take **no arguments**.
Context arrives as exported env vars — `$stdid`, `$wid`, `$w`, `$ws`, `$randompw`,
`$WODRTARGET` — and scripts `source functions.sh`. Current scripts read `$1`/`$2` and would
fail immediately. Ports must be range-normalized:
`port = $stdid - $(wod_get_range_min $wid) + BASE`.

Model on `create-WKSHP-Docker101.sh.j2` / `create-WKSHP-ML101.sh.j2`, which already do
docker-run-per-student with port arithmetic.

---

## 6. Repo documentation corrections (independent)

1. **Never run `build.sh` off the HPE VPN.** Line 54 `rm -rf "$INSTROSPECT_DIR"` runs
   *before* the clone → deletes vendored `instrospect/`, then fails.
   Recover: `git checkout -- instrospect/`. **Use `docker build .`**
2. **instrospect is vendored, not gitignored** — 51 tracked files; `skill_review.py` 970
   lines, `bootstrap.py` 2620 lines, no stub markers. **Lab 2D works without VPN.**
   `ARCHITECTURE.md` §2.2/§12 and `TLDR.md` are stale.
3. `make build-quick` is obsolete.
4. `.qscale-creds.json` was untracked but **not ignored** — `.gitignore` now covers
   `*-creds.json`, `install.priv`, `*.kubeconfig`.

---

## 7. Rollback
Restore the Phase 2 snapshot. Full reset: delete all three VMs, re-clone (~5 min).

---

## 8. Time estimate

| Phase | Duration |
|---|---|
| 1 Ubuntu template | 30 min |
| 2 Clone + network + snapshot | 20 min |
| 3 Pre-install config | 10 min |
| 4 Install 3 tiers | 2-3 hr |
| 5 Smoke test (stock workshop) | 30 min |
| **Total** | **~4 hr** |
| 6 WKSHP-OpenWork | +4 hr, separate |

---

## 9. Questions for the admin

1. **Is the domain `hpedevlab.local`?** The email reads `.hpedevlab.localgre` — assumed a
   typo. Must be right before install.
2. ~~Backend disk size~~ — **RESOLVED: staying at 40 GB**, expandable live via `qm resize`.
3. **Are the three FQDNs registered in DNS at `192.168.10.120`,** or should we rely on
   `/etc/hosts`?
4. **Netmask confirmation** — assumed `/24`.
5. **Outbound internet from the `192.168.10.x` VMs?** The installer pulls ~80 packages, and
   the workshop needs `opencode.ai` (no GPU on these VMs).
