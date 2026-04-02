# Qualifying-Device Release Unblock Runbook

## Quick diagnosis
- Release is blocked by missing qualifying-device proof only.
- Do not change detector logic for this phase.
- Required classes:
  - Airtel-heavy physical Android
  - Weak/mid-range physical Android

## Qualification rules (hard pass/fail)
### Airtel-heavy
- Physical Android only (not emulator).
- `airtel_share = airtel / (airtel + jio) >= 0.55`.
- `airtel_count >= 300`.
- Airtel bundle/noise evidence present (`wynk`, promo, Hindi/Hinglish telecom wording).

### Weak/mid-range
- Physical Android only (not emulator).
- Must be clearly lower class than prior 11.6 GB device.
- `MemTotal` captured from `/proc/meminfo`.
- Recommended: `MemTotal <= 8,500,000 kB`.
- Preferred: `MemTotal <= 6,500,000 kB`.

### Immediate reject examples
- Emulator.
- Mixed Airtel/Jio corpus with `airtel_share < 0.55`.
- High-memory handset close to `~11.6 GB`.
- Missing `device_info.txt` or `corpus_counts.txt`.

## Sourcing (easiest first)
1. Borrow friend/family handset.
2. Temporary tester device swap (1-2 days).
3. Recruit two testers in parallel (Airtel-heavy + weak/mid-range).
4. Buy used low-cost Android for weak/mid-range reproducibility.

## Pre-run readiness checklist
- `adb devices -l` shows physical device.
- App installed and launch verified.
- SMS permission granted.
- Artifact folder path ready.
- Qualification capture ready:
  - `ro.product.model`
  - `gsm.sim.operator.alpha`
  - `/proc/meminfo`
  - `ro.config.low_ram`
- SMS corpus count capture ready.
- Scenario CSV template ready.
- Screenshot capture step ready.

## Artifact structure (per qualifying run)
- `signoff_artifacts/qualifying_device_<YYYY-MM-DD>/<device_class>_<device_id>/`
  - `device_info.txt` (mandatory)
  - `corpus_counts.txt` (mandatory)
  - `qualification_verdict.txt` (mandatory)
  - `log_fresh.txt` (mandatory)
  - `log_force_kill.txt` (mandatory)
  - `log_reboot.txt` (mandatory; if skipped, include reason)
  - `snapshot_fresh.json` (mandatory)
  - `snapshot_force_kill.json` (mandatory)
  - `snapshot_reboot.json` (mandatory; if skipped, include reason)
  - `timing_fresh_ms.txt` (mandatory)
  - `timing_restore_ms.txt` (mandatory)
  - `scenario_truth_table.csv` (mandatory)
  - `dashboard.png` (mandatory)
  - `review_queue.png` (mandatory when review queue non-empty)
  - `usability_notes.txt` (mandatory for weak/mid-range)

## Zero-code execution order
1. Capture qualification evidence.
2. Capture corpus counts.
3. Stop immediately on qualification fail.
4. Fresh scan logs + timing.
5. Snapshot + dashboard screenshot.
6. Force-kill relaunch logs + restore timing + snapshot.
7. Reboot relaunch logs + snapshot.
8. Review screenshot.
9. Fill all 12 scenario rows.
10. Verify mandatory file completeness.

## Stop conditions
- Device fails class qualification.
- Missing mandatory files.
- Missing scenario rows.
- Reboot step skipped without written reason.

## Final hold rule
- Release remains blocked until both qualifying classes are complete with full mandatory bundles.
