# Waddle — Claude Code Project Guide

> Run–Walk interval timer for iOS. Simple, playful, zero pressure.
> Tagline: "No shame in the waddle." 🐧

---

## Spec & Source of Truth

The full design and technical specification lives in `Waddle-Spec.docx` in this
project folder. Read it before implementing anything. It covers brand, colours,
screen layouts, architecture, data models, audio strategy, and milestones.

---

## Project State

Track the current milestone here. Update this line after each milestone is confirmed.

**Current milestone: 7 — Live Activity & Dynamic Island**

| # | Milestone              | Status  |
|---|------------------------|---------|
| 1 | Static UI shell        | ✅ Complete |
| 2 | Timer engine           | ✅ Complete |
| 3 | Phase switching + modes| ✅ Complete |
| 4 | Voice prompts          | ✅ Complete |
| 5 | Background + lock screen | ✅ Complete |
| 6 | Polish                 | ✅ Complete |
| 7 | Live Activity + Dynamic Island | ✅ Complete |

**Rule: complete and confirm one milestone before starting the next.**

---

## Architecture

Pattern: **MVVM**. No exceptions.

```
Views → observe → IntervalViewModel → owns → TimerService
                                     └────→ SpeechService
                                               ↓
                                      AudioSessionManager
```

- Views never own business logic or timers
- `IntervalViewModel` is the single source of truth for all workout state
- Services are owned by the ViewModel — not singletons, not accessible to Views directly
- `@StateObject` in the root view, `@ObservedObject` in child views

---

## Folder Structure

All new files must go in the correct folder. Do not deviate.

```
Waddle/
├── App/WaddleApp.swift
├── Models/          (WorkoutSettings, WorkoutState, IntervalMode)
├── ViewModels/      (IntervalViewModel)
├── Services/        (TimerService, SpeechService, AudioSessionManager)
├── Views/           (HomeView, SetupView, ActiveView, DoneView)
│   └── Components/  (PhaseIndicator, CircularTimer, CycleProgress)
└── Utilities/       (TimeFormatter)
```

---

## Design Tokens

Use these exact values. Do not approximate or substitute.

```swift
// Colours
static let runColor    = Color(hex: "FF6B35")  // coral-orange — RUN phase
static let walkColor   = Color(hex: "4ECDC4")  // mint-teal    — WALK phase
static let background  = Color(hex: "0F0F14")  // near-black
static let surface     = Color(hex: "1C1C24")  // card background
static let textPrimary = Color(hex: "F7F7F7")  // off-white
static let textMuted   = Color(hex: "8888A0")  // secondary labels

// Typography
// Phase label (RUN/WALK): .largeTitle, .rounded, .bold, ~72pt
// Timer:                  .system(size: 96, weight: .thin, design: .rounded)
// Cycle label:            .title3, .rounded, .medium
// UI chrome:              .body, .default, .regular

// Corner radius
static let cornerRadius: CGFloat = 20
```

---

## Swift Rules

**Use modern Swift and SwiftUI only.** This is a greenfield project targeting iOS 17+.

- SwiftUI for all UI — no UIKit unless there is literally no SwiftUI equivalent
- `async/await` over completion handlers
- No third-party packages — Foundation and SwiftUI only for MVP
- Add a `// MARK: -` section comment in every file
- Add a one-line comment at the top of each new file explaining its role
- Break large SwiftUI view bodies into smaller sub-views or `@ViewBuilder` functions —
  the Swift type-checker fails on expressions that are too complex and will produce
  cryptic "unable to type-check in reasonable time" errors

---

## Xcode File Management

⚠️ **Never modify the `.pbxproj` file directly.** If you create new Swift files,
tell me so I can add them to the Xcode project manually. A corrupted `.pbxproj`
can waste hours.

⚠️ **Never delete the DerivedData folder** to fix build errors. It does not fix
the underlying problem and breaks Xcode's ability to read Swift packages until
you restart Xcode. Instead, fix the actual compiler error.

---

## Building & Testing

Build from the command line to catch errors without switching to Xcode:

```bash
# Build for simulator (replace with your scheme/simulator as needed)
xcodebuild -scheme Waddle \
           -destination 'platform=iOS Simulator,name=iPhone 17 Pro' \
           build 2>&1 | grep -E 'error:|warning:|Build succeeded|Build FAILED'
```

After every milestone, build must succeed with zero errors before we proceed.

---

## Audio Rules (important for Milestones 4–5)

- `AVAudioSession` category: `.playback`, options: `[.duckOthers, .allowBluetooth]`
- Activate session on workout **Start**, not on first voice prompt
- Deactivate with `.notifyOthersOnDeactivation` on workout **Stop**
- Single `AVSpeechSynthesizer` instance — never recreate it mid-workout
- Voice rate: `0.48`, pitch: `1.1`, volume: `1.0`
- Background capability: "Audio, AirPlay, and Picture in Picture" in Xcode
  Signing & Capabilities (do not add this until Milestone 5)

---

## Common Pitfalls — Do Not Do These

| ❌ Anti-pattern | ✅ Correct approach |
|---|---|
| Timer logic in a View | Timer logic in TimerService, owned by ViewModel |
| `@State` for workout state in Views | `@Published` in IntervalViewModel |
| Recreating `AVSpeechSynthesizer` per utterance | Single instance, reused |
| Deleting DerivedData to fix builds | Fix the actual compiler error |
| Modifying `.pbxproj` | Create files, I'll add them to Xcode |
| Starting Milestone N+1 without confirming N | One milestone at a time |
| Using UIKit for UI | SwiftUI only |
| Third-party packages | Foundation + SwiftUI only |
| Giant SwiftUI view body | Extract into sub-views / @ViewBuilder |

---

## Microcopy Reference

Use these exact strings — they are part of the brand.

| Moment | Text |
|---|---|
| Start button | `Start →` |
| Pause state label | `Taking a breather` |
| Complete (limited) | `You waddled! 🐧` |
| Cycle progress | `Round X of Y` |
| Unlimited badge | `Going until you stop` |
| Back to home | `Back to Home` |

---

## After Each Milestone

When a milestone is complete:
1. Confirm the project builds with zero errors
2. List every file created or modified
3. Note any decisions that deviate from the spec and explain why
4. Tell me what to look for when running in the simulator
5. Update the milestone status table above
6. Wait for my explicit confirmation before starting the next milestone
