# MORTAL LEGENDS — LÖVE2D Edition
## Gandhi vs Bin Laden — 2-Player Arcade Fighter

### Requirements
- **LÖVE2D** (11.x or later) — https://love2d.org/

### Setup
1. Download and install LÖVE2D from https://love2d.org/
2. **(Optional but recommended):** Download the "Press Start 2P" font from Google Fonts
   and place `PressStart2P-Regular.ttf` renamed to `PressStart2P.ttf` in this folder.
   The game works without it (uses a fallback font), but looks best with the pixel font.
3. Run the game:
   - **Windows:** Drag the `mortal-legends` folder onto `love.exe`
   - **macOS:** `open -a love mortal-legends/`
   - **Linux:** `love mortal-legends/`

### Controls

| Action       | P1 (Gandhi)  | P2 (Bin Laden)   |
|-------------|-------------|------------------|
| Move        | A / D       | Left / Right     |
| Jump        | W           | Up               |
| Block       | S           | Down             |
| Punch       | F           | J                |
| Kick        | G           | K                |
| Special     | H           | L                |
| Super       | T           | ; (semicolon)    |
| Pause       | ESC         | ESC              |

### Super Abilities
- **Gandhi:** Unlocks after dealing 50% damage. Press T to launch 2 homing boomerangs.
- **Bin Laden:** Unlocks after dealing 50% damage. Press ; to activate AK-47, then tap ; for each bullet (5 total).

### Game Rules
- Best of 3 rounds
- 99-second round timer
- Special meter fills from dealing damage (and slowly over time)
- Special attack requires full meter (100)
