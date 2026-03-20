# MORTAL LEGENDS — Test Checklist

Run through this before each commit. Mark each item pass/fail.

## Menu & Navigation
- [ ] Menu loads with correct items (NEW GAME, CONTROLS, SOUND, ABOUT)
- [ ] Arrow keys navigate menu, Enter selects
- [ ] CONTROLS screen shows both players' keys
- [ ] ABOUT screen shows game info
- [ ] ESC / Enter returns from CONTROLS and ABOUT
- [ ] SOUND toggle works (ON/OFF)

## Game Start
- [ ] NEW GAME starts at Round 1 with "ROUND 1" → "FIGHT!" announcements
- [ ] Both players spawn at correct positions with 100 HP
- [ ] Timer starts at 99 and counts down

## P1 (Gandhi) — Controls
- [ ] W = jump
- [ ] A/D = move left/right
- [ ] S = block (shield circle appears)
- [ ] F = punch (stick thrust)
- [ ] G = kick (ONE standing leg + ONE kicking leg, NOT 3 legs)
- [ ] H = special (requires full meter, chakram spin)
- [ ] T = super (requires 50% damage dealt, fires 2 boomerangs)
- [ ] Punch/kick/special work AFTER super boomerangs end

## P2 (Bin Laden) — Controls
- [ ] Arrow Up = jump
- [ ] Arrow Left/Right = move
- [ ] Arrow Down = block
- [ ] J = punch (fist thrust)
- [ ] K = kick (ONE standing leg + ONE kicking leg, NOT 3 legs)
- [ ] L = special (requires full meter, energy blast)
- [ ] ; = super (requires 50% damage dealt, activates AK-47)
- [ ] 5 gold bullet icons appear above head when super is READY
- [ ] Each ; press fires a bullet and one icon turns dark
- [ ] After all 5 spent, super ends and normal attacks resume

## Combat & Damage
- [ ] Hits reduce health bar
- [ ] Blocked hits deal reduced damage
- [ ] Hit effects (sparks) appear on contact
- [ ] Combo counter shows for 2+ consecutive hits
- [ ] Special meter fills from dealing damage
- [ ] Screen shakes on hit

## Round System
- [ ] KO after Round 1 → "K.O.!" → proceeds to Round 2
- [ ] KO after Round 2 (same winner) → "[NAME] WINS!" → gameover
- [ ] If tied 1-1, Round 3 shows "FINAL ROUND"
- [ ] Win dots update correctly (gold for P1, red for P2)
- [ ] Timer reaching 0 → player with more health wins the round

## Gameover & Reset
- [ ] Gameover screen shows "[NAME] WINS!" + "PRESS ENTER"
- [ ] Enter goes to menu with NO "RESUME" option
- [ ] Starting new game resets everything (health, rounds, wins, timer)

## Pause
- [ ] ESC during fight pauses the game
- [ ] Pause menu shows RESUME, NEW GAME, CONTROLS, SOUND, ABOUT, EXIT
- [ ] RESUME returns to fight
- [ ] EXIT goes to fresh menu (no RESUME)

## Projectiles
- [ ] Gandhi boomerangs home toward enemy then return
- [ ] Boomerangs deal 15 damage (5 if blocked)
- [ ] Bin Laden bullets travel straight
- [ ] Bullets deal 12 damage (4 if blocked)
- [ ] Projectile KOs trigger round end properly (no double-KO)

## Visuals
- [ ] Player names visible above health bars
- [ ] Stage renders (sky, mountains, moon, stars, torches, ground)
- [ ] Characters face each other
- [ ] Super ready aura pulses around character
- [ ] No visual glitches or flickering
