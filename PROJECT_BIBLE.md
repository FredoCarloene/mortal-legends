# SEE YOU IN THE PIT — Project Bible

> **Purpose:** Upload this file at the start of any new Claude chat or Claude Code session. Contains everything about the project.

> **Last updated:** May 9, 2026

---

## Quick Links
- **GitHub repo:** https://github.com/FredoCarloene/mortal-legends
- **Live game:** https://fredocarloene.github.io/mortal-legends/
- **Web version:** `index.html` (online multiplayer, V45+ with GGPO rollback netcode)
- **LÖVE2D version:** `main.lua` + `conf.lua` (local 2-player, v11, reference/prototype)

---

## The Game

**Name:** *See You In The Pit*

**Tagline:** *See you in the Pit.*

**Concept:** A 2D arcade fighting game where history's most infamous figures are condemned to fight forever in "The Pit." Mortal Kombat-inspired, fast-paced, pick-up-and-play. Currently has Gandhi vs Bin Laden as the 2 working characters.

---

## Tech Stack

### Web Version (`index.html`)
- **Single file** — no build step, no npm, no bundler
- **Rendering:** HTML5 Canvas (800×400), pixel art characters drawn via code (no sprite sheets)
- **UI Framework:** React 18 + Babel (all via CDN)
- **Networking:** WebRTC P2P via PeerJS CDN, **GGPO-style rollback netcode**
- **Audio:** Web Audio API oscillator-based SFX synthesis
- **Hosting:** GitHub Pages (static, free, no backend)
- **Font:** Press Start 2P (Google Fonts CDN)

### LÖVE2D Version (`main.lua`)
- Local 2-player on same keyboard, v11
- All gameplay features, no networking
- Used as reference/prototype

---

## Networking — Rollback Netcode (V45+)

Both phones run identical deterministic simulation. No host, no client, equal for both players.

### How It Works
- Each frame, both send only their inputs (~30 bytes) via WebRTC
- If remote input hasn't arrived, predict (repeat last input) and continue
- When real input arrives and differs, roll back to that frame, replay with corrected inputs
- Binary input packets with 12-frame redundant history

### Key Constants
```
LOCAL_INPUT_DELAY = 2 frames (~33ms)
MAX_PREDICTION_FRAMES = 8
MAX_SIM_STEPS = 6 per render frame
ROLLBACK_BUFFER_SIZE = 512 frames
INPUT_PACKET_HISTORY = 12 redundant frames per packet
```

### Key Functions
- `stepFrame(g, p1Mask, p2Mask, frame)` — deterministic sim for one frame
- `rollbackFromFrame(frame)` — restore snapshot, replay with corrected inputs
- `copyGameStateInto(dst, g)` — deep copy game state for snapshots
- `encodeLocalInput()` — read buttons, return 8-bit bitmask
- `applyRemoteHistory(frame, history)` — process remote inputs, trigger rollback

### Input Bitmask
```
L=1  R=2  U=4  D=8  P=16  K=32  S=64  SU=128
```

### Determinism Rules
- All timers are frame counters (no setTimeout in gameplay)
- Rocket explosions use fixed offsets (no Math.random in sim)
- Math.random only in render code (cosmetic only)

---

## Characters

### Gandhi (P1 — gold #e8a926) — Zoner
- Speed: 3.2 | Punch: 3 | Kick: 5 | Special: 14
- Super: 2 homing boomerangs (10 dmg / 2 blocked)

### Bin Laden (P2 — red #c0392b) — Rushdown
- Speed: 4.5 | Punch: 2 | Kick: 3 | Special: 10
- Super: 5 rockets (8 dmg / 2 blocked, explosion + blast knockback)
- Planned passive: 20% dodge

### Shared: Block 75%, Super at 50% dmg dealt, once per round, jump=-15, gravity=1.0

---

## Planned Roster: "The Iconic Six"

15 total stat points per character (Speed + Power + HP).

| Character | Archetype | Speed/Power/HP | Signature |
|---|---|---|---|
| Gandhi | Zoner | 6/3/6 | Boomerang super |
| Hitler | Technical | 5/5/5 | Gains power over time |
| Stalin | Grappler | 2/6/7 | Unblockable grabs |
| Churchill | All-rounder | 4/4/7 | Beginner-friendly |
| Mao | Bruiser | 4/5/6 | Every 3rd hit +50% dmg |
| Bin Laden | Rushdown | 7/3/5 | 20% dodge passive |

Add order: Stalin → Hitler → Churchill → Mao. One at a time.

---

## Combat System
- Knockback: P=6px, K=10px, S=18px (scales with combo up to 1.5×)
- Hit freeze: 2-5 frames (scales with combo)
- White flash on unblocked hits
- Screen shake: `*2` multiplier
- Combo: 90-frame window, visual scales with count
- Knockback friction: 0.75×/frame

---

## Game Flow
- Best of 3 rounds, 99 sec timer
- States: `fighting` → `ko` → next round or `gameover`
- Rematch: any button after gameover (3 sec delay)
- All timers frame-based (deterministic)

---

## Mobile Features
- Landscape only (portrait = rotate message)
- PS5 diamond controls: D-pad left (△◁○▷), attacks right (K P S ★), 62px buttons
- Fullscreen: Android only (hidden on iOS)
- Install-as-App: iOS only (Safari Add to Home Screen guide)
- Haptics: Android only, 15-100ms per event type
- PWA manifest embedded

---

## Lobby
- Splash → "TAP TO START" → Lobby
- 4-digit numeric room codes, PeerJS peer ID `ML-{code}`
- Shareable `?room=1234` links
- Ready handshake with periodic resends

---

## Bugs Fixed

| Bug | Fix |
|---|---|
| Desync after frame 512 | Deep-copy in `copyGameStateInto` (was aliasing) |
| RNG divergence | Removed `confirmed` gate on random |
| `confirmed` inconsistency | Unified definition |
| Frame drops / GC | In-place mutation instead of map/filter |
| Shake too aggressive | Reduced multiplier to `*2` |
| Super lockout | Fixed action gating |
| Double KO | `roundEnded` guard |
| iOS fullscreen buttons | Hidden via `isIOS` |
| Keyboard blocking input | `tagName==="INPUT"` check |
| Half-second freezes | Separate input scheduler |

---

## Priority Roadmap

### 🔥 Phase 1: Tier S Polish (NOW)
1. Hit-stop — partially done via `g.freeze`, needs tuning
2. Screen shake — ✅ done
3. Sound variety — 3 variants per attack + layered sounds
4. Rematch countdown — giant button + 3-sec countdown + running score

### Phase 2: Local WiFi Mode
"LOCAL WIFI PLAY" button — same network = 1-5ms lag

### Phase 3: More Characters
Stalin → Hitler → Churchill → Mao (one at a time)

### Phase 4: Mobile App
**Defold** (Lua engine, native iOS/Android) — long-term best path. Or Capacitor wrap for quick release.

### Phase 5: Optional Matchmaking
Node.js queue server (~$5/month). Not priority — room codes work.

---

## Design Principles
1. **Feel > features.** Hit-stop + shake + sounds = 70% of fun
2. **One character at a time.** Tune before adding next
3. **15-point stat rule.** Rebalance by shifting points
4. **The Pit is a character.** UI/sound/copy reinforce the world
5. **Polish before content.** Existing characters must feel incredible first
6. **Arcade-y, not technical.** 60-90 sec rounds, 3-4 buttons, pick-up-and-play
7. **Mobile-first.** Landscape, touch controls, local WiFi central

---

## Distribution
- **Web:** Real names, full edgy branding (current)
- **App stores:** Parody names ("The Pacifist," "The Iron Commissar")
- **One codebase, two builds.** Free-to-play, no paywalls.

---

## Workflow

### Primary: Claude Code in VS Code
- Edit files directly, auto-commit and push
- GitHub Pages auto-deploys on push

### Secondary: Claude Chat
- Architecture, design, planning discussions
- Upload this file at start of any new chat

---

## How to Use This File
- **New chat:** Upload + say "Read the project bible, then help me with [task]"
- **Claude Code:** Say "Read PROJECT_BIBLE.md for context, then [task]"
- **Keep updated:** After major changes, say "Update PROJECT_BIBLE.md with [what changed]"

---

*v2.0 — May 9, 2026*
