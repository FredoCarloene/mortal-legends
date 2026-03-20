-- ═══════════════════════════════════════════════════
-- MORTAL LEGENDS — Gandhi vs Bin Laden
-- LÖVE2D Port (100% faithful to React/Canvas original)
-- ═══════════════════════════════════════════════════

-- ─── CONSTANTS ───
local STAGE_W = 800
local STAGE_H = 400
local GROUND_Y = 320
local GRAVITY = 0.8
local CHAR_W = 60
local CHAR_H = 90
local ROUND_TIME = 99
local PI = math.pi
local TWO_PI = PI * 2

-- ─── CHARACTERS ───
local CHARACTERS = {
    gandhi = { name = "GANDHI", accent = {232/255, 169/255, 38/255}, punchDmg = 4, kickDmg = 6, specialDmg = 12, speed = 3.8, blockReduction = 0.85 },
    binladen = { name = "BIN LADEN", accent = {192/255, 57/255, 43/255}, punchDmg = 4, kickDmg = 6, specialDmg = 12, speed = 3.8, blockReduction = 0.85 },
}

-- ─── COLOR HELPERS ───
local function hex(h)
    local r = tonumber(h:sub(2,3), 16) / 255
    local g = tonumber(h:sub(4,5), 16) / 255
    local b = tonumber(h:sub(6,7), 16) / 255
    return {r, g, b, 1}
end

local function rgba(r, g, b, a)
    return {r/255, g/255, b/255, a}
end

-- Pre-computed colors
local C = {
    skin = hex("#C4956A"),
    dhoti = hex("#f5f0e0"),
    drape = hex("#e8dcc0"),
    leg_gandhi = hex("#8B7355"),
    sandal = hex("#654321"),
    glasses = hex("#333333"),
    eye_dark = hex("#222222"),
    stick = hex("#8B6914"),
    smile = hex("#8B6914"),
    robe = hex("#4a4a4a"),
    robe_collar = hex("#3a3a3a"),
    robe_center = hex("#3a3a3a"),
    leg_bin = hex("#333333"),
    boot = hex("#222222"),
    turban = hex("#f0f0f0"),
    beard = hex("#444444"),
    eye_white = {1, 1, 1, 1},
    pupil = hex("#111111"),
    eyebrow = hex("#333333"),
    backpack = hex("#2a2a1a"),
    backpack_detail = hex("#3a3a2a"),
    gandhi_accent = hex("#e8a926"),
    bin_accent = hex("#c0392b"),
    moon = hex("#ffe4b5"),
    ground_top = hex("#4a3520"),
    ground_mid = hex("#3a2810"),
    ground_bot = hex("#1a1005"),
    sky_top = hex("#0a0a2e"),
    sky_mid = hex("#1a0a3e"),
    sky_bot = hex("#2d1b69"),
    mountain = hex("#1a1040"),
    torch_pole = hex("#5a3a1a"),
    white = {1, 1, 1, 1},
    black = {0, 0, 0, 1},
    red = {1, 0, 0, 1},
    bullet_yellow = hex("#ffdd44"),
    bullet_trail = rgba(255, 150, 50, 0.5),
    muzzle_yellow = hex("#ffaa00"),
    muzzle_white = {1, 1, 1, 1},
    gun_body = hex("#555555"),
    gun_stock = hex("#3a2a1a"),
    gun_grip = hex("#444444"),
    gun_muzzle = hex("#666666"),
    energy_red_half = rgba(192, 57, 43, 0.5),
    energy_red_full = rgba(255, 50, 50, 0.8),
}

-- ─── SOUND ENGINE (LÖVE Audio Synthesis) ───
local SFX = {}
SFX.muted = false
SFX.volume = 0.35

function SFX.init() end -- no-op, LÖVE handles audio context

function SFX.setMuted(m)
    SFX.muted = m
end

-- Generate a tone using SoundData
local function makeTone(waveType, freq, dur, gain)
    if SFX.muted then return end
    gain = gain or 0.3
    local sampleRate = 44100
    local samples = math.floor(sampleRate * dur)
    local sd = love.sound.newSoundData(samples, sampleRate, 16, 1)
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local env = gain * math.max(0.001, 1 - t / dur)
        local val = 0
        local phase = (freq * t * TWO_PI) % TWO_PI
        if waveType == "sine" then
            val = math.sin(phase)
        elseif waveType == "square" then
            val = math.sin(phase) > 0 and 1 or -1
        elseif waveType == "sawtooth" then
            val = 2 * ((freq * t) % 1) - 1
        elseif waveType == "triangle" then
            val = 2 * math.abs(2 * ((freq * t) % 1) - 1) - 1
        end
        sd:setSample(i, val * env * SFX.volume)
    end
    local src = love.audio.newSource(sd)
    src:play()
end

local function makeNoise(dur, gain)
    if SFX.muted then return end
    gain = gain or 0.15
    local sampleRate = 44100
    local samples = math.floor(sampleRate * dur)
    local sd = love.sound.newSoundData(samples, sampleRate, 16, 1)
    -- Simple high-pass via difference
    local prev = 0
    for i = 0, samples - 1 do
        local t = i / sampleRate
        local env = gain * math.max(0.001, 1 - t / dur)
        local raw = (math.random() * 2 - 1)
        local hp = raw - prev
        prev = raw * 0.8
        sd:setSample(i, hp * env * SFX.volume)
    end
    local src = love.audio.newSource(sd)
    src:play()
end

-- Delayed tone helper
local delayedSounds = {}
local function delayTone(delay, waveType, freq, dur, gain)
    table.insert(delayedSounds, { timer = delay, fn = function() makeTone(waveType, freq, dur, gain) end })
end

local function updateDelayedSounds(dt)
    local i = 1
    while i <= #delayedSounds do
        delayedSounds[i].timer = delayedSounds[i].timer - dt
        if delayedSounds[i].timer <= 0 then
            delayedSounds[i].fn()
            table.remove(delayedSounds, i)
        else
            i = i + 1
        end
    end
end

function SFX.punch() makeNoise(0.08, 0.25); makeTone("square", 200, 0.06, 0.2) end
function SFX.kick() makeTone("sine", 100, 0.15, 0.35); makeNoise(0.1, 0.2) end
function SFX.special()
    for i = 0, 4 do delayTone(i * 0.04, "sawtooth", 300 + i * 120, 0.2, 0.2) end
    makeNoise(0.3, 0.15)
    delayTone(0.15, "sine", 800, 0.4, 0.25)
end
function SFX.block() makeTone("triangle", 300, 0.1, 0.15) end
function SFX.hit() makeNoise(0.06, 0.3); makeTone("square", 150, 0.08, 0.2) end
function SFX.ko()
    local freqs = {600,500,400,300,200}
    for i, f in ipairs(freqs) do delayTone((i-1)*0.1, "square", f, 0.3, 0.2) end
    delayTone(0.5, "sawtooth", 80, 0.8, 0.3)
end
function SFX.roundStart()
    local freqs = {523,659,784,1047}
    for i, f in ipairs(freqs) do delayTone((i-1)*0.1, "square", f, 0.15, 0.15) end
end
function SFX.fight()
    delayTone(0.05, "sawtooth", 400, 0.1, 0.2)
    delayTone(0.13, "square", 1000, 0.3, 0.2)
end
function SFX.menuSelect() makeTone("square", 660, 0.08, 0.12); delayTone(0.06, "square", 880, 0.08, 0.12) end
function SFX.menuMove() makeTone("square", 440, 0.04, 0.08) end
function SFX.menuBack() makeTone("square", 440, 0.06, 0.1); delayTone(0.06, "square", 330, 0.08, 0.1) end
function SFX.win()
    local freqs = {523,659,784,880,1047,1175,1319,1568}
    for i, f in ipairs(freqs) do delayTone((i-1)*0.12, "square", f, 0.2, 0.12) end
end
function SFX.superReady()
    local freqs = {800,1000,1200,1600}
    for i, f in ipairs(freqs) do delayTone((i-1)*0.06, "sawtooth", f, 0.12, 0.18) end
    makeTone("sine", 200, 0.5, 0.1)
end
function SFX.boomerang()
    for i = 0, 7 do delayTone(i*0.03, "triangle", 500 + i*60, 0.1, 0.15) end
    makeNoise(0.2, 0.1)
end
function SFX.gunshot() makeNoise(0.12, 0.4); makeTone("square", 60, 0.15, 0.3); makeTone("sawtooth", 150, 0.08, 0.2) end
function SFX.bgDrone() if SFX.muted then return end; makeTone("sine", 55, 2, 0.04) end

-- ─── GAME STATE ───
local gameState = "menu"
local announcement = ""
local round = 1
local wins = { p1 = 0, p2 = 0 }
local timer = ROUND_TIME
local timerAccum = 0
local menuIndex = 1  -- 1-indexed in Lua
local soundOn = true
local hasPlayed = false
local frame = 0

-- Key tracking
local keys = {}
local justPressed = {}

-- Game data
local g = nil

-- Delayed game events
local gameTimers = {}
local function addGameTimer(delay, fn)
    table.insert(gameTimers, { timer = delay, fn = fn })
end

local function updateGameTimers(dt)
    local i = 1
    while i <= #gameTimers do
        gameTimers[i].timer = gameTimers[i].timer - dt
        if gameTimers[i].timer <= 0 then
            gameTimers[i].fn()
            table.remove(gameTimers, i)
        else
            i = i + 1
        end
    end
end

-- ─── FONT ───
local pixelFont = nil
local pixelFontSmall = nil
local pixelFontTiny = nil
local pixelFontLarge = nil
local pixelFontHuge = nil
local pixelFontMed = nil

-- ─── PLAYER FACTORY ───
local function makePlayer(id, x, facing)
    return {
        id = id, x = x, y = GROUND_Y - CHAR_H, vy = 0,
        health = 100, maxHealth = 100, special = 0,
        action = nil, actionTimer = 0, facing = facing,
        isJumping = false, isBlocking = false,
        combo = 0, comboTimer = 0, hitStun = 0, dmgDealt = 0,
        superReady = false, superActive = false, superBullets = 0, superBoomerangs = 0,
    }
end

local function initGame()
    return {
        p1 = makePlayer("gandhi", 150, 1),
        p2 = makePlayer("binladen", 550, -1),
        hitEffects = {}, shakeFrames = 0, slowMotion = 0, projectiles = {},
    }
end

-- ─── MENU ITEMS ───
local function getMenuItems()
    if hasPlayed then
        return {"RESUME", "NEW GAME", "CONTROLS", "SOUND: " .. (soundOn and "ON" or "OFF"), "ABOUT", "EXIT"}
    else
        return {"NEW GAME", "CONTROLS", "SOUND: " .. (soundOn and "ON" or "OFF"), "ABOUT"}
    end
end

-- ─── FORWARD DECLARATIONS ───
local handleRoundEnd
local handleAttack

-- ─── PROJECTILE UPDATE ───
local function updateProjectiles()
    local newProj = {}
    for _, p in ipairs(g.projectiles) do
        p.age = p.age + 1
        local target = p.owner == "p1" and g.p2 or g.p1
        local targetCX = target.x + CHAR_W / 2
        local targetCY = target.y + CHAR_H / 2
        local keep = false

        if p.type == "boomerang" then
            if p.phase == "out" then
                local dx = targetCX - p.x
                local speed = 8
                if dx > 0 then p.x = p.x + math.min(speed, dx) else p.x = p.x + math.max(-speed, dx) end
                local dy = targetCY - p.y
                p.y = p.y + dy * 0.05
                p.rotation = p.rotation + 0.5
                if math.abs(dx) < 15 or p.age > 80 then p.phase = "back" end
            else
                local owner = p.owner == "p1" and g.p1 or g.p2
                local ox = owner.x + CHAR_W / 2
                local dx = ox - p.x
                local dy = (owner.y + 35) - p.y
                if dx > 0 then p.x = p.x + math.min(9, dx) else p.x = p.x + math.max(-9, dx) end
                p.y = p.y + dy * 0.08
                p.rotation = p.rotation + 0.5
                if math.abs(dx) < 20 then goto continue end -- caught
            end
            -- Hit check
            if math.abs(p.x - targetCX) < 35 and math.abs(p.y - targetCY) < 50 and not p.hit then
                p.hit = true
                local dmg = target.isBlocking and 2 or 10
                target.health = math.max(0, target.health - dmg)
                target.hitStun = 12
                g.shakeFrames = 6
                table.insert(g.hitEffects, { x = targetCX, y = target.y + 30, frame = 0, type = "special" })
                if not target.isBlocking then SFX.hit() else SFX.block() end
            end
            if p.age < 150 then keep = true end

        elseif p.type == "bullet" then
            p.x = p.x + p.dir * 14
            if math.abs(p.x - targetCX) < 30 and math.abs(p.y - targetCY) < 45 and not p.hit then
                p.hit = true
                local dmg = target.isBlocking and 1 or 4
                target.health = math.max(0, target.health - dmg)
                target.hitStun = 6
                g.shakeFrames = 4
                table.insert(g.hitEffects, { x = targetCX, y = target.y + 30, frame = 0, type = "normal" })
                if not target.isBlocking then SFX.hit() else SFX.block() end
                goto continue
            end
            if p.x > -20 and p.x < STAGE_W + 20 then keep = true end
        end

        if keep then table.insert(newProj, p) end
        ::continue::
    end
    g.projectiles = newProj
end

-- ─── DRAWING HELPERS ───
local function setColor(c)
    love.graphics.setColor(c[1], c[2], c[3], c[4] or 1)
end

local function fillRect(x, y, w, h)
    love.graphics.rectangle("fill", x, y, w, h)
end

local function strokeRect(x, y, w, h, lw)
    love.graphics.setLineWidth(lw or 1)
    love.graphics.rectangle("line", x, y, w, h)
end

local function fillCircle(x, y, r)
    love.graphics.circle("fill", x, y, r)
end

local function strokeCircle(x, y, r, lw)
    love.graphics.setLineWidth(lw or 1)
    love.graphics.circle("line", x, y, r)
end

local function fillEllipse(cx, cy, rx, ry)
    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.scale(1, ry / rx)
    love.graphics.circle("fill", 0, 0, rx)
    love.graphics.pop()
end

local function strokeEllipse(cx, cy, rx, ry, lw)
    love.graphics.setLineWidth(lw or 1)
    love.graphics.push()
    love.graphics.translate(cx, cy)
    love.graphics.scale(1, ry / rx)
    love.graphics.circle("line", 0, 0, rx)
    love.graphics.pop()
end

local function drawLine(x1, y1, x2, y2, lw)
    love.graphics.setLineWidth(lw or 1)
    love.graphics.line(x1, y1, x2, y2)
end

-- ─── DRAW GANDHI ───
local function drawGandhi(bobY, action, isBlocking, fr, superActive, superReady, superBoomerangs)
    -- Dhoti body
    setColor(C.dhoti); fillRect(-15, 25 + bobY, 30, 45)
    -- Drape
    setColor(C.drape); fillRect(-18, 40 + bobY, 6, 30)
    -- Legs (skip during kick — drawn in kick pose instead)
    if action ~= "kick" then
        setColor(C.leg_gandhi); fillRect(-12, 70 + bobY, 8, 18); fillRect(4, 70 + bobY, 8, 18)
        setColor(C.sandal); fillRect(-14, 86 + bobY, 12, 4); fillRect(2, 86 + bobY, 12, 4)
    end
    -- Head
    setColor(C.skin); fillCircle(0, 18 + bobY, 16)
    -- Glasses
    setColor(C.glasses)
    strokeCircle(-6, 16 + bobY, 5, 1.5)
    strokeCircle(6, 16 + bobY, 5, 1.5)
    drawLine(-1, 16 + bobY, 1, 16 + bobY, 1.5)
    -- Eyes
    setColor(C.eye_dark); fillRect(-7, 15 + bobY, 3, 3); fillRect(5, 15 + bobY, 3, 3)
    -- Smile
    setColor(C.smile)
    love.graphics.setLineWidth(1)
    love.graphics.arc("line", "open", 0, 20 + bobY, 5, 0.1, PI - 0.1)
    -- Ears
    setColor(C.skin)
    fillEllipse(-15, 18 + bobY, 4, 6)
    fillEllipse(15, 18 + bobY, 4, 6)

    -- Action poses
    if action == "super" then
        setColor(C.skin); fillRect(15, 25 + bobY, 25, 8); fillRect(-20, 35 + bobY, 12, 8)
        love.graphics.setColor(232/255, 169/255, 38/255, 0.4)
        fillCircle(0, 40 + bobY, 30)
    elseif action == "punch" then
        setColor(C.skin); fillRect(15, 30 + bobY, 30, 8)
        setColor(C.stick); fillRect(40, 25 + bobY, 4, 25)
    elseif action == "kick" then
        -- Standing leg
        setColor(C.leg_gandhi); fillRect(-12, 70 + bobY, 8, 18)
        setColor(C.sandal); fillRect(-14, 86 + bobY, 12, 4)
        -- Kicking leg (extended)
        setColor(C.leg_gandhi); fillRect(12, 65 + bobY, 28, 8)
        setColor(C.sandal); fillRect(36, 63 + bobY, 12, 4)
        -- Arms crossed
        setColor(C.skin); fillRect(15, 30 + bobY, 15, 8); fillRect(-15, 30 + bobY, 15, 8)
    elseif action == "special" then
        local angle = fr * 0.5
        love.graphics.push()
        love.graphics.translate(0, 40 + bobY)
        love.graphics.rotate(angle)
        setColor(C.gandhi_accent); fillRect(-30, -2, 60, 4)
        love.graphics.pop()
        setColor(C.skin); fillRect(15, 30 + bobY, 12, 8); fillRect(-27, 30 + bobY, 12, 8)
        love.graphics.setColor(232/255, 169/255, 38/255, 0.3)
        fillCircle(0, 45 + bobY, 35)
    elseif isBlocking then
        setColor(C.skin); fillRect(-5, 28 + bobY, 25, 8); fillRect(-20, 32 + bobY, 25, 8)
        love.graphics.setColor(232/255, 169/255, 38/255, 0.6)
        strokeCircle(0, 45 + bobY, 25, 2)
    else
        -- Idle arms
        setColor(C.skin); fillRect(15, 30 + bobY, 12, 8); fillRect(-27, 30 + bobY, 12, 8)
        -- Walking stick (only when not in super mode)
        if not superActive then
            setColor(C.stick); fillRect(22, 25 + bobY, 3, 50)
        end
    end

    -- Boomerang icons above head (shown when super is ready OR active)
    if superReady or superActive then
        local boomerangsToShow = superActive and superBoomerangs or 2
        for i = 1, 2 do
            if i <= boomerangsToShow then
                love.graphics.setColor(232/255, 169/255, 38/255, 1) -- live boomerang (gold)
            else
                love.graphics.setColor(0.3, 0.3, 0.3, 0.5) -- spent (dark)
            end
            -- Draw small boomerang shape (horizontal bar)
            fillRect(-8 + (i-1) * 14, -12 + bobY, 10, 4)
        end
    end
end

-- ─── DRAW BIN LADEN ───
local function drawBinLaden(bobY, action, isBlocking, fr, superActive, superBullets, superReady)
    -- Robe
    setColor(C.robe); fillRect(-18, 22 + bobY, 36, 50)
    setColor(C.robe_collar); fillRect(-18, 22 + bobY, 36, 5)
    setColor(C.robe_center); fillRect(-2, 22 + bobY, 4, 50)
    -- Legs (skip during kick — drawn in kick pose instead)
    if action ~= "kick" then
        setColor(C.leg_bin); fillRect(-12, 70 + bobY, 8, 18); fillRect(4, 70 + bobY, 8, 18)
        setColor(C.boot); fillRect(-14, 84 + bobY, 12, 6); fillRect(2, 84 + bobY, 12, 6)
    end
    -- Turban
    setColor(C.turban)
    love.graphics.arc("fill", "pie", 0, 12 + bobY, 17, -PI, 0)
    fillRect(-17, 5 + bobY, 34, 10)
    -- Face
    setColor(C.skin)
    love.graphics.arc("fill", "pie", 0, 18 + bobY, 14, 0, PI)
    fillRect(-14, 12 + bobY, 28, 10)
    -- Beard (pentagon)
    setColor(C.beard)
    local bverts = {-10, 22+bobY, 10, 22+bobY, 6, 35+bobY, 0, 38+bobY, -6, 35+bobY}
    love.graphics.polygon("fill", bverts)
    -- Eyes
    setColor(C.eye_white); fillRect(-8, 14 + bobY, 6, 4); fillRect(2, 14 + bobY, 6, 4)
    setColor(C.pupil); fillRect(-6, 15 + bobY, 3, 3); fillRect(3, 15 + bobY, 3, 3)
    -- Eyebrows
    setColor(C.eyebrow)
    love.graphics.push(); love.graphics.translate(-5, 12 + bobY); love.graphics.rotate(-0.2)
    fillRect(-4, 0, 8, 2); love.graphics.pop()
    love.graphics.push(); love.graphics.translate(5, 12 + bobY); love.graphics.rotate(0.2)
    fillRect(-4, 0, 8, 2); love.graphics.pop()
    -- Backpack
    setColor(C.backpack); fillRect(-22, 28 + bobY, 8, 20)
    setColor(C.backpack_detail); fillRect(-21, 30 + bobY, 6, 16)

    -- Action poses
    if superActive then
        -- AK-47 held
        setColor(C.robe); fillRect(10, 32 + bobY, 15, 8)
        setColor(C.gun_body); fillRect(20, 30 + bobY, 35, 6)
        setColor(C.gun_stock); fillRect(15, 30 + bobY, 12, 10)
        setColor(C.gun_grip); fillRect(28, 36 + bobY, 4, 10)
        setColor(C.gun_muzzle); fillRect(50, 29 + bobY, 8, 3)
        setColor(C.robe); fillRect(-5, 34 + bobY, 20, 6)
        -- Muzzle flash
        if action == "super" and fr % 4 < 2 then
            setColor(C.muzzle_yellow); fillCircle(60, 31 + bobY, 6)
            setColor(C.muzzle_white); fillCircle(60, 31 + bobY, 3)
        end
    elseif action == "punch" then
        setColor(C.robe); fillRect(15, 30 + bobY, 30, 10)
        setColor(C.skin); fillRect(42, 28 + bobY, 10, 12)
    elseif action == "kick" then
        -- Standing leg
        setColor(C.leg_bin); fillRect(-12, 70 + bobY, 8, 18)
        setColor(C.boot); fillRect(-14, 84 + bobY, 12, 6)
        -- Kicking leg (extended)
        setColor(C.leg_bin); fillRect(12, 65 + bobY, 30, 10)
        setColor(C.boot); fillRect(38, 63 + bobY, 10, 12)
        -- Arms guard
        setColor(C.robe); fillRect(15, 30 + bobY, 15, 8); fillRect(-15, 30 + bobY, 15, 8)
    elseif action == "special" then
        setColor(C.robe); fillRect(15, 25 + bobY, 20, 8); fillRect(-35, 25 + bobY, 20, 8)
        local ps = 20 + math.sin(fr * 0.4) * 8
        love.graphics.setColor(192/255, 57/255, 43/255, 0.5); fillCircle(0, 45 + bobY, ps)
        love.graphics.setColor(1, 50/255, 50/255, 0.8); fillCircle(0, 45 + bobY, ps * 0.5)
    elseif isBlocking then
        setColor(C.robe); fillRect(-5, 25 + bobY, 25, 10); fillRect(-20, 30 + bobY, 25, 10)
        love.graphics.setColor(192/255, 57/255, 43/255, 0.5); strokeCircle(0, 45 + bobY, 25, 2)
    else
        -- Idle arms
        setColor(C.robe); fillRect(15, 30 + bobY, 15, 8); fillRect(-30, 30 + bobY, 15, 8)
        setColor(C.skin); fillRect(28, 28 + bobY, 8, 10); fillRect(-30, 28 + bobY, 8, 10)
    end

    -- Bullet icons above head (shown when super is ready OR active)
    if superReady or superActive then
        local bulletsToShow = superActive and superBullets or 5
        for i = 1, 5 do
            if i <= bulletsToShow then
                love.graphics.setColor(1, 0.85, 0.2, 1) -- live bullet (gold)
            else
                love.graphics.setColor(0.3, 0.3, 0.3, 0.5) -- spent (dark)
            end
            fillRect(-14 + (i-1) * 7, -12 + bobY, 4, 8)
        end
    end
end

-- ─── DRAW CHARACTER (dispatcher) ───
local function drawCharacter(player, facing, fr, action, isBlocking, superReady, superActive, superBullets)
    local x, y = player.x, player.y
    local isGandhi = player.id == "gandhi"

    love.graphics.push()
    love.graphics.translate(x + CHAR_W / 2, y)
    if facing == -1 then love.graphics.scale(-1, 1) end

    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.3)
    fillEllipse(0, CHAR_H + 2, 30, 8)

    local bobY = math.sin(fr * 0.15) * 2

    -- Super ready aura
    if superReady and not superActive then
        local pulse = math.sin(fr * 0.15) * 0.3 + 0.5
        if isGandhi then
            love.graphics.setColor(232/255, 169/255, 38/255, pulse * 0.25)
        else
            love.graphics.setColor(192/255, 57/255, 43/255, pulse * 0.25)
        end
        fillCircle(0, 45, 45 + math.sin(fr * 0.2) * 5)
        for i = 0, 3 do
            local a = fr * 0.05 + i * PI / 2
            local r = 35 + math.sin(fr * 0.1 + i) * 10
            if isGandhi then setColor(C.gandhi_accent) else love.graphics.setColor(1, 0.27, 0.27, 1) end
            fillRect(math.cos(a) * r - 1, 45 + math.sin(a) * r - 1, 3, 3)
        end
    end

    -- Super active aura
    if superActive then
        local pulse = math.sin(fr * 0.25) * 0.2 + 0.4
        if isGandhi then
            love.graphics.setColor(232/255, 169/255, 38/255, pulse)
        else
            love.graphics.setColor(192/255, 57/255, 43/255, pulse)
        end
        fillCircle(0, 45, 35)
    end

    if isGandhi then
        drawGandhi(bobY, action, isBlocking, fr, superActive, superReady, player.superBoomerangs or 0)
    else
        drawBinLaden(bobY, action, isBlocking, fr, superActive, superBullets, superReady)
    end

    love.graphics.pop()
end

-- ─── DRAW PROJECTILES ───
local function drawProjectiles(fr)
    for _, p in ipairs(g.projectiles) do
        if p.type == "boomerang" then
            love.graphics.push()
            love.graphics.translate(p.x, p.y)
            love.graphics.rotate(p.rotation)
            setColor(C.gandhi_accent); fillRect(-20, -3, 40, 6)
            setColor(C.white); fillRect(-18, -1, 8, 2); fillRect(10, -1, 8, 2)
            local pa = 0.3 + math.sin(fr * 0.3) * 0.15
            love.graphics.setColor(232/255, 169/255, 38/255, pa)
            fillCircle(0, 0, 18)
            love.graphics.pop()
        elseif p.type == "bullet" then
            love.graphics.push()
            love.graphics.translate(p.x, p.y)
            setColor(C.bullet_yellow)
            if p.dir > 0 then fillRect(-2, -2, 12, 4) else fillRect(-10, -2, 12, 4) end
            local trailAlpha = math.max(0, 0.5 - p.age * 0.03)
            love.graphics.setColor(1, 150/255, 50/255, trailAlpha)
            if p.dir > 0 then fillRect(-14, -1, 10, 2) else fillRect(2, -1, 10, 2) end
            love.graphics.pop()
        end
    end
end

-- ─── DRAW STAGE ───
local function drawStage(fr)
    -- Sky gradient (simplified to bands)
    local bands = 20
    for i = 0, bands - 1 do
        local t = i / bands
        local r, gc, b
        if t < 0.5 then
            local lt = t / 0.5
            r = 10/255 * (1-lt) + 26/255 * lt
            gc = 10/255 * (1-lt) + 10/255 * lt
            b = 46/255 * (1-lt) + 62/255 * lt
        else
            local lt = (t - 0.5) / 0.5
            r = 26/255 * (1-lt) + 45/255 * lt
            gc = 10/255 * (1-lt) + 27/255 * lt
            b = 62/255 * (1-lt) + 105/255 * lt
        end
        love.graphics.setColor(r, gc, b, 1)
        local yy = (GROUND_Y / bands) * i
        fillRect(0, yy, STAGE_W, GROUND_Y / bands + 1)
    end

    -- Mountains
    setColor(C.mountain)
    local mverts = {0, GROUND_Y}
    for x = 0, STAGE_W, 40 do
        local my = GROUND_Y - 60 - math.sin(x * 0.02) * 30 - math.cos(x * 0.01) * 20
        table.insert(mverts, x)
        table.insert(mverts, my)
    end
    table.insert(mverts, STAGE_W)
    table.insert(mverts, GROUND_Y)
    if #mverts >= 6 then
        love.graphics.polygon("fill", mverts)
    end

    -- Moon
    setColor(C.moon); fillCircle(650, 60, 25)

    -- Stars
    for i = 0, 29 do
        local sx = (i * 137.5) % STAGE_W
        local sy = (i * 73.1) % (GROUND_Y - 80)
        local tw = math.sin(fr * 0.1 + i) * 0.5 + 0.5
        love.graphics.setColor(1, 1, 1, 0.3 + tw * 0.7)
        fillRect(sx, sy, 2, 2)
    end

    -- Torches
    for _, tx in ipairs({80, 720}) do
        setColor(C.torch_pole); fillRect(tx - 3, GROUND_Y - 80, 6, 80)
        local fl = math.sin(fr * 0.3 + tx) * 3
        love.graphics.setColor(1, 0.4, 0, 1)
        fillEllipse(tx, GROUND_Y - 85, 8 + fl, 15 + fl)
        love.graphics.setColor(1, 0.67, 0, 1)
        fillEllipse(tx, GROUND_Y - 88, 4 + fl * 0.5, 8 + fl * 0.5)
        love.graphics.setColor(1, 0.4, 0, 0.1)
        fillCircle(tx, GROUND_Y - 80, 40)
    end

    -- Ground gradient
    local gBands = 10
    for i = 0, gBands - 1 do
        local t = i / gBands
        local r, gc, b
        if t < 0.3 then
            local lt = t / 0.3
            r = 74/255 * (1-lt) + 58/255 * lt
            gc = 53/255 * (1-lt) + 40/255 * lt
            b = 32/255 * (1-lt) + 16/255 * lt
        else
            local lt = (t - 0.3) / 0.7
            r = 58/255 * (1-lt) + 26/255 * lt
            gc = 40/255 * (1-lt) + 16/255 * lt
            b = 16/255 * (1-lt) + 5/255 * lt
        end
        love.graphics.setColor(r, gc, b, 1)
        local yy = GROUND_Y + ((STAGE_H - GROUND_Y) / gBands) * i
        fillRect(0, yy, STAGE_W, (STAGE_H - GROUND_Y) / gBands + 1)
    end

    -- Ground line
    love.graphics.setColor(106/255, 69/255, 48/255, 1)
    drawLine(0, GROUND_Y, STAGE_W, GROUND_Y, 2)

    -- Ground texture
    love.graphics.setColor(90/255, 58/255, 32/255, 1)
    for i = 0, 19 do
        fillRect((i * 47) % STAGE_W, GROUND_Y + 5 + (i % 3) * 15, 15 + (i % 4) * 5, 2)
    end
end

-- ─── DRAW HEALTH BAR ───
local function drawHealthBar(x, y, health, maxHealth, special, name, accent, isRight, superReady, superActive, superLabel, superCount)
    local barW, barH = 280, 20
    local ratio = math.max(0, health / maxHealth)
    local specR = math.min(1, special / 100)

    -- Name with dark background for readability
    love.graphics.setColor(0, 0, 0, 0.5); fillRect(x, y - 16, barW, 15)
    love.graphics.setFont(pixelFontSmall)
    setColor(C.white)
    if isRight then
        love.graphics.printf(name, x, y - 15, barW, "right")
    else
        love.graphics.printf(name, x, y - 15, barW, "left")
    end

    -- Health bar bg
    love.graphics.setColor(34/255, 34/255, 34/255, 1); fillRect(x, y, barW, barH)

    -- Health bar fill
    local hr, hg, hb
    if ratio > 0.5 then hr, hg, hb = 0, 0.8, 0.27
    elseif ratio > 0.25 then hr, hg, hb = 0.8, 0.67, 0
    else hr, hg, hb = 0.8, 0.13, 0 end
    love.graphics.setColor(hr, hg, hb, 1)
    if isRight then
        fillRect(x + barW * (1 - ratio), y, barW * ratio, barH)
    else
        fillRect(x, y, barW * ratio, barH)
    end

    -- Health bar border
    love.graphics.setColor(accent[1], accent[2], accent[3], 1)
    strokeRect(x, y, barW, barH, 2)

    -- Health text
    love.graphics.setFont(pixelFontTiny)
    setColor(C.white)
    love.graphics.printf(tostring(math.ceil(health)), x, y + 4, barW, "center")

    -- Special bar
    local sY = y + barH + 4
    love.graphics.setColor(17/255, 17/255, 17/255, 1); fillRect(x, sY, barW, 7)
    love.graphics.setColor(accent[1], accent[2], accent[3], 1)
    if isRight then
        fillRect(x + barW * (1 - specR), sY, barW * specR, 7)
    else
        fillRect(x, sY, barW * specR, 7)
    end
    love.graphics.setColor(85/255, 85/255, 85/255, 1); strokeRect(x, sY, barW, 7, 1)

    if specR >= 1 then
        love.graphics.setFont(pixelFontTiny)
        love.graphics.setColor(accent[1], accent[2], accent[3], 1)
        if isRight then
            love.graphics.printf("SPECIAL READY!", x, sY + 9, barW, "right")
        else
            love.graphics.printf("SPECIAL READY!", x, sY + 9, barW, "left")
        end
    end

    -- Super indicator
    local suY = sY + 22
    love.graphics.setFont(pixelFontTiny)
    if superActive then
        love.graphics.setColor(1, 0.27, 0.27, 1)
        local txt = superLabel .. " ACTIVE! [" .. tostring(superCount) .. "]"
        if isRight then love.graphics.printf(txt, x, suY, barW, "right")
        else love.graphics.printf(txt, x, suY, barW, "left") end
    elseif superReady then
        love.graphics.setColor(accent[1], accent[2], accent[3], 1)
        local txt = "* " .. superLabel .. " READY"
        if isRight then love.graphics.printf(txt, x, suY, barW, "right")
        else love.graphics.printf(txt, x, suY, barW, "left") end
    end
end

-- ─── DRAW HIT EFFECT ───
local function drawHitEffect(x, y, fr, etype)
    if fr > 15 then return end
    local alpha = 1 - fr / 15
    local size = 10 + fr * 3
    if etype == "special" then
        love.graphics.setColor(1, 200/255, 50/255, alpha); fillCircle(x, y, size * 2)
        love.graphics.setColor(1, 100/255, 0, alpha * 0.8); fillCircle(x, y, size * 1.2)
        for i = 0, 7 do
            local a = (i / 8) * TWO_PI
            love.graphics.setColor(1, 1, 100/255, alpha)
            fillRect(x + math.cos(a) * size * 1.5, y + math.sin(a) * size * 1.5, 4, 4)
        end
    else
        love.graphics.setColor(1, 1, 1, alpha); fillCircle(x, y, size)
        for i = 0, 4 do
            local a = (i / 5) * TWO_PI + fr * 0.2
            love.graphics.setColor(1, 220/255, 100/255, alpha)
            drawLine(
                x + math.cos(a) * size * 0.5, y + math.sin(a) * size * 0.5,
                x + math.cos(a) * size * 1.2, y + math.sin(a) * size * 1.2, 2
            )
        end
    end
end

-- ─── DRAW COMBO TEXT ───
local function drawComboText(x, y, combo, fr)
    if combo < 2 then return end
    local alpha = math.min(1, 2 - (fr % 60) / 30)
    if alpha <= 0 then return end
    love.graphics.setColor(1, 0.27, 0.27, alpha)
    love.graphics.setFont(pixelFontMed)
    love.graphics.printf(combo .. " HIT COMBO!", x - 80, y - 25, 160, "center")
end

-- ─── ATTACK HANDLER ───
handleAttack = function(attacker, defender, atype)
    local cd = CHARACTERS[attacker.id]
    local dmg, reach = 0, 50
    if atype == "punch" then dmg = cd.punchDmg; reach = 55
    elseif atype == "kick" then dmg = cd.kickDmg; reach = 65
    elseif atype == "special" then dmg = cd.specialDmg; reach = 80 end

    if math.abs(attacker.x - defender.x) < reach + CHAR_W then
        if defender.isBlocking then
            dmg = dmg * (1 - cd.blockReduction)
            g.shakeFrames = 3; SFX.block()
        else
            g.shakeFrames = atype == "special" and 10 or 5
            if atype == "special" then g.slowMotion = 8 end
            defender.combo = defender.combo + 1
            defender.comboTimer = 60
            if atype == "special" then SFX.special() else SFX.hit() end
        end
        defender.health = defender.health - dmg
        defender.hitStun = atype == "special" and 15 or 8
        attacker.special = math.min(100, attacker.special + dmg * 0.8)
        attacker.dmgDealt = attacker.dmgDealt + dmg
        if not attacker.superReady and not attacker.superActive and attacker.dmgDealt >= defender.maxHealth * 0.5 then
            attacker.superReady = true; SFX.superReady()
        end
        table.insert(g.hitEffects, {
            x = (attacker.x + defender.x) / 2 + CHAR_W / 2,
            y = attacker.y + 30, frame = 0,
            type = atype == "special" and "special" or "normal"
        })
        if defender.health <= 0 then
            defender.health = 0
            handleRoundEnd(attacker == g.p1 and "p1" or "p2")
        end
    end
end

-- ─── ROUND END ───
handleRoundEnd = function(winner)
    -- Prevent double-trigger
    if gameState ~= "fighting" then return end
    gameState = "ko"; announcement = "K.O.!"; SFX.ko()
    if winner ~= "draw" then wins[winner] = wins[winner] + 1 end

    addGameTimer(2.5, function()
        if wins.p1 >= 2 or wins.p2 >= 2 then
            announcement = (wins.p1 >= 2 and CHARACTERS.gandhi.name or CHARACTERS.binladen.name) .. " WINS!"
            SFX.win(); gameState = "gameover"
        else
            local nr = round + 1; round = nr
            announcement = nr == 3 and "FINAL ROUND" or ("ROUND " .. nr)
            SFX.roundStart()
            g = initGame(); timer = ROUND_TIME; timerAccum = 0
            addGameTimer(1.5, function()
                announcement = "FIGHT!"; SFX.fight()
                gameState = "fighting"
                addGameTimer(1.0, function() announcement = "" end)
            end)
        end
    end)
end

-- ─── START NEW GAME ───
local function startNewGame()
    g = initGame(); round = 1; wins = { p1 = 0, p2 = 0 }; timer = ROUND_TIME; timerAccum = 0
    hasPlayed = true; gameState = "fighting"; announcement = "ROUND 1"
    SFX.roundStart(); gameTimers = {}
    addGameTimer(1.5, function()
        announcement = "FIGHT!"; SFX.fight()
        addGameTimer(1.0, function() announcement = "" end)
    end)
end

local function resumeGame() SFX.menuSelect(); gameState = "fighting" end

-- ─── MENU SELECT ───
local function handleMenuSelect(idx)
    local items = getMenuItems()
    local item = items[idx]
    SFX.menuSelect()
    if item == "RESUME" then resumeGame()
    elseif item == "NEW GAME" then startNewGame()
    elseif item == "CONTROLS" then gameState = "controls"
    elseif item and item:sub(1, 5) == "SOUND" then
        soundOn = not soundOn; SFX.setMuted(not soundOn)
    elseif item == "ABOUT" then gameState = "about"
    elseif item == "EXIT" then
        hasPlayed = false; g = initGame(); round = 1; wins = { p1 = 0, p2 = 0 }
        timer = ROUND_TIME; timerAccum = 0; announcement = ""; gameState = "menu"; menuIndex = 1; gameTimers = {}
    end
end

-- ═══════════════════════════════════════════════════
-- LÖVE CALLBACKS
-- ═══════════════════════════════════════════════════

function love.load()
    love.graphics.setDefaultFilter("nearest", "nearest")
    -- Try to load Press Start 2P, fall back to default
    local ok, font
    ok = pcall(function()
        pixelFontTiny = love.graphics.newFont("PressStart2P.ttf", 8)
        pixelFontSmall = love.graphics.newFont("PressStart2P.ttf", 11)
        pixelFontMed = love.graphics.newFont("PressStart2P.ttf", 14)
        pixelFont = love.graphics.newFont("PressStart2P.ttf", 10)
        pixelFontLarge = love.graphics.newFont("PressStart2P.ttf", 24)
        pixelFontHuge = love.graphics.newFont("PressStart2P.ttf", 30)
    end)
    if not ok then
        -- Fallback to built-in font at various sizes
        pixelFontTiny = love.graphics.newFont(8)
        pixelFontSmall = love.graphics.newFont(11)
        pixelFontMed = love.graphics.newFont(14)
        pixelFont = love.graphics.newFont(10)
        pixelFontLarge = love.graphics.newFont(24)
        pixelFontHuge = love.graphics.newFont(30)
    end
    g = initGame()
end

function love.update(dt)
    updateDelayedSounds(dt)
    updateGameTimers(dt)

    if gameState == "fighting" then
        -- Timer countdown
        timerAccum = timerAccum + dt
        if timerAccum >= 1 then
            timerAccum = timerAccum - 1
            timer = timer - 1
            if timer <= 0 then
                timer = 0
                if g.p1.health > g.p2.health then handleRoundEnd("p1")
                elseif g.p2.health > g.p1.health then handleRoundEnd("p2")
                else handleRoundEnd("draw") end
            end
        end

        frame = frame + 1
        local held = keys

        -- ─── P1 (Gandhi) ───
        if g.p1.hitStun > 0 then
            g.p1.hitStun = g.p1.hitStun - 1
        else
            if held["a"] then g.p1.x = g.p1.x - CHARACTERS.gandhi.speed end
            if held["d"] then g.p1.x = g.p1.x + CHARACTERS.gandhi.speed end
            if held["w"] and not g.p1.isJumping then g.p1.vy = -14; g.p1.isJumping = true end
            g.p1.isBlocking = held["s"] == true
            if not g.p1.action then
                if held["f"] then g.p1.action = "punch"; g.p1.actionTimer = 12; SFX.punch(); handleAttack(g.p1, g.p2, "punch")
                elseif held["g"] then g.p1.action = "kick"; g.p1.actionTimer = 18; SFX.kick(); handleAttack(g.p1, g.p2, "kick")
                elseif held["h"] and g.p1.special >= 100 then g.p1.action = "special"; g.p1.actionTimer = 30; g.p1.special = 0; handleAttack(g.p1, g.p2, "special")
                end
            end
            -- Super: Gandhi tap-fires boomerangs (2 max, one per T press)
            if justPressed["t"] and g.p1.superReady and not g.p1.superActive then
                g.p1.superReady = false; g.p1.superActive = true; g.p1.superBoomerangs = 2
                SFX.boomerang()
                local dir = g.p1.facing
                table.insert(g.projectiles, { type = "boomerang", owner = "p1", x = g.p1.x + CHAR_W/2 + dir*20, y = g.p1.y + 35, dir = dir, startX = g.p1.x + CHAR_W/2, phase = "out", rotation = 0, age = 0, hit = false })
                g.p1.superBoomerangs = 1
                g.p1.action = "super"; g.p1.actionTimer = 15
            elseif justPressed["t"] and g.p1.superActive and g.p1.superBoomerangs > 0 then
                SFX.boomerang()
                local dir = g.p1.facing
                table.insert(g.projectiles, { type = "boomerang", owner = "p1", x = g.p1.x + CHAR_W/2 + dir*20, y = g.p1.y + 35, dir = dir, startX = g.p1.x + CHAR_W/2, phase = "out", rotation = 1.5, age = 0, hit = false })
                g.p1.superBoomerangs = g.p1.superBoomerangs - 1
                g.p1.action = "super"; g.p1.actionTimer = 15
                if g.p1.superBoomerangs <= 0 then
                    addGameTimer(0.5, function() g.p1.superActive = false; g.p1.action = nil end)
                end
            end
        end

        -- ─── P2 (Bin Laden) ───
        if g.p2.hitStun > 0 then
            g.p2.hitStun = g.p2.hitStun - 1
        else
            if held["left"] then g.p2.x = g.p2.x - CHARACTERS.binladen.speed end
            if held["right"] then g.p2.x = g.p2.x + CHARACTERS.binladen.speed end
            if held["up"] and not g.p2.isJumping then g.p2.vy = -14; g.p2.isJumping = true end
            g.p2.isBlocking = held["down"] == true
            if not g.p2.action or g.p2.action == "super" then
                if not g.p2.superActive then
                    if held["j"] and g.p2.action ~= "punch" then g.p2.action = "punch"; g.p2.actionTimer = 12; SFX.punch(); handleAttack(g.p2, g.p1, "punch")
                    elseif held["k"] and g.p2.action ~= "kick" then g.p2.action = "kick"; g.p2.actionTimer = 18; SFX.kick(); handleAttack(g.p2, g.p1, "kick")
                    elseif held["l"] and g.p2.special >= 100 and g.p2.action ~= "special" then g.p2.action = "special"; g.p2.actionTimer = 30; g.p2.special = 0; handleAttack(g.p2, g.p1, "special")
                    end
                end
            end
            -- Super: BL activates AK-47
            if justPressed[";"] and g.p2.superReady and not g.p2.superActive then
                g.p2.superReady = false; g.p2.superActive = true; g.p2.superBullets = 5
                SFX.gunshot()
                local dir = g.p2.facing
                table.insert(g.projectiles, { type = "bullet", owner = "p2", x = g.p2.x + CHAR_W/2 + dir*30, y = g.p2.y + 33, dir = dir, age = 0, hit = false })
                g.p2.superBullets = 4; g.p2.action = "super"; g.p2.actionTimer = 10
            elseif justPressed[";"] and g.p2.superActive and g.p2.superBullets > 0 then
                SFX.gunshot()
                local dir = g.p2.facing
                table.insert(g.projectiles, { type = "bullet", owner = "p2", x = g.p2.x + CHAR_W/2 + dir*30, y = g.p2.y + 33, dir = dir, age = 0, hit = false })
                g.p2.superBullets = g.p2.superBullets - 1; g.p2.action = "super"; g.p2.actionTimer = 10
                if g.p2.superBullets <= 0 then
                    addGameTimer(0.3, function() g.p2.superActive = false; g.p2.action = nil end)
                end
            end
        end

        -- Physics
        for _, p in ipairs({g.p1, g.p2}) do
            p.vy = p.vy + GRAVITY; p.y = p.y + p.vy
            if p.y >= GROUND_Y - CHAR_H then p.y = GROUND_Y - CHAR_H; p.vy = 0; p.isJumping = false end
            p.x = math.max(10, math.min(STAGE_W - CHAR_W - 10, p.x))
            if p.actionTimer > 0 then
                p.actionTimer = p.actionTimer - 1
                if p.actionTimer <= 0 then
                    if p.action ~= "super" or not p.superActive then p.action = nil end
                end
            end
            if p.comboTimer > 0 then p.comboTimer = p.comboTimer - 1; if p.comboTimer <= 0 then p.combo = 0 end end
        end

        -- Facing
        g.p1.facing = g.p1.x < g.p2.x and 1 or -1
        g.p2.facing = g.p2.x < g.p1.x and 1 or -1

        -- Push apart
        local overlap = CHAR_W - math.abs(g.p1.x - g.p2.x)
        if overlap > 0 and math.abs(g.p1.y - g.p2.y) < CHAR_H then
            local push = overlap / 2
            if g.p1.x < g.p2.x then g.p1.x = g.p1.x - push; g.p2.x = g.p2.x + push
            else g.p1.x = g.p1.x + push; g.p2.x = g.p2.x - push end
        end

        -- Passive special regen
        g.p1.special = math.min(100, g.p1.special + 0.05)
        g.p2.special = math.min(100, g.p2.special + 0.05)

        updateProjectiles()

        -- Projectile KO check
        for _, p in ipairs({g.p1, g.p2}) do
            if p.health <= 0 then
                p.health = 0
                handleRoundEnd(p == g.p1 and "p2" or "p1")
                break
            end
        end

        if frame % 120 == 0 then SFX.bgDrone() end
    else
        frame = frame + 1
    end

    -- Update hit effects
    local newEffects = {}
    for _, e in ipairs(g.hitEffects) do
        e.frame = e.frame + 1
        if e.frame < 20 then table.insert(newEffects, e) end
    end
    g.hitEffects = newEffects

    if g.shakeFrames > 0 then g.shakeFrames = g.shakeFrames - 1 end
    if g.slowMotion > 0 then g.slowMotion = g.slowMotion - 1 end

    -- Clear justPressed
    justPressed = {}
end

-- Override: track keys as held
function love.keypressed(key, scancode, isrepeat)
    keys[key] = true
    justPressed[key] = true

    -- Route to menu/game handlers
    if key == "escape" then
        if gameState == "fighting" then SFX.menuBack(); gameState = "paused"; menuIndex = 1
        elseif gameState == "paused" then resumeGame()
        elseif gameState == "about" or gameState == "controls" then SFX.menuBack(); gameState = hasPlayed and "paused" or "menu"
        elseif gameState == "gameover" then gameState = "menu"; menuIndex = 1; announcement = ""; hasPlayed = false
        end
        return
    end

    if gameState == "menu" or gameState == "paused" then
        local items = getMenuItems()
        if key == "up" or key == "w" then SFX.menuMove(); menuIndex = ((menuIndex - 2) % #items) + 1
        elseif key == "down" or key == "s" then SFX.menuMove(); menuIndex = (menuIndex % #items) + 1
        elseif key == "return" or key == "space" then handleMenuSelect(menuIndex)
        end
        return
    end

    if gameState == "about" or gameState == "controls" then
        if key == "return" or key == "space" then SFX.menuBack(); gameState = hasPlayed and "paused" or "menu" end
        return
    end

    if gameState == "gameover" and (key == "return" or key == "space") then
        gameState = "menu"; menuIndex = 1; announcement = ""; hasPlayed = false
    end
end

function love.keyreleased(key)
    keys[key] = false
end

-- ─── DRAW ───
function love.draw()
    love.graphics.push()

    -- Screen shake
    if g.shakeFrames > 0 then
        love.graphics.translate(
            (math.random() - 0.5) * g.shakeFrames * 3,
            (math.random() - 0.5) * g.shakeFrames * 3
        )
    end

    love.graphics.clear(0, 0, 0, 1)
    drawStage(frame)

    if gameState == "menu" then
        -- Idle characters in background
        drawCharacter({ x = 150, y = GROUND_Y - CHAR_H, id = "gandhi" }, 1, frame, nil, false, false, false, 0)
        drawCharacter({ x = 550, y = GROUND_Y - CHAR_H, id = "binladen" }, -1, frame, nil, false, false, false, 0)

        -- Overlay
        love.graphics.setColor(0, 0, 0, 0.78); fillRect(0, 0, STAGE_W, STAGE_H)

        -- Border
        love.graphics.setColor(192/255, 57/255, 43/255, 1); strokeRect(STAGE_W/2 - 220, 30, 440, STAGE_H - 60, 3)
        love.graphics.setColor(232/255, 169/255, 38/255, 1); strokeRect(STAGE_W/2 - 217, 33, 434, STAGE_H - 66, 1)

        -- Title
        love.graphics.setFont(pixelFontHuge)
        love.graphics.setColor(1, 0.13, 0.13, 1)
        love.graphics.printf("MORTAL", 0, 50, STAGE_W, "center")
        love.graphics.printf("LEGENDS", 0, 87, STAGE_W, "center")

        -- Subtitle
        love.graphics.setFont(pixelFontSmall)
        setColor(C.gandhi_accent)
        love.graphics.printf("GANDHI  vs  BIN LADEN", 0, 127, STAGE_W, "center")

        -- Divider
        love.graphics.setColor(232/255, 169/255, 38/255, 0.27)
        drawLine(STAGE_W/2 - 140, 145, STAGE_W/2 + 140, 145, 1)

        -- Menu items
        local items = getMenuItems()
        love.graphics.setFont(pixelFont)
        for i, item in ipairs(items) do
            local iy = 160 + (i-1) * 30
            local sel = (i == menuIndex)
            if sel then
                love.graphics.setColor(232/255, 169/255, 38/255, 0.1); fillRect(STAGE_W/2 - 155, iy - 7, 310, 24)
                love.graphics.setColor(232/255, 169/255, 38/255, 1); strokeRect(STAGE_W/2 - 155, iy - 7, 310, 24, 1.5)
                -- Arrow
                love.graphics.printf(">", STAGE_W/2 - 150, iy - 4, 30, "left")
            end
            love.graphics.setColor(sel and {232/255, 169/255, 38/255, 1} or {119/255, 119/255, 119/255, 1})
            love.graphics.printf(item, 0, iy - 4, STAGE_W, "center")
        end

        -- Footer
        love.graphics.setFont(pixelFontTiny)
        love.graphics.setColor(68/255, 68/255, 68/255, 1)
        love.graphics.printf("UP/DOWN NAVIGATE  -  ENTER SELECT  -  ESC BACK", 0, STAGE_H - 30, STAGE_W, "center")

    elseif gameState == "paused" then
        drawCharacter(g.p1, g.p1.facing, frame, g.p1.action, g.p1.isBlocking, g.p1.superReady, g.p1.superActive, g.p1.superBullets)
        drawCharacter(g.p2, g.p2.facing, frame, g.p2.action, g.p2.isBlocking, g.p2.superReady, g.p2.superActive, g.p2.superBullets)

        love.graphics.setColor(0, 0, 0, 0.78); fillRect(0, 0, STAGE_W, STAGE_H)
        love.graphics.setColor(232/255, 169/255, 38/255, 1); strokeRect(STAGE_W/2 - 200, 20, 400, STAGE_H - 40, 2)

        love.graphics.setFont(pixelFontLarge)
        love.graphics.setColor(232/255, 169/255, 38/255, 1)
        love.graphics.printf("|| PAUSED ||", 0, 40, STAGE_W, "center")

        local items = getMenuItems()
        love.graphics.setFont(pixelFont)
        for i, item in ipairs(items) do
            local iy = 85 + (i-1) * 30
            local sel = (i == menuIndex)
            if sel then
                love.graphics.setColor(232/255, 169/255, 38/255, 0.1); fillRect(STAGE_W/2 - 155, iy - 7, 310, 24)
                love.graphics.setColor(232/255, 169/255, 38/255, 1); strokeRect(STAGE_W/2 - 155, iy - 7, 310, 24, 1.5)
                love.graphics.printf(">", STAGE_W/2 - 150, iy - 4, 30, "left")
            end
            love.graphics.setColor(sel and {232/255, 169/255, 38/255, 1} or {119/255, 119/255, 119/255, 1})
            love.graphics.printf(item, 0, iy - 4, STAGE_W, "center")
        end

        love.graphics.setFont(pixelFontTiny)
        love.graphics.setColor(68/255, 68/255, 68/255, 1)
        love.graphics.printf("UP/DOWN NAVIGATE  -  ENTER SELECT  -  ESC RESUME", 0, STAGE_H - 30, STAGE_W, "center")

    elseif gameState == "about" then
        love.graphics.setColor(0, 0, 0, 0.9); fillRect(0, 0, STAGE_W, STAGE_H)
        love.graphics.setColor(192/255, 57/255, 43/255, 1); strokeRect(STAGE_W/2 - 200, 20, 400, STAGE_H - 40, 2)

        love.graphics.setFont(pixelFontLarge)
        love.graphics.setColor(192/255, 57/255, 43/255, 1)
        love.graphics.printf("ABOUT", 0, 40, STAGE_W, "center")

        local lines = {
            {text = "MORTAL LEGENDS", color = C.gandhi_accent},
            {text = "", color = C.white},
            {text = "A 2-PLAYER ARCADE FIGHTER", color = {0.67, 0.67, 0.67, 1}},
            {text = "INSPIRED BY CLASSIC", color = {0.67, 0.67, 0.67, 1}},
            {text = "90s FIGHTING GAMES.", color = {0.67, 0.67, 0.67, 1}},
            {text = "", color = C.white},
            {text = "* SUPER UNLOCKS AT 50% DMG *", color = {0.67, 0.67, 0.67, 1}},
            {text = "", color = C.white},
            {text = "GANDHI: 2x HOMING BOOMERANG", color = {1, 0.53, 0.27, 1}},
            {text = "BIN LADEN: 5x TAP-FIRE AK-47", color = {1, 0.53, 0.27, 1}},
        }
        love.graphics.setFont(pixelFontTiny)
        for i, l in ipairs(lines) do
            setColor(l.color)
            love.graphics.printf(l.text, 0, 72 + (i-1) * 22, STAGE_W, "center")
        end

        if math.sin(frame * 0.08) > 0 then
            setColor(C.gandhi_accent)
            love.graphics.setFont(pixelFont)
            love.graphics.printf("ESC / ENTER TO GO BACK", 0, STAGE_H - 35, STAGE_W, "center")
        end

    elseif gameState == "controls" then
        love.graphics.setColor(0, 0, 0, 0.9); fillRect(0, 0, STAGE_W, STAGE_H)
        love.graphics.setColor(232/255, 169/255, 38/255, 1); strokeRect(STAGE_W/2 - 260, 12, 520, STAGE_H - 24, 2)

        love.graphics.setFont(pixelFontLarge)
        love.graphics.setColor(232/255, 169/255, 38/255, 1)
        love.graphics.printf("CONTROLS", 0, 22, STAGE_W, "center")

        -- Divider
        love.graphics.setColor(232/255, 169/255, 38/255, 0.27)
        drawLine(STAGE_W/2, 55, STAGE_W/2, 320, 1)

        -- P1
        love.graphics.setFont(pixelFontTiny)
        love.graphics.setColor(232/255, 169/255, 38/255, 1)
        love.graphics.printf("P1 -- GANDHI", 30, 62, STAGE_W/2 - 40, "center")
        local p1controls = {"W -- JUMP", "A / D -- MOVE", "S -- BLOCK", "F -- PUNCH", "G -- KICK", "H -- SPECIAL", "T -- SUPER (2x BOOMERANG)"}
        for i, l in ipairs(p1controls) do
            love.graphics.setColor(i == 7 and {1, 0.53, 0.27, 1} or {0.73, 0.73, 0.73, 1})
            love.graphics.printf(l, 30, 82 + (i-1) * 24, STAGE_W/2 - 40, "center")
        end

        -- P2
        love.graphics.setColor(192/255, 57/255, 43/255, 1)
        love.graphics.printf("P2 -- BIN LADEN", STAGE_W/2 + 10, 62, STAGE_W/2 - 40, "center")
        local p2controls = {"UP -- JUMP", "LEFT / RIGHT -- MOVE", "DOWN -- BLOCK", "J -- PUNCH", "K -- KICK", "L -- SPECIAL", "; -- SUPER (TAP x5 AK-47)"}
        for i, l in ipairs(p2controls) do
            love.graphics.setColor(i == 7 and {1, 0.53, 0.27, 1} or {0.73, 0.73, 0.73, 1})
            love.graphics.printf(l, STAGE_W/2 + 10, 82 + (i-1) * 24, STAGE_W/2 - 40, "center")
        end

        -- Footer info
        love.graphics.setColor(1, 0.53, 0.27, 1)
        love.graphics.printf("* SUPER UNLOCKS AFTER 50% DAMAGE DEALT *", 0, 270, STAGE_W, "center")
        love.graphics.setColor(0.53, 0.53, 0.53, 1)
        love.graphics.printf("GANDHI: HOMING BOOMERANGS | BIN LADEN: TAP ; FOR EACH BULLET", 0, 290, STAGE_W, "center")
        love.graphics.printf("ESC -- PAUSE GAME", 0, 310, STAGE_W, "center")

        if math.sin(frame * 0.08) > 0 then
            setColor(C.gandhi_accent)
            love.graphics.printf("ESC / ENTER TO GO BACK", 0, STAGE_H - 28, STAGE_W, "center")
        end

    else
        -- Fighting / KO / Gameover: draw characters + HUD
        drawCharacter(g.p1, g.p1.facing, frame, g.p1.action, g.p1.isBlocking, g.p1.superReady, g.p1.superActive, 0)
        drawCharacter(g.p2, g.p2.facing, frame, g.p2.action, g.p2.isBlocking, g.p2.superReady, g.p2.superActive, g.p2.superBullets)
        drawProjectiles(frame)

        for _, ef in ipairs(g.hitEffects) do
            drawHitEffect(ef.x, ef.y, ef.frame, ef.type)
        end

        drawComboText(g.p1.x + CHAR_W / 2, g.p1.y, g.p2.combo, frame)
        drawComboText(g.p2.x + CHAR_W / 2, g.p2.y, g.p1.combo, frame)

        -- HUD
        drawHealthBar(20, 28, g.p1.health, g.p1.maxHealth, g.p1.special, CHARACTERS.gandhi.name, CHARACTERS.gandhi.accent, false, g.p1.superReady, g.p1.superActive, "BOOMERANG", g.p1.superBoomerangs)
        drawHealthBar(500, 28, g.p2.health, g.p2.maxHealth, g.p2.special, CHARACTERS.binladen.name, CHARACTERS.binladen.accent, true, g.p2.superReady, g.p2.superActive, "AK-47", g.p2.superBullets)

        -- Timer box
        love.graphics.setColor(17/255, 17/255, 17/255, 1); fillRect(STAGE_W/2 - 30, 24, 60, 35)
        love.graphics.setColor(232/255, 169/255, 38/255, 1); strokeRect(STAGE_W/2 - 30, 24, 60, 35, 2)
        love.graphics.setFont(pixelFontLarge)
        love.graphics.setColor(timer <= 10 and {1, 0.2, 0.2, 1} or {1, 1, 1, 1})
        love.graphics.printf(tostring(timer), STAGE_W/2 - 30, 28, 60, "center")

        -- Round indicator
        love.graphics.setFont(pixelFontTiny)
        love.graphics.setColor(0.53, 0.53, 0.53, 1)
        love.graphics.printf("ROUND " .. round, STAGE_W/2 - 40, 64, 80, "center")

        -- Win dots
        for i = 0, 1 do
            love.graphics.setColor(i < wins.p1 and {232/255, 169/255, 38/255, 1} or {51/255, 51/255, 51/255, 1})
            fillCircle(330 + i * 15, 69, 4)
        end
        for i = 0, 1 do
            love.graphics.setColor(i < wins.p2 and {192/255, 57/255, 43/255, 1} or {51/255, 51/255, 51/255, 1})
            fillCircle(455 + i * 15, 69, 4)
        end

        -- ESC hint
        love.graphics.setColor(1, 1, 1, 0.2)
        love.graphics.setFont(pixelFontTiny)
        love.graphics.printf("ESC = PAUSE", 10, STAGE_H - 15, 200, "left")
    end

    -- Announcement overlay
    if announcement ~= "" and gameState ~= "menu" and gameState ~= "paused" and gameState ~= "about" and gameState ~= "controls" then
        love.graphics.setColor(0, 0, 0, 0.55); fillRect(0, STAGE_H/2 - 50, STAGE_W, 100)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.setFont(pixelFontHuge)
        love.graphics.printf(announcement, 0, STAGE_H/2 - 12, STAGE_W, "center")
        if gameState == "gameover" and math.sin(frame * 0.08) > 0 then
            setColor(C.gandhi_accent)
            love.graphics.setFont(pixelFontSmall)
            love.graphics.printf("PRESS ENTER", 0, STAGE_H/2 + 30, STAGE_W, "center")
        end
    end

    love.graphics.pop()
end
