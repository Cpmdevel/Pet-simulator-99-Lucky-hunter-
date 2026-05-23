--[[
╔══════════════════════════════════════════════════════════════════════╗
║  LUCKY HUNTER  v7.0  —  FINAL WORKING EDITION                       ║
║  Pet Simulator 99  |  RNG Event 2026                                ║
║  FIX: ClickDetector Roll, GUI Button click, VirtualClick            ║
║       Auto Roll + Auto Hatch BOTH working                           ║
║  Works: Delta, Solara, Wave, Xeno, Fluxus, Arceus X                ║
╚══════════════════════════════════════════════════════════════════════╝
--]]

-- ══════════════════════════════════════════════
-- 1. CLEANUP + SERVICES
-- ══════════════════════════════════════════════
local LP   = game:GetService("Players").LocalPlayer
local RS   = game:GetService("ReplicatedStorage")
local VIS  = game:GetService("VirtualInputService")
local UIS  = game:GetService("UserInputService")

local function killOld(n)
    pcall(function() game:GetService("CoreGui"):FindFirstChild(n):Destroy() end)
    pcall(function() LP:WaitForChild("PlayerGui",3):FindFirstChild(n):Destroy() end)
end
killOld("LH_v7")

local GUI_PARENT
pcall(function() GUI_PARENT = game:GetService("CoreGui") end)
if not GUI_PARENT then GUI_PARENT = LP:WaitForChild("PlayerGui",10) end

-- ══════════════════════════════════════════════
-- 2. REMOTE CACHE
-- ══════════════════════════════════════════════
local RC = {}
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
    task.wait(1.5); rebuildCache()
    while true do task.wait(8); rebuildCache() end
end)

local function fireAny(kwList, a1, a2)
    for _, kw in ipairs(kwList) do
        local r = RC[kw:lower()]
        if r then
            local ok = pcall(function()
                if r:IsA("RemoteEvent") then
                    if a2~=nil then r:FireServer(a1,a2)
                    elseif a1~=nil then r:FireServer(a1)
                    else r:FireServer() end
                else
                    if a2~=nil then r:InvokeServer(a1,a2)
                    elseif a1~=nil then r:InvokeServer(a1)
                    else r:InvokeServer() end
                end
            end)
            if ok then return true, r.Name end
        end
    end
    return false, nil
end

-- ══════════════════════════════════════════════
-- 3. CLICK ENGINE
-- PS99 uses ClickDetector + GuiButton + ProximityPrompt
-- We try ALL three methods on every object
-- ══════════════════════════════════════════════
local function clickObject(obj)
    if not obj then return false end
    local fired = false

    -- Collect all parts including descendants
    local parts = {}
    pcall(function()
        if obj:IsA("BasePart") then
            parts[#parts+1] = obj
        end
        for _, d in ipairs(obj:GetDescendants()) do
            if d:IsA("BasePart") then parts[#parts+1] = d end
        end
    end)

    for _, part in ipairs(parts) do
        -- Method A: ClickDetector
        local cd
        pcall(function() cd = part:FindFirstChildOfClass("ClickDetector") end)
        if cd then
            pcall(function() fireclickdetector(cd) end)
            pcall(function()
                local evt = cd.MouseClick
                if evt then evt:Fire(LP) end
            end)
            fired = true
        end

        -- Method B: ProximityPrompt
        local pp
        pcall(function() pp = part:FindFirstChildOfClass("ProximityPrompt") end)
        if pp then
            pcall(function() fireproximityprompt(pp) end)
            fired = true
        end

        -- Method C: VirtualClick at part's screen position
        pcall(function()
            local cam = workspace.CurrentCamera
            if cam then
                local pos, onScreen = cam:WorldToScreenPoint(part.Position)
                if onScreen then
                    local v2 = Vector2.new(pos.X, pos.Y)
                    VIS:SendMouseButtonEvent(v2.X, v2.Y, 0, true, game, 0)
                    task.wait(0.02)
                    VIS:SendMouseButtonEvent(v2.X, v2.Y, 0, false, game, 0)
                end
            end
        end)
    end

    return fired
end

-- Click a GuiButton by name search (for Roll button in game UI)
local function clickGuiButton(keywords)
    local fired = false
    local function searchGui(parent)
        if not parent then return end
        pcall(function()
            for _, child in ipairs(parent:GetChildren()) do
                if child:IsA("GuiButton") or child:IsA("TextButton") or child:IsA("ImageButton") then
                    local low = child.Name:lower()
                    for _, kw in ipairs(keywords) do
                        if low:find(kw:lower(), 1, true) then
                            pcall(function() child.MouseButton1Click:Fire() end)
                            pcall(function()
                                local pos = child.AbsolutePosition
                                local sz  = child.AbsoluteSize
                                local cx  = pos.X + sz.X/2
                                local cy  = pos.Y + sz.Y/2
                                VIS:SendMouseButtonEvent(cx, cy, 0, true, game, 0)
                                task.wait(0.02)
                                VIS:SendMouseButtonEvent(cx, cy, 0, false, game, 0)
                            end)
                            fired = true
                            return
                        end
                    end
                end
                searchGui(child)
            end
        end)
    end
    -- Search PlayerGui
    pcall(function() searchGui(LP.PlayerGui) end)
    -- Search CoreGui
    pcall(function() searchGui(game:GetService("CoreGui")) end)
    return fired
end

-- ProximityPrompt trigger (standalone)
local function triggerPrompt(obj)
    if not obj then return false end
    local fired = false
    local list = {obj}
    pcall(function()
        for _, d in ipairs(obj:GetDescendants()) do list[#list+1]=d end
    end)
    for _, p in ipairs(list) do
        local pp
        pcall(function() pp = p:FindFirstChildOfClass("ProximityPrompt") end)
        if pp then
            pcall(function() fireproximityprompt(pp) end)
            fired = true
        end
    end
    return fired
end

-- ══════════════════════════════════════════════
-- 4. CONFIG
-- ══════════════════════════════════════════════
local CFG = {
    rollDelay  = 0.12,
    hatchDelay = 0.80,
    chestDelay = 0.09,
    boostDelay = 18,
    giftDelay  = 3,
    questDelay = 5,
    afkDelay   = 50,
    tpEnabled  = true,
    tpUp       = Vector3.new(0, 3.5, 0),
    speedMult  = 1.0,

    -- Remote keyword lists
    rollR  = {"Roll","RollDice","DoRoll","StartRoll","UseRoll","EventRoll",
               "RollEvent","RNGRoll","RollRNG","LuckyRoll","DiceRoll",
               "SpinRNG","RNGSpin","Spin","SpinWheel","RollAction",
               "ActivateRoll","RequestRoll","TriggerRoll","PerformRoll",
               "RollRequest","GameRoll","RollServer","ServerRoll",
               "RNGRoll","AutoRoll","QuickRoll","InstantRoll"},

    hatchR = {"HatchEgg","HatchPet","OpenEgg","EggHatch","HatchRequest",
               "HatchEventEgg","RNG_Hatch","HatchRNG","AutoHatch","EggOpen",
               "HatchBaby","HatchNow","RequestHatch","DoHatch","StartHatch",
               "HatchAction","ServerHatch","EggHatchRequest","HatchEggEvent",
               "HatchInstant","QuickHatch","FastHatch"},

    chestR = {"ClickToCollect","CollectBlock","ClaimBlock","Interact",
               "TouchPart","ClickBlock","CollectLucky","OpenChest","ClaimChest",
               "CollectChest","OpenLucky","LuckyChest","ChestClaim","BlockClaim",
               "CollectItem","PickupItem","ClaimItem"},

    boostR = {"UseItem","ActivateBoost","UseBoost","ActivateItem",
               "UseLucky","LuckyBoost","BoostActivate","ItemUse","UseCharm"},

    giftR  = {"OpenGift","OpenBag","OpenCrate","UseGift","OpenReward",
               "GiftOpen","CrateOpen","BagOpen","ClaimReward","LootBox"},

    questR = {"ClaimQuest","CompleteQuest","QuestClaim","RewardClaim",
               "FinishQuest","QuestReward","DailyReward","EventQuest","ClaimDaily"},

    -- GUI button keywords to click (Roll button in game UI)
    rollGuiKW  = {"roll","autoroll","auto roll","rng","dice","spin","lucky"},
    hatchGuiKW = {"hatch","egg","incubat","open egg"},

    -- Workspace object names
    rollObjs  = {"RNGMachine","SpinMachine","DiceMachine","RollMachine","EventMachine",
                 "RNGWheel","SpinWheel","DiceWheel","LuckyWheel","RollWheel",
                 "RollNPC","DiceNPC","SpinNPC","RNGStation","RollStation",
                 "EventStation","DicePad","RollPad","RNGPad","LuckyStation",
                 "RollObject","SpinObject","RNGObject","DiceObject"},

    eggObjs   = {"RNG_Egg","RNGEgg","EventEgg","LuckyEgg","TitanicEgg","HugeEgg",
                 "GoldenEgg","MythicalEgg","ArcaneEgg","Egg","EggModel",
                 "HatchStation","EggStation","EggBase","EggPad"},

    chestObjs = {"LuckyBlock","LuckyChest","GoldenChest","RNGBlock","EventBlock",
                 "MagicBlock","DiceChest","Lucky","Chest","Block","RNGChest"},

    questObjs = {"QuestBoard","QuestNPC","EventNPC","DailyQuest",
                 "QuestGiver","RewardNPC","EventBoard","MissionNPC"},

    boostKW   = {"Lucky","Boost","RNG","Charm","Fortune","Dice","Roll","Event"},
    giftKW    = {"Gift","Bag","Crate","Box","Reward","Prize"},
}

-- ══════════════════════════════════════════════
-- 5. STATE
-- ══════════════════════════════════════════════
local S = {
    running = false,
    roll    = {on=true,  count=0, last="none"},
    hatch   = {on=true,  count=0, last="none"},
    chest   = {on=true,  count=0, last="none"},
    boost   = {on=true,  count=0, last="none"},
    gift    = {on=false, count=0, last="none"},
    quest   = {on=true,  count=0, last="none"},
}
local sessionStart = 0
local totalActions = 0

-- ══════════════════════════════════════════════
-- 6. HELPERS
-- ══════════════════════════════════════════════
local function hrp()
    local c = LP.Character
    return c and c:FindFirstChild("HumanoidRootPart")
end

local function tp(pos)
    if not CFG.tpEnabled then return end
    pcall(function()
        local h = hrp()
        if h and pos then h.CFrame = CFrame.new(pos + CFG.tpUp) end
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
    local h = hrp()
    if not h then return nil end
    local hp2 = h.Position
    local ok, desc = pcall(function() return workspace:GetDescendants() end)
    if not ok then return nil end
    for _, o in ipairs(desc) do
        if o:IsA("BasePart") or o:IsA("Model") then
            local p = getPos(o)
            if p then
                local low = o.Name:lower()
                for _, n in ipairs(names) do
                    if low:find(n:lower(),1,true) then
                        local d=(p-hp2).Magnitude
                        if d<bd then bd=d; best=o end
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
                if low:find(kw:lower(),1,true) then out[#out+1]=it; break end
            end
        end
    end)
    return out
end

local function delayFor(base)
    return math.max(0.05, base / CFG.speedMult)
end

-- ══════════════════════════════════════════════
-- 7. LOOPS
-- ══════════════════════════════════════════════

-- AUTO ROLL — tries 4 methods
local function loopRoll()
    while S.running do
        task.wait(delayFor(CFG.rollDelay))
        if S.roll.on then
            local success = false
            local usedName = "none"

            -- Method 1: Find Roll object in workspace, click it
            local o = nearest(CFG.rollObjs, 80)
            if o then
                local p = getPos(o)
                if p then tp(p); task.wait(0.06) end
                if clickObject(o) then
                    success = true; usedName = "ClickDetector"
                end
            end

            -- Method 2: Click Roll button in game GUI
            if not success then
                if clickGuiButton(CFG.rollGuiKW) then
                    success = true; usedName = "GuiButton"
                end
            end

            -- Method 3: Fire remote
            if not success then
                local ok, name = fireAny(CFG.rollR)
                if ok then success=true; usedName=name or "Remote" end
            end

            -- Method 4: ProximityPrompt on nearest
            if not success and o then
                if triggerPrompt(o) then
                    success=true; usedName="ProxPrompt"
                end
            end

            if success then
                S.roll.count = S.roll.count + 1
                S.roll.last  = usedName
                totalActions = totalActions + 1
            end
        end
    end
end

-- AUTO HATCH — tries 3 methods
local function loopHatch()
    while S.running do
        task.wait(delayFor(CFG.hatchDelay))
        if S.hatch.on then
            local success = false
            local usedName = "none"

            local o = nearest(CFG.eggObjs, 100)
            if o then
                local p = getPos(o)
                if p then tp(p); task.wait(0.15) end

                -- Method 1: ClickDetector
                if clickObject(o) then
                    success=true; usedName="ClickDetector"
                end

                -- Method 2: Remote (multiple arg combos)
                if not success then
                    local ok, name = fireAny(CFG.hatchR, o, "Instant")
                    if not ok then ok, name = fireAny(CFG.hatchR, o) end
                    if not ok then ok, name = fireAny(CFG.hatchR) end
                    if ok then success=true; usedName=name or "Remote" end
                end

                -- Method 3: ProximityPrompt
                if not success then
                    if triggerPrompt(o) then success=true; usedName="ProxPrompt" end
                end

                -- Method 4: GUI button
                if not success then
                    if clickGuiButton(CFG.hatchGuiKW) then
                        success=true; usedName="GuiButton"
                    end
                end
            end

            if success then
                S.hatch.count = S.hatch.count + 1
                S.hatch.last  = usedName
                totalActions  = totalActions + 1
            end
        end
    end
end

-- AUTO CHEST
local function loopChest()
    while S.running do
        task.wait(delayFor(CFG.chestDelay))
        if S.chest.on then
            local o = nearest(CFG.chestObjs)
            if o then
                local p = getPos(o)
                if p then tp(p); task.wait(0.04) end
                clickObject(o)
                local ok, name = fireAny(CFG.chestR, o)
                if ok then
                    S.chest.count=S.chest.count+1
                    S.chest.last=name or "?"
                    totalActions=totalActions+1
                end
            end
        end
    end
end

-- AUTO BOOST
local function loopBoost()
    while S.running do
        task.wait(delayFor(CFG.boostDelay))
        if S.boost.on then
            for _, it in ipairs(backpackItems(CFG.boostKW)) do
                local ok, name = fireAny(CFG.boostR, it)
                if ok then
                    S.boost.count=S.boost.count+1
                    S.boost.last=name or "?"
                    totalActions=totalActions+1
                end
                task.wait(0.1)
            end
        end
    end
end

-- AUTO GIFT
local function loopGift()
    while S.running do
        task.wait(delayFor(CFG.giftDelay))
        if S.gift.on then
            for _, it in ipairs(backpackItems(CFG.giftKW)) do
                local ok, name = fireAny(CFG.giftR, it)
                if ok then
                    S.gift.count=S.gift.count+1
                    S.gift.last=name or "?"
                    totalActions=totalActions+1
                end
                task.wait(0.1)
            end
        end
    end
end

-- AUTO QUEST
local function loopQuest()
    while S.running do
        task.wait(delayFor(CFG.questDelay))
        if S.quest.on then
            local o = nearest(CFG.questObjs)
            if o then
                local p = getPos(o)
                if p then tp(p); task.wait(0.3) end
                clickObject(o); triggerPrompt(o)
            end
            local ok, name = fireAny(CFG.questR)
            if ok then
                S.quest.count=S.quest.count+1
                S.quest.last=name or "?"
                totalActions=totalActions+1
            end
        end
    end
end

-- ANTI-AFK
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

-- ══════════════════════════════════════════════
-- 8. GUI — 4 Tab Full Menu
-- ══════════════════════════════════════════════
local W       = 300
local H_TB    = 46   -- title bar
local H_TAB   = 30   -- tab bar
local H_BODY  = 312  -- body
local H_TOTAL = H_TB + H_TAB + H_BODY

local C = {
    bg     = Color3.fromRGB(10, 7, 18),
    card   = Color3.fromRGB(18, 12, 30),
    acc    = Color3.fromRGB(110, 40, 230),
    acc2   = Color3.fromRGB(185, 75, 255),
    green  = Color3.fromRGB(25, 175, 68),
    red    = Color3.fromRGB(155, 28, 28),
    text   = Color3.fromRGB(228, 218, 245),
    sub    = Color3.fromRGB(148, 132, 175),
    gold   = Color3.fromRGB(255, 215, 0),
    cyan   = Color3.fromRGB(0, 215, 255),
    orange = Color3.fromRGB(255, 140, 0),
    purple = Color3.fromRGB(190, 90, 255),
    teal   = Color3.fromRGB(55, 225, 148),
}

local sg = Instance.new("ScreenGui")
sg.Name="LH_v7"; sg.ResetOnSpawn=false
sg.DisplayOrder=9999; sg.IgnoreGuiInset=true
sg.Parent=GUI_PARENT

-- Shadow
local sdw=Instance.new("Frame")
sdw.Size=UDim2.new(0,W+4,0,H_TOTAL+4)
sdw.Position=UDim2.new(0,12,0,12)
sdw.BackgroundColor3=Color3.new(0,0,0)
sdw.BackgroundTransparency=0.55
sdw.BorderSizePixel=0; sdw.ZIndex=1; sdw.Parent=sg
Instance.new("UICorner",sdw).CornerRadius=UDim.new(0,14)

-- Main frame
local mf=Instance.new("Frame")
mf.Name="MF"; mf.Size=UDim2.new(0,W,0,H_TOTAL)
mf.Position=UDim2.new(0,10,0,10)
mf.BackgroundColor3=C.bg; mf.BorderSizePixel=0
mf.Active=true; mf.Draggable=true; mf.ZIndex=2; mf.Parent=sg
Instance.new("UICorner",mf).CornerRadius=UDim.new(0,14)
local mfS=Instance.new("UIStroke")
mfS.Color=C.acc; mfS.Thickness=2.2; mfS.Transparency=0.08; mfS.Parent=mf

-- ── Title bar ──
local tb=Instance.new("Frame")
tb.Size=UDim2.new(1,0,0,H_TB); tb.BackgroundColor3=C.acc
tb.BorderSizePixel=0; tb.ZIndex=3; tb.Parent=mf
Instance.new("UICorner",tb).CornerRadius=UDim.new(0,14)
local tbG=Instance.new("UIGradient")
tbG.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(205,85,255)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(58,14,158)),
}); tbG.Rotation=90; tbG.Parent=tb

local function mkLbl(par,txt,x,y,w,h,sz,col,xa,bold,zi)
    local l=Instance.new("TextLabel")
    l.Size=UDim2.new(0,w,0,h); l.Position=UDim2.new(0,x,0,y)
    l.BackgroundTransparency=1; l.Text=txt
    l.TextColor3=col or C.text; l.TextSize=sz or 11
    l.Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham
    l.TextXAlignment=xa or Enum.TextXAlignment.Left
    l.ZIndex=zi or 4; l.Parent=par
    return l
end

mkLbl(tb,"LUCKY HUNTER  v7.0",14,0,200,H_TB,14,Color3.new(1,1,1),Enum.TextXAlignment.Left,true,4)
mkLbl(tb,"RNG Event 2026  |  Full Menu  |  All Executors",14,H_TB-16,260,14,9,
    Color3.fromRGB(210,180,255),Enum.TextXAlignment.Left,false,4)

-- Minimize button
local minBtn=Instance.new("TextButton")
minBtn.Size=UDim2.new(0,28,0,28); minBtn.Position=UDim2.new(1,-34,0.5,-14)
minBtn.BackgroundColor3=Color3.new(1,1,1); minBtn.BackgroundTransparency=0.82
minBtn.Text="-"; minBtn.TextColor3=Color3.new(1,1,1); minBtn.TextSize=18
minBtn.Font=Enum.Font.GothamBold; minBtn.BorderSizePixel=0
minBtn.ZIndex=5; minBtn.Parent=tb
Instance.new("UICorner",minBtn).CornerRadius=UDim.new(0,6)

-- ── Tab bar ──
local tabBar=Instance.new("Frame")
tabBar.Size=UDim2.new(1,0,0,H_TAB); tabBar.Position=UDim2.new(0,0,0,H_TB)
tabBar.BackgroundColor3=Color3.fromRGB(14,9,24)
tabBar.BorderSizePixel=0; tabBar.ZIndex=3; tabBar.Parent=mf

local TABS={"HOME","SETTINGS","STATS","HELP"}
local tabBtns={}; local tabPages={}; local activeTab="HOME"
local TW=W/#TABS

for i,name in ipairs(TABS) do
    local btn=Instance.new("TextButton")
    btn.Size=UDim2.new(0,TW-2,0,H_TAB-4)
    btn.Position=UDim2.new(0,(i-1)*TW+1,0,2)
    btn.BackgroundColor3=(name=="HOME") and C.acc or Color3.fromRGB(22,15,36)
    btn.Text=name; btn.TextColor3=Color3.new(1,1,1)
    btn.TextSize=10; btn.Font=Enum.Font.GothamBold
    btn.BorderSizePixel=0; btn.ZIndex=4; btn.Parent=tabBar
    Instance.new("UICorner",btn).CornerRadius=UDim.new(0,5)
    tabBtns[name]=btn

    local pg=Instance.new("ScrollingFrame")
    pg.Size=UDim2.new(1,0,0,H_BODY)
    pg.Position=UDim2.new(0,0,0,H_TB+H_TAB)
    pg.BackgroundTransparency=1; pg.BorderSizePixel=0
    pg.ScrollBarThickness=3; pg.ScrollBarImageColor3=C.acc
    pg.CanvasSize=UDim2.new(0,0,0,0)
    pg.Visible=(name=="HOME"); pg.ZIndex=3; pg.Parent=mf
    tabPages[name]=pg
end

local function switchTab(name)
    activeTab=name
    for n,pg in pairs(tabPages) do pg.Visible=(n==name) end
    for n,btn in pairs(tabBtns) do
        btn.BackgroundColor3=(n==name) and C.acc or Color3.fromRGB(22,15,36)
    end
end
for name,btn in pairs(tabBtns) do
    btn.MouseButton1Click:Connect(function() switchTab(name) end)
end

-- ── UI helpers ──
local function card(par,y,h)
    local f=Instance.new("Frame")
    f.Size=UDim2.new(1,-16,0,h); f.Position=UDim2.new(0,8,0,y)
    f.BackgroundColor3=C.card; f.BorderSizePixel=0; f.ZIndex=4; f.Parent=par
    Instance.new("UICorner",f).CornerRadius=UDim.new(0,9)
    return f
end

local function mkToggle(par,sr,x,y)
    local b=Instance.new("TextButton")
    b.Size=UDim2.new(0,50,0,24); b.Position=UDim2.new(0,x,0,y)
    b.BackgroundColor3=sr.on and C.green or C.red
    b.Text=sr.on and "ON" or "OFF"
    b.TextColor3=Color3.new(1,1,1); b.TextSize=11
    b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; b.ZIndex=5; b.Parent=par
    Instance.new("UICorner",b).CornerRadius=UDim.new(0,6)
    b.MouseButton1Click:Connect(function()
        sr.on=not sr.on
        b.BackgroundColor3=sr.on and C.green or C.red
        b.Text=sr.on and "ON" or "OFF"
    end)
    return b
end

-- ══════════════════════
-- HOME TAB
-- ══════════════════════
local hp=tabPages["HOME"]
local curY=6

-- Remote scan status
local rcCard=card(hp,curY,24); curY=curY+28
local rcTxt=mkLbl(rcCard,"Scanning remotes...",8,0,268,24,9,C.gold,Enum.TextXAlignment.Left,true,5)
task.spawn(function()
    while sg and sg.Parent do
        task.wait(2)
        pcall(function()
            local n=0; for _ in pairs(RC) do n=n+1 end
            local cats={CFG.rollR,CFG.hatchR,CFG.chestR,CFG.boostR,CFG.giftR,CFG.questR}
            local m=0
            for _,lst in ipairs(cats) do
                for _,kw in ipairs(lst) do
                    if RC[kw:lower()] then m=m+1; break end
                end
            end
            local col=m>=3 and C.teal or (m>0 and C.gold or Color3.fromRGB(230,55,55))
            rcTxt.Text="RS: "..n.." remotes  |  Matched: "..m.."/6  (auto-scan every 8s)"
            rcTxt.TextColor3=col
        end)
    end
end)

-- Feature rows
local ROWS={
    {key="roll",  lbl="Auto Roll  (RNG)",    col=C.gold,   icon="ROLL"},
    {key="hatch", lbl="Auto Hatch RNG Egg",  col=C.cyan,   icon="EGG"},
    {key="chest", lbl="Auto Chest / Block",  col=Color3.fromRGB(80,200,255), icon="BOX"},
    {key="boost", lbl="Auto Boost / Charm",  col=C.orange, icon="PWR"},
    {key="gift",  lbl="Auto Gift / Crate",   col=C.purple, icon="GIFT"},
    {key="quest", lbl="Auto Quest Claim",    col=C.teal,   icon="QST"},
}
local RH,RG=34,3

for _,def in ipairs(ROWS) do
    local sr=S[def.key]
    local rf=card(hp,curY,RH); curY=curY+RH+RG

    -- Accent bar
    local acc=Instance.new("Frame")
    acc.Size=UDim2.new(0,3,1,-8); acc.Position=UDim2.new(0,4,0,4)
    acc.BackgroundColor3=def.col; acc.BorderSizePixel=0; acc.ZIndex=5; acc.Parent=rf
    Instance.new("UICorner",acc).CornerRadius=UDim.new(0,2)

    -- Icon badge
    local ib=Instance.new("Frame")
    ib.Size=UDim2.new(0,34,0,20); ib.Position=UDim2.new(0,11,0.5,-10)
    ib.BackgroundColor3=def.col; ib.BackgroundTransparency=0.35
    ib.BorderSizePixel=0; ib.ZIndex=5; ib.Parent=rf
    Instance.new("UICorner",ib).CornerRadius=UDim.new(0,4)
    mkLbl(ib,def.icon,0,0,34,20,8,Color3.new(1,1,1),Enum.TextXAlignment.Center,true,6)

    -- Count
    local cntL=mkLbl(rf,"0",50,0,30,RH,13,def.col,Enum.TextXAlignment.Left,true,5)

    -- Method label (shows what worked)
    local methL=mkLbl(rf,"none",82,RH-13,100,12,8,C.sub,Enum.TextXAlignment.Left,false,5)

    -- Name
    mkLbl(rf,def.lbl,82,0,120,RH-14,11,C.text,Enum.TextXAlignment.Left,true,5)

    -- Toggle
    mkToggle(rf,sr,232,5)

    -- Row stroke
    local rs=Instance.new("UIStroke")
    rs.Color=def.col; rs.Thickness=1; rs.Transparency=0.55; rs.Parent=rf

    -- Live update
    task.spawn(function()
        while sg and sg.Parent do
            task.wait(0.9)
            pcall(function()
                cntL.Text=tostring(sr.count)
                methL.Text="via: "..(sr.last or "none")
            end)
        end
    end)
end

-- Status
local stCard=card(hp,curY,20); curY=curY+24
local stLbl=mkLbl(stCard,"Idle  --  Press START",6,0,270,20,11,C.sub,Enum.TextXAlignment.Left,false,5)

-- START/STOP
local sBtn=Instance.new("TextButton")
sBtn.Size=UDim2.new(1,-16,0,44); sBtn.Position=UDim2.new(0,8,0,curY)
sBtn.BackgroundColor3=C.acc; sBtn.Text="START HUNTING"
sBtn.TextColor3=Color3.new(1,1,1); sBtn.TextSize=15
sBtn.Font=Enum.Font.GothamBold; sBtn.BorderSizePixel=0; sBtn.ZIndex=4; sBtn.Parent=hp
Instance.new("UICorner",sBtn).CornerRadius=UDim.new(0,10)
local sBG=Instance.new("UIGradient")
sBG.Color=ColorSequence.new({
    ColorSequenceKeypoint.new(0,Color3.fromRGB(155,62,255)),
    ColorSequenceKeypoint.new(1,Color3.fromRGB(70,20,192)),
}); sBG.Rotation=90; sBG.Parent=sBtn
curY=curY+52
hp.CanvasSize=UDim2.new(0,0,0,curY)

-- ══════════════════════
-- SETTINGS TAB
-- ══════════════════════
local sp=tabPages["SETTINGS"]
local sy=8
mkLbl(sp,"DELAY SETTINGS  (seconds)",14,sy,260,14,11,C.gold,Enum.TextXAlignment.Left,true,4)
sy=sy+20

local function settingRow(par,y,lbl,key,minV,maxV,step)
    local c=card(par,y,34)
    mkLbl(c,lbl,10,0,155,34,11,C.text,Enum.TextXAlignment.Left,false,5)
    local function mkBtn(txt,px)
        local b=Instance.new("TextButton")
        b.Size=UDim2.new(0,26,0,24); b.Position=UDim2.new(0,px,0.5,-12)
        b.BackgroundColor3=Color3.fromRGB(45,25,75); b.Text=txt
        b.TextColor3=Color3.new(1,1,1); b.TextSize=15
        b.Font=Enum.Font.GothamBold; b.BorderSizePixel=0; b.ZIndex=5; b.Parent=c
        Instance.new("UICorner",b).CornerRadius=UDim.new(0,5)
        return b
    end
    local mB=mkBtn("-",166)
    local vL=mkLbl(c,tostring(CFG[key]),194,0,46,34,11,C.acc2,Enum.TextXAlignment.Center,true,5)
    local pB=mkBtn("+",242)
    mB.MouseButton1Click:Connect(function()
        CFG[key]=math.max(minV,math.floor((CFG[key]-step)*100+0.5)/100)
        vL.Text=tostring(CFG[key])
    end)
    pB.MouseButton1Click:Connect(function()
        CFG[key]=math.min(maxV,math.floor((CFG[key]+step)*100+0.5)/100)
        vL.Text=tostring(CFG[key])
    end)
    return c
end

local settRows={
    {"Roll Delay",    "rollDelay",  0.05,5,0.05},
    {"Hatch Delay",   "hatchDelay", 0.2, 5,0.1},
    {"Chest Delay",   "chestDelay", 0.05,5,0.05},
    {"Boost Delay",   "boostDelay", 5,  60,1},
    {"Quest Delay",   "questDelay", 2,  30,1},
    {"Speed Mult x",  "speedMult",  0.5, 5,0.5},
}
for _,r in ipairs(settRows) do
    settingRow(sp,sy,r[1],r[2],r[3],r[4],r[5]); sy=sy+38
end

-- TP toggle
local tpCard=card(sp,sy,34); sy=sy+38
mkLbl(tpCard,"Teleport to Target",10,0,180,34,11,C.text,Enum.TextXAlignment.Left,false,5)
local tpSt={on=CFG.tpEnabled}
local tpEl=mkToggle(tpCard,tpSt,225,5)
tpEl.MouseButton1Click:Connect(function()
    task.wait(0.05); CFG.tpEnabled=tpSt.on
end)
sp.CanvasSize=UDim2.new(0,0,0,sy+8)

-- ══════════════════════
-- STATS TAB
-- ══════════════════════
local stp=tabPages["STATS"]
local sty=8
mkLbl(stp,"SESSION STATISTICS",14,sty,260,14,11,C.gold,Enum.TextXAlignment.Left,true,4)
sty=sty+20

local statDefs={
    {key="roll",  lbl="Rolls"},
    {key="hatch", lbl="Hatches"},
    {key="chest", lbl="Chests"},
    {key="boost", lbl="Boosts"},
    {key="gift",  lbl="Gifts"},
    {key="quest", lbl="Quests"},
}
local statEls={}
for _,def in ipairs(statDefs) do
    local c=card(stp,sty,30); sty=sty+34
    mkLbl(c,def.lbl,10,0,100,30,11,C.text,Enum.TextXAlignment.Left,false,5)
    local vl=mkLbl(c,"0",115,0,60,30,14,C.acc2,Enum.TextXAlignment.Left,true,5)
    local ll=mkLbl(c,"via: none",180,0,100,30,9,C.sub,Enum.TextXAlignment.Left,false,5)
    statEls[def.key]={v=vl,l=ll}
end

local tcCard=card(stp,sty,42); sty=sty+46
local totalL=mkLbl(tcCard,"Total Actions: 0",10,0,270,20,12,C.gold,Enum.TextXAlignment.Left,true,5)
local timeL=mkLbl(tcCard,"Session: paused",10,22,270,18,11,C.sub,Enum.TextXAlignment.Left,false,5)

local rstBtn=Instance.new("TextButton")
rstBtn.Size=UDim2.new(1,-16,0,30); rstBtn.Position=UDim2.new(0,8,0,sty)
rstBtn.BackgroundColor3=Color3.fromRGB(38,18,65); rstBtn.Text="RESET STATS"
rstBtn.TextColor3=Color3.fromRGB(200,180,255); rstBtn.TextSize=12
rstBtn.Font=Enum.Font.GothamBold; rstBtn.BorderSizePixel=0; rstBtn.ZIndex=4; rstBtn.Parent=stp
Instance.new("UICorner",rstBtn).CornerRadius=UDim.new(0,8)
sty=sty+38
rstBtn.MouseButton1Click:Connect(function()
    for _,sr in pairs(S) do
        if type(sr)=="table" and sr.count then sr.count=0; sr.last="none" end
    end
    totalActions=0; sessionStart=os.time()
end)

task.spawn(function()
    while sg and sg.Parent do
        task.wait(1)
        pcall(function()
            for _,def in ipairs(statDefs) do
                local sr=S[def.key]; local el=statEls[def.key]
                if el then
                    el.v.Text=tostring(sr.count)
                    el.l.Text="via: "..(sr.last or "none")
                end
            end
            totalL.Text="Total Actions: "..totalActions
            local el=S.running and (os.time()-sessionStart) or 0
            timeL.Text=S.running
                and string.format("Session: %dm %ds",math.floor(el/60),el%60)
                or "Session: paused"
        end)
    end
end)
stp.CanvasSize=UDim2.new(0,0,0,sty+8)

-- ══════════════════════
-- HELP TAB
-- ══════════════════════
local helpP=tabPages["HELP"]
local hy=8
local helpLines={
    {"HOW TO USE",                    C.gold,   true},
    {"1. Execute script in executor",  C.text,   false},
    {"2. Wait ~3s for remote scan",    C.text,   false},
    {"3. Press START HUNTING",         C.text,   false},
    {"4. Roll/Hatch counts go up",     C.text,   false},
    {"",C.text,false},
    {"IF COUNT = 0 AFTER 30s",        C.gold,   true},
    {"Remotes not found yet.",         C.sub,    false},
    {"Roll uses 4 methods: Click,",    C.sub,    false},
    {"GuiBtn, Remote, ProxPrompt.",    C.sub,    false},
    {"Wait 10s and try again.",        C.sub,    false},
    {"",C.text,false},
    {"RNG EVENT 2026 TARGETS",         C.gold,   true},
    {"Titanic Arcane Void Cat",        C.cyan,   false},
    {"Titanic Arcane Halo Cat",        C.cyan,   false},
    {"Huge Nebula Lion",               C.purple, false},
    {"Huge Eclipse Owl",               C.purple, false},
    {"Huge Cataclysm Bear",            C.purple, false},
    {"Huge Oracle Tiger",              C.purple, false},
    {"Huge Prism Pegasus",             C.purple, false},
    {"Huge Anubis",                    C.purple, false},
    {"",C.text,false},
    {"EXECUTORS SUPPORTED",            C.gold,   true},
    {"Delta, Solara, Wave, Xeno",      C.teal,   false},
    {"Fluxus, Arceus X, Hydrogen",     C.teal,   false},
}
for _,ln in ipairs(helpLines) do
    if ln[1]=="" then hy=hy+5
    else
        local lh=16
        mkLbl(helpP,ln[1],14,hy,262,lh,ln[3] and 11 or 10,ln[2],Enum.TextXAlignment.Left,ln[3],4)
        hy=hy+lh+2
    end
end
helpP.CanvasSize=UDim2.new(0,0,0,hy+10)

-- ══════════════════════
-- MINIMIZE
-- ══════════════════════
local minimized=false
local bodyParts={tabBar}
for _,pg in pairs(tabPages) do bodyParts[#bodyParts+1]=pg end

minBtn.MouseButton1Click:Connect(function()
    minimized=not minimized
    for _,f in ipairs(bodyParts) do pcall(function() f.Visible=not minimized end) end
    if minimized then
        mf.Size=UDim2.new(0,W,0,H_TB)
        sdw.Size=UDim2.new(0,W+4,0,H_TB+4)
        minBtn.Text="+"
    else
        mf.Size=UDim2.new(0,W,0,H_TOTAL)
        sdw.Size=UDim2.new(0,W+4,0,H_TOTAL+4)
        minBtn.Text="-"
    end
end)

-- ══════════════════════
-- START / STOP
-- ══════════════════════
local function startH()
    if S.running then return end
    S.running=true; sessionStart=os.time()
    stLbl.Text="Hunting...  RNG Event 2026!"
    stLbl.TextColor3=C.teal
    sBtn.Text="STOP HUNTING"
    sBG.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(212,40,40)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(145,10,10)),
    })
    startLoops()
end

local function stopH()
    S.running=false
    stLbl.Text="Stopped."
    stLbl.TextColor3=Color3.fromRGB(218,62,62)
    sBtn.Text="START HUNTING"
    sBG.Color=ColorSequence.new({
        ColorSequenceKeypoint.new(0,Color3.fromRGB(155,62,255)),
        ColorSequenceKeypoint.new(1,Color3.fromRGB(70,20,192)),
    })
end

sBtn.MouseButton1Click:Connect(function()
    if S.running then stopH() else startH() end
end)

LP.CharacterAdded:Connect(function()
    if S.running then
        task.wait(2); startLoops()
        stLbl.Text="Respawned -- Resumed!"
        stLbl.TextColor3=Color3.fromRGB(255,198,52)
        task.wait(2)
        if S.running then
            stLbl.Text="Hunting...  RNG Event 2026!"
            stLbl.TextColor3=C.teal
        end
    end
end)

-- Boot
stLbl.Text="v7.0 loaded!  Scanning remotes..."
stLbl.TextColor3=Color3.fromRGB(72,255,142)
task.wait(3)
if not S.running then
    stLbl.Text="Idle  --  Press START"
    stLbl.TextColor3=C.sub
end
print("[LH v7.0] Ready | GUI: "..tostring(GUI_PARENT))
