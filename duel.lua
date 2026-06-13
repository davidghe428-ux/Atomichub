-- ============================================================
--  ATOMIC HUB - COMPLETE FRAMEWORK & FUNCTIONAL PANEL UI
-- ============================================================
repeat task.wait() until game and game:IsLoaded()

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UIS = game:GetService("UserInputService")
local TS = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")
local CoreGui = game:GetService("CoreGui")
local LP = Players.LocalPlayer

-- Cleanup old instances
pcall(function() CoreGui:FindFirstChild("CandyHub"):Destroy() end)
pcall(function() CoreGui:FindFirstChild("CandyHubMobileButtons"):Destroy() end)
pcall(function() CoreGui:FindFirstChild("AtomicHub"):Destroy() end)
pcall(function() CoreGui:FindFirstChild("AtomicHubMobileButtons"):Destroy() end)
pcall(function()
   local pg = LP:FindFirstChild("PlayerGui")
   if pg then
       pcall(function() pg:FindFirstChild("AtomicHub"):Destroy() end)
       pcall(function() pg:FindFirstChild("AtomicHubMobileButtons"):Destroy() end)
   end
end)

-- Colors Configuration (Toxic Neon Green & Core Cyber Cyan)
local ATOMIC_COLORS = {
    TOXIC = Color3.fromRGB(57, 255, 20),      -- Neon Green
    CORE = Color3.fromRGB(30, 241, 222),       -- Cyber Cyan
    INPUT = Color3.fromRGB(28, 28, 32),        -- Dark Slate
    TEXT_DARK = Color3.fromRGB(140, 140, 150),  -- Muted Gray
    BG = Color3.fromRGB(12, 12, 14), 
    PANEL = Color3.fromRGB(18, 18, 22), 
    CARD = Color3.fromRGB(24, 24, 28),
    TEXT = Color3.fromRGB(240,240,240), 
    STROKE = Color3.fromRGB(40, 44, 52)
}

local ACCENT = ATOMIC_COLORS.TOXIC
local ICE = ATOMIC_COLORS.CORE
local BG_BTN = ATOMIC_COLORS.INPUT
local TXT_C = ATOMIC_COLORS.TEXT_DARK

local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local GUI_W, GUI_H = IsMobile and 260 or 360, IsMobile and 300 or 400

-- ============================================================
--  GLOBAL STATE VARIABLES
-- ============================================================
NS = 60; CS = 30
LAGGER_SPEED = 15; LAGGER_CARRY_SPEED = 24.5
speedMode = false; laggerToggled = false
autoBatEnabled = false; autoSwingEnabled = true
autoLeftEnabled = false; autoRightEnabled = false
autoBatActive = false

-- Speed label setup
speedLabel = nil
function setupSpeedIndicator(char)
   local head = char:FindFirstChild("Head")
   if not head then return end
   local old = head:FindFirstChild("AtomicHubSpeedBB")
   if old then old:Destroy() end
   local bb = Instance.new("BillboardGui", head)
   bb.Name = "AtomicHubSpeedBB"
   bb.Size = UDim2.new(0, 190, 0, 54)
   bb.StudsOffset = Vector3.new(0, 3.35, 0)
   bb.AlwaysOnTop = true
   local tag = Instance.new("TextLabel", bb)
   tag.Size = UDim2.new(1,0,0,22); tag.Position = UDim2.new(0,0,0,0)
   tag.BackgroundTransparency = 1; tag.Text = "ATOMIC HUB"
   tag.TextColor3 = ATOMIC_COLORS.CORE; tag.Font = Enum.Font.GothamBlack
   tag.TextSize = 15; tag.TextXAlignment = Enum.TextXAlignment.Center
   local val = Instance.new("TextLabel", bb)
   val.Size = UDim2.new(1,0,0,26); val.Position = UDim2.new(0,0,0,24)
   val.BackgroundTransparency = 1; val.Text = "Speed: 0.0"
   val.TextColor3 = ATOMIC_COLORS.TOXIC; val.Font = Enum.Font.GothamBlack
   val.TextSize = 17; val.TextXAlignment = Enum.TextXAlignment.Center
   speedLabel = val
end
if LP.Character then setupSpeedIndicator(LP.Character) end
LP.CharacterAdded:Connect(setupSpeedIndicator)

function getActiveMoveSpeed()
   if laggerToggled and speedMode then return LAGGER_CARRY_SPEED
   elseif laggerToggled then return LAGGER_SPEED
   elseif speedMode then return CS else return NS end
end

-- Movement engine
lastMoveDir = Vector3.new(0,0,0)
MOVE_KEYS = {[Enum.KeyCode.W]=true,[Enum.KeyCode.A]=true,[Enum.KeyCode.S]=true,[Enum.KeyCode.D]=true,
   [Enum.KeyCode.Up]=true,[Enum.KeyCode.Left]=true,[Enum.KeyCode.Down]=true,[Enum.KeyCode.Right]=true}
function isRagdollState(hum)
   if not hum then return true end
   local st = hum:GetState()
   return hum.PlatformStand or st==Enum.HumanoidStateType.Physics or st==Enum.HumanoidStateType.Ragdoll or st==Enum.HumanoidStateType.FallingDown
end

RunService.RenderStepped:Connect(function()
   local char = LP.Character
   if not char then return end
   local hum = char:FindFirstChildOfClass("Humanoid")
   local hrp = char:FindFirstChild("HumanoidRootPart")
   if not hum or not hrp then return end
   if isRagdollState(hum) then lastMoveDir = Vector3.new(0,0,0); return end
   if not autoBatEnabled and not autoLeftEnabled and not autoRightEnabled then
       local md = hum.MoveDirection
       local spd = getActiveMoveSpeed()
       if md.Magnitude > 0 then
           lastMoveDir = md
           hrp.Velocity = Vector3.new(md.X*spd, hrp.Velocity.Y, md.Z*spd)
       end
   end
   if speedLabel then
       local actualSpeed = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z).Magnitude
       if actualSpeed < 0.05 then actualSpeed = 0 end
       speedLabel.Text = string.format("Speed: %.1f", actualSpeed)
   end
end)

-- Orbit System Paths
AP_L1, AP_L2 = Vector3.new(-476.47,-6.28,92.73), Vector3.new(-483.12,-4.95,94.81)
AP_R1, AP_R2 = Vector3.new(-476.16,-6.52,25.62), Vector3.new(-483.06,-5.03,25.48)
alConn, arConn = nil, nil
alPhase, arPhase = 1, 1

function stopAutoLeft()
   if alConn then alConn:Disconnect(); alConn = nil end
   alPhase = 1
   local char = LP.Character
   if char then local h = char:FindFirstChildOfClass("Humanoid"); if h then h:Move(Vector3.zero, false) end end
end
function stopAutoRight()
   if arConn then arConn:Disconnect(); arConn = nil end
   arPhase = 1
   local char = LP.Character
   if char then local h = char:FindFirstChildOfClass("Humanoid"); if h then h:Move(Vector3.zero, false) end end
end
function startAutoLeft()
   if alConn then alConn:Disconnect() end
   alPhase = 1
   alConn = RunService.Heartbeat:Connect(function()
       if not autoLeftEnabled then return end
       local char = LP.Character; if not char then return end
       local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChildOfClass("Humanoid")
       if not hrp or not hum then return end
       if isRagdollState(hum) then hum:Move(Vector3.zero, false); return end
       local spd = 60
       if alPhase == 1 then
           local tgt = Vector3.new(AP_L1.X, hrp.Position.Y, AP_L1.Z)
           if (tgt - hrp.Position).Magnitude < 1 then
               alPhase = 2
               return
           end
           local d = AP_L1 - hrp.Position
           local mv = Vector3.new(d.X, 0, d.Z).Unit
           hum:Move(mv, false)
           hrp.Velocity = Vector3.new(mv.X*spd, hrp.Velocity.Y, mv.Z*spd)
       elseif alPhase == 2 then
           local tgt = Vector3.new(AP_L2.X, hrp.Position.Y, AP_L2.Z)
           if (tgt - hrp.Position).Magnitude < 1 then
               hum:Move(Vector3.zero, false); hrp.Velocity = Vector3.zero
               autoLeftEnabled = false
               stopAutoLeft()
               return
           end
           local d = AP_L2 - hrp.Position
           local mv = Vector3.new(d.X, 0, d.Z).Unit
           hum:Move(mv, false)
           hrp.Velocity = Vector3.new(mv.X*spd, hrp.Velocity.Y, mv.Z*spd)
       end
   end)
end
function startAutoRight()
   if arConn then arConn:Disconnect() end
   arPhase = 1
   arConn = RunService.Heartbeat:Connect(function()
       if not autoRightEnabled then return end
       local char = LP.Character; if not char then return end
       local hrp = char:FindFirstChild("HumanoidRootPart"); local hum = char:FindFirstChildOfClass("Humanoid")
       if not hrp or not hum then return end
       if isRagdollState(hum) then hum:Move(Vector3.zero, false); return end
       local spd = 60
       if arPhase == 1 then
           local tgt = Vector3.new(AP_R1.X, hrp.Position.Y, AP_R1.Z)
           if (tgt - hrp.Position).Magnitude < 1 then
               arPhase = 2
               return
           end
           local d = AP_R1 - hrp.Position
           local mv = Vector3.new(d.X, 0, d.Z).Unit
           hum:Move(mv, false)
           hrp.Velocity = Vector3.new(mv.X*spd, hrp.Velocity.Y, mv.Z*spd)
       elseif arPhase == 2 then
           local tgt = Vector3.new(AP_R2.X, hrp.Position.Y, AP_R2.Z)
           if (tgt - hrp.Position).Magnitude < 1 then
               hum:Move(Vector3.zero, false); hrp.Velocity = Vector3.zero
               autoRightEnabled = false
               stopAutoRight()
               return
           end
           local d = AP_R2 - hrp.Position
           local mv = Vector3.new(d.X, 0, d.Z).Unit
           hum:Move(mv, false)
           hrp.Velocity = Vector3.new(mv.X*spd, hrp.Velocity.Y, mv.Z*spd)
       end
   end)
end

-- Mechanics Execution
function runDrop()
   local char = LP.Character
   local root = char and char:FindFirstChild("HumanoidRootPart")
   if root then
       root.Velocity = Vector3.new(0, 10000, 0)
       task.wait(0.1)
       root.Velocity = Vector3.zero
   end
end

function runTPFloor()
   local char = LP.Character
   local hrp = char and char:FindFirstChild("HumanoidRootPart")
   if hrp then
       hrp.CFrame = CFrame.new(hrp.Position.X, -7.00, hrp.Position.Z) * CFrame.Angles(0, select(2, hrp.CFrame:ToEulerAnglesYXZ()), 0)
       hrp.Velocity = Vector3.zero
   end
end

-- Target Engine
aimbotConn = nil
function findBat()
   local char = LP.Character
   if not char then return nil end
   for _,tool in ipairs(char:GetChildren()) do
       if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then return tool end
   end
   return nil
end
function getClosestTarget()
   local root = LP.Character and LP.Character:FindFirstChild("HumanoidRootPart")
   if not root then return nil end
   local closest, minDist = nil, math.huge
   for _,plr in ipairs(Players:GetPlayers()) do
       if plr ~= LP and plr.Character then
           local tRoot = plr.Character:FindFirstChild("HumanoidRootPart")
           local hum = plr.Character:FindFirstChildOfClass("Humanoid")
           if tRoot and hum and hum.Health > 0 then
               local dist = (tRoot.Position - root.Position).Magnitude
               if dist < minDist then minDist = dist; closest = tRoot end
           end
       end
   end
   return closest
end
function startBatAimbot()
   if aimbotConn then aimbotConn:Disconnect() end
   autoBatEnabled = true
   local hum0 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
   if hum0 then hum0.AutoRotate = false end
   aimbotConn = RunService.RenderStepped:Connect(function()
       if not autoBatEnabled then return end
       local char = LP.Character
       if not char then return end
       local root = char:FindFirstChild("HumanoidRootPart")
       local hum = char:FindFirstChildOfClass("Humanoid")
       if not root or not hum then return end
       local target = getClosestTarget()
       if not target then return end
       local direction = (target.Position + target.Velocity * 0.14) - root.Position
       local flatDir = Vector3.new(direction.X, 0, direction.Z).Unit
       root.Velocity = Vector3.new(flatDir.X * 58, (target.Position.Y + 3.7 - root.Position.Y) * 19.5, flatDir.Z * 58)
       local bat = findBat()
       if bat and bat.Parent == char then bat:Activate() end
   end)
end
function stopBatAimbot()
   if aimbotConn then aimbotConn:Disconnect(); aimbotConn = nil end
   autoBatEnabled = false
   local hum2 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
   if hum2 then hum2.AutoRotate = true end
end

-- ============================================================
--  MAIN UI PANEL GENERATOR
-- ============================================================
local mainFrame = nil
function buildMainPanel()
    local mainGui = Instance.new("ScreenGui")
    mainGui.Name = "AtomicHub"
    mainGui.ResetOnSpawn = false
    mainGui.Parent = CoreGui
    
    mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, GUI_W, 0, GUI_H)
    mainFrame.Position = UDim2.new(0.5, -GUI_W/2, 0.4, -GUI_H/2)
    mainFrame.BackgroundColor3 = ATOMIC_COLORS.BG
    mainFrame.BorderSizePixel = 0
    mainFrame.Parent = mainGui
    
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, 8)
    c.Parent = mainFrame
    
    local st = Instance.new("UIStroke")
    st.Color = ATOMIC_COLORS.STROKE
    st.Thickness = 1.5
    st.Parent = mainFrame

    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 40)
    header.BackgroundColor3 = ATOMIC_COLORS.PANEL
    header.BorderSizePixel = 0
    header.Parent = mainFrame
    
    local hc = Instance.new("UICorner")
    hc.CornerRadius = UDim.new(0, 8)
    hc.Parent = header

    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, -20, 1, 0)
    title.Position = UDim2.new(0, 12, 0, 0)
    title.BackgroundTransparency = 1
    title.Text = "ATOMIC HUB — CONTROL MATRIX"
    title.TextColor3 = ATOMIC_COLORS.TOXIC
    title.Font = Enum.Font.GothamBold
    title.TextSize = 13
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = header
    
    local status = Instance.new("TextLabel")
    status.Size = UDim2.new(1, -24, 0, 30)
    status.Position = UDim2.new(0, 12, 0, 50)
    status.BackgroundTransparency = 1
    status.Text = "STATUS: SYSTEM OPERATIONAL"
    status.TextColor3 = ATOMIC_COLORS.CORE
    status.Font = Enum.Font.Code
    status.TextSize = 12
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = mainFrame

    -- Simple Toggle Button inside Menu for visibility demo
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 80, 0, 24)
    closeBtn.Position = UDim2.new(1, -92, 0, 8)
    closeBtn.BackgroundColor3 = ATOMIC_COLORS.INPUT
    closeBtn.Text = "MINIMIZE"
    closeBtn.TextColor3 = Color3.fromRGB(200, 50, 50)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 10
    closeBtn.Parent = header
    
    local cc = Instance.new("UICorner")
    cc.CornerRadius = UDim.new(0, 4)
    cc.Parent = closeBtn
    
    closeBtn.Activated:Connect(function()
        mainFrame.Visible = false
    end)
    
    -- Dragging Logic for Mobile Touch
    local dragging, dragInput, dragStart, startPos
    header.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = mainFrame.Position
            input.Changed:Connect(function()
                if input.UserInputState == Enum.UserInputState.End then dragging = false end
            end)
        end
    end)
    header.InputChanged:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
            dragInput = input
        end
    end)
    UIS.InputChanged:Connect(function(input)
        if input == dragInput and dragging then
            local delta = input.Position - dragStart
            mainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
        end
    end)
end

-- ============================================================
--  MOBILE BUTTON OVERLAYS
-- ============================================================
function buildMobileButtons()
   local mobileGui = Instance.new("ScreenGui")
   mobileGui.Name = "AtomicHubMobileButtons"
   mobileGui.ResetOnSpawn = false
   mobileGui.Parent = CoreGui

   local function makeBtn(actionKey, text, x, y, accentColor)
       local btn = Instance.new("TextButton")
       btn.Size = UDim2.new(0, 90, 0, 45)
       btn.Position = UDim2.new(0, 10 + (x-1)*100, 0, 140 + (y-1)*55)
       btn.BackgroundColor3 = BG_BTN
       btn.TextColor3 = TXT_C
       btn.Text = text
       btn.Font = Enum.Font.GothamBold
       btn.TextSize = 11
       btn.Parent = mobileGui
       
       local st = Instance.new("UIStroke")
       st.Thickness = 1
       st.Color = accentColor
       st.Transparency = 0.34
       st.Parent = btn
       
       local f = Instance.new("UICorner")
       f.CornerRadius = UDim.new(0, 6)
       f.Parent = btn

       local function setActive(isOn)
           TS:Create(btn, TweenInfo.new(0.15), {TextColor3 = isOn and accentColor or TXT_C}):Play()
       end
       btn.Activated:Connect(function()
           MobileButtonActions[actionKey](setActive)
       end)
       return setActive
   end
   
   MobileButtonActions = {}
   MobileButtonActions.autoLeft = function(sa)
       autoLeftEnabled = not autoLeftEnabled
       if autoLeftEnabled then startAutoLeft() else stopAutoLeft() end
   end
   MobileButtonActions.autoRight = function(sa)
       autoRightEnabled = not autoRightEnabled
       if autoRightEnabled then startAutoRight() else stopAutoRight() end
   end
   MobileButtonActions.autoBat = function(sa)
       autoBatActive = not autoBatActive
       if autoBatActive then startBatAimbot() else stopBatAimbot() end
   end
   MobileButtonActions.carry = function(sa) speedMode = not speedMode end
   MobileButtonActions.drop = function(sa) runDrop() end
   MobileButtonActions.tpDown = function(sa) runTPFloor() end
   MobileButtonActions.lagCarry = function(sa)
       local enabled = not (laggerToggled and speedMode)
       laggerToggled = enabled; speedMode = enabled
   end
   MobileButtonActions.lagger = function(sa) laggerToggled = not laggerToggled end
   MobileButtonActions.toggleMenu = function()
       if mainFrame then mainFrame.Visible = not mainFrame.Visible end
   end
   
   local setAL = makeBtn("autoLeft", "ORBIT\nLEFT", 1, 1, ACCENT)
   local setAR = makeBtn("autoRight", "ORBIT\nRIGHT", 2, 1, ICE)
   local setAB = makeBtn("autoBat", "RADAR AIM", 1, 2, ICE)
   local setSP = makeBtn("carry", "OVERDRIVE", 2, 2, ACCENT)
   makeBtn("drop", "NUKEOUT", 1, 3, ACCENT)
   makeBtn("tpDown", "FALLOUT", 2, 3, ICE)
   local setLC = makeBtn("lagCarry", "FISSION\nCARRY", 1, 4, ICE)
   local setPLAY = makeBtn("toggleMenu", "TOGGLE\nMENU", 2, 4, ATOMIC_COLORS.TOXIC)
   
   RunService.Heartbeat:Connect(function()
       setAL(autoLeftEnabled)
       setAR(autoRightEnabled)
       setAB(autoBatActive)
       setSP(speedMode)
       setLC(laggerToggled and speedMode)
   end)
end

-- Run Setup
buildMainPanel()
buildMobileButtons()
print("Atomic Hub Loaded with Active UI Frame.")
