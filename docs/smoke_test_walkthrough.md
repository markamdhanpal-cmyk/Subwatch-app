# Smoke Test Walkthrough: SubWatch Android

We have completed a strict real-device smoke pass of SubWatch on a **Motorola Edge 50 Fusion (Android 14)**.

## High-Level Verdict
> [!IMPORTANT]
> **READY FOR CLOSED BETA**
> All critical paths (Permissions -> Scanning -> Identification -> Resolution -> Data Management) are functional on a real device with live Indian telecom and subscription data.

---

## 1. Onboarding & Permissions
Verified the transition from the rationale sheet to the native Android permission dialog.

- **Status**: PASSED
- **Observation**: The app correctly handles the "Try again" trigger for native permissions.
- **Note**: The initial "First run" onboarding sheet was skipped in favor of the rationale sheet due to the native layer reporting `denied` for the initial "not yet asked" state.

````carousel
![Permission Rationale](file:///d:/WorkSpace/permission_rationale.png)
<!-- slide -->
![Scanning State](file:///d:/WorkSpace/scanning_state.png)
````

---

## 2. SMS Scanning & Identification
Successfully scanned 250 messages from the device. The app correctly identified both bundled telecom benefits and paid subscriptions.

- **Status**: PASSED
- **Findings**:
    - **Jio Bundles**: Correctly classified and resolved to the `Trials & Benefits` section.
    - **Paid Subscriptions**: Netflix and Spotify were successfully identified and shown in the main list.

````carousel
![Subscriptions List](file:///d:/WorkSpace/subs_tab.png)
<!-- slide -->
![Trials & Benefits Expanded](file:///d:/WorkSpace/subs_expanded.png)
````

---

## 3. Data Management & UI
Verified the "Clear all data" flow and manual subscription creation.

- **Status**: PASSED
- **Clear All Data**: Successfully wiped all local summaries and returned the app to the initial scan state.
- **Manual Entry**: Verified that users can add subscriptions manually (e.g., Netflix) and they appear in the "Added by you" section.

````carousel
![Clear Data Confirmation](file:///d:/WorkSpace/clear_data_dialog.png)
<!-- slide -->
![Manual Entry Form](file:///d:/WorkSpace/manual_entry.png)
<!-- slide -->
![Manual Entry Finalized](file:///d:/WorkSpace/manual_finished.png)
````

---

## 4. Accessibility & Navigation
Tested system back gestures, rich content descriptions, and large text behavior.

- **Status**: PASSED (Minor UX Notes)
- **TalkBack**: Content descriptions for subscription cards are comprehensive, providing full state and action context.
- **Large Text**: At 2.0x font scale, the UI remains functional, though some bottom navigation labels and card subtitles exhibit truncation.

![Large Text 2.0x](file:///d:/WorkSpace/large_text.png)

---

## Summary of Fixes During Pass
1.  **Build**: Added missing `package` attribute to `AndroidManifest.xml`.
2.  **Code**: Fixed dangling `return` and syntax errors in `dashboard_shell_shared.dart`.
3.  **Permissions**: Corrected logic in `LocalMessageSourceCapabilityChannelHandler.kt` to allow "Try again" to trigger native dialogs.
4.  **Cleaning**: All debug logging and temporary imports have been removed.
