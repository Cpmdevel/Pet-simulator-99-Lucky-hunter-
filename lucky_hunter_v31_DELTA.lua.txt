-- ╔══════════════════════════════════════════════════════════════════╗
-- ║  LUCKY HUNTER v3.1  |  DELTA EDITION                            ║
-- ║  Pet Simulator 99  -  RNG Part 2 Event                          ║
-- ║  FIX: Remote scanner, Auto-Roll, Chest collector, UI v3.1       ║
-- ╚══════════════════════════════════════════════════════════════════╝

-- ══ Cleanup old GUI ══
pcall(function()
    game:GetService("CoreGui"):FindFirstChild("LH_GUI") and
    game:GetService("CoreGui"):FindFirstChild("LH_GUI"):Destroy()
end)
pcall(function()
    game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("LH_GUI") and
    game:GetService("Players").LocalPlayer.PlayerGui:FindFirstChild("LH_GUI"):Destroy()
end)

local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")
local LocalPlayer       = Players.LocalPlayer

-- ══════════════════════════════════════════════════
-- GUI PARENT (CoreGui → PlayerGui fallback)
-- ══════════════════════════════════════════════════
local GUI_PARENT
pcall(function() GUI_PARENT = game:GetService("CoreGui") end)
if not GUI_PARENT then
    GUI_PARENT = LocalPlayer:WaitForChild("PlayerGui", 10)
end

-- ══════════════════════════════════════════════════
-- REMOTE SCANNER
-- Game эхлэхэд ReplicatedStorage-с бодит remote
-- нэрнүүдийг автоматаар скан хийнэ
-- ══════════════════════════════════════════════════
local scanned = {
    roll     = nil,  -- Auto Roll (RNG Part 2 гол mechanic)
    chest    = nil,  -- Chest нээх
    egg      = nil,  -- Egg hatch
    boost    = nil,  -- Boost идэвхжүүлэх
    gift     = nil,  -- Gift/Crate нээх
    quest    = nil,  -- Quest claim
}

-- PS99 RNG Part 2-д ашиглагддаг бодит remote нэрнүүд
local REMOTE_HINTS = {
    roll  = {"Roll","RollDice","SpinRNG","RNGRoll","DoRoll","RollEvent",
             "ActivateRoll","StartRoll","UseRoll","RollLucky","EventRoll",
             "SpinWheel","RNGSpin","Spin","LuckyRoll","DiceRoll"},
    chest = {"OpenChest","ClaimChest","CollectChest","ClickToCollect",
             "Interact","TouchPart","ClaimBlock","CollectLucky","ClickBlock",
             "OpenLucky","LuckyChest","ChestClaim","BlockClaim"},
    egg   = {"HatchEgg","OpenEgg","EggHatch","HatchRequest","HatchEventEgg",
             "RNG_Hatch","HatchRNG","HatchPet","EggOpen","AutoHatch"},
    boost = {"UseItem","ActivateBoost","UseBoost","ActivateItem",
             "UseLucky","LuckyBoost","BoostActivate","ItemUse"},
    gift  = {"OpenGift","OpenBag","OpenCrate","UseGift","OpenReward",
             "GiftOpen","CrateOpen","BagOpen","ClaimReward"},
    quest = {"ClaimQuest","CompleteQuest","QuestClaim","RewardClaim",
             "FinishQuest","QuestReward","DailyReward","EventQuest"},
}

local function scanRemotes()
    local allRemotes = {}
    -- ReplicatedStorage бүх remote цуглуулах
    for _, obj in ipairs(ReplicatedStorage:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") then
            allRemotes[obj.Name:lower()] = obj
        end
    end

    for category, hints in pairs(REMOTE_HINTS) do
        for _, hint in ipairs(hints) do
            local found = allRemotes[hint:lower()]
            if found then
                scanned[category] = found
                print("[LH] Found remote [" .. category .. "]: " .. found.Name)
                break
            end
        end
        if not scanned[category] then
            -- Partial match fallback
            for rname, robj in pairs(allRemotes) do
                local hintLow = hint and hint:lower() or ""
                if rname:find(category:lower()) then
                    scanned[category] = robj
                    print("[LH] Partial match [" .. category .. "]: " .. robj.Name)
                    break
                end
            end
        end
    end
end

-- Scan on load + retry
task.spawn(function()
    task.wait(2)
    scanRemotes()
    -- 10 секунд болгон дахин скан (game update болсон үед)
    while true do
        task.wait(10)
        scanRemotes()
    end
end)

-- ══════════════════════════════════════════════════
-- CONFIG
-- ══════════════════════════════════════════════════
local CFG = {
    rollDelay    = 0.15,   -- RNG Roll (хамгийн чухал)
    chestDelay   = 0.08,   -- Chest/Block цуглуулах
    eggDelay     = 1.2,
    boostDelay   = 18,
    giftDelay    = 3.5,
    questDelay   = 5,
    antiAFKDelay = 50,
    tpOffset     = Vector3.new(0, 4, 0),

    -- Object search names
    chestNames = {"LuckyBlock","Lucky Chest","GoldenChest","LuckyChest",
                  "LuckyBox","RNGBlock","RNG_Block","EventBlock","MagicBlock",
                  "Chest","Lucky","RNGChest","EventChest","DiceChest"},
    eggNames   = {"RNG_Egg","EventEgg","MythicalEgg","LuckyEgg","GoldenEgg",
                  "TitanicEgg","HugeEgg","RNGPart2Egg","DiceEgg"},
    rollNames  = {"RNGMachine","SpinMachine","DiceMachine","RollMachine",
                  "LuckyMachine","RNGWheel","SpinWheel","DiceWheel",
                  "RollNPC","SpinNPC","DiceNPC","RNGStation"},
    questNames = {"QuestBoard","QuestNPC","EventNPC","DailyQuest",
                  "QuestGiver","RewardNPC","EventBoard"},

    boostKeywords = {"Lucky","Boost","RNG","Charm","Fortune","Dice","Roll"},
    giftKeywords  = {"Gift","Bag","Crate","Box","Reward","Prize","Chest"},
}

-- ══════════════════════════════════════════════════
-- STATE
-- ══════════════════════════════════════════════════
local state = {
    running = false,
    roll    = { on = true,  count = 0, label = "Auto Roll (RNG)" },
    chest   = { on = true,  count = 0, label = "Auto Chest/Block" },
    eggs    = { on = false, count = 0, label = "Auto Eggs" },
    boosts  = { on = true,  count = 0, label = "Auto Boosts" },
    gifts   = { on = false, count = 0, label = "Auto Gifts/Crates" },
    quests  = { on = true,  count = 0, label = "Auto Quest Claim" },
}

-- ══════════════════════════════════════════════════
-- UTILITY
-- ══════════════════════════════════════════════════
local function getHRP()
    local c = LocalPlayer.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function safeTeleport(pos)
    pcall(function()
        local hrp = getHRP()
        if hrp and pos then
            hrp.CFrame = CFrame.new(pos + CFG.tpOffset)
        end
    end)
end

local function getPos(obj)
    if not obj then return nil end
    local ok, pos = pcall(function()
        if obj:IsA("Model") then
            if obj.PrimaryPart then return obj.PrimaryPart.Position end
            local cf = obj:GetBoundingBox()
            return cf.Position
        end
        return obj.Position
    end)
    return ok and pos or nil
end

local function fireScanned(key, arg1, arg2)
    local r = scanned[key]
    if not r then return false end
    local ok = pcall(function()
        if r:IsA("RemoteEvent") then
            if arg2 ~= nil then r:FireServer(arg1, arg2)
            elseif arg1 ~= nil then r:FireServer(arg1)
            else r:FireServer() end
        else
            if arg2 ~= nil then r:InvokeServer(arg1, arg2)
            elseif arg1 ~= nil then r:InvokeServer(arg1)
            else r:InvokeServer() end
        end
    end)
    return ok
end

local function findClosest(nameList, maxDist)
    local target, minDist = nil, maxDist or 9999
    local hrp = getHRP()
    if not hrp then return nil end
    local hrpPos = hrp.Position
    local ok, desc = pcall(function() return workspace:GetDescendants() end)
    if not ok then return nil end
    for i = 1, #desc do
        local obj = desc[i]
        if obj:IsA("BasePart") or obj:IsA("Model") then
            local pos = getPos(obj)
            if pos then
                local low = obj.Name:lower()
                for j = 1, #nameList do
                    if low:find(nameList[j]:lower(), 1, true) then
                        local d = (pos - hrpPos).Magnitude
                        if d < minDist then
                            minDist = d
                            target = obj
                        end
                        break
                    end
                end
            end
        end
    end
    return target
end

local function findInBackpack(keywords)
    local found = {}
    pcall(function()
        for _, item in ipairs(LocalPlayer.Backpack:GetChildren()) do
            local low = item.Name:lower()
            for _, kw in ipairs(keywords) do
                if low:find(kw:lower(), 1, true) then
                    found[#found+1] = item
                    break
                end
            end
        end
    end)
    return found
end

-- ══════════════════════════════════════════════════
-- LOOPS
-- ══════════════════════════════════════════════════

-- 1. AUTO ROLL — RNG Part 2 гол feature
local function loopRoll()
    while state.running do
        task.wait(CFG.rollDelay)
        if state.roll.on then
            -- Roll object олох эсвэл шууд remote дуудах
            local rollObj = findClosest(CFG.rollNames, 30)
            if rollObj then
                local pos = getPos(rollObj)
                if pos then safeTeleport(pos) end
                task.wait(0.05)
            end
            if fireScanned("roll") then
                state.roll.count = state.roll.count + 1
            end
        end
    end
end

-- 2. AUTO CHEST / BLOCK
local function loopChest()
    while state.running do
        task.wait(CFG.chestDelay)
        if state.chest.on then
            local obj = findClosest(CFG.chestNames)
            if obj then
                local pos = getPos(obj)
                if pos then
                    safeTeleport(pos)
                    task.wait(0.04)
                    if fireScanned("chest", obj) then
                        state.chest.count = state.chest.count + 1
                    end
                end
            end
        end
    end
end

-- 3. AUTO EGG HATCH
local function loopEggs()
    while state.running do
        task.wait(CFG.eggDelay)
        if state.eggs.on then
            local obj = findClosest(CFG.eggNames)
            if obj then
                local pos = getPos(obj)
                if pos then
                    safeTeleport(pos)
                    task.wait(0.25)
                    if fireScanned("egg", obj, "Instant") then
                        state.eggs.count = state.eggs.count + 1
                    end
                end
            end
        end
    end
end

-- 4. AUTO BOOSTS
local function loopBoosts()
    while state.running do
        task.wait(CFG.boostDelay)
        if state.boosts.on then
            for _, item in ipairs(findInBackpack(CFG.boostKeywords)) do
                if fireScanned("boost", item) then
                    state.boosts.count = state.boosts.count + 1
                end
                task.wait(0.1)
            end
        end
    end
end

-- 5. AUTO GIFTS
local function loopGifts()
    while state.running do
        task.wait(CFG.giftDelay)
        if state.gifts.on then
            for _, item in ipairs(findInBackpack(CFG.giftKeywords)) do
                if fireScanned("gift", item) then
                    state.gifts.count = state.gifts.count + 1
                end
                task.wait(0.1)
            end
        end
    end
end

-- 6. AUTO QUEST CLAIM
local function loopQuests()
    while state.running do
        task.wait(CFG.questDelay)
        if state.quests.on then
            local obj = findClosest(CFG.questNames)
            if obj then
                local pos = getPos(obj)
                if pos then
                    safeTeleport(pos)
                    task.wait(0.3)
                end
            end
            if fireScanned("quest") then
                state.quests.count = state.quests.count + 1
            end
        end
    end
end

-- 7. ANTI-AFK
local function loopAntiAFK()
    while state.running do
        task.wait(CFG.antiAFKDelay)
        pcall(function()
            local hrp = getHRP()
            if hrp then
                local orig = hrp.CFrame
                hrp.CFrame = orig * CFrame.new(0.1, 0, 0)
                task.wait(0.1)
                hrp.CFrame = orig
            end
        end)
    end
end

local function spawnAllLoops()
    task.spawn(loopRoll)
    task.spawn(loopChest)
    task.spawn(loopEggs)
    task.spawn(loopBoosts)
    task.spawn(loopGifts)
    task.spawn(loopQuests)
    task.spawn(loopAntiAFK)
end

-- ══════════════════════════════════════════════════
-- GUI v3.1
-- ══════════════════════════════════════════════════
local sg = Instance.new("ScreenGui")
sg.Name           = "LH_GUI"
sg.ResetOnSpawn   = false
sg.DisplayOrder   = 999
sg.IgnoreGuiInset = true
sg.Parent         = GUI_PARENT

-- Shadow frame (depth effect)
local shadow = Instance.new("Frame")
shadow.Size             = UDim2.new(0, 268, 0, 100)
shadow.Position         = UDim2.new(0, 13, 0, 13)
shadow.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
shadow.BackgroundTransparency = 0.7
shadow.BorderSizePixel  = 0
shadow.Parent           = sg
Instance.new("UICorner", shadow).CornerRadius = UDim.new(0, 12)

-- Main frame
local fr = Instance.new("Frame")
fr.Name             = "Main"
fr.Size             = UDim2.new(0, 265, 0, 100)
fr.Position         = UDim2.new(0, 10, 0, 10)
fr.BackgroundColor3 = Color3.fromRGB(14, 10, 24)
fr.BorderSizePixel  = 0
fr.Active           = true
fr.Draggable        = true
fr.Parent           = sg
Instance.new("UICorner", fr).CornerRadius = UDim.new(0, 12)

local frStroke = Instance.new("UIStroke")
frStroke.Color       = Color3.fromRGB(130, 60, 240)
frStroke.Thickness   = 2
frStroke.Transparency = 0.2
frStroke.Parent      = fr

-- Title bar
local titleFr = Instance.new("Frame")
titleFr.Size             = UDim2.new(1, 0, 0, 40)
titleFr.BackgroundColor3 = Color3.fromRGB(80, 25, 170)
titleFr.BorderSizePixel  = 0
titleFr.Parent           = fr
Instance.new("UICorner", titleFr).CornerRadius = UDim.new(0, 12)

local titleGrad = Instance.new("UIGradient")
titleGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(180, 80, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 20, 180)),
})
titleGrad.Rotation = 90
titleGrad.Parent = titleFr

local titleTxt = Instance.new("TextLabel")
titleTxt.Size               = UDim2.new(1, 0, 1, 0)
titleTxt.BackgroundTransparency = 1
titleTxt.Text               = "LUCKY HUNTER v3.1  |  RNG PART 2"
titleTxt.TextColor3         = Color3.fromRGB(255, 255, 255)
titleTxt.TextSize           = 12
titleTxt.Font               = Enum.Font.GothamBold
titleTxt.Parent             = titleFr

-- Version badge
local verBadge = Instance.new("TextLabel")
verBadge.Size               = UDim2.new(1, -16, 0, 14)
verBadge.Position           = UDim2.new(0, 8, 0, 42)
verBadge.BackgroundTransparency = 1
verBadge.Text               = "AUTO ROLL  |  CHEST  |  BOOST  |  QUEST  |  ANTI-AFK"
verBadge.TextColor3         = Color3.fromRGB(200, 160, 255)
verBadge.TextSize           = 9
verBadge.Font               = Enum.Font.Gotham
verBadge.Parent             = fr

-- Remote status bar
local remoteTxt = Instance.new("TextLabel")
remoteTxt.Size               = UDim2.new(1, -16, 0, 14)
remoteTxt.Position           = UDim2.new(0, 8, 0, 57)
remoteTxt.BackgroundTransparency = 1
remoteTxt.Text               = "Scanning remotes..."
remoteTxt.TextColor3         = Color3.fromRGB(255, 180, 50)
remoteTxt.TextSize           = 9
remoteTxt.Font               = Enum.Font.Gotham
remoteTxt.Parent             = fr

-- Update remote status every 3s
task.spawn(function()
    while sg and sg.Parent do
        task.wait(3)
        pcall(function()
            local found = 0
            for _, v in pairs(scanned) do
                if v then found = found + 1 end
            end
            remoteTxt.Text = "Remotes found: " .. found .. "/6"
            remoteTxt.TextColor3 = found > 0
                and Color3.fromRGB(80, 220, 120)
                or  Color3.fromRGB(255, 80, 80)
        end)
    end
end)

-- ── Row builder ──
local ROW_Y_START = 74
local ROW_H       = 33
local ROW_GAP     = 3

local ROWS = {
    { key = "roll",   emoji = "ROLL",  color = Color3.fromRGB(255, 210, 0)   },
    { key = "chest",  emoji = "CHEST", color = Color3.fromRGB(80,  200, 255) },
    { key = "eggs",   emoji = "EGG",   color = Color3.fromRGB(120, 255, 140) },
    { key = "boosts", emoji = "BOOST", color = Color3.fromRGB(255, 140, 0)   },
    { key = "gifts",  emoji = "GIFT",  color = Color3.fromRGB(190, 90,  255) },
    { key = "quests", emoji = "QUEST", color = Color3.fromRGB(60,  220, 150) },
}

for i, row in ipairs(ROWS) do
    local stateRef = state[row.key]
    local y = ROW_Y_START + (i - 1) * (ROW_H + ROW_GAP)

    local rowFr = Instance.new("Frame")
    rowFr.Size             = UDim2.new(1, -16, 0, ROW_H)
    rowFr.Position         = UDim2.new(0, 8, 0, y)
    rowFr.BackgroundColor3 = Color3.fromRGB(22, 15, 40)
    rowFr.BorderSizePixel  = 0
    rowFr.Parent           = fr
    Instance.new("UICorner", rowFr).CornerRadius = UDim.new(0, 8)

    local rowStroke = Instance.new("UIStroke")
    rowStroke.Color       = row.color
    rowStroke.Thickness   = 1
    rowStroke.Transparency = 0.65
    rowStroke.Parent      = rowFr

    -- Accent left bar
    local accentBar = Instance.new("Frame")
    accentBar.Size             = UDim2.new(0, 4, 1, -8)
    accentBar.Position         = UDim2.new(0, 4, 0, 4)
    accentBar.BackgroundColor3 = row.color
    accentBar.BorderSizePixel  = 0
    accentBar.Parent           = rowFr
    Instance.new("UICorner", accentBar).CornerRadius = UDim.new(0, 2)

    -- Count badge
    local cntFr = Instance.new("Frame")
    cntFr.Size             = UDim2.new(0, 38, 0, 22)
    cntFr.Position         = UDim2.new(0, 12, 0.5, -11)
    cntFr.BackgroundColor3 = row.color
    cntFr.BackgroundTransparency = 0.45
    cntFr.BorderSizePixel  = 0
    cntFr.Parent           = rowFr
    Instance.new("UICorner", cntFr).CornerRadius = UDim.new(0, 5)

    local cntTxt = Instance.new("TextLabel")
    cntTxt.Size               = UDim2.new(1, 0, 1, 0)
    cntTxt.BackgroundTransparency = 1
    cntTxt.Text               = "0"
    cntTxt.TextColor3         = Color3.fromRGB(255, 255, 255)
    cntTxt.TextSize           = 11
    cntTxt.Font               = Enum.Font.GothamBold
    cntTxt.Parent             = cntFr

    -- Label
    local labelTxt = Instance.new("TextLabel")
    labelTxt.Size               = UDim2.new(0, 110, 1, 0)
    labelTxt.Position           = UDim2.new(0, 56, 0, 0)
    labelTxt.BackgroundTransparency = 1
    labelTxt.Text               = stateRef.label
    labelTxt.TextColor3         = Color3.fromRGB(225, 215, 240)
    labelTxt.TextSize           = 11
    labelTxt.Font               = Enum.Font.GothamBold
    labelTxt.TextXAlignment     = Enum.TextXAlignment.Left
    labelTxt.Parent             = rowFr

    -- Toggle button
    local togBtn = Instance.new("TextButton")
    togBtn.Size             = UDim2.new(0, 52, 0, 23)
    togBtn.Position         = UDim2.new(1, -58, 0.5, -11)
    togBtn.BackgroundColor3 = stateRef.on and Color3.fromRGB(30, 180, 70) or Color3.fromRGB(160, 35, 35)
    togBtn.Text             = stateRef.on and "ON" or "OFF"
    togBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
    togBtn.TextSize         = 11
    togBtn.Font             = Enum.Font.GothamBold
    togBtn.BorderSizePixel  = 0
    togBtn.Parent           = rowFr
    Instance.new("UICorner", togBtn).CornerRadius = UDim.new(0, 6)

    togBtn.MouseButton1Click:Connect(function()
        stateRef.on = not stateRef.on
        togBtn.BackgroundColor3 = stateRef.on
            and Color3.fromRGB(30, 180, 70)
            or  Color3.fromRGB(160, 35, 35)
        togBtn.Text = stateRef.on and "ON" or "OFF"
    end)

    -- Count live update
    task.spawn(function()
        while sg and sg.Parent do
            task.wait(0.8)
            pcall(function() cntTxt.Text = tostring(stateRef.count) end)
        end
    end)
end

-- Status label
local totalRows = #ROWS
local STATUS_Y  = ROW_Y_START + totalRows * (ROW_H + ROW_GAP) + 4

local statusLbl = Instance.new("TextLabel")
statusLbl.Size               = UDim2.new(1, -16, 0, 18)
statusLbl.Position           = UDim2.new(0, 8, 0, STATUS_Y)
statusLbl.BackgroundTransparency = 1
statusLbl.Text               = "Idle  --  Press START HUNTING"
statusLbl.TextColor3         = Color3.fromRGB(150, 140, 175)
statusLbl.TextSize           = 11
statusLbl.Font               = Enum.Font.Gotham
statusLbl.Parent             = fr

-- START / STOP button
local BTN_Y = STATUS_Y + 22

local startBtn = Instance.new("TextButton")
startBtn.Size             = UDim2.new(1, -16, 0, 42)
startBtn.Position         = UDim2.new(0, 8, 0, BTN_Y)
startBtn.BackgroundColor3 = Color3.fromRGB(90, 30, 200)
startBtn.Text             = "START HUNTING"
startBtn.TextColor3       = Color3.fromRGB(255, 255, 255)
startBtn.TextSize         = 15
startBtn.Font             = Enum.Font.GothamBold
startBtn.BorderSizePixel  = 0
startBtn.Parent           = fr
Instance.new("UICorner", startBtn).CornerRadius = UDim.new(0, 10)

local btnGrad = Instance.new("UIGradient")
btnGrad.Color = ColorSequence.new({
    ColorSequenceKeypoint.new(0, Color3.fromRGB(155, 65, 255)),
    ColorSequenceKeypoint.new(1, Color3.fromRGB(75,  25, 195)),
})
btnGrad.Rotation = 90
btnGrad.Parent = startBtn

-- Fix frame + shadow height
local TOTAL_H = BTN_Y + 54
fr.Size     = UDim2.new(0, 265, 0, TOTAL_H)
shadow.Size = UDim2.new(0, 268, 0, TOTAL_H)

-- ══════════════════════════════════════════════════
-- START / STOP LOGIC
-- ══════════════════════════════════════════════════
local function startHunting()
    if state.running then return end
    state.running = true
    statusLbl.Text       = "Hunting... RNG Part 2!"
    statusLbl.TextColor3 = Color3.fromRGB(65, 220, 95)
    startBtn.Text        = "STOP HUNTING"
    btnGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(210, 45, 45)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(150, 15, 15)),
    })
    spawnAllLoops()
end

local function stopHunting()
    state.running = false
    statusLbl.Text       = "Stopped."
    statusLbl.TextColor3 = Color3.fromRGB(220, 70, 70)
    startBtn.Text        = "START HUNTING"
    btnGrad.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(155, 65, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(75,  25, 195)),
    })
end

startBtn.MouseButton1Click:Connect(function()
    if state.running then stopHunting() else startHunting() end
end)

-- ══════════════════════════════════════════════════
-- RESPAWN HANDLER
-- ══════════════════════════════════════════════════
LocalPlayer.CharacterAdded:Connect(function()
    if state.running then
        task.wait(2)
        spawnAllLoops()
        statusLbl.Text       = "Respawned  --  Resumed!"
        statusLbl.TextColor3 = Color3.fromRGB(255, 200, 55)
        task.wait(2)
        if state.running then
            statusLbl.Text       = "Hunting... RNG Part 2!"
            statusLbl.TextColor3 = Color3.fromRGB(65, 220, 95)
        end
    end
end)

-- ══════════════════════════════════════════════════
-- BOOT
-- ══════════════════════════════════════════════════
statusLbl.Text       = "v3.1 loaded  --  Scanning remotes..."
statusLbl.TextColor3 = Color3.fromRGB(80, 255, 150)
task.wait(3)
if state.running == false then
    statusLbl.Text       = "Idle  --  Press START HUNTING"
    statusLbl.TextColor3 = Color3.fromRGB(150, 140, 175)
end

print("[LuckyHunter v3.1] Loaded! GUI -> " .. tostring(GUI_PARENT))
