# 🎮 Puissance 4 — iOS App

> A native iOS Connect Four game built with Swift and UIKit.  
> Features a 3-difficulty AI opponent powered by the **Minimax algorithm with alpha-beta pruning**.

**Authors:** Tadimi Sofiane · Bekkar Mounir  
**University:** Université Lumière Lyon 2 — Licence Informatique  
**Language:** Swift 5 · UIKit · iOS 16+

---

## 📱 Features

| Feature | Details |
|---------|---------|
| **Game modes** | Player vs Player (local) · Player vs AI |
| **AI — Easy** | Random column selection |
| **AI — Medium** | Wins immediately if possible · Blocks player · Prefers centre |
| **AI — Hard** | Minimax depth-6 with alpha-beta pruning + board evaluation heuristic |
| **Win detection** | Horizontal · Vertical · Diagonal ↘ · Diagonal ↗ |
| **Animations** | Pop-in animation with pulse effect on every piece placement |
| **UI** | Storyboard-based · NavigationController · UIAlertController for game end |
| **Architecture** | MVC — `GameEngine` (pure logic) separated from `ViewController` (UIKit) |
| **Tests** | 20+ unit tests covering board logic, win detection and AI decisions |

---

## 🗂️ Project Structure

```
Puissance4/
├── Puissance4/
│   ├── GameEngine.swift              ← Pure game logic (no UIKit)
│   ├── ViewController.swift          ← Game screen (UI + animations)
│   ├── ViewControllerAccueil.swift   ← Home/menu screen
│   ├── AppDelegate.swift
│   ├── SceneDelegate.swift
│   ├── Base.lproj/
│   │   ├── Main.storyboard           ← UI layout
│   │   └── LaunchScreen.storyboard
│   └── Assets.xcassets/
│       ├── red_pawn                  ← Player 1 pawn (red)
│       ├── yellow_pawn               ← Player 2 / AI pawn (yellow)
│       └── grid                      ← Game grid background
├── Puissance4Tests/
│   └── GameEngineTests.swift         ← Unit tests (XCTest)
└── Puissance4.xcodeproj/
```

---

## 🚀 Getting Started

### Requirements
- macOS 13+
- Xcode 15+
- iOS 16+ simulator or device

### Steps

1. Clone the repository:
```bash
git clone https://github.com/mbekkar/puissance4-ios.git
cd puissance4-ios
```

2. Open the project:
```bash
open Puissance4/Puissance4.xcodeproj
```

3. Select a simulator (iPhone 15 recommended) and press **⌘R** to run.

---

## 🧠 How the AI Works

### Easy
Selects a random available column.

### Medium
1. Check if AI can **win immediately** → play that column
2. Check if player can **win next turn** → block that column
3. Otherwise, prefer **centre columns** `[3, 2, 4, 1, 5, 0, 6]`

### Hard — Minimax with Alpha-Beta Pruning

The AI explores the game tree up to **depth 6** (all possible positions 6 moves ahead), using alpha-beta pruning to skip branches that won't affect the outcome.

```
minimax(depth, alpha, beta, isMaximizing)
├── Terminal: AI wins   → +100,000 + depth   (prefer faster wins)
├── Terminal: P1 wins   → -100,000 - depth
├── Terminal: draw / depth=0 → evaluateBoard()
└── Recursive: try all available columns
    ├── Maximizing (AI):   pick column with highest score
    └── Minimizing (P1):   pick column with lowest score
        └── alpha-beta cut-off when beta ≤ alpha
```

**Board evaluation heuristic:**
- **Centre column bonus**: +3 per AI piece, -3 per player piece in centre column
- **4-cell window scoring** across all H/V/diagonal directions:

| AI pieces | Empty | Score |
|-----------|-------|-------|
| 4 | 0 | +100 |
| 3 | 1 | +5 |
| 2 | 2 | +2 |
| Player 3 | 1 | -4 |
| Player 2 | 2 | -1 |

---

## 🧪 Running Tests

In Xcode: **Product → Test** (`⌘U`)

Tests cover:
- Board helpers (`availableRow`, `isBoardFull`, `availableColumns`)
- Piece dropping and stacking
- Win detection in all 4 directions
- No false positives with mixed pieces
- Game result states (ongoing / win / draw)
- Reset state
- AI: Easy, Medium (blocks), Hard (wins immediately)
- `findWinningMove` utility
- Minimax performance benchmark

---

## 🏗️ Architecture

```
ViewControllerAccueil      ViewController
(Menu screen)              (Game screen)
       │                         │
       │ prepare(for segue)      │ uses
       │ sets gameMode +         ▼
       │ aiDifficulty      GameEngine
       └──────────────────►  (pure Swift, no UIKit)
                              ├── board state
                              ├── win detection
                              ├── AI (Easy/Medium/Hard)
                              └── Minimax + alpha-beta
```

The `GameEngine` class has **no UIKit import** — it can be tested entirely without a simulator.

---

## ⚠️ Known Issue

A simulator configuration bug was encountered on **Xcode / iOS 18.6** at the end of the project, causing the app not to launch on that specific Target configuration. The bug is **not in the Swift code** — the game logic and UI are structurally complete. The issue is linked to the iOS 18.6 simulator Target settings.

---

## 🚀 Possible Improvements

- [ ] Fix iOS 18.6 simulator Target configuration issue
- [ ] Add **Game Center** multiplayer (GameKit)
- [ ] **SwiftUI** rewrite for a modern UI
- [ ] Sound effects and haptic feedback
- [ ] Score history with Core Data persistence
- [ ] Animated piece **drop** (gravity fall animation)

---

## 📄 License

MIT License — free to use and modify.
