--[[
╔══════════════════════════════════════════════════════════════════╗
║  LUCKY HUNTER v5.0  —  FINAL EDITION                            ║
║  Pet Simulator 99  |  RNG Event 2026                            ║
║  FIXED: Auto Roll ON default, Hatch works, ProximityPrompt      ║
║  Works on: Delta, Solara, Wave, Xeno, Fluxus, Arceus X         ║
╚══════════════════════════════════════════════════════════════════╝
--]]

-- ─────────────────────────────────────────
-- 1. CLEANUP
-- ─────────────────────────────────────────
local LP  = game:GetService("Players").LocalPlayer
local RS  = game:GetService("ReplicatedStorage")
local GUI_PARENT

pcall(function()
    local cg = game:GetService("CoreGui")
    local old = cg:FindFirstChild("LH_v5")
    if old then old:Destroy() end
    GUI_PARENT = cg
end)
pcall(function()
    local pg = LP:WaitForChild("PlayerGui", 5)
    local old = pg:FindFirstChild("LH_v5")
    if old then old:Destroy() end
    if not GUI_PARENT then GUI_PARENT = pg end
end)
if not GUI_PARENT then
    GUI_PARENT = LP:WaitForChild("PlayerGui", 10)
end

-- ─────────────────────────────────────────
-- 2. REMOTE CACHE
-- ─────────────────────────────────────────
local RC = {}   -- RC["name"] = RemoteEvent/Function

local function rebuildCache()
    RC = {}
    pcall(function()
        for _, v in ipairs(RS:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                RC[v.Name:lower()] = v
            end
        end
    end)
end

task.spawn(function()
    task.wait(1.5)
    rebuildCache()
    while true do task.wait(10); rebuildCache() end
end)

-- Fire by keyword list (tries each, returns true on first success)
local function fireAny(keywords, a1, a2)
    for _, kw in ipairs(keywords) do
        local r = RC[kw:lower()]
        if r then
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
            if ok then return true, r.Name end
        end
    end
    return false, nil
end

-- ─────────────────────────────────────────
-- 3. PROXIMITY PROMPT TRIGGER
-- The REAL way PS99 handles Roll & Hatch
-- ─────────────────────────────────────────
local function triggerPrompt(obj)
    if not obj then return false end
    local found = false
    -- Check obj and all its descendants for ProximityPrompt
    local targets = {obj}
    pcall(function()
        for _, d in ipairs(obj:GetDescendants()) do
            targets[#targets+1] = d
        end
    end)
    for _, part in ipairs(targets) do
        local pp = nil
        pcall(function() pp = part:FindFirstChildOfClass("ProximityPrompt") end)
        if pp then
            pcall(function()
                fireproximityprompt(pp)  -- executor built-in
            end)
            -- Also try the event directly
            pcall(function()
                local ppe = RS:FindFirstChild("ProximityPromptService", true)
                if ppe then ppe:FireServer(pp) end
            end)
            found = true
        end
    end
    return found
end

-- ─────────────────────────────────────────
-- 4. CONFIG
-- ─────────────────────────────────────────
local CFG = {
    rollDelay  = 0.10,
    hatchDelay = 0.80,
    chestDelay = 0.08,
    boostDelay = 18,
    giftDelay  = 3,
    questDelay = 5,
    afkDelay   = 50,
    tpUp       = Vector3.new(0, 3.5, 0),

    -- PS99 RNG Event 2026 — Roll remote names (all known variants)
    rollRemotes = {
        "Roll","RollDice","DoRoll","StartRoll","UseRoll","EventRoll",
        "RollEvent","RNGRoll","RollRNG","LuckyRoll","DiceRoll",
        "SpinRNG","RNGSpin","Spin","SpinWheel","RollAction",
        "ActivateRoll","RequestRoll","TriggerRoll","PerformRoll",
        "RollRequest","GameRoll","RollServer","ServerRoll",
    },
    -- PS99 RNG Egg hatch remote names
    hatchRemotes = {
        "HatchEgg","HatchPet","OpenEgg","EggHatch","HatchRequest",
        "HatchEventEgg","RNG_Hatch","HatchRNG","AutoHatch","EggOpen",
        "HatchBaby","HatchNow","RequestHatch","DoHatch","StartHatch",
        "HatchAction","ServerHatch","EggHatchRequest","HatchEggEvent",
    },
    chestRemotes = {
        "ClickToCollect","CollectBlock","ClaimBlock","Interact",
        "TouchPart","ClickBlock","CollectLucky","OpenChest","ClaimChest",
        "CollectChest","OpenLucky","LuckyChest","ChestClaim","BlockClaim",
        "CollectItem","PickupItem","ClaimItem",
    },
    boostRemotes = {
        "UseItem","ActivateBoost","UseBoost","ActivateItem",
        "UseLucky","LuckyBoost","BoostActivate","ItemUse","UseCharm",
    },
    giftRemotes = {
        "OpenGift","OpenBag","OpenCrate","UseGift","OpenReward",
        "GiftOpen","CrateOpen","BagOpen","ClaimReward","LootBox",
    },
    questRemotes = {
        "ClaimQuest","CompleteQuest","QuestClaim","RewardClaim",
        "FinishQuest","QuestReward","DailyReward","EventQuest","ClaimDaily",
    },

    -- Object names to search in workspace
    rollObjs  = {
        "RNGMachine","SpinMachine","DiceMachine","RollMachine","EventMachine",
        "RNGWheel","SpinWheel","DiceWheel","LuckyWheel","RollWheel",
        "RollNPC","DiceNPC","SpinNPC","RNGStation","RollStation",
        "LuckyStation","DicePad","RollPad","RNGPad","EventStation",
    },
    eggObjs   = {
        "RNG_Egg","RNGEgg","RNG Egg","EventEgg","LuckyEgg",
        "TitanicEgg","HugeEgg","GoldenEgg","MythicalEgg","ArcaneEgg",
        "Egg","EggModel","EggBase","HatchEgg","HatchStation",
    },
    chestObjs = {
        "LuckyBlock","LuckyChest","GoldenChest","RNGBlock","EventBlock",
        "MagicBlock","DiceChest","Lucky","Chest","Block","RNGChest",
    },
    questObjs = {
        "QuestBoard","QuestNPC","EventNPC","DailyQuest",
        "QuestGiver","RewardNPC","EventBoard","MissionNPC",
    },
    boostKW = {"Lucky","Boost","RNG","Charm","Fortune","Dice","Roll","Event"},
    giftKW  = {"Gift","Bag","Crate","Box","Reward","Prize"},
}

-- ─────────────────────────────────────────
-- 5. STATE
-- ─────────────────────────────────────────
local S = {
    running = false,
    roll    = {on=true,  count=0, last=""},
    hatch   = {on=true,  count=0, last=""},
    chest   = {on=true,  count=0, last=""},
    boost   = {on=true,  count=0, last=""},
    gift    = {on=false, count=0, last=""},
    quest   = {on=true,  count=0, last=""},
}

-- ─────────────────────────────────────────
-- 6. HELPERS
-- ─────────────────────────────────────────
local function getHRP()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function tp(pos)
    pcall(function()
        local h = getHRP()
        if h and pos then
            h.CFrame = CFrame.new(pos + CFG.tpUp)
        end
    end)
end

local function getPos(o)
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
    local best, bd = nil, maxD or 9999
    local h = getHRP()
    if not h then return nil end
    local hp = h.Position
    local ok, desc = pcall(function() return workspace:GetDescendants() end)
    if not ok then return nil end
    for _, o in ipairs(desc) do
        if o:IsA("BasePart") or o:IsA("Model") then
            local p = getPos(o)
            if p then
                local low = o.Name:lower()
                for _, n in ipairs(names) do
                    if low:find(n:lower(), 1, true) then
                        local d = (p - hp).Magnitude
                        if d < bd then bd=d; best=o end
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

-- ─────────────────────────────────────────
-- 7. LOOPS
-- ─────────────────────────────────────────

-- AUTO ROLL
local function loopRoll()
    while S.running do
        task.wait(CFG.rollDelay)
        if S.roll.on then
            -- Find roll machine
            local o = nearest(CFG.rollObjs, 60)
            if o then
                local p = getPos(o)
                if p then tp(p); task.wait(0.05) end
                -- Method 1: ProximityPrompt
                triggerPrompt(o)
                task.wait(0.03)
            end
            -- Method 2: Remote fire (always attempt)
            local ok, name = fireAny(CFG.rollRemotes)
            if ok then
                S.roll.count = S.roll.count + 1
                S.roll.last  = name or "?"
            end
        end
    end
end

-- AUTO HATCH RNG EGG
local function loopHatch()
    while S.running do
        task.wait(CFG.hatchDelay)
        if S.hatch.on then
            local o = nearest(CFG.eggObjs, 80)
            if o then
                local p = getPos(o)
                if p then tp(p); task.wait(0.15) end
                -- Method 1: ProximityPrompt
                local prompted = triggerPrompt(o)
                task.wait(0.05)
                -- Method 2: Remote (with and without args)
                local ok, name = fireAny(CFG.hatchRemotes, o, "Instant")
                if not ok then
                    ok, name = fireAny(CFG.hatchRemotes, o)
                end
                if not ok then
                    ok, name = fireAny(CFG.hatchRemotes)
                end
                if ok or prompted then
                    S.hatch.count = S.hatch.count + 1
                    S.hatch.last  = name or "prompt"
                end
            end
        end
    end
end

-- AUTO CHEST / BLOCK
local function loopChest()
    while S.running do
        task.wait(CFG.chestDelay)
        if S.chest.on then
            local o = nearest(CFG.chestObjs)
            if o then
                local p = getPos(o)
                if p then tp(p); task.wait(0.04) end
                triggerPrompt(o)
                local ok, name = fireAny(CFG.chestRemotes, o)
                if ok then
                    S.chest.count = S.chest.count + 1
                    S.chest.last  = name or "?"
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
                local ok, name = fireAny(CFG.boostRemotes, it)
                if ok then
                    S.boost.count = S.boost.count + 1
                    S.boost.last  = name or "?"
                end
                task.wait(0.1)
            end
        end
    end
end

-- AUTO GIFT
local function loopGift()
    while S.running do
        task.wait(CFG.giftDelay)
        if S.gift.on then
            for _, it in ipairs(backpackItems(CFG.giftKW)) do
                local ok, name = fireAny(CFG.giftRemotes, it)
                if ok then
                    S.gift.count = S.gift.count + 1
                    S.gift.last  = name or "?"
                end
                task.wait(0.1)
            end
        end
    end
end

-- AUTO QUEST
local function loopQuest()
    while S.running do
        task.wait(CFG.questDelay)
        if S.quest.on then
            local o = nearest(CFG.questObjs)
            if o then
                local p = getPos(o)
                if p then tp(p); task.wait(0.3) end
                triggerPrompt(o)
            end
            local ok, name = fireAny(CFG.questRemotes)
            if ok then
                S.quest.count = S.quest.count + 1
                S.quest.last  = name or "?"
            end
        end
    end
end

-- ANTI-AFK
local function loopAFK()
    while S.running do
        task.wait(CFG.afkDelay)
        pcall(function()
            local h = getHRP()
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

-- ─────────────────────────────────────────
-- 8. GUI
-- ─────────────────────────────────────────
local sg = Instance.new("ScreenGui")
sg.Name           = "LH_v5"
sg.ResetOnSpawn   = false
sg.DisplayOrder   = 9999
sg.IgnoreGuiInset = true
sg.Parent         = GUI_PARENT

-- Shadow
local sdw = Instance.new("Frame")
sdw.Size                  = UDim2.new(0, 272, 0, 50)
sdw.Position              = UDim2.new(0, 14, 0, 14)
sdw.BackgroundColor3      = Color3.new(0,0,0)
sdw.BackgroundTransparency = 0.6
sdw.BorderSizePixel       = 0
sdw.ZIndex                = 1
sdw.Parent                = sg
Instance.new("UICorner", sdw).CornerRadius = UDim.new(0, 14)

-- Main
local mf = Instance.new("Frame")
mf.Name             = "MF"
mf.Size             = UDim2.new(0, 268, 0, 50)
mf.Position         = UDim2.new(0, 10, 0, 10)
mf.BackgroundColor3 = Color3.fromRGB(11, 8, 20)
mf.BorderSizePixel  = 0
mf.Active           = true
mf.Draggable        = true
mf.ZIndex           = 2
mf.Parent           = sg
Instance.new("UICorner", mf).CornerRadius = UDim.new(0, 14)

local mfStroke = Instance.new("UIStroke")
mfStroke.Color       = Color3.fromRGB(110, 44, 220)
mfStroke.Thickness   = 2.5
mfStroke.Transparency = 0.1
mfStroke.Parent      = mf

-- Title bar
local tb = Instance.new("Frame")
tb.Size             = UDim2.new(1, 0, 0, 42)
tb.BackgroundColor3 = Color3.fromRGB(65, 18, 155)
tb.BorderSizePixel  = 0
tb.ZIndex           = 3
tb.Parent           = mf
Instance.new("UICorner", tb).CornerRadius = UDim.new(0, 14)

local tbG = Instance.new("UIGradient")
tbG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0,   Color3.fromRGB(185, 75, 255)),
    ColorSequenceKeypoint.new(0.5, Color3.fromRGB(120, 38, 215)),
    ColorSequenceKeypoint.new(1,   Color3.fromRGB(55,  14, 155)),
})
tbG.Rotation = 90
tbG.Parent = tb

local tbTxt = Instance.new("TextLabel")
tbTxt.Size               = UDim2.new(1, -80, 1, 0)
tbTxt.Position           = UDim2.new(0, 12, 0, 0)
tbTxt.BackgroundTransparency = 1
tbTxt.Text               = "LUCKY HUNTER  v5.0  |  RNG 2026"
tbTxt.TextColor3         = Color3.fromRGB(255,255,255)
tbTxt.TextSize           = 12
tbTxt.Font               = Enum.Font.GothamBold
tbTxt.TextXAlignment     = Enum.TextXAlignment.Left
tbTxt.ZIndex             = 4
tbTxt.Parent             = tb

-- Minimize button
local minBtn = Instance.new("TextButton")
minBtn.Size             = UDim2.new(0, 28, 0, 28)
minBtn.Position         = UDim2.new(1, -34, 0.5, -14)
minBtn.BackgroundColor3 = Color3.fromRGB(255,255,255)
minBtn.BackgroundTransparency = 0.82
minBtn.Text             = "-"
minBtn.TextColor3       = Color3.fromRGB(255,255,255)
minBtn.TextSize         = 16
minBtn.Font             = Enum.Font.GothamBold
minBtn.BorderSizePixel  = 0
minBtn.ZIndex           = 5
minBtn.Parent           = tb
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

-- Sub header
local subY = 44
local subTxt = Instance.new("TextLabel")
subTxt.Size               = UDim2.new(1, -16, 0, 12)
subTxt.Position           = UDim2.new(0, 8, 0, subY)
subTxt.BackgroundTransparency = 1
subTxt.Text               = "Target: Titanic Arcane Cat  |  Huge: Nebula Lion, Eclipse Owl, Anubis..."
subTxt.TextColor3         = Color3.fromRGB(190, 140, 255)
subTxt.TextSize           = 9
subTxt.Font               = Enum.Font.Gotham
subTxt.ZIndex             = 3
subTxt.Parent             = mf

-- Remote status
local remY = subY + 14
local remTxt = Instance.new("TextLabel")
remTxt.Size               = UDim2.new(1, -16, 0, 12)
remTxt.Position           = UDim2.new(0, 8, 0, remY)
remTxt.BackgroundTransparency = 1
remTxt.Text               = "Scanning remotes..."
remTxt.TextColor3         = Color3.fromRGB(255, 180, 50)
remTxt.TextSize           = 9
remTxt.Font               = Enum.Font.Gotham
remTxt.ZIndex             = 3
remTxt.Parent             = mf

task.spawn(function()
    while sg and sg.Parent do
        task.wait(2)
        pcall(function()
            local n = 0
            for k, _ in pairs(RC) do n = n + 1 end
            local found = 0
            local cats = {CFG.rollRemotes, CFG.hatchRemotes, CFG.chestRemotes,
                         CFG.boostRemotes, CFG.giftRemotes, CFG.questRemotes}
            for _, list in ipairs(cats) do
                for _, kw in ipairs(list) do
                    if RC[kw:lower()] then found = found + 1; break end
                end
            end
            local col = found >= 3 and Color3.fromRGB(55,215,90)
                or (found > 0 and Color3.fromRGB(255,200,50) or Color3.fromRGB(230,55,55))
            remTxt.Text       = "Remotes in RS: " .. n .. "  |  Matched: " .. found .. "/6"
            remTxt.TextColor3 = col
        end)
    end
end)

-- ── ROW DEFINITIONS ──
local ROW_DEFS = {
    {key="roll",  label="Auto Roll  (RNG)",    color=Color3.fromRGB(255,215,0),   icon="ROLL"},
    {key="hatch", label="Auto Hatch RNG Egg",  color=Color3.fromRGB(0,215,255),   icon="EGG"},
    {key="chest", label="Auto Chest / Block",  color=Color3.fromRGB(80,200,255),  icon="BOX"},
    {key="boost", label="Auto Boost / Charm",  color=Color3.fromRGB(255,140,0),   icon="PWR"},
    {key="gift",  label="Auto Gift / Crate",   color=Color3.fromRGB(190,90,255),  icon="GIFT"},
    {key="quest", label="Auto Quest Claim",    color=Color3.fromRGB(55,225,148),  icon="QST"},
}

local ROW_START = remY + 16
local ROW_H, ROW_G = 34, 3
local bodyObjs = {}

for i, def in ipairs(ROW_DEFS) do
    local sr = S[def.key]
    local y  = ROW_START + (i-1)*(ROW_H+ROW_G)

    local rf = Instance.new("Frame")
    rf.Size             = UDim2.new(1, -16, 0, ROW_H)
    rf.Position         = UDim2.new(0, 8, 0, y)
    rf.BackgroundColor3 = Color3.fromRGB(18, 12, 32)
    rf.BorderSizePixel  = 0
    rf.ZIndex           = 3
    rf.Parent           = mf
    Instance.new("UICorner", rf).CornerRadius = UDim.new(0, 9)
    bodyObjs[#bodyObjs+1] = rf

    local rStroke = Instance.new("UIStroke")
    rStroke.Color       = def.color
    rStroke.Thickness   = 1
    rStroke.Transparency = 0.55
    rStroke.Parent      = rf

    -- Left accent bar
    local acc = Instance.new("Frame")
    acc.Size             = UDim2.new(0, 3, 1, -10)
    acc.Position         = UDim2.new(0, 5, 0, 5)
    acc.BackgroundColor3 = def.color
    acc.BorderSizePixel  = 0
    acc.ZIndex           = 4
    acc.Parent           = rf
    Instance.new("UICorner", acc).CornerRadius = UDim.new(0, 2)

    -- Icon badge
    local ib = Instance.new("Frame")
    ib.Size             = UDim2.new(0, 36, 0, 22)
    ib.Position         = UDim2.new(0, 12, 0.5, -11)
    ib.BackgroundColor3 = def.color
    ib.BackgroundTransparency = 0.38
    ib.BorderSizePixel  = 0
    ib.ZIndex           = 4
    ib.Parent           = rf
    Instance.new("UICorner", ib).CornerRadius = UDim.new(0, 5)

    local iconTxt = Instance.new("TextLabel")
    iconTxt.Size               = UDim2.new(1, 0, 1, 0)
    iconTxt.BackgroundTransparency = 1
    iconTxt.Text               = def.icon
    iconTxt.TextColor3         = Color3.fromRGB(255,255,255)
    iconTxt.TextSize           = 8
    iconTxt.Font               = Enum.Font.GothamBold
    iconTxt.ZIndex             = 5
    iconTxt.Parent             = ib

    -- Count (right of icon)
    local cntTxt = Instance.new("TextLabel")
    cntTxt.Size               = UDim2.new(0, 30, 1, 0)
    cntTxt.Position           = UDim2.new(0, 52, 0, 0)
    cntTxt.BackgroundTransparency = 1
    cntTxt.Text               = "0"
    cntTxt.TextColor3         = def.color
    cntTxt.TextSize           = 13
    cntTxt.Font               = Enum.Font.GothamBold
    cntTxt.TextXAlignment     = Enum.TextXAlignment.Left
    cntTxt.ZIndex             = 4
    cntTxt.Parent             = rf

    -- Label
    local lbl = Instance.new("TextLabel")
    lbl.Size               = UDim2.new(0, 100, 1, 0)
    lbl.Position           = UDim2.new(0, 85, 0, 0)
    lbl.BackgroundTransparency = 1
    lbl.Text               = def.label
    lbl.TextColor3         = Color3.fromRGB(228, 218, 245)
    lbl.TextSize           = 11
    lbl.Font               = Enum.Font.GothamBold
    lbl.TextXAlignment     = Enum.TextXAlignment.Left
    lbl.ZIndex             = 4
    lbl.Parent             = rf

    -- Toggle
    local tog = Instance.new("TextButton")
    tog.Size             = UDim2.new(0, 48, 0, 24)
    tog.Position         = UDim2.new(1, -54, 0.5, -12)
    tog.BackgroundColor3 = sr.on
        and Color3.fromRGB(25, 172, 66) or Color3.fromRGB(158, 28, 28)
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
            and Color3.fromRGB(25,172,66) or Color3.fromRGB(158,28,28)
        tog.Text = sr.on and "ON" or "OFF"
    end)

    -- Live count update
    task.spawn(function()
        while sg and sg.Parent do
            task.wait(0.8)
            pcall(function() cntTxt.Text = tostring(sr.count) end)
        end
    end)
end

-- Status label
local ST_Y = ROW_START + #ROW_DEFS*(ROW_H+ROW_G) + 4
local stLbl = Instance.new("TextLabel")
stLbl.Size               = UDim2.new(1, -16, 0, 18)
stLbl.Position           = UDim2.new(0, 8, 0, ST_Y)
stLbl.BackgroundTransparency = 1
stLbl.Text               = "Idle  --  Press START"
stLbl.TextColor3         = Color3.fromRGB(145, 135, 170)
stLbl.TextSize           = 11
stLbl.Font               = Enum.Font.Gotham
stLbl.ZIndex             = 3
stLbl.Parent             = mf
bodyObjs[#bodyObjs+1]    = stLbl

-- START/STOP button
local BT_Y = ST_Y + 22
local sBtn = Instance.new("TextButton")
sBtn.Size             = UDim2.new(1, -16, 0, 44)
sBtn.Position         = UDim2.new(0, 8, 0, BT_Y)
sBtn.BackgroundColor3 = Color3.fromRGB(85, 26, 195)
sBtn.Text             = "START HUNTING"
sBtn.TextColor3       = Color3.fromRGB(255,255,255)
sBtn.TextSize         = 15
sBtn.Font             = Enum.Font.GothamBold
sBtn.BorderSizePixel  = 0
sBtn.ZIndex           = 3
sBtn.Parent           = mf
Instance.new("UICorner", sBtn).CornerRadius = UDim.new(0, 10)
bodyObjs[#bodyObjs+1] = sBtn

local sBG = Instance.new("UIGradient")
sBG.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(155, 62, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(70,  20, 192)),
})
sBG.Rotation = 90
sBG.Parent = sBtn

-- Set final height
local FH = BT_Y + 56
mf.Size  = UDim2.new(0, 268, 0, FH)
sdw.Size = UDim2.new(0, 272, 0, FH)

-- Minimize
local minimized = false
minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, o in ipairs(bodyObjs) do
        pcall(function() o.Visible = not minimized end)
    end
    subTxt.Visible = not minimized
    remTxt.Visible = not minimized
    if minimized then
        mf.Size  = UDim2.new(0, 268, 0, 42)
        sdw.Size = UDim2.new(0, 272, 0, 42)
        minBtn.Text = "+"
    else
        mf.Size  = UDim2.new(0, 268, 0, FH)
        sdw.Size = UDim2.new(0, 272, 0, FH)
        minBtn.Text = "-"
    end
end)

-- ─────────────────────────────────────────
-- 9. START / STOP
-- ─────────────────────────────────────────
local function startH()
    if S.running then return end
    S.running = true
    stLbl.Text       = "Hunting...  RNG Event 2026!"
    stLbl.TextColor3 = Color3.fromRGB(55, 215, 90)
    sBtn.Text        = "STOP HUNTING"
    sBG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(212, 40, 40)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(145, 10, 10)),
    })
    startLoops()
end

local function stopH()
    S.running = false
    stLbl.Text       = "Stopped."
    stLbl.TextColor3 = Color3.fromRGB(218, 62, 62)
    sBtn.Text        = "START HUNTING"
    sBG.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(155, 62, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(70,  20, 192)),
    })
end

sBtn.MouseButton1Click:Connect(function()
    if S.running then stopH() else startH() end
end)

-- ─────────────────────────────────────────
-- 10. RESPAWN HANDLER
-- ─────────────────────────────────────────
LP.CharacterAdded:Connect(function()
    if S.running then
        task.wait(2)
        startLoops()
        stLbl.Text       = "Respawned  --  Resumed!"
        stLbl.TextColor3 = Color3.fromRGB(255, 198, 52)
        task.wait(2)
        if S.running then
            stLbl.Text       = "Hunting...  RNG Event 2026!"
            stLbl.TextColor3 = Color3.fromRGB(55, 215, 90)
        end
    end
end)

-- ─────────────────────────────────────────
-- 11. BOOT
-- ─────────────────────────────────────────
stLbl.Text       = "v5.0 loaded!  Scanning remotes..."
stLbl.TextColor3 = Color3.fromRGB(72, 255, 142)
task.wait(3)
if not S.running then
    stLbl.Text       = "Idle  --  Press START"
    stLbl.TextColor3 = Color3.fromRGB(145, 135, 170)
end
print("[LH v5.0] Ready | GUI: " .. tostring(GUI_PARENT))
