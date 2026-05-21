# Launchpad 🚀

> A collaborative classroom runtime for STEM and computer science education.

Launchpad is an offline-first classroom operating system designed for project-based STEM and computer science classrooms.

It combines:
- collaborative warm-ups
- classroom pacing
- team organization
- participation systems
- lightweight classroom management
- lesson flow orchestration

into a single streamlined experience built for real classrooms.

---

## Philosophy

Launchpad is inspired by:
- project-based learning
- collaborative engineering workflows
- systems-oriented classroom management
- *The First Days of School* by Harry Wong
- software dashboard UX
- coding/editor aesthetics

The goal is to create classrooms that feel:
- structured
- calm
- collaborative
- engaging
- intentional
- technically authentic

Instead of:
> chaos + disconnected tools + endless tabs

Launchpad aims to become:
> a lightweight operational layer for modern STEM classrooms.

---

# Core Features

## Current MVP
- Classroom display screen
- Warm-up runtime system
- Lesson JSON import from Teacher View
- Manual lesson phase progression
- Team-based collaboration
- Countdown timers
- Daily agenda flow
- Team submission interface
- Teacher control dashboard
- Offline/demo mode
- Team leaderboards
- Randomized team assignment
- Color-coded team identity system

---

# Lesson JSON Import

Launchpad can import a lesson JSON file from the Teacher tab. The import sets
the active lesson, resets the lesson to Phase 1, and resets the countdown timer
to that phase duration. The imported lesson is stored locally, so a browser
refresh keeps the active lesson and current phase.

The default demo lesson lives at:

```text
lib/src/data/sample_lesson_import.json
```

Reset Demo Data restores that sample lesson from `src/data`; the JSON is not
duplicated into another assets folder.

## Supported Schema

The importer currently reads and preserves:
- `lessonInfo`
- `displaySettings`
- `standards`
- `learningObjectives`
- `successCriteria`
- `vocabulary`
- `materials`
- `differentiation`
- `teacherMoves`
- `pointRewards`
- `phases`

Each phase supports fields such as `id`, `type`, `title`, `durationSeconds`,
`prompt`, `instructions`, `submission`, `teacherNotes`, `display`,
`discussionPrompts`, and `reflectionQuestions`.

Only fields that already have a place in the current app UI are displayed:
course/period/date, current phase prompt, instructions, phase agenda, timer,
team map visibility, leaderboard visibility, and team submission settings.
Standards, vocabulary, materials, differentiation, teacher moves, success
criteria, and teacher notes are imported and preserved for future features, but
they are not shown as new visible sections yet.

## Testing Import Locally

1. Run the app:

```bash
flutter run -d chrome
```

2. Open the Teacher tab.
3. Use **Import Lesson JSON** and select a `.json` file.
4. Use **Lesson Flow** to move Previous/Next, restart the phase timer, or jump
   directly to a phase.
5. Check the Display and Team Submit tabs. They should respond to the current
   phase.

---

# Design Goals

- Offline-first
- Low friction
- Fast transitions
- Projector-friendly
- Minimal clicks during instruction
- Built for real classroom pacing
- Calm dark-mode UI
- Code-editor-inspired visual design

---

# Example Classroom Workflow

1. Students enter class
2. Display screen shows:
   - seating/team map
   - warm-up
   - timer
   - expectations
   - agenda
3. Teams collaborate
4. Teacher advances lesson phases from tablet/iPad
5. Students submit responses
6. Reflection + discussion close the loop

---

# Tech Stack

## Frontend
- Flutter Web

## Backend (planned/in progress)
- Supabase
- Offline local persistence
- Sync queue architecture

---

# Planned Features

- Help request queue
- Exit tickets
- Multi-class support
- Project checkpoints
- Lesson runtime sequencing
- Team rotation generation
- Ambient classroom music
- Reflection analytics
- Realtime sync
- Teacher mobile control mode

---

# Why This Exists

Many classroom tools optimize for:
- grading
- compliance
- surveillance
- static content delivery

Launchpad is designed around:
- collaboration
- momentum
- visibility
- participation
- engineering-style thinking
- project-based learning

It is built from the perspective of someone actively preparing to teach STEM and computer science.

---

# Status

Early prototype / active development.

Built throughout Summer 2026 in preparation for first-year STEM and computer science teaching.

---

# Screenshots

Coming soon.

---

# Local Development

```bash
flutter pub get
flutter run -d chrome
```

---

# Vision

Launchpad is intended to feel less like:
> presentation software

and more like:
> mission control for collaborative learning 🚀
