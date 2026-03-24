# Manual Verification Scripts

These scripts cover UI and interaction scenarios that are difficult to automate reliably or require visual inspection for "feel" and correctness.

## 1. Font Scaling & Accessibility
**Location**: Home Dashboard, Subscriptions List, Service Details.

1.  **System Setting**: Set Android/iOS "Font Size" and "Display Size" to Maximum.
2.  **Verification**:
    - [ ] **Home Dashboard**: Total spend figure (hero) does not clip or overflow its card.
    - [ ] **Subscription Chips**: Currency symbols (₹) and amounts are vertically aligned and fully visible.
    - [ ] **Labels**: Secondary text ("Next renewal", "Monthly") does not overlap with titles.
    - [ ] **Touch Targets**: Buttons (Add, Filter, Destination tabs) remain large enough to tap easily (>48dp).

## 2. Android System Back Gesture
**Location**: Any Modal Bottom Sheet (e.g., Manual Editor, Service Details, Help & Privacy).

1.  **Action**: Open the "Add Manual Subscription" form.
2.  **Gesture**: Perform the system "Back" swipe (edge-to-center) or press the Back button.
3.  **Verification**:
    - [ ] The bottom sheet closes smoothly.
    - [ ] The app DOES NOT exit to the home screen.
    - [ ] Any unsaved changes prompt a confirmation (if implemented) or discard safely.

## 3. Local Renewal Reminder UI
**Location**: Service Detail View.

1.  **Setup**: Open a service detail (manual or detected).
2.  **Action**: Tap "Set local reminder".
3.  **Verification**:
    - [ ] Preset chips (1 day, 3 days, 1 week) are visible.
    - [ ] Tapping a preset highlights it immediately.
    - [ ] Tapping "Remove reminder" clears the selection and closes the panel.
    - [ ] The "Reminders" section on the Home tab updates to show the newly set reminder.

## 4. Large Inbox Responsiveness (Feeling)
**Location**: Home Dashboard.

1.  **Setup**: Use the `SampleLocalMessageSource` or a test device with 1000+ messages.
2.  **Verification**:
    - [ ] Scrolling the dashboard is "buttery smooth" (fixed 60/120fps feel).
    - [ ] Tapping a destination (e.g., Subscriptions) switches tabs in <200ms.
    - [ ] No "ANR" (App Not Responding) dialogs appear during initial sync.
