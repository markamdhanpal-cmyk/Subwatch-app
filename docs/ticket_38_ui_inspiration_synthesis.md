# Ticket 38: UI inspiration synthesis and concept exploration

## Research summary

Subscription Killer should borrow from products that make one object unmistakably central, explain trust signals plainly, and keep powerful information compact. The best references here are not finance dashboards. They are object trackers, privacy-first tools, and productivity products that make state legible without making the interface noisy.

Current references reviewed:

- Bobby: subscription tracking framed as fixed-cost objects instead of a broad finance product.
- Rocket Money and newer subscription trackers: useful for recurring-item organization, but risky because they quickly broaden into spending, account-linking, and cancellation-first mental models.
- Proton Mail: strong examples of trust markers, explicit authenticity cues, and calm privacy language.
- Obsidian: strong local-first and ownership framing.
- Flighty: excellent object-centric cards, decisive operational status chips, and compact high-value alert surfaces.
- Linear Mobile: excellent triage hierarchy, compact inbox thinking, and low-noise action surfaces.
- Things 3 and Day One: examples of premium calm, spacing discipline, and surfaces that feel intentional rather than generic.

## Inspiration pattern board

### What visually works

- Object-first cards. Flighty and Bobby make the primary entity obvious immediately. The surface feels designed around the thing itself, not around dashboard chrome.
- Calm but explicit trust framing. Proton pairs privacy claims with specific visible markers, such as an Official badge, instead of vague reassurance.
- Compact triage layers. Linear keeps urgent work visible without letting the whole product become an alarm screen.
- Premium quiet. Things 3 and Day One show that premium can come from rhythm, restraint, and finishing quality instead of heavy gradients or data density.
- Ownership language. Obsidian and Proton both make data ownership and local control legible in plain English.

### What makes these products memorable

- A recognizable primary object system: flights, notes, tasks, entries, subscriptions.
- Signature chips and status markers that look product-specific instead of generic Material defaults.
- Surfaces that imply purpose immediately: inbox, passport, journal, workspace, flight board.
- Confident empty states that still look designed.

### What is risky for Subscription Killer

- Rocket Money-style breadth: account aggregation, budgets, spend charts, concierge cancellation, and “control your finances” framing.
- Calendar-and-spend metaphors that imply broad money management.
- Heavy analytics surfaces that overstate precision for conservative SMS-derived truth.
- Cancellation-first UI that suggests the app knows more than it actually does.
- Ambient monitoring language that conflicts with explicit, manual refresh behavior.

## Patterns to borrow

- Strong service objects with logo, monogram, or brand-colored capsule treatment.
- Compact overview strips that summarize state without competing with the main list.
- More decisive status chips with a product-specific visual language.
- A clearly separated triage lane for user decisions.
- Trust surfaces that use honest labels, provenance, and authenticity-style badges.
- Quiet premium surfaces with crisp tonal layering and consistent spacing rhythm.
- Archive and recovery sections that feel controlled, not accidental.

## Patterns to avoid

- Spend graphs, savings meters, and renewal-cost dashboards.
- Banking palettes, card-balance motifs, or ledger visuals that suggest full financial tracking.
- Account-linking or “all your money in one place” metaphors.
- Cancellation workflows as the dominant CTA.
- Overly playful motion or lifestyle-brand visuals that weaken seriousness.
- Dense settings-like control panels that make the product feel administrative instead of trustworthy.

## Visual concepts

### Concept 1: Service Passport Console

Overall feel:
Premium utility with object-first cards and a calm operational layer. Think private registry plus compact trust console.

Why it fits:
Subscriptions are the product’s primary objects. This concept makes each service feel distinct and memorable without implying more certainty than the app actually has.

Signature surfaces and components:

- Passport-style service cards with a logo or monogram medallion, service title, subtitle, and compact state stamps.
- A top trust deck that reads like the current snapshot certificate for the screen.
- A narrow overview register with four compact state counters.
- Review cards as decision dossiers, clearly separated from confirmed services.

Top area and dashboard structure:

- Trust deck first.
- Compact register strip second.
- Review Decisions.
- Confirmed Subscriptions.
- Observed Signals.
- Trials and Benefits.
- Recovery trays.

Service-card style:

- High-contrast object cards with brand/monogram anchor on the left.
- Small state stamps on the right.
- Tighter subtitle treatment and stronger object silhouette.

Review-card style:

- Dossier cards with an amber edge accent, decision badge, plain-language rationale box, and explicit reversible actions in the footer.

Empty-state style:

- “Designed blank” cards with a smaller icon seal, concise message, and more formal tone than friendly placeholder copy.

Risk and tradeoff:

- Requires disciplined icon/logo handling so the object system feels premium and not random.
- Needs care so “passport” cues stay subtle and do not become decorative gimmicks.

### Concept 2: Quiet Triage Studio

Overall feel:
A more editorial, productivity-led interface with stronger list rhythm and a lighter, sharper dashboard shell.

Why it fits:
It emphasizes the review and decision model clearly, which reinforces the trust-first philosophy.

Signature surfaces and components:

- A slim triage ribbon for what needs attention now.
- Section containers that feel like curated workspaces rather than cards stacked on cards.
- Reduced ornament, stronger type, and cleaner separators.

Top area and dashboard structure:

- Snapshot ribbon.
- Review Decisions as the main anchor.
- Confirmed list.
- Secondary signals and recovery underneath.

Service-card style:

- Leaner list rows with stronger typography and small medallions instead of large cards.

Review-card style:

- Tighter, form-like layouts inspired by Linear issue triage.

Empty-state style:

- Minimal, editorial blank states with fine-line icons and short support text.

Risk and tradeoff:

- Could become too productivity-tool-like and lose distinctiveness if the service objects are not strong enough.

### Concept 3: Private Ledger Gallery

Overall feel:
A calmer archival interface inspired by premium journaling and local-first note tools. Softer, more reflective, more “your private record”.

Why it fits:
It reinforces local-first ownership and restore semantics better than most adjacent categories.

Signature surfaces and components:

- Snapshot cards that feel archival and trustworthy.
- Section headers with quieter museum-label styling.
- Recovery and history sections framed as part of a private archive.

Top area and dashboard structure:

- Provenance gallery card first.
- Service collections below.

Service-card style:

- Softer surface blocks with more white space and understated labels.

Review-card style:

- Evidence cards with softer caution treatment and more explanatory copy.

Empty-state style:

- Intentionally sparse, almost journal-like blank states.

Risk and tradeoff:

- Could undersell actionability and feel too gentle for the explicit review workflow.

## Recommended concept

### Recommendation: Service Passport Console

This is the best fit for Subscription Killer because it solves the current “clean but basic utility” problem without pushing the product into finance or generic productivity territory.

Why it is the best fit:

- It makes subscriptions feel like recognizable objects, which is the clearest way to make the product more distinctive.
- It keeps the trust/status layer strong. The top area can behave like a snapshot certificate, which matches the app’s fresh/restored/demo/fallback semantics exactly.
- It gives review decisions a more formal, safer-looking presentation. That helps users understand that non-confirmation is intentional.
- It is implementation-friendly. Ticket 36 and 37 already introduced premium surfaces and tonal layering, so this direction builds on the current shell instead of replacing it.

Why it feels less basic:

- The interface would have a signature object card language.
- The top area would become a branded trust artifact instead of a generic status panel.
- Chips and counters would become product-specific stamps and registers rather than default dashboard tiles.

Why it stays aligned with trust-first behavior:

- It emphasizes object identity, provenance, and decision state.
- It does not need charts, spend totals, or predictive money language.
- It visually preserves the difference between confirmed, reviewed, observed, and restored states.

## Product-specific UI direction for Service Passport Console

### Top trust and status area

- Turn the current hero into a snapshot certificate deck.
- Left side: current snapshot title and plain-language explanation.
- Right side or lower strip: provenance stamp, freshness stamp, and source-availability stamp.
- Use one dominant trust accent at a time based on state: fresh, restored, caution, unavailable, or demo.
- Replace duplicated copy with short status stamps plus one clear sentence of explanation.

### Summary strip

- Keep it, but make it feel like a register rather than a dashboard.
- Use compact counters with short nouns: Confirmed, Decisions, Signals, Recovery.
- Reduce captions to one line each.
- Visually subordinate it beneath the trust deck.

### Confirmed subscriptions

- Present as the strongest object cards in the product.
- Add service avatars or brand-colored monograms where safe.
- Use a stable right-edge stamp such as Confirmed.
- Keep subtitles short and factual.
- Avoid cost-led emphasis.

### Review decisions

- Make this the most formal section after the trust deck.
- Card structure:
  - service object header
  - decision-required stamp
  - rationale slab
  - confirm/hide actions in a dedicated footer
- Use a more distinct caution edge or inset band so it reads differently from confirmed services immediately.

### Observed signals

- Treat these as quieter object cards, not action cards.
- Lower saturation and fewer badges than review decisions.
- Keep them clearly separate from confirmed services and from the review queue.

### Trials and bundled benefits

- Use a lighter accent family than confirmed subscriptions.
- Present as “separate access” cards, not weaker confirmed cards.
- Avoid visual cues that imply they are one step away from auto-confirmation.

### Hidden and recovery sections

- Frame them as archive trays.
- Use tighter cards and calmer tinting.
- Keep Undo visible but secondary.
- Make “you changed this” explicit through a stamp-like label.

### Chips, badges, and buttons

- Shift from generic pills to stamp-style markers with a slightly more formal cadence.
- Use chips primarily for truth/state, not decoration.
- Keep primary actions compact and decisive.
- Keep secondary actions quieter and lighter.

### Empty states

- Keep them small and composed.
- Use a subtle seal or medallion instead of large utility icons.
- Phrase them like a calm registry: nothing waiting, nothing confirmed yet, no observed signals right now.

### Tone, spacing, contrast, and identity

- Tone: private registry, not finance console.
- Spacing: compact vertical rhythm with strong object grouping.
- Contrast: crisp separation between page, section, and nested cards.
- Identity: teal trust accent, amber decision accent, slate archive accent, with stronger object color moments on service cards.
- Typography: stronger uppercase/eyebrow system, tighter support text, and more confident card titles.

## Next implementation ticket recommendation

### Ticket 39: implement Service Passport Console object system

Scope for the next implementation ticket:

- Introduce a service avatar or monogram system for dashboard objects.
- Redesign the trust deck into a snapshot certificate surface.
- Replace the current summary tiles with a compact register strip.
- Rework confirmed, review, observed, and recovery cards into the Service Passport component family.
- Keep all runtime logic and truth mapping unchanged.

## Concept direction summary

Service Passport Console: object-first, trust-stamped, premium local snapshot dashboard.

## Source references

- Bobby: https://bobbyapp.co/
- Rocket Money subscriptions: https://www.rocketmoney.com/feature/manage-subscriptions
- Proton Mail redesign: https://proton.me/blog/new-mail-apps
- Proton Official badge: https://proton.me/support/what-does-official-in-proton-emails-mean
- Flighty: https://flighty.com/
- Linear Mobile: https://linear.app/mobile
- Things: https://culturedcode.com/
- Day One: https://dayoneapp.com/
- Obsidian home: https://obsidian.md/
- Obsidian manifesto: https://obsidian.md/about
