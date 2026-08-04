# Go Binary Rush

Fast-paced binary number puzzle game for Android. Nine game modes, all built around binary and hex manipulation. Hacker terminal aesthetic.

## Play

- **Web demo:** https://jankovicsrb-droid.github.io/go-binary-rush/
- **Android:** Google Play (search "Go Binary Rush")

## Modes

| # | Mode | Mechanic |
|---|------|----------|
| 1 | **MATCH** | Decimal shown → build its binary representation |
| 2 | **REVERSE** | Binary pre-lit → type the decimal value |
| 3 | **ADDITION** | Fill two rows so A + B = target |
| 4 | **XOR** | Rows A and B fixed → fill C so A ⊕ B = C |
| 5 | **BIT FLIP** | Reach a decimal target from a starting bit pattern in minimum flips |
| 6 | **SPEED BURST** | Any mode, 60-second blitz |
| 7 | **HEX MATCH** | Binary shown → enter the hex value |
| 8 | **HEX WORD** | ASCII hex pairs → tap letters to decode the word |
| 9 | **DAILY** | 10 mixed questions, one per day, 3 attempts per question |

## Scoring

- **10 pts** base per correct answer
- **+5 pts** per consecutive correct answer (streak bonus)
- **+5 pts** for a PAR-perfect BIT FLIP solve
- Wrong answers cost 1 pt in HEX WORD; no penalty in other modes
- Daily Challenge: failed questions (3 wrong attempts) score 0 and are marked red

## Difficulty

MATCH uses a tier system (T1–T6). Solve enough questions to advance to wider bit widths:

```
T1–T2  4-bit   0–15
T3     5-bit   16–31
T4     6-bit   32–63
T5     7-bit   64–127
T6     8-bit   128–255
```

Daily Challenge uses a fixed schedule of 10 questions with increasing bit widths, seeded by date — everyone gets the same challenge each day. The full-mix rotation includes BIT FLIP.

## Onboarding

First-time players go through an interactive 6-page LEARN screen covering binary basics, positional values, hexadecimal, ASCII, and a hands-on practice exercise. Accessible any time via HOW TO PLAY.

## Tech Stack

- Flutter / Dart
- `shared_preferences` — local persistence (scores, streaks, progress)
- `google_fonts` — JetBrains Mono
- No backend, no analytics, no ads

## Privacy

No personal data collected or transmitted. All data stored locally on device.  
Privacy policy: https://jankovicsrb-droid.github.io/go-binary-rush/privacy-policy.html

## License

MIT — see [LICENSE](LICENSE).
