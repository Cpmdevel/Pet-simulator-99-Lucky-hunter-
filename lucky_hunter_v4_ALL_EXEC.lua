--[[
╔═══════════════════════════════════════════════════════════════╗
║   LUCKY HUNTER v4.0  —  ALL EXECUTOR EDITION                 ║
║   Pet Simulator 99  |  RNG Event 2026                        ║
║   Target: Titanic Arcane Void/Halo Cat                       ║
║           Huge Nebula Lion, Eclipse Owl, Cataclysm Bear      ║
║           Huge Oracle Tiger, Prism Pegasus, Anubis           ║
║   Works: Delta, Solara, Wave, Xeno, Fluxus, Arceus X        ║
╚═══════════════════════════════════════════════════════════════╝
--]]

-- ═══════════════════════════════════════════
-- SECTION 1: SAFE CLEANUP
-- ═══════════════════════════════════════════
local function safeDestroy(parent, name)
    pcall(function()
        local old = parent:FindFirstChild(name)
        if old then old:Destroy() end
    end)
end

local LP = game:GetService("Players").LocalPlayer
safeDestroy(LP:WaitForChild("PlayerGui", 5), "LH_v4")
pcall(function() safeDestroy(game:GetService("CoreGui"), "LH_v4") end)

-- ═══════════════════════════════════════════
-- SECTION 2: SERVICES
-- ═══════════════════════════════════════════
local RS  = game:GetService("ReplicatedStorage")
local RNS = game:GetService("RunService")

-- ═══════════════════════════════════════════
-- SECTION 3: GUI PARENT (all-executor safe)
-- ═══════════════════════════════════════════
local GUI_PARENT = nil
-- Try CoreGui first (Synapse, Solara, Wave, Xeno)
pcall(function()
    GUI_PARENT = game:GetService("CoreGui")
end)
-- Delta / Fluxus / Arceus X fallback
if not GUI_PARENT or not pcall(function()
    local t = Instance.new("Frame")
    t.Parent = GUI_PARENT
    t:Destroy()
end) then
    GUI_PARENT = LP:WaitForChild("PlayerGui", 10)
end

-- ═══════════════════════════════════════════
-- SECTION 4: REMOTE ENGINE
-- Scans ReplicatedStorage for real remotes
-- Works even when remotes are obfuscated
-- ═══════════════════════════════════════════
local remotes = {
    roll  = nil,
    hatch = nil,
    chest = nil,
    boost = nil,
    gift  = nil,
    quest = nil,
}

-- Known PS99 RNG Event 2026 remote name patterns
local PATTERNS = {
    roll  = {"roll","spin","rng","dice","wheel","lucky","event"},
    hatch = {"hatch","egg","open","incubat"},
    chest = {"chest","block","collect","claim","interact","touch"},
    boost = {"boost","item","use","activat","charm","fortune"},
    gift  = {"gift","bag","crate","reward","prize","loot"},
    quest = {"quest","mission","daily","task","complet","finish"},
}

local function scanOnce()
    local all = {}
    pcall(function()
        for _, obj in ipairs(RS:GetDescendants()) do
            if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
                all[#all+1] = obj
            end
        end
    end)

    for cat, patterns in pairs(PATTERNS) do
        if not remotes[cat] then
            for _, remote in ipairs(all) do
                local low = remote.Name:lower()
                for _, pat in ipairs(patterns) do
                    if low:find(pat, 1, true) then
                        remotes[cat] = remote
                        print("[LH v4] Remote [" .. cat .. "] = " .. remote.Name)
                        break
                    end
                end
                if remotes[cat] then break end
            end
        end
    end
end

-- Initial scan + periodic rescan
task.spawn(function()
    task.wait(1.5)
    scanOnce()
    while true do
        task.wait(8)
        scanOnce()
    end
end)

local function fire(cat, a1, a2)
    local r = remotes[cat]
    if not r then return false end
    local ok = pcall(function()
        if r:IsA("RemoteEvent") then
            if a2 ~= nil then r:FireServer(a1, a2)
            elseif a1 ~= nil then r:FireServer(a1)
            else r:FireServer() end
        else
            if a2 ~= nil then r:InvokeServer(a1, a2)
            elseif a1 ~= nil then r:InvokeServer(a1)
            else r:InvokeServer() end
        end
    end)
    return ok
end

-- ═══════════════════════════════════════════
-- SECTION 5: CONFIG
-- ═══════════════════════════════════════════
local CFG = {
    rollDelay   = 0.12,
    hatchDelay  = 1.0,
    chestDelay  = 0.08,
    boostDelay  = 18,
    giftDelay   = 3,
    questDelay  = 5,
    afkDelay    = 50,
    tpUp        = Vector3.new(0, 4, 0),

    -- RNG Event 2026 object names
    rollObjs  = {"RNGMachine","SpinMachine","DiceMachine","RollMachine",
                 "RNGWheel","SpinWheel","DiceWheel","RNGStation",
                 "RollNPC","DiceNPC","EventMachine","LuckyWheel"},
    -- RNG Egg — source of Titanics & Huges
    eggObjs   = {"RNG_Egg","RNGEgg","RNG Egg","EventEgg","TitanicEgg",
                 "HugeEgg","LuckyEgg","GoldenEgg","MythicalEgg","ArcaneEgg"},
    chestObjs = {"LuckyBlock","LuckyChest","GoldenChest","RNGBlock",
                 "EventBlock","MagicBlock","DiceChest","Chest","Lucky"},
    questObjs = {"QuestBoard","QuestNPC","EventNPC","DailyQuest",
                 "QuestGiver","RewardNPC"},

    boostKW = {"Lucky","Boost","RNG","Charm","Fortune","Dice","Roll","Event"},
    giftKW  = {"Gift","Bag","Crate","Box","Reward","Prize"},
}

-- ═══════════════════════════════════════════
-- SECTION 6: STATE
-- ═══════════════════════════════════════════
local S = {
    running = false,
    roll    = {on=true,  count=0},
    hatch   = {on=true,  count=0},
    chest   = {on=true,  count=0},
    boost   = {on=true,  count=0},
    gift    = {on=false, count=0},
    quest   = {on=true,  count=0},
}

-- ═══════════════════════════════════════════
-- SECTION 7: HELPERS
-- ═══════════════════════════════════════════
local function hrp()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function tp(pos)
    pcall(function()
        local h = hrp()
        if h and pos then h.CFrame = CFrame.new(pos + CFG.tpUp) end
    end)
end

local function objPos(o)
    if not o then return nil end
    local ok, p = pcall(function()
        if o:IsA("Model") then
            if o.PrimaryPart then return o.PrimaryPart.Position end
            return o:GetBoundingBox().Position
        end
        return o.Position
    end)
    return ok and p or nil
end

local function nearest(names, maxD)
    local best, bestD = nil, maxD or 9999
    local h = hrp()
    if not h then return nil end
    local hp = h.Position
    local ok, desc = pcall(function() return workspace:GetDescendants() end)
    if not ok then return nil end
    for _, o in ipairs(desc) do
        if o:IsA("BasePart") or o:IsA("Model") then
            local p = objPos(o)
            if p then
                local low = o.Name:lower()
                for _, n in ipairs(names) do
                    if low:find(n:lower(), 1, true) then
                        local d = (p - hp).Magnitude
                        if d < bestD then bestD=d; best=o end
                        break
                    end
                end
            end
        end
    end
    return best
end

local function backpackItems(kws)
    local out = {}
    pcall(function()
        for _, it in ipairs(LP.Backpack:GetChildren()) do
            local low = it.Name:lower()
            for _, kw in ipairs(kws) do
                if low:find(kw:lower(), 1, true) then
                    out[#out+1] = it; break
                end
            end
        end
    end)
    return out
end

-- ═══════════════════════════════════════════
-- SECTION 8: LOOPS
-- ═══════════════════════════════════════════

-- AUTO ROLL (RNG Event 2026 core mechanic)
local function loopRoll()
    while S.running do
        task.wait(CFG.rollDelay)
        if S.roll.on then
            local o = nearest(CFG.rollObjs, 40)
            if o then
                local p = objPos(o); if p then tp(p) end
                task.wait(0.05)
            end
            if fire("roll") then S.roll.count = S.roll.count + 1 end
        end
    end
end

-- AUTO HATCH RNG EGG (Titanic & Huge source)
local function loopHatch()
    while S.running do
        task.wait(CFG.hatchDelay)
        if S.hatch.on then
            local o = nearest(CFG.eggObjs)
            if o then
                local p = objPos(o)
                if p then tp(p); task.wait(0.2) end
                if fire("hatch", o, "Instant") then
                    S.hatch.count = S.hatch.count + 1
                end
            end
        end
    end
end

-- AUTO CHEST / LUCKY BLOCK
local function loopChest()
    while S.running do
        task.wait(CFG.chestDelay)
        if S.chest.on then
            local o = nearest(CFG.chestObjs)
            if o then
                local p = objPos(o)
                if p then tp(p); task.wait(0.04) end
                if fire("chest", o) then
                    S.chest.count = S.chest.count + 1
                end
            end
        end
    end
end

-- AUTO BOOST
local function loopBoost()
    while S.running do
        task.wait(CFG.boostDelay)
        if S.boost.on then
            for _, it in ipairs(backpackItems(CFG.boostKW)) do
                if fire("boost", it) then
                    S.boost.count = S.boost.count + 1
                end
                task.wait(0.1)
            end
        end
    end
end

-- AUTO GIFT / CRATE
local function loopGift()
    while S.running do
        task.wait(CFG.giftDelay)
        if S.gift.on then
            for _, it in ipairs(backpackItems(CFG.giftKW)) do
                if fire("gift", it) then
                    S.gift.count = S.gift.count + 1
                end
                task.wait(0.1)
            end
        end
    end
end

-- AUTO QUEST CLAIM
local function loopQuest()
    while S.running do
        task.wait(CFG.questDelay)
        if S.quest.on then
            local o = nearest(CFG.questObjs)
            if o then
                local p = objPos(o); if p then tp(p); task.wait(0.3) end
            end
            if fire("quest") then S.quest.count = S.quest.count + 1 end
        end
    end
end

-- ANTI AFK
local function loopAFK()
    while S.running do
        task.wait(CFG.afkDelay)
        pcall(function()
            local h = hrp()
            if h then
                local c = h.CFrame
                h.CFrame = c * CFrame.new(0.1,0,0)
                task.wait(0.1)
                h.CFrame = c
            end
        end)
    end
end

local function startLoops()
    task.spawn(loopRoll)
    task.spawn(loopHatch)
    task.spawn(loopChest)
    task.spawn(loopBoost)
    task.spawn(loopGift)
    task.spawn(loopQuest)
    task.spawn(loopAFK)
end

-- ═══════════════════════════════════════════
-- SECTION 9: GUI
-- ═══════════════════════════════════════════
local sg = Instance.new("ScreenGui")
sg.Name           = "LH_v4"
sg.ResetOnSpawn   = false
sg.DisplayOrder   = 9999
sg.IgnoreGuiInset = true
sg.Parent         = GUI_PARENT

-- Drop shadow
local shdw = Instance.new("Frame")
shdw.Size                  = UDim2.new(0, 272, 0, 50)
shdw.Position              = UDim2.new(0, 14, 0, 14)
shdw.BackgroundColor3      = Color3.new(0, 0, 0)
shdw.BackgroundTransparency = 0.65
shdw.BorderSizePixel       = 0
shdw.ZIndex                = 1
shdw.Parent                = sg
Instance.new("UICorner", shdw).CornerRadius = UDim.new(0, 14)

-- Main frame
local mf = Instance.new("Frame")
mf.Name             = "MF"
mf.Size             = UDim2.new(0, 268, 0, 50)
mf.Position         = UDim2.new(0, 10, 0, 10)
mf.BackgroundColor3 = Color3.fromRGB(13, 9, 22)
mf.BorderSizePixel  = 0
mf.Active           = true
mf.Draggable        = true
mf.ZIndex           = 2
mf.Parent           = sg
Instance.new("UICorner", mf).CornerRadius = UDim.new(0, 14)

-- Outer glow stroke
local glow = Instance.new("UIStroke")
glow.Color       = Color3.fromRGB(120, 50, 230)
glow.Thickness   = 2.5
glow.Transparency = 0.15
glow.Parent      = mf

-- ── TITLE BAR ──
local tb = Instance.new("Frame")
tb.Size             = UDim2.new(1, 0, 0, 44)
tb.BackgroundColor3 = Color3.fromRGB(70, 20, 160)
tb.BorderSizePixel  = 0
tb.ZIndex           = 3
tb.Parent           = mf
Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 14)

local tbG = Instance.new("UIGradient")
tbG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(190, 80, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(130, 40, 220)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(60,  15, 160)),
})
tbG.Rotation = 90
tbG.Parent = tb

local tbTxt = Instance.new("TextLabel")
tbTxt.Size               = UDim2.new(1, -10, 1, 0)
tbTxt.Position           = UDim2.new(0, 10, 0, 0)
tbTxt.BackgroundTransparency = 1
tbTxt.Text               = "LUCKY HUNTER  v4.0  |  RNG 2026"
tbTxt.TextColor3         = Color3.fromRGB(255, 255, 255)
tbTxt.TextSize           = 13
tbTxt.Font               = Enum.Font.GothamBold
tbTxt.TextXAlignment     = Enum.TextXAlignment.Left
tbTxt.ZIndex             = 4
tbTxt.Parent             = tb

-- Minimize button
local minBtn = Instance.new("TextButton")
minBtn.Size             = UDim2.new(0, 30, 0, 30)
minBtn.Position         = UDim2.new(1, -36, 0.5, -15)
minBtn.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
minBtn.BackgroundTransparency = 0.85
minBtn.Text             = "-"
minBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
minBtn.TextSize         = 18
minBtn.Font             = Enum.Font.GothamBold
minBtn.BorderSizePixel  = 0
minBtn.ZIndex           = 5
minBtn.Parent           = tb
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

-- ── SUBHEADER ──
local subY = 46
local sub = Instance.new("TextLabel")
sub.Size               = UDim2.new(1, -16, 0, 13)
sub.Position           = UDim2.new(0, 8, 0, subY)
sub.BackgroundTransparency = 1
sub.Text               = "Titanic Arcane Cat  |  Huge Nebula Lion  |  Eclipse Owl  |  Anubis"
sub.TextColor3         = Color3.fromRGB(200, 150, 255)
sub.TextSize           = 9
sub.Font               = Enum.Font.Gotham
sub.TextXAlignment     = Enum.TextXAlignment.Left
sub.ZIndex             = 3
sub.Parent             = mf

-- Remote status
local remY = subY + 14
local remTxt = Instance.new("TextLabel")
remTxt.Size               = UDim2.new(1, -16, 0, 13)
remTxt.Position           = UDim2.new(0, 8, 0, remY)
remTxt.BackgroundTransparency = 1
remTxt.Text               = "Scanning remotes..."
remTxt.TextColor3         = Color3.fromRGB(255, 180, 50)
remTxt.TextSize           = 9
remTxt.Font               = Enum.Font.Gotham
remTxt.TextXAlignment     = Enum.TextXAlignment.Left
remTxt.ZIndex             = 3
remTxt.Parent             = mf

task.spawn(function()
    while sg and sg.Parent do
        task.wait(2)
        pcall(function()
            local n = 0
            for _, v in pairs(remotes) do if v then n = n + 1 end end
            local col = n >= 3
                and Color3.fromRGB(60, 220, 110)
                or (n > 0 and Color3.fromRGB(255, 200, 50) or Color3.fromRGB(230, 60, 60))
            remTxt.Text      = "Remotes found: " .. n .. " / 6  (auto-scanning)"
            remTxt.TextColor3 = col
        end)
    end
end)

-- ── ROW DEFINITIONS ──
local ROW_DEFS = {
    {key="roll",  label="Auto Roll  (RNG)",    color=Color3.fromRGB(255,215,0)},
    {key="hatch", label="Auto Hatch RNG Egg",  color=Color3.fromRGB(0,210,255)},
    {key="chest", label="Auto Chest/Block",    color=Color3.fromRGB(80,200,255)},
    {key="boost", label="Auto Boost/Charm",    color=Color3.fromRGB(255,140,0)},
    {key="gift",  label="Auto Gift/Crate",     color=Color3.fromRGB(190,90,255)},
    {key="quest", label="Auto Quest Claim",    color=Color3.fromRGB(60,225,150)},
}

local ROW_START = remY + 16
local ROW_H     = 34
local ROW_G     = 3

local bodyMinH  = ROW_START
local isMinimized = false
local bodyFrames  = {}

-- Row builder
for i, def in ipairs(ROW_DEFS) do
    local sr = S[def.key]
    local y  = ROW_START + (i-1)*(ROW_H+ROW_G)

    local rf = Instance.new("Frame")
    rf.Size             = UDim2.new(1, -16, 0, ROW_H)
    rf.Position         = UDim2.new(0, 8, 0, y)
    rf.BackgroundColor3 = Color3.fromRGB(20, 14, 36)
    rf.BorderSizePixel  = 0
    rf.ZIndex           = 3
    rf.Parent           = mf
    Instance.new("UICorner", rf).CornerRadius = UDim.new(0, 9)
    bodyFrames[#bodyFrames+1] = rf

    local rStroke = Instance.new("UIStroke")
    rStroke.Color       = def.color
    rStroke.Thickness   = 1
    rStroke.Transparency = 0.6
    rStroke.Parent      = rf

    -- Left accent
    local acc = Instance.new("Frame")
    acc.Size             = UDim2.new(0, 3, 1, -10)
    acc.Position         = UDim2.new(0, 5, 0, 5)
    acc.BackgroundColor3 = def.color
    acc.BorderSizePixel  = 0
    acc.ZIndex           = 4
    acc.Parent           = rf
    Instance.new("UICorner", acc).CornerRadius = UDim.new(0, 2)

    -- Count badge
    local cb = Instance.new("Frame")
    cb.Size             = UDim2.new(0, 38, 0, 22)
    cb.Position         = UDim2.new(0, 12, 0.5, -11)
    cb.BackgroundColor3 = def.color
    cb.BackgroundTransparency = 0.42
    cb.BorderSizePixel  = 0
    cb.ZIndex           = 4
    cb.Parent           = rf
    Instance.new("UICorner", cb).CornerRadius = UDim.new(0, 5)

    local ct = Instance.new("TextLabel")
    ct.Size               = UDim2.new(1, 0, 1, 0)
    ct.BackgroundTransparency = 1
    ct.Text               = "0"
    ct.TextColor3         = Color3.fromRGB(255,255,255)
    ct.TextSize           = 11
    ct.Font               = Enum.Font.GothamBold
    ct.ZIndex             = 5
    ct.Parent             = cb

    -- Feature label
    local fl = Instance.new("TextLabel")
    fl.Size               = UDim2.new(0, 118, 1, 0)
    fl.Position           = UDim2.new(0, 55, 0, 0)
    fl.BackgroundTransparency = 1
    fl.Text               = def.label
    fl.TextColor3         = Color3.fromRGB(228, 218, 245)
    fl.TextSize           = 11
    fl.Font               = Enum.Font.GothamBold
    fl.TextXAlignment     = Enum.TextXAlignment.Left
    fl.ZIndex             = 4
    fl.Parent             = rf

    -- Toggle
    local tog = Instance.new("TextButton")
    tog.Size             = UDim2.new(0, 52, 0, 24)
    tog.Position         = UDim2.new(1, -58, 0.5, -12)
    tog.BackgroundColor3 = sr.on
        and Color3.fromRGB(28,175,68) or Color3.fromRGB(160,32,32)
    tog.Text             = sr.on and "ON" or "OFF"
    tog.TextColor3       = Color3.fromRGB(255,255,255)
    tog.TextSize         = 11
    tog.Font             = Enum.Font.GothamBold
    tog.BorderSizePixel  = 0
    tog.ZIndex           = 5
    tog.Parent           = rf
    Instance.new("UICorner", tog).CornerRadius = UDim.new(0, 6)

    tog.MouseButton1Click:Connect(function()
        sr.on = not sr.on
        tog.BackgroundColor3 = sr.on
            and Color3.fromRGB(28,175,68) or Color3.fromRGB(160,32,32)
        tog.Text = sr.on and "ON" or "OFF"
    end)

    task.spawn(function()
        while sg and sg.Parent do
            task.wait(0.9)
            pcall(function() ct.Text = tostring(sr.count) end)
        end
    end)
end

-- ── STATUS ──
local totalRows = #ROW_DEFS
local STATUS_Y  = ROW_START + totalRows*(ROW_H+ROW_G) + 4

local stLbl = Instance.new("TextLabel")
stLbl.Size               = UDim2.new(1, -16, 0, 18)
stLbl.Position           = UDim2.new(0, 8, 0, STATUS_Y)
stLbl.BackgroundTransparency = 1
stLbl.Text               = "Idle  --  Press START"
stLbl.TextColor3         = Color3.fromRGB(148, 138, 172)
stLbl.TextSize           = 11
stLbl.Font               = Enum.Font.Gotham
stLbl.ZIndex             = 3
stLbl.Parent             = mf
bodyFrames[#bodyFrames+1] = stLbl

-- ── START/STOP BUTTON ──
local BTN_Y = STATUS_Y + 22

local sBtn = Instance.new("TextButton")
sBtn.Size             = UDim2.new(1, -16, 0, 44)
sBtn.Position         = UDim2.new(0, 8, 0, BTN_Y)
sBtn.BackgroundColor3 = Color3.fromRGB(88, 28, 200)
sBtn.Text             = "START HUNTING"
sBtn.TextColor3       = Color3.fromRGB(255,255,255)
sBtn.TextSize         = 15
sBtn.Font             = Enum.Font.GothamBold
sBtn.BorderSizePixel  = 0
sBtn.ZIndex           = 3
sBtn.Parent           = mf
Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 10)
bodyFrames[#bodyFrames+1] = sBtn

local sBtnG = Instance.new("UIGradient")
sBtnG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 65, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(72,  22, 195)),
})
sBtnG.Rotation = 90
sBtnG.Parent = sBtn

-- Set final heights
local FINAL_H = BTN_Y + 56
mf.Size   = UDim2.new(0, 268, 0, FINAL_H)
shdw.Size = UDim2.new(0, 272, 0, FINAL_H)

-- ── MINIMIZE ──
minBtn.MouseButton1Click:Connect(function()
    isMinimized = not isMinimized
    for _, f in ipairs(bodyFrames) do
        pcall(function() f.Visible = not isMinimized end)
    end
    sub.Visible    = not isMinimized
    remTxt.Visible = not isMinimized
    if isMinimized then
        mf.Size   = UDim2.new(0, 268, 0, 44)
        shdw.Size = UDim2.new(0, 272, 0, 44)
        minBtn.Text = "+"
    else
        mf.Size   = UDim2.new(0, 268, 0, FINAL_H)
        shdw.Size = UDim2.new(0, 272, 0, FINAL_H)
        minBtn.Text = "-"
    end
end)

-- ═══════════════════════════════════════════
-- SECTION 10: START / STOP LOGIC
-- ═══════════════════════════════════════════
local function startH()
    if S.running then return end
    S.running = true
    stLbl.Text       = "Hunting...  RNG Event 2026!"
    stLbl.TextColor3 = Color3.fromRGB(60, 218, 92)
    sBtn.Text        = "STOP HUNTING"
    sBtnG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(215, 42, 42)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(148, 12, 12)),
    })
    startLoops()
end

local function stopH()
    S.running = false
    stLbl.Text       = "Stopped."
    stLbl.TextColor3 = Color3.fromRGB(220, 65, 65)
    sBtn.Text        = "START HUNTING"
    sBtnG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(160, 65, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(72,  22, 195)),
    })
end

sBtn.MouseButton1Click:Connect(function()
    if S.running then stopH() else startH() end
end)

-- ═══════════════════════════════════════════
-- SECTION 11: RESPAWN HANDLER
-- ═══════════════════════════════════════════
LP.CharacterAdded:Connect(function()
    if S.running then
        task.wait(2)
        startLoops()
        stLbl.Text       = "Respawned  --  Resumed!"
        stLbl.TextColor3 = Color3.fromRGB(255, 200, 55)
        task.wait(2)
        if S.running then
            stLbl.Text       = "Hunting...  RNG Event 2026!"
            stLbl.TextColor3 = Color3.fromRGB(60, 218, 92)
        end
    end
end)

-- ═══════════════════════════════════════════
-- SECTION 12: BOOT
-- ═══════════════════════════════════════════
stLbl.Text       = "v4.0 loaded!  Scanning..."
stLbl.TextColor3 = Color3.fromRGB(75, 255, 145)
task.wait(3)
if not S.running then
    stLbl.Text       = "Idle  --  Press START"
    stLbl.TextColor3 = Color3.fromRGB(148, 138, 172)
end
print("[LH v4.0] Loaded | GUI: " .. tostring(GUI_PARENT) .. " | RNG Event 2026")
