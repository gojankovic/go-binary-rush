# Go Binary Rush

Fast-paced binary number game for mobile (Flutter/Dart). Nine game modes, all built around binary bit manipulation. Hacker terminal aesthetic.

## Tech Stack

- Flutter + Dart
- `shared_preferences` for local persistence (scores, streaks, tier progress, settings)
- `google_fonts` (bundled, runtime fetching disabled), `flutter_local_notifications` + `timezone` for the daily reminder
- No backend, no database, no accounts, no analytics
- Run on Chrome for dev, target Android

## Visual Design

**Hacker / terminal aesthetic — non-negotiable.**

- Background: pure black `#000000`
- Primary text/UI: terminal green (soft, easy on eyes)
- Font: monospace everywhere (JetBrains Mono)
- Bit tiles: dark bordered squares, green when active (1), dim when inactive (0)
- Animations: subtle CRT flicker or glow on success, no candy/rainbow effects
- No gradients, no rounded pastel buttons — keep it sharp and terminal-like

Two palettes ship (GREEN, CYAN) and the CRT overlay has four intensity levels; both are player settings, not per-screen choices. Colours come from `theme.dart` (`AppColors`, `AppText`, `AppGlow`) — never hardcode a colour in a screen.

**Mood: fun arcade game with a hacker skin, not an educational app.**

## Architecture

```
lib/
  main.dart                    # App entry; bootstrap() loads settings before first frame
  theme.dart                   # Palettes, text styles, glows
  game/
    binary.dart                # Shared MSB-first binary conversion helpers
    bit_flip.dart              # Bit Flip question generation and optimal-move rules
    daily_challenge.dart       # Daily question model + pure schedule/streak functions
    difficulty.dart            # Tier table (bits, targets, cap)
    question_generator.dart    # Tier-aware target generation, solve-based progress
    score_engine.dart          # Score, streak, high score, new-best flash
    word_list.dart             # Hex Word vocabulary
  screens/
    main_shell.dart            # Bottom dock: PLAY / STATS / ACHV / REF / SET
    menu_screen.dart           # Mode list
    game_screen.dart           # Match
    bit_flip_screen.dart       # Bit Flip
    reverse_screen.dart        # Reverse
    addition_screen.dart       # Addition
    xor_screen.dart            # XOR
    hex_screen.dart            # Hex Match
    hex_word_screen.dart       # Hex Word
    speed_burst_screen.dart    # Speed Burst (60s, per-mode)
    daily_challenge_screen.dart# Daily Challenge
    success_feedback.dart      # Shared post-correct flash/advance mixin
    profile_screen.dart, achievements_screen.dart, settings_screen.dart,
    reference_screen.dart, how_to_play_screen.dart, learn_screen.dart,
    name_entry_screen.dart
  services/
    daily_progress_store.dart  # Awaited Daily completion persistence
    prefs_keys.dart            # Every gameplay prefs key + mode ids
    crt_settings.dart, palette_settings.dart, haptics.dart, notifications.dart
  widgets/
    bit_tile.dart, bit_row.dart, num_pad.dart, hex_word_keyboard.dart,
    game_hud.dart, game_pips.dart, new_best_banner.dart, crt_overlay.dart
```

## Game Logic

- Bits stored as `List<int>` (values 0 or 1), index 0 is the most significant bit
- Decimal value: `sum(bits[i] << (n - 1 - i))`
- `QuestionGenerator.next()` returns a target and has no side effect on progress
- `QuestionGenerator.recordSolved()` is what advances progress — call it on a correct answer
- **Read `currentBits` after `next()`, never before.** `next()` applies a deferred tier advance, so reading the width first renders the question at the previous tier's size

### Persistence

All gameplay keys go through `PrefsKeys` / `GameModes` in `lib/services/prefs_keys.dart`. Never spell a key out inline.

The stored literals are a contract with installed builds — changing one wipes that player's progress. Two hex-word mode ids coexist and are **not** interchangeable: `hex_word_*` (standalone screen) and `speed_hexWord_*` (Speed Burst, built from an enum name). `test/prefs_keys_test.dart` locks all of them.

## Game Modes

| Mode | Task |
|------|------|
| Match | Decimal target shown, build it in binary. One correct answer. |
| Reverse | Binary shown pre-lit, type the decimal value. |
| Addition | Decimal target, fill two binary rows that sum to it. Each row shows its own value, the sum is not displayed. Multiple valid solutions. |
| XOR | Rows A and B pre-filled and fixed, fill row C so `A XOR B = C`. |
| Bit Flip | Start from a generated bit pattern and reach the decimal target. PAR is the Hamming distance; matching it earns +5 points. |
| Hex Match | Binary shown, enter the hex value. |
| Hex Word | ASCII hex pairs shown, type the word they spell. |
| Speed Burst | 60-second blitz of any of Match / Reverse / Addition / XOR / Hex Word / Bit Flip. Separate high score per mode; the menu and achievements show the best across all of them. |
| Daily Challenge | 10 questions, same for every player on a given day, one of five rotating schedule variants. The full-mix variant includes Bit Flip. Tracks a daily streak. |

## Difficulty System

Targets progress through tiers. Progress is **solve-based**: only `recordSolved()` grows the seen-set, and a tier advances once its cap of solves is reached. The advance is applied on the next generated question so the solved one keeps its own tier and bit width while its success state is on screen.

| Tier | Bits | Range | Solves to advance |
|------|------|-------|-------------------|
| 1 | 4-bit | 1, 2, 4, 8, 15 — powers of two and all-ones | 3 |
| 2 | 4-bit | the remaining 3–14 | 5 |
| 3 | 5-bit | 16–31 | 7 |
| 4 | 6-bit | 32–63 | 8 |
| 5 | 7-bit | 64–127 | 10 |
| 6 | 8-bit | 128–255 (max) | 20 |

Hex Match uses its own tier table (`kHexTiers`). At the last tier the solved-set resets rather than advancing.

## Conventions

- Stateless widgets where possible; `StatefulWidget` only for interactive screens
- No hardcoded magic numbers — use constants or pass via constructor
- `setState` only; no state management library
- All UI strings in English, no i18n
- No comments unless the why is non-obvious
- Custom tappable controls need `Semantics` with a label and their toggled/selected state
- Layouts must survive a 320px-wide phone, 1.5x system text, and Android system-bar insets; `test/responsive_test.dart` sweeps every screen across those scenarios
- Guard every `setState` that follows an `await` with `if (!mounted) return;`

## Testing

`flutter test` covers routing, scoring, binary conversion, tier semantics, daily generation and completion persistence, prefs key literals, semantics, responsive layout, and widget disposal during async init. `flutter analyze` must be clean.

Before committing, `dart format --output=none --set-exit-if-changed lib test` must pass.
