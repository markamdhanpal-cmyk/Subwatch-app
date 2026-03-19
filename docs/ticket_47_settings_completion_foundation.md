# Ticket 47: Settings and Completion Foundation

## Scope
- Add a dedicated settings entry point from the main dashboard shell.
- Build a settings home for the current completion surfaces.
- Add small supporting sheets for Help, Privacy & Local Data, About SubWatch, and Feedback / Report Issue.
- Show the current packaged app version and build label in settings.

## Layer placement
- Domain: unchanged.
- Application: unchanged.
- Storage: unchanged.
- Platform/runtime: unchanged.
- Presentation: settings entry, settings home, and informational sheets.

## Notes
- Feedback is intentionally an informational surface only in this build.
- No settings toggles were added because no safe user preferences are wired yet.
- The version/build section is static and scoped to the current packaged build metadata for this ticket.
