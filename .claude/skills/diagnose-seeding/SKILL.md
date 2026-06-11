---
name: diagnose-seeding
description: Diagnose and fix the "qBittorrent shows seeding but trackers don't credit me" problem. Use when the user reports stalled uploads, trackers not registering them as a seeder, "disconnected" status, missing announces, or after a ProtonVPN reconnect. Walks the read-only diagnostic first, interprets it, then applies the minimal fix.
---

# Diagnose tracker / seeding issues

This project runs qBittorrent behind ProtonVPN with NAT-PMP port forwarding. The
recurring failure: qB shows "seeding" locally but trackers don't credit it. A
ProtonVPN reconnect breaks two things at once — (1) the forwarded port rotates,
and (2) the tunnel interface renumbers, leaving qB bound to a dead interface.

All scripts live in `scripts/` and load credentials from `config.ps1`. Run from
the repo root.

## Step 1 — Diagnose (read-only, always safe)

```powershell
.\scripts\Diagnose-TrackerSeeding.ps1
```

Read the output and identify the failure from these signals:

- **`Connection status : disconnected`** or **`Bound interface`** points at a
  stale `iftype53_NNNNN` value → qB is bound to a dead VPN interface.
- **`NAT-PMP forwarded port`** prints `MISMATCH` against the listen port → the
  forwarded port rotated and qB is announcing the wrong port.
- **Tracker sample shows `NOT WORKING`** with a timeout/connection msg → almost
  always a downstream symptom of one of the two above.
- **`NAT-PMP forwarded port :`** (blank/null) → the VPN tunnel is down; do **not**
  rebind (avoids an IP leak). Tell the user to reconnect ProtonVPN, then re-run.

## Step 2 — Fix (only what the diagnosis points to)

If the port mismatched **or** the interface drifted, run one reconciliation pass.
It fixes both the listen port and the bound interface, renews the NAT-PMP lease,
and force-reannounces:

```powershell
.\scripts\Sync-VpnPort.ps1 -Once
```

If only announces were stale (port + interface already correct), just reannounce:

```powershell
.\scripts\Force-Reannounce-All.ps1
```

## Step 3 — Verify

Re-run the diagnostic and confirm: `Connection status : connected`, listen port
`OK: matches forwarded port`, and the tracker sample shows `WORKING`.

```powershell
.\scripts\Diagnose-TrackerSeeding.ps1
```

## Notes

- The scheduled task `Sync-VpnPort` (registered by `Schedule-VpnPortSync.ps1`)
  normally keeps this reconciled every ~45s. If the problem persists, the task
  may be stopped — check it, and remember that after editing `Sync-VpnPort.ps1`
  the task must be restarted to reload the code.
- See `docs/QBITTORRENT_VPN_BINDING.md` for the full mechanism.
- Never rebind qBittorrent's interface while the VPN is down — leaving the stale
  binding is the safe state (no traffic leaks to the real interface).
