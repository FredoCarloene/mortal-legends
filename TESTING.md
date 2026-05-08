# MORTAL LEGENDS — Test Checklist (v11)

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
- [ ] T = super (requires 50% damage dealt, tap-fires boomerangs)
- [ ] 2 gold boomerang icons appear above head when super is READY
- [ ] First T press fires 1 boomerang, 1 icon turns dark
- [ ] Second T press fires 2nd boomerang, both dark, super ends
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

## Super System (v11)
- [ ] Super unlocks after dealing 50% of enemy's max health
- [ ] Super is ONE TIME PER ROUND — does NOT come back after use
- [ ] After using super and continuing to fight, super stays gone
- [ ] Super resets on new round (fresh players)
- [ ] Icons disappear after super is fully spent

## Combat & Damage
- [ ] Hits reduce health bar
- [ ] Blocked hits deal very low damage (85% reduction)
- [ ] Hit effects (sparks) appear on contact
- [ ] Combo counter shows for 2+ consecutive hits
- [ ] Special meter fills from dealing damage
- [ ] Screen shakes on hit
- [ ] Rounds last long enough for strategic play

## Damage Balance (v11)
- [ ] Punch = 2 damage (both characters)
- [ ] Kick = 4 damage (both characters)
- [ ] Special = 12 damage (both characters)
- [ ] Block reduction = 85% (only 15% damage gets through)
- [ ] Gandhi boomerang = 10 damage (2 if blocked), 2 total = 20 max
- [ ] Bin Laden bullet = 4 damage (1 if blocked), 5 total = 20 max
- [ ] Both supers deal equal max damage (20)

## Round System
- [ ] KO after Round 1 → "K.O.!" → proceeds to Round 2
- [ ] KO after Round 2 (same winner) → "[NAME] WINS!" → gameover
- [ ] If tied 1-1, Round 3 shows "FINAL ROUND"
- [ ] Win dots update correctly (gold for P1, red for P2)
- [ ] Timer reaching 0 → player with more health wins the round
- [ ] No double-KO bug (only 1 win counted per round)

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
- [ ] Boomerangs deal 10 damage (2 if blocked)
- [ ] Bin Laden bullets travel straight
- [ ] Bullets deal 4 damage (1 if blocked)
- [ ] Projectile KOs trigger round end properly (no double-KO)

## Visuals
- [ ] Player names visible above health bars (dark backdrop)
- [ ] Stage renders (sky, mountains, moon, stars, torches, ground)
- [ ] Characters face each other
- [ ] Super ready aura pulses around character
- [ ] Gandhi: 2 boomerang icons above head (gold=ready, dark=spent)
- [ ] Bin Laden: 5 bullet icons above head (gold=ready, dark=spent)
- [ ] No mirrored text on bullet/boomerang counters
- [ ] No visual glitches or flickering