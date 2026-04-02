# Device Validation Toolkit

## Files
- `collect_qualifying_device_artifacts.ps1`: qualification-first collector with hard stop conditions.
- `scenario_truth_table_template.csv`: required 12-row scenario template.

## Usage
### Qualification only
```powershell
powershell -ExecutionPolicy Bypass -File .\tools\device_validation\collect_qualifying_device_artifacts.ps1 -DeviceId <DEVICE_ID> -DeviceClass airtel_heavy
```

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\device_validation\collect_qualifying_device_artifacts.ps1 -DeviceId <DEVICE_ID> -DeviceClass weak_mid_range
```

### Qualification + runtime artifact collection
```powershell
powershell -ExecutionPolicy Bypass -File .\tools\device_validation\collect_qualifying_device_artifacts.ps1 -DeviceId <DEVICE_ID> -DeviceClass airtel_heavy -CollectRuntime
```

```powershell
powershell -ExecutionPolicy Bypass -File .\tools\device_validation\collect_qualifying_device_artifacts.ps1 -DeviceId <DEVICE_ID> -DeviceClass weak_mid_range -CollectRuntime
```

Optional flags:
- `-ArtifactsRoot <path>`
- `-DateStamp yyyy-MM-dd`
- `-FreshWaitSeconds <int>`
- `-RestoreWaitSeconds <int>`
- `-SkipReboot`

## Output location
`signoff_artifacts/qualifying_device_<YYYY-MM-DD>/<device_class>_<device_id>/`

## Exit codes
- `0`: qualification passed (and runtime collection completed if requested)
- `2`: qualification failed; run rejected
- `3`: runtime package incomplete
