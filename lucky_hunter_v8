--[[
  LUCKY HUNTER v8.0 — CLEAN REWRITE
  Pet Simulator 99 | RNG Event 2026
  Works: Delta, Solara, Wave, Xeno, Fluxus, Arceus X
  
  ROOT CAUSE FIX:
  - Removed VirtualInputService (crashes Delta)
  - Removed all nil service calls
  - Pure fireclickdetector + fireproximityprompt + RemoteEvent
  - Simplified loops, no varargs
  - Delta-safe: no continue, no ..., no CoreGui assumption
--]]

-- ============================================================
-- SERVICES
-- ============================================================
local Players = game:GetService("Players")
local RS      = game:GetService("ReplicatedStorage")
local LP      = Players.LocalPlayer

-- ============================================================
-- SAFE GUI PARENT
-- ============================================================
local function getGuiParent()
    local ok, cg = pcall(function() return game:GetService("CoreGui") end)
    if ok and cg then
        -- test write access
        local t = Instance.new("Frame")
        local ok2 = pcall(function() t.Parent = cg end)
        pcall(function() t:Destroy() end)
        if ok2 then return cg end
    end
    return LP:WaitForChild("PlayerGui", 10)
end

-- cleanup old
pcall(function()
    local old = game:GetService("CoreGui"):FindFirstChild("LH_v8")
    if old then old:Destroy() end
end)
pcall(function()
    local old = LP:WaitForChild("PlayerGui",3):FindFirstChild("LH_v8")
    if old then old:Destroy() end
end)

local GUIP = getGuiParent()

-- ============================================================
-- REMOTE CACHE  — rebuilt every 8s
-- ============================================================
local RC = {}  -- lowercase name → remote object

local function buildCache()
    local tmp = {}
    pcall(function()
        for _, v in ipairs(RS:GetDescendants()) do
            if v:IsA("RemoteEvent") or v:IsA("RemoteFunction") then
                tmp[v.Name:lower()] = v
            end
        end
    end)
    RC = tmp
end

task.spawn(function()
    task.wait(2)
    buildCache()
    while true do
        task.wait(8)
        buildCache()
    end
end)

-- Fire first matching remote from list
-- a1, a2 are optional — explicit params, no varargs (Delta safe)
local function fire0(list)
    for i = 1, #list do
        local r = RC[list[i]:lower()]
        if r then
            local ok = pcall(function()
                if r:IsA("RemoteEvent") then r:FireServer()
                else r:InvokeServer() end
            end)
            if ok then return true, list[i] end
        end
    end
    return false, nil
end

local function fire1(list, a1)
    for i = 1, #list do
        local r = RC[list[i]:lower()]
        if r then
            local ok = pcall(function()
                if r:IsA("RemoteEvent") then r:FireServer(a1)
                else r:InvokeServer(a1) end
            end)
            if ok then return true, list[i] end
        end
    end
    return false, nil
end

local function fire2(list, a1, a2)
    for i = 1, #list do
        local r = RC[list[i]:lower()]
        if r then
            local ok = pcall(function()
                if r:IsA("RemoteEvent") then r:FireServer(a1, a2)
                else r:InvokeServer(a1, a2) end
            end)
            if ok then return true, list[i] end
        end
    end
    return false, nil
end

-- ============================================================
-- CLICK ENGINE — ClickDetector + ProximityPrompt only
-- No VirtualInputService (crashes Delta)
-- ============================================================
local function clickObj(obj)
    if not obj then return false end
    local hit = false

    local parts = {}
    pcall(function()
        if obj:IsA("BasePart") then
            parts[#parts+1] = obj
        end
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("BasePart") then parts[#parts+1] = d end
        end
    end)

    for i = 1, #parts do
        local p = parts[i]

        -- ClickDetector
        local cd
        pcall(function() cd = p:FindFirstChildOfClass("ClickDetector") end)
        if cd then
            pcall(function() fireclickdetector(cd) end)
            hit = true
        end

        -- ProximityPrompt
        local pp
        pcall(function() pp = p:FindFirstChildOfClass("ProximityPrompt") end)
        if pp then
            pcall(function() fireproximityprompt(pp) end)
            hit = true
        end
    end

    return hit
end

-- ============================================================
-- CONFIG
-- ============================================================
local CFG = {
    rollDelay   = 0.15,
    hatchDelay  = 0.90,
    chestDelay  = 0.10,
    boostDelay  = 20,
    giftDelay   = 4,
    questDelay  = 5,
    afkDelay    = 50,
    tpOn        = true,
    tpOffset    = Vector3.new(0, 4, 0),
    speedMult   = 1.0,

    ROLL_R = {
        "Roll","RollDice","DoRoll","StartRoll","UseRoll","EventRoll",
        "RNGRoll","LuckyRoll","DiceRoll","SpinRNG","RNGSpin","Spin",
        "SpinWheel","RollAction","ActivateRoll","RequestRoll",
        "PerformRoll","RollRequest","AutoRoll","QuickRoll",
        "RNGEvent","RollRNG","TriggerRoll","GameRoll",
    },
    HATCH_R = {
        "HatchEgg","HatchPet","OpenEgg","EggHatch","HatchRequest",
        "HatchEventEgg","RNG_Hatch","HatchRNG","AutoHatch","EggOpen",
        "HatchNow","DoHatch","StartHatch","HatchAction","ServerHatch",
        "QuickHatch","FastHatch","InstantHatch",
    },
    CHEST_R = {
        "ClickToCollect","CollectBlock","ClaimBlock","Interact",
        "TouchPart","ClickBlock","CollectLucky","OpenChest",
        "ClaimChest","CollectChest","ChestClaim","CollectItem",
    },
    BOOST_R = {
        "UseItem","ActivateBoost","UseBoost","ActivateItem",
        "UseLucky","LuckyBoost","BoostActivate","UseCharm",
    },
    GIFT_R = {
        "OpenGift","OpenBag","OpenCrate","UseGift","OpenReward",
        "GiftOpen","CrateOpen","ClaimReward",
    },
    QUEST_R = {
        "ClaimQuest","CompleteQuest","QuestClaim","RewardClaim",
        "FinishQuest","QuestReward","DailyReward","ClaimDaily",
    },

    ROLL_OBJ = {
        "RNGMachine","SpinMachine","DiceMachine","RollMachine",
        "EventMachine","RNGWheel","SpinWheel","DiceWheel","LuckyWheel",
        "RollWheel","RollNPC","DiceNPC","SpinNPC","RNGStation",
        "RollStation","EventStation","DicePad","RollPad","RNGPad",
        "LuckyStation","RollObject","SpinObject","RNGObject",
    },
    EGG_OBJ = {
        "RNG_Egg","RNGEgg","RNG Egg","EventEgg","LuckyEgg",
        "TitanicEgg","HugeEgg","GoldenEgg","MythicalEgg","ArcaneEgg",
        "Egg","EggModel","HatchStation","EggStation","EggPad",
    },
    CHEST_OBJ = {
        "LuckyBlock","LuckyChest","GoldenChest","RNGBlock","EventBlock",
        "MagicBlock","DiceChest","Chest","Block","RNGChest",
    },
    QUEST_OBJ = {
        "QuestBoard","QuestNPC","EventNPC","DailyQuest",
        "QuestGiver","RewardNPC","EventBoard","MissionNPC",
    },
    BOOST_KW = {"Lucky","Boost","RNG","Charm","Fortune","Dice","Roll"},
    GIFT_KW  = {"Gift","Bag","Crate","Box","Reward","Prize"},
}

-- ============================================================
-- STATE
-- ============================================================
local S = {
    running = false,
    roll    = { on=true,  count=0, via="none" },
    hatch   = { on=true,  count=0, via="none" },
    chest   = { on=true,  count=0, via="none" },
    boost   = { on=true,  count=0, via="none" },
    gift    = { on=false, count=0, via="none" },
    quest   = { on=true,  count=0, via="none" },
}
local sessionStart = 0
local totalActions = 0

-- ============================================================
-- HELPERS
-- ============================================================
local function getHRP()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function teleport(pos)
    if not CFG.tpOn then return end
    pcall(function()
        local h = getHRP()
        if h and pos then
            h.CFrame = CFrame.new(pos + CFG.tpOffset)
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
    if ok then return p end
    return nil
end

local function findNearest(nameList, maxDist)
    local best   = nil
    local bestD  = maxDist or 9999
    local h = getHRP()
    if not h then return nil end
    local hp = h.Position

    local ok, desc = pcall(function() return workspace:GetDescendants() end)
    if not ok then return nil end

    for i = 1, #desc do
        local o = desc[i]
        local isOk = o:IsA("BasePart") or o:IsA("Model")
        if isOk then
            local pos = getPos(o)
            if pos then
                local low = o.Name:lower()
                for j = 1, #nameList do
                    if low:find(nameList[j]:lower(), 1, true) then
                        local d = (pos - hp).Magnitude
                        if d < bestD then
                            bestD = d
                            best  = o
                        end
                        break
                    end
                end
            end
        end
    end
    return best
end

local function getBackpackItems(kwList)
    local out = {}
    pcall(function()
        for _, item in ipairs(LP.Backpack:GetChildren()) do
            local low = item.Name:lower()
            for j = 1, #kwList do
                if low:find(kwList[j]:lower(), 1, true) then
                    out[#out+1] = item
                    break
                end
            end
        end
    end)
    return out
end

local function waitD(base)
    return math.max(0.05, base / CFG.speedMult)
end

-- ============================================================
-- LOOPS
-- ============================================================

-- AUTO ROLL
local function loopRoll()
    while S.running do
        task.wait(waitD(CFG.rollDelay))
        if S.roll.on then
            local worked = false
            local via    = "none"

            -- Step 1: find roll object, teleport, click
            local obj = findNearest(CFG.ROLL_OBJ, 100)
            if obj then
                local pos = getPos(obj)
                if pos then teleport(pos); task.wait(0.06) end
                if clickObj(obj) then
                    worked = true; via = "ClickDetector"
                end
            end

            -- Step 2: fire remote (no args)
            if not worked then
                local ok, name = fire0(CFG.ROLL_R)
                if ok then worked=true; via=name end
            end

            if worked then
                S.roll.count = S.roll.count + 1
                S.roll.via   = via
                totalActions = totalActions + 1
            end
        end
    end
end

-- AUTO HATCH
local function loopHatch()
    while S.running do
        task.wait(waitD(CFG.hatchDelay))
        if S.hatch.on then
            local worked = false
            local via    = "none"

            local obj = findNearest(CFG.EGG_OBJ, 120)
            if obj then
                local pos = getPos(obj)
                if pos then teleport(pos); task.wait(0.18) end

                -- Try click first
                if clickObj(obj) then
                    worked=true; via="ClickDetector"
                end

                -- Try remote with object + "Instant"
                if not worked then
                    local ok, name = fire2(CFG.HATCH_R, obj, "Instant")
                    if ok then worked=true; via=name end
                end

                -- Try remote with object only
                if not worked then
                    local ok, name = fire1(CFG.HATCH_R, obj)
                    if ok then worked=true; via=name end
                end

                -- Try remote no args
                if not worked then
                    local ok, name = fire0(CFG.HATCH_R)
                    if ok then worked=true; via=name end
                end
            end

            if worked then
                S.hatch.count = S.hatch.count + 1
                S.hatch.via   = via
                totalActions  = totalActions + 1
            end
        end
    end
end

-- AUTO CHEST / BLOCK
local function loopChest()
    while S.running do
        task.wait(waitD(CFG.chestDelay))
        if S.chest.on then
            local obj = findNearest(CFG.CHEST_OBJ)
            if obj then
                local pos = getPos(obj)
                if pos then teleport(pos); task.wait(0.05) end
                clickObj(obj)
                local ok, name = fire1(CFG.CHEST_R, obj)
                if ok then
                    S.chest.count = S.chest.count + 1
                    S.chest.via   = name
                    totalActions  = totalActions + 1
                end
            end
        end
    end
end

-- AUTO BOOST
local function loopBoost()
    while S.running do
        task.wait(waitD(CFG.boostDelay))
        if S.boost.on then
            local items = getBackpackItems(CFG.BOOST_KW)
            for i = 1, #items do
                local ok, name = fire1(CFG.BOOST_R, items[i])
                if ok then
                    S.boost.count = S.boost.count + 1
                    S.boost.via   = name
                    totalActions  = totalActions + 1
                end
                task.wait(0.12)
            end
        end
    end
end

-- AUTO GIFT
local function loopGift()
    while S.running do
        task.wait(waitD(CFG.giftDelay))
        if S.gift.on then
            local items = getBackpackItems(CFG.GIFT_KW)
            for i = 1, #items do
                local ok, name = fire1(CFG.GIFT_R, items[i])
                if ok then
                    S.gift.count = S.gift.count + 1
                    S.gift.via   = name
                    totalActions = totalActions + 1
                end
                task.wait(0.12)
            end
        end
    end
end

-- AUTO QUEST
local function loopQuest()
    while S.running do
        task.wait(waitD(CFG.questDelay))
        if S.quest.on then
            local obj = findNearest(CFG.QUEST_OBJ)
            if obj then
                local pos = getPos(obj)
                if pos then teleport(pos); task.wait(0.35) end
                clickObj(obj)
            end
            local ok, name = fire0(CFG.QUEST_R)
            if ok then
                S.quest.count = S.quest.count + 1
                S.quest.via   = name
                totalActions  = totalActions + 1
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
                h.CFrame = c * CFrame.new(0.1, 0, 0)
                task.wait(0.1)
                h.CFrame = c
            end
        end)
    end
end

local function startAllLoops()
    task.spawn(loopRoll)
    task.spawn(loopHatch)
    task.spawn(loopChest)
    task.spawn(loopBoost)
    task.spawn(loopGift)
    task.spawn(loopQuest)
    task.spawn(loopAFK)
end

-- ============================================================
-- COLORS
-- ============================================================
local C = {
    BG     = Color3.fromRGB(10, 7, 18),
    CARD   = Color3.fromRGB(18, 12, 30),
    ACC    = Color3.fromRGB(108, 38, 228),
    ACC2   = Color3.fromRGB(188, 78, 255),
    GREEN  = Color3.fromRGB(24, 172, 66),
    RED    = Color3.fromRGB(155, 26, 26),
    TEXT   = Color3.fromRGB(228, 218, 245),
    SUB    = Color3.fromRGB(148, 132, 175),
    GOLD   = Color3.fromRGB(255, 215, 0),
    CYAN   = Color3.fromRGB(0, 215, 255),
    ORANGE = Color3.fromRGB(255, 140, 0),
    PURPLE = Color3.fromRGB(188, 88, 255),
    TEAL   = Color3.fromRGB(52, 225, 148),
    WHITE  = Color3.new(1, 1, 1),
    BLACK  = Color3.new(0, 0, 0),
}

-- ============================================================
-- GUI BUILD
-- ============================================================
local W      = 298
local H_TITLE = 44
local H_TABS  = 30
local H_BODY  = 308
local H_FULL  = H_TITLE + H_TABS + H_BODY

local sg = Instance.new("ScreenGui")
sg.Name           = "LH_v8"
sg.ResetOnSpawn   = false
sg.DisplayOrder   = 9999
sg.IgnoreGuiInset = true
sg.Parent         = GUIP

-- Shadow
local shadow = Instance.new("Frame")
shadow.Size                  = UDim2.new(0, W+4, 0, H_FULL+4)
shadow.Position              = UDim2.new(0, 12, 0, 12)
shadow.BackgroundColor3      = C.BLACK
shadow.BackgroundTransparency = 0.55
shadow.BorderSizePixel       = 0
shadow.ZIndex                = 1
shadow.Parent                = sg
Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 14)

-- Main frame
local mf = Instance.new("Frame")
mf.Name             = "Main"
mf.Size             = UDim2.new(0, W, 0, H_FULL)
mf.Position         = UDim2.new(0, 10, 0, 10)
mf.BackgroundColor3 = C.BG
mf.BorderSizePixel  = 0
mf.Active           = true
mf.Draggable        = true
mf.ZIndex           = 2
mf.Parent           = sg
Instance.new("UICorner", mf).CornerRadius = UDim.new(0, 14)

local mfStroke = Instance.new("UIStroke")
mfStroke.Color       = C.ACC
mfStroke.Thickness   = 2.2
mfStroke.Transparency = 0.08
mfStroke.Parent      = mf

-- ── TITLE BAR ──
local titleFr = Instance.new("Frame")
titleFr.Size             = UDim2.new(1, 0, 0, H_TITLE)
titleFr.BackgroundColor3 = C.ACC
titleFr.BorderSizePixel  = 0
titleFr.ZIndex           = 3
titleFr.Parent           = mf
Instance.new("UICorner", titleFr).CornerRadius = UDim.new(0, 14)

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(205, 82, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(55, 12, 155)),
})
titleGrad.Rotation = 90
titleGrad.Parent   = titleFr

local titleTxt = Instance.new("TextLabel")
titleTxt.Size               = UDim2.new(1, -80, 0, 26)
titleTxt.Position           = UDim2.new(0, 12, 0, 2)
titleTxt.BackgroundTransparency = 1
titleTxt.Text               = "LUCKY HUNTER  v8.0"
titleTxt.TextColor3         = C.WHITE
titleTxt.TextSize           = 14
titleTxt.Font               = Enum.Font.GothamBold
titleTxt.TextXAlignment     = Enum.TextXAlignment.Left
titleTxt.ZIndex             = 4
titleTxt.Parent             = titleFr

local subTitleTxt = Instance.new("TextLabel")
subTitleTxt.Size               = UDim2.new(1, -80, 0, 14)
subTitleTxt.Position           = UDim2.new(0, 12, 0, 28)
subTitleTxt.BackgroundTransparency = 1
subTitleTxt.Text               = "RNG Event 2026  |  All Executors"
subTitleTxt.TextColor3         = Color3.fromRGB(210, 180, 255)
subTitleTxt.TextSize           = 9
subTitleTxt.Font               = Enum.Font.Gotham
subTitleTxt.TextXAlignment     = Enum.TextXAlignment.Left
subTitleTxt.ZIndex             = 4
subTitleTxt.Parent             = titleFr

-- Minimize button
local minBtn = Instance.new("TextButton")
minBtn.Size             = UDim2.new(0, 28, 0, 28)
minBtn.Position         = UDim2.new(1, -34, 0.5, -14)
minBtn.BackgroundColor3 = C.WHITE
minBtn.BackgroundTransparency = 0.82
minBtn.Text             = "-"
minBtn.TextColor3       = C.WHITE
minBtn.TextSize         = 18
minBtn.Font             = Enum.Font.GothamBold
minBtn.BorderSizePixel  = 0
minBtn.ZIndex           = 5
minBtn.Parent           = titleFr
Instance.new("UICorner", minBtn).CornerRadius = UDim.new(0, 6)

-- ── TAB BAR ──
local tabBarFr = Instance.new("Frame")
tabBarFr.Size             = UDim2.new(1, 0, 0, H_TABS)
tabBarFr.Position         = UDim2.new(0, 0, 0, H_TITLE)
tabBarFr.BackgroundColor3 = Color3.fromRGB(14, 9, 24)
tabBarFr.BorderSizePixel  = 0
tabBarFr.ZIndex           = 3
tabBarFr.Parent           = mf

local TABNAMES = {"HOME", "SETTINGS", "STATS", "HELP"}
local tabBtns  = {}
local tabPages = {}
local TW = W / #TABNAMES

for i, tname in ipairs(TABNAMES) do
    local btn = Instance.new("TextButton")
    btn.Size             = UDim2.new(0, TW-2, 0, H_TABS-4)
    btn.Position         = UDim2.new(0, (i-1)*TW+1, 0, 2)
    btn.BackgroundColor3 = (tname == "HOME") and C.ACC or Color3.fromRGB(22, 15, 36)
    btn.Text             = tname
    btn.TextColor3       = C.WHITE
    btn.TextSize         = 10
    btn.Font             = Enum.Font.GothamBold
    btn.BorderSizePixel  = 0
    btn.ZIndex           = 4
    btn.Parent           = tabBarFr
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 5)
    tabBtns[tname] = btn

    local page = Instance.new("ScrollingFrame")
    page.Size                = UDim2.new(1, 0, 0, H_BODY)
    page.Position            = UDim2.new(0, 0, 0, H_TITLE + H_TABS)
    page.BackgroundTransparency = 1
    page.BorderSizePixel     = 0
    page.ScrollBarThickness  = 3
    page.ScrollBarImageColor3 = C.ACC
    page.CanvasSize          = UDim2.new(0, 0, 0, 0)
    page.Visible             = (tname == "HOME")
    page.ZIndex              = 3
    page.Parent              = mf
    tabPages[tname] = page
end

local function switchTab(name)
    for n, pg in pairs(tabPages) do
        pg.Visible = (n == name)
    end
    for n, btn in pairs(tabBtns) do
        btn.BackgroundColor3 = (n == name) and C.ACC or Color3.fromRGB(22, 15, 36)
    end
end
for name, btn in pairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
end

-- ── UI helpers ──
local function mkCard(parent, y, h)
    local f = Instance.new("Frame")
    f.Size             = UDim2.new(1, -16, 0, h)
    f.Position         = UDim2.new(0, 8, 0, y)
    f.BackgroundColor3 = C.CARD
    f.BorderSizePixel  = 0
    f.ZIndex           = 4
    f.Parent           = parent
    Instance.new("UICorner", f).CornerRadius = UDim.new(0, 9)
    return f
end

local function mkText(parent, txt, x, y, w, h, sz, col, xa, bold)
    local l = Instance.new("TextLabel")
    l.Size               = UDim2.new(0, w, 0, h)
    l.Position           = UDim2.new(0, x, 0, y)
    l.BackgroundTransparency = 1
    l.Text               = txt
    l.TextColor3         = col or C.TEXT
    l.TextSize           = sz or 11
    l.Font               = bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextXAlignment     = xa or Enum.TextXAlignment.Left
    l.ZIndex             = 5
    l.Parent             = parent
    return l
end

local function mkToggle(parent, sr, x, y)
    local b = Instance.new("TextButton")
    b.Size             = UDim2.new(0, 50, 0, 24)
    b.Position         = UDim2.new(0, x, 0, y)
    b.BackgroundColor3 = sr.on and C.GREEN or C.RED
    b.Text             = sr.on and "ON" or "OFF"
    b.TextColor3       = C.WHITE
    b.TextSize         = 11
    b.Font             = Enum.Font.GothamBold
    b.BorderSizePixel  = 0
    b.ZIndex           = 5
    b.Parent           = parent
    Instance.new("UICorner", b).CornerRadius = UDim.new(0, 6)
    b.MouseButton1Click:Connect(function()
        sr.on = not sr.on
        b.BackgroundColor3 = sr.on and C.GREEN or C.RED
        b.Text = sr.on and "ON" or "OFF"
    end)
    return b
end

-- ════════════════════════════════════════
-- HOME TAB
-- ════════════════════════════════════════
local homePg = tabPages["HOME"]
local homeY  = 6

-- Remote status card
local rcCard = mkCard(homePg, homeY, 22)
homeY = homeY + 26
local rcTxt = mkText(rcCard, "Scanning remotes...", 8, 0, W-32, 22, 9, C.GOLD, Enum.TextXAlignment.Left, true)

task.spawn(function()
    while sg and sg.Parent do
        task.wait(2)
        pcall(function()
            local total = 0
            for _ in pairs(RC) do total = total + 1 end
            local lists = {CFG.ROLL_R,CFG.HATCH_R,CFG.CHEST_R,
                           CFG.BOOST_R,CFG.GIFT_R,CFG.QUEST_R}
            local matched = 0
            for _, lst in ipairs(lists) do
                for _, kw in ipairs(lst) do
                    if RC[kw:lower()] then matched=matched+1; break end
                end
            end
            local col = matched >= 3 and C.TEAL
                     or (matched > 0 and C.GOLD or Color3.fromRGB(228,52,52))
            rcTxt.Text      = "RS: "..total.." remotes  |  Matched: "..matched.."/6"
            rcTxt.TextColor3 = col
        end)
    end
end)

-- Feature rows
local ROW_DEFS = {
    {key="roll",  lbl="Auto Roll  (RNG)",    col=C.GOLD,   icon="ROLL"},
    {key="hatch", lbl="Auto Hatch RNG Egg",  col=C.CYAN,   icon="EGG"},
    {key="chest", lbl="Auto Chest / Block",  col=Color3.fromRGB(78,198,255), icon="BOX"},
    {key="boost", lbl="Auto Boost / Charm",  col=C.ORANGE, icon="PWR"},
    {key="gift",  lbl="Auto Gift / Crate",   col=C.PURPLE, icon="GIFT"},
    {key="quest", lbl="Auto Quest Claim",    col=C.TEAL,   icon="QST"},
}

local RH = 34
local RG = 3

for _, def in ipairs(ROW_DEFS) do
    local sr  = S[def.key]
    local row = mkCard(homePg, homeY, RH)
    homeY = homeY + RH + RG

    -- Left accent
    local acc = Instance.new("Frame")
    acc.Size             = UDim2.new(0, 3, 1, -8)
    acc.Position         = UDim2.new(0, 4, 0, 4)
    acc.BackgroundColor3 = def.col
    acc.BorderSizePixel  = 0
    acc.ZIndex           = 5
    acc.Parent           = row
    Instance.new("UICorner", acc).CornerRadius = UDim.new(0, 2)

    -- Icon badge
    local ibFr = Instance.new("Frame")
    ibFr.Size             = UDim2.new(0, 34, 0, 20)
    ibFr.Position         = UDim2.new(0, 11, 0.5, -10)
    ibFr.BackgroundColor3 = def.col
    ibFr.BackgroundTransparency = 0.35
    ibFr.BorderSizePixel  = 0
    ibFr.ZIndex           = 5
    ibFr.Parent           = row
    Instance.new("UICorner", ibFr).CornerRadius = UDim.new(0, 4)
    mkText(ibFr, def.icon, 0, 0, 34, 20, 8, C.WHITE, Enum.TextXAlignment.Center, true)

    -- Count
    local cntL = mkText(row, "0", 50, 1, 28, RH-2, 13, def.col, Enum.TextXAlignment.Left, true)

    -- Feature name
    mkText(row, def.lbl, 82, 1, 120, RH/2, 11, C.TEXT, Enum.TextXAlignment.Left, true)

    -- Via label
    local viaL = mkText(row, "via: none", 82, RH/2, 120, RH/2-2, 8, C.SUB, Enum.TextXAlignment.Left, false)

    -- Toggle
    mkToggle(row, sr, 232, 5)

    -- Row stroke
    local rs = Instance.new("UIStroke")
    rs.Color       = def.col
    rs.Thickness   = 1
    rs.Transparency = 0.55
    rs.Parent      = row

    -- Live update
    task.spawn(function()
        while sg and sg.Parent do
            task.wait(0.9)
            pcall(function()
                cntL.Text = tostring(sr.count)
                viaL.Text = "via: " .. (sr.via or "none")
            end)
        end
    end)
end

-- Status label
local stCard = mkCard(homePg, homeY, 20)
homeY = homeY + 24
local stLbl = mkText(stCard, "Idle  --  Press START", 8, 0, W-32, 20, 11, C.SUB, Enum.TextXAlignment.Left, false)

-- START / STOP button
local startBtn = Instance.new("TextButton")
startBtn.Size             = UDim2.new(1, -16, 0, 44)
startBtn.Position         = UDim2.new(0, 8, 0, homeY)
startBtn.BackgroundColor3 = C.ACC
startBtn.Text             = "START HUNTING"
startBtn.TextColor3       = C.WHITE
startBtn.TextSize         = 15
startBtn.Font             = Enum.Font.GothamBold
startBtn.BorderSizePixel  = 0
startBtn.ZIndex           = 4
startBtn.Parent           = homePg
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 10)
local sBtnGrad = Instance.new("UIGradient")
sBtnGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(155, 60, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(68, 18, 190)),
})
sBtnGrad.Rotation = 90
sBtnGrad.Parent   = startBtn
homeY = homeY + 52
homePg.CanvasSize = UDim2.new(0, 0, 0, homeY)

-- ════════════════════════════════════════
-- SETTINGS TAB
-- ════════════════════════════════════════
local settPg = tabPages["SETTINGS"]
local sy = 8
mkText(settPg, "DELAY SETTINGS", 14, sy, W-28, 14, 11, C.GOLD, Enum.TextXAlignment.Left, true)
sy = sy + 20

local function settRow(par, y, label, cfgKey, minV, maxV, step)
    local c = mkCard(par, y, 34)
    mkText(c, label, 10, 0, 155, 34, 11, C.TEXT, Enum.TextXAlignment.Left, false)
    local function mkPM(txt, px)
        local b = Instance.new("TextButton")
        b.Size             = UDim2.new(0, 26, 0, 24)
        b.Position         = UDim2.new(0, px, 0.5, -12)
        b.BackgroundColor3 = Color3.fromRGB(42, 22, 72)
        b.Text             = txt
        b.TextColor3       = C.WHITE
        b.TextSize         = 15
        b.Font             = Enum.Font.GothamBold
        b.BorderSizePixel  = 0
        b.ZIndex           = 5
        b.Parent           = c
        Instance.new("UICorner", b).CornerRadius = UDim.new(0, 5)
        return b
    end
    local mBtn = mkPM("-", 164)
    local vLbl = mkText(c, tostring(CFG[cfgKey]), 192, 0, 46, 34, 11, C.ACC2, Enum.TextXAlignment.Center, true)
    local pBtn = mkPM("+", 240)
    mBtn.MouseButton1Click:Connect(function()
        CFG[cfgKey] = math.max(minV, math.floor((CFG[cfgKey]-step)*100+0.5)/100)
        vLbl.Text   = tostring(CFG[cfgKey])
    end)
    pBtn.MouseButton1Click:Connect(function()
        CFG[cfgKey] = math.min(maxV, math.floor((CFG[cfgKey]+step)*100+0.5)/100)
        vLbl.Text   = tostring(CFG[cfgKey])
    end)
end

local settDefs = {
    {"Roll Delay (s)",   "rollDelay",  0.05, 5,  0.05},
    {"Hatch Delay (s)",  "hatchDelay", 0.2,  5,  0.1},
    {"Chest Delay (s)",  "chestDelay", 0.05, 5,  0.05},
    {"Boost Delay (s)",  "boostDelay", 5,    60, 1},
    {"Quest Delay (s)",  "questDelay", 2,    30, 1},
    {"Speed Mult x",     "speedMult",  0.5,  5,  0.5},
}
for _, d in ipairs(settDefs) do
    settRow(settPg, sy, d[1], d[2], d[3], d[4], d[5])
    sy = sy + 38
end

-- TP toggle
local tpCard = mkCard(settPg, sy, 34)
sy = sy + 38
mkText(tpCard, "Teleport to Target", 10, 0, 180, 34, 11, C.TEXT, Enum.TextXAlignment.Left, false)
local tpSt = {on = CFG.tpOn}
local tpBtn = mkToggle(tpCard, tpSt, 225, 5)
tpBtn.MouseButton1Click:Connect(function()
    task.wait(0.05); CFG.tpOn = tpSt.on
end)
settPg.CanvasSize = UDim2.new(0, 0, 0, sy+8)

-- ════════════════════════════════════════
-- STATS TAB
-- ════════════════════════════════════════
local statPg = tabPages["STATS"]
local sty = 8
mkText(statPg, "SESSION STATISTICS", 14, sty, W-28, 14, 11, C.GOLD, Enum.TextXAlignment.Left, true)
sty = sty + 20

local statDefs = {
    {key="roll", lbl="Rolls"}, {key="hatch", lbl="Hatches"},
    {key="chest",lbl="Chests"},{key="boost", lbl="Boosts"},
    {key="gift", lbl="Gifts"}, {key="quest", lbl="Quests"},
}
local statEls = {}
for _, def in ipairs(statDefs) do
    local c = mkCard(statPg, sty, 30)
    sty = sty + 34
    mkText(c, def.lbl, 10, 0, 90, 30, 11, C.TEXT, Enum.TextXAlignment.Left, false)
    local vl = mkText(c, "0",  105, 0, 55, 30, 14, C.ACC2, Enum.TextXAlignment.Left, true)
    local ll = mkText(c, "via: none", 165, 0, 110, 30, 9, C.SUB, Enum.TextXAlignment.Left, false)
    statEls[def.key] = {v=vl, l=ll}
end

local totCard = mkCard(statPg, sty, 42)
sty = sty + 46
local totLbl  = mkText(totCard, "Total Actions: 0",  10, 2,  W-32, 20, 12, C.GOLD, Enum.TextXAlignment.Left, true)
local timeLbl = mkText(totCard, "Session: paused",   10, 22, W-32, 18, 11, C.SUB,  Enum.TextXAlignment.Left, false)

local rstBtn = Instance.new("TextButton")
rstBtn.Size             = UDim2.new(1, -16, 0, 30)
rstBtn.Position         = UDim2.new(0, 8, 0, sty)
rstBtn.BackgroundColor3 = Color3.fromRGB(36, 16, 62)
rstBtn.Text             = "RESET STATS"
rstBtn.TextColor3       = Color3.fromRGB(200, 178, 255)
rstBtn.TextSize         = 12
rstBtn.Font             = Enum.Font.GothamBold
rstBtn.BorderSizePixel  = 0
rstBtn.ZIndex           = 4
rstBtn.Parent           = statPg
Instance.new("UICorner", rstBtn).CornerRadius = UDim.new(0, 8)
sty = sty + 38
rstBtn.MouseButton1Click:Connect(function()
    for _, sr in pairs(S) do
        if type(sr) == "table" and sr.count ~= nil then
            sr.count = 0; sr.via = "none"
        end
    end
    totalActions = 0; sessionStart = os.time()
end)

task.spawn(function()
    while sg and sg.Parent do
        task.wait(1)
        pcall(function()
            for _, def in ipairs(statDefs) do
                local el = statEls[def.key]
                local sr = S[def.key]
                if el then
                    el.v.Text = tostring(sr.count)
                    el.l.Text = "via: " .. (sr.via or "none")
                end
            end
            totLbl.Text = "Total Actions: " .. totalActions
            if S.running then
                local el = os.time() - sessionStart
                timeLbl.Text = string.format("Session: %dm %ds", math.floor(el/60), el%60)
            else
                timeLbl.Text = "Session: paused"
            end
        end)
    end
end)
statPg.CanvasSize = UDim2.new(0, 0, 0, sty+8)

-- ════════════════════════════════════════
-- HELP TAB
-- ════════════════════════════════════════
local helpPg = tabPages["HELP"]
local hy = 8
local helpData = {
    {"HOW TO USE",                   C.GOLD,   true},
    {"1. Execute script",             C.TEXT,   false},
    {"2. Wait 3s (remote scan)",      C.TEXT,   false},
    {"3. Press START HUNTING",        C.TEXT,   false},
    {"4. Watch counts go up",         C.TEXT,   false},
    {"",C.TEXT,false},
    {"ROLL METHOD (4 fallbacks)",     C.GOLD,   true},
    {"1. ClickDetector on object",    C.SUB,    false},
    {"2. Remote fire (24 names)",     C.SUB,    false},
    {"3. ProximityPrompt",            C.SUB,    false},
    {"4. Repeat every 0.15s",         C.SUB,    false},
    {"",C.TEXT,false},
    {"IF STILL NOT WORKING",          C.GOLD,   true},
    {"Remotes: Matched 0/6 = normal", C.SUB,    false},
    {"Roll uses ClickDetector,",      C.SUB,    false},
    {"not remotes. Count > 0 = OK.",  C.SUB,    false},
    {"",C.TEXT,false},
    {"TARGET PETS",                   C.GOLD,   true},
    {"Titanic Arcane Void Cat",       C.CYAN,   false},
    {"Titanic Arcane Halo Cat",       C.CYAN,   false},
    {"Huge Nebula Lion",              C.PURPLE, false},
    {"Huge Eclipse Owl",              C.PURPLE, false},
    {"Huge Cataclysm Bear",           C.PURPLE, false},
    {"Huge Oracle Tiger",             C.PURPLE, false},
    {"Huge Prism Pegasus",            C.PURPLE, false},
    {"Huge Anubis",                   C.PURPLE, false},
    {"",C.TEXT,false},
    {"SUPPORTED EXECUTORS",           C.GOLD,   true},
    {"Delta, Solara, Wave, Xeno",     C.TEAL,   false},
    {"Fluxus, Arceus X, Hydrogen",    C.TEAL,   false},
}
for _, ln in ipairs(helpData) do
    if ln[1] == "" then
        hy = hy + 6
    else
        local lh = 16
        mkText(helpPg, ln[1], 14, hy, W-28, lh, ln[3] and 11 or 10, ln[2], Enum.TextXAlignment.Left, ln[3])
        hy = hy + lh + 2
    end
end
helpPg.CanvasSize = UDim2.new(0, 0, 0, hy+10)

-- ════════════════════════════════════════
-- MINIMIZE
-- ════════════════════════════════════════
local minimized = false
local bodyElems = {tabBarFr}
for _, pg in pairs(tabPages) do bodyElems[#bodyElems+1] = pg end

minBtn.MouseButton1Click:Connect(function()
    minimized = not minimized
    for _, el in ipairs(bodyElems) do
        pcall(function() el.Visible = not minimized end)
    end
    if minimized then
        mf.Size     = UDim2.new(0, W, 0, H_TITLE)
        shadow.Size = UDim2.new(0, W+4, 0, H_TITLE+4)
        minBtn.Text = "+"
    else
        mf.Size     = UDim2.new(0, W, 0, H_FULL)
        shadow.Size = UDim2.new(0, W+4, 0, H_FULL+4)
        minBtn.Text = "-"
    end
end)

-- ════════════════════════════════════════
-- START / STOP LOGIC
-- ════════════════════════════════════════
local function startHunting()
    if S.running then return end
    S.running    = true
    sessionStart = os.time()
    stLbl.Text       = "Hunting...  RNG Event 2026!"
    stLbl.TextColor3 = C.TEAL
    startBtn.Text    = "STOP HUNTING"
    sBtnGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(210, 38, 38)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(142, 8, 8)),
    })
    startAllLoops()
end

local function stopHunting()
    S.running        = false
    stLbl.Text       = "Stopped."
    stLbl.TextColor3 = Color3.fromRGB(215, 60, 60)
    startBtn.Text    = "START HUNTING"
    sBtnGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(155, 60, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(68, 18, 190)),
    })
end

startBtn.MouseButton1Click:Connect(function()
    if S.running then stopHunting() else startHunting() end
end)

-- Respawn resume
LP.CharacterAdded:Connect(function()
    if S.running then
        task.wait(2)
        startAllLoops()
        stLbl.Text       = "Respawned  --  Resumed!"
        stLbl.TextColor3 = Color3.fromRGB(255, 196, 50)
        task.wait(2)
        if S.running then
            stLbl.Text       = "Hunting...  RNG Event 2026!"
            stLbl.TextColor3 = C.TEAL
        end
    end
end)

-- ════════════════════════════════════════
-- BOOT
-- ════════════════════════════════════════
stLbl.Text       = "v8.0 loaded!  Scanning..."
stLbl.TextColor3 = Color3.fromRGB(70, 255, 140)
task.wait(3)
if not S.running then
    stLbl.Text       = "Idle  --  Press START"
    stLbl.TextColor3 = C.SUB
end
print("[LH v8.0] Ready | Parent: " .. tostring(GUIP))
