-- ============================================================
--  ATOMIC HUB - COMPLETE CORE FRAMEWORK & INTERFACE
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
       pcall(function() pg:FindFirstChild("CandyHub"):Destroy() end)
       pcall(function() pg:FindFirstChild("CandyHubMobileButtons"):Destroy() end)
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
    BG = Color3.fromRGB(0,0,0), PANEL = Color3.fromRGB(0,0,0), CARD = Color3.fromRGB(9,9,12),
    TEXT = Color3.fromRGB(240,240,240), STROKE = Color3.fromRGB(24,28,36)
}

local ACCENT = ATOMIC_COLORS.TOXIC
local ICE = ATOMIC_COLORS.CORE
local BG_BTN = ATOMIC_COLORS.INPUT
local TXT_C = ATOMIC_COLORS.TEXT_DARK

local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local GUI_W, GUI_H = IsMobile and 248 or 360, IsMobile and 360 or 462
local HDR_H = IsMobile and 52 or 58
local PAD = IsMobile and 8 or 10
local PROGRESS_H = 30                       
local PAGE_TOP = HDR_H + (IsMobile and 10 or 12)
local PAGE_BOTTOM = PAGE_TOP + (IsMobile and 8 or 10)
local ROW_H = IsMobile and 28 or 31
local SECTION_H = IsMobile and 16 or 18

-- ============================================================
--  GLOBAL STATE VARIABLES
-- ============================================================
NS = 60; CS = 30
LAGGER_SPEED = 15; LAGGER_CARRY_SPEED = 24.5
speedMode = false; laggerToggled = false
autoBatEnabled = false; autoSwingEnabled = true
batCounterEnabled = false; medusaCounterEnabled = false
autoLeftEnabled = false; autoRightEnabled = false
antiRagdollEnabled = false; unwalkEnabled = false
autoTPEnabled = false; autoTPHeight = 20
stretchRezEnabled = false; antiLagEnabled = false
uiLocked = false; infJumpEnabled = false
_anyKeyListening = false
modeValLbl = nil
setTopLockVisual = nil
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
   val.TextSize = 17; tag.TextXAlignment = Enum.TextXAlignment.Center
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
       elseif antiRagdollEnabled and lastMoveDir.Magnitude > 0 then
           local anyHeld = false
           for key in pairs(MOVE_KEYS) do if UIS:IsKeyDown(key) then anyHeld = true; break end end
           if anyHeld then hrp.Velocity = Vector3.new(lastMoveDir.X*spd, hrp.Velocity.Y, lastMoveDir.Z*spd) end
       end
   end
   if speedLabel then
       local actualSpeed = Vector3.new(hrp.Velocity.X, 0, hrp.Velocity.Z).Magnitude
       if actualSpeed < 0.05 then actualSpeed = 0 end
       speedLabel.Text = string.format("Speed: %.1f", actualSpeed)
   end
end)

-- Automation nodes
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
               local d = AP_L2 - hrp.Position
               local mv = Vector3.new(d.X, 0, d.Z).Unit
               hum:Move(mv, false)
               hrp.Velocity = Vector3.new(mv.X*spd, hrp.Velocity.Y, mv.Z*spd)
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
               if alConn then alConn:Disconnect(); alConn = nil end
               alPhase = 1
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
               local d = AP_R2 - hrp.Position
               local mv = Vector3.new(d.X, 0, d.Z).Unit
               hum:Move(mv, false)
               hrp.Velocity = Vector3.new(mv.X*spd, hrp.Velocity.Y, mv.Z*spd)
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
               if arConn then arConn:Disconnect(); arConn = nil end
               arPhase = 1
               return
           end
           local d = AP_R2 - hrp.Position
           local mv = Vector3.new(d.X, 0, d.Z).Unit
           hum:Move(mv, false)
           hrp.Velocity = Vector3.new(mv.X*spd, hrp.Velocity.Y, mv.Z*spd)
       end
   end)
end

-- Physics Modification / Jump Overrides
holdJumpPressed, holdJumpActive = false, false
function applyInfJumpBoost(boost)
   if not infJumpEnabled then return end
   local char = LP.Character
   if char then
       local root = char:FindFirstChild("HumanoidRootPart")
       if root then root.Velocity = Vector3.new(root.Velocity.X, boost, root.Velocity.Z) end
   end
end
UIS.JumpRequest:Connect(function() applyInfJumpBoost(50) end)
UIS.InputBegan:Connect(function(input)
   if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space and not UIS:GetFocusedTextBox() then
       holdJumpPressed = true
       task.wait(0.12)
       if holdJumpPressed then holdJumpActive = true; applyInfJumpBoost(50) end
   end
end)
UIS.InputEnded:Connect(function(input)
   if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Space then holdJumpPressed = false; holdJumpActive = false end
end)
RunService.Heartbeat:Connect(function() if holdJumpActive then applyInfJumpBoost(50) end end)

-- Positional Teleportation
function doAutoTPDown(force)
   local char = LP.Character
   if not char then return end
   local hrp = char:FindFirstChild("HumanoidRootPart")
   local hum = char:FindFirstChildOfClass("Humanoid")
   if not hrp or not hum then return end
   if not force then
       if hum.FloorMaterial ~= Enum.Material.Air then return end
       if not (hrp.Position.Y >= autoTPHeight) then return end
   end
   hrp.CFrame = CFrame.new(hrp.Position.X, -7.00, hrp.Position.Z) * CFrame.Angles(0, select(2, hrp.CFrame:ToEulerAnglesYXZ()), 0)
   hrp.Velocity = Vector3.zero
end
autoTPConn = nil
function startAutoTP()
   if autoTPConn then coroutine.close(autoTPConn) end
   autoTPConn = coroutine.create(function()
       while autoTPEnabled do
           task.wait(0.1)
           pcall(function() doAutoTPDown(false) end)
       end
   end)
   coroutine.resume(autoTPConn)
end
function stopAutoTP() autoTPEnabled = false; if autoTPConn then coroutine.close(autoTPConn); autoTPConn = nil end end
function runTPFloor() pcall(function() doAutoTPDown(true) end) end

-- Environment Adjustments
function enableStretchRez() stretchRezEnabled = true; workspace.CurrentCamera.FieldOfView = 107 end
function disableStretchRez() stretchRezEnabled = false; workspace.CurrentCamera.FieldOfView = 70 end
function enableAntiLag() antiLagEnabled = true; Lighting.GlobalShadows = false; Lighting.FogEnd = 1e10; Lighting.Brightness = 1 end
function disableAntiLag() antiLagEnabled = false; Lighting.GlobalShadows = true; Lighting.FogEnd = 100000; Lighting.Brightness = 2 end

-- State Management
unwalkSavedAnimate = nil
function startUnwalk()
   local c = LP.Character
   if not c then return end
   local hum = c:FindFirstChildOfClass("Humanoid")
   if hum then for _,t in ipairs(hum:GetPlayingAnimationTracks()) do t:Stop() end end
   local anim = c:FindFirstChild("Animate")
   if anim then unwalkSavedAnimate = anim:Clone(); anim:Destroy() end
end
function stopUnwalk()
   local c = LP.Character
   if c and unwalkSavedAnimate then unwalkSavedAnimate:Clone().Parent = c; unwalkSavedAnimate = nil end
end

dropActive = false
function runDrop()
   if dropActive then return end
   dropActive = true
   local char = LP.Character
   local root = char and char:FindFirstChild("HumanoidRootPart")
   if root then
       root.Velocity = Vector3.new(0, 10000, 0)
       task.wait(0.1)
       root.Velocity = Vector3.zero
   end
   dropActive = false
end

-- Aimbot Calculations
aimbotConn = nil
function findBat()
   local char = LP.Character
   if not char then return nil end
   for _,tool in ipairs(char:GetChildren()) do
       if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then return tool end
   end
   local bp = LP:FindFirstChild("Backpack")
   if bp then
       for _,tool in ipairs(bp:GetChildren()) do
           if tool:IsA("Tool") and (tool.Name:lower():find("bat") or tool.Name:lower():find("slap")) then return tool end
       end
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
function swingCurrentBat()
   if not autoSwingEnabled then return end
   local bat = findBat()
   if bat and bat.Parent == LP.Character and bat:IsA("Tool") then
       pcall(function() bat:Activate() end)
   end
end
function startBatAimbot()
   if aimbotConn then aimbotConn:Disconnect() end
   autoBatEnabled = true
   if autoLeftEnabled then autoLeftEnabled = false; stopAutoLeft() end
   if autoRightEnabled then autoRightEnabled = false; stopAutoRight() end
   local hum0 = LP.Character and LP.Character:FindFirstChildOfClass("Humanoid")
   if hum0 then hum0.AutoRotate = false end
   aimbotConn = RunService.RenderStepped:Connect(function()
       if not autoBatEnabled then return end
       local char = LP.Character
       if not char then return end
       local root = char:FindFirstChild("HumanoidRootPart")
       local hum = char:FindFirstChildOfClass("Humanoid")
       if not root or not hum then return end
       if not char:FindFirstChildOfClass("Tool") then
           local bat = findBat()
           if bat then pcall(function() hum:EquipTool(bat) end) end
       end
       local target = getClosestTarget()
       if not target then swingCurrentBat(); return end
       local targetVel = target.Velocity
       local myPos = root.Position
       local targetPos = target.Position
       local predictPos = targetPos + targetVel * 0.14
       local direction = predictPos - myPos
       local flatDir = Vector3.new(direction.X, 0, direction.Z).Unit
       local chaseSpeed = 58
       local desiredHeight = targetPos.Y + 3.7
       local yVel = (desiredHeight - myPos.Y) * 19.5 + targetVel.Y * 0.8
       if hum.FloorMaterial ~= Enum.Material.Air then yVel = math.max(yVel, 13) end
       yVel = math.clamp(yVel, -70, 110)
       local desiredVel = Vector3.new(flatDir.X * chaseSpeed, yVel, flatDir.Z * chaseSpeed)
       root.Velocity = root.Velocity:Lerp(desiredVel, 0.8)
       local predictedPos = targetPos + targetVel * math.clamp(targetVel.Magnitude/150, 0.05, 0.2)
       local toPredict = predictedPos - myPos
       if toPredict.Magnitude > 0.1 then
           local goalCF = CFrame.lookAt(myPos, predictedPos)
           local diffCF = root.CFrame:Inverse() * goalCF
           local rx, ry, rz = diffCF:ToEulerAnglesXYZ()
           rx = math.clamp(rx, -2.5, 2.5); ry = math.clamp(ry, -2.5, 2.5); rz = math.clamp(rz, -2.5, 2.5)
           root.AssemblyAngularVelocity = root.CFrame:VectorToWorldSpace(Vector3.new(rx*42, ry*42, rz*42))
       end
       swingCurrentBat()
   end)
end
function stopBatAimbot()
   if aimbotConn then aimbotConn:Disconnect(); aimbotConn = nil end
   autoBatEnabled = false
   local char = LP.Character
   local root = char and char:FindFirstChild("HumanoidRootPart")
   if root then root.Velocity = Vector3.zero; root.AssemblyAngularVelocity = Vector3.zero end
   local hum2 = char and char:FindFirstChildOfClass("Humanoid")
   if hum2 then hum2.AutoRotate = true end
end

-- Fallback Frame Builder (Guarantees execution if script searches for it)
function buildMainFrame()
    local mainGui = Instance.new("ScreenGui")
    mainGui.Name = "AtomicHub"
    mainGui.ResetOnSpawn = false
    mainGui.Parent = IsMobile and LP:WaitForChild("PlayerGui") or CoreGui
    
    local mainFrame = Instance.new("Frame")
    mainFrame.Name = "MainFrame"
    mainFrame.Size = UDim2.new(0, GUI_W, 0, GUI_H)
    mainFrame.Position = UDim2.new(0.5, -GUI_W/2, 0.5, -GUI_H/2)
    mainFrame.BackgroundColor3 = ATOMIC_COLORS.BG
    mainFrame.Visible = true
    mainFrame.Parent = mainGui
    
    -- Global Label reference for display mode updates
    local modeLabel = Instance.new("TextLabel")
    modeLabel.Size = UDim2.new(1, 0, 0, 20)
    modeLabel.Position = UDim2.new(0, 0, 0, 60)
    modeLabel.Text = "Stable"
    modeLabel.TextColor3 = ATOMIC_COLORS.TOXIC
    modeLabel.BackgroundTransparency = 1
    modeLabel.Parent = mainFrame
    modeValLbl = modeLabel
    
    main = mainFrame
    return mainFrame
end

-- Stubs for empty interface functions to prevent crashing
function buildProgressBar() end
function buildSpeedValues() end
function buildSpeedKeybinds() end
function buildBatAimbot() end
function buildInstaGrab() end
function buildSkyTheme() end
function buildMovement() end
function buildVisuals() end
function buildSettings() end
function showGui() if main then main.Visible = true end end
function hideGui() if main then main.Visible = false end end

-- ============================================================
--  ATOMIC HUB INTERFACE CONFIGURATION
-- ============================================================
function buildMobileButtons()
   local mobileGui = Instance.new("ScreenGui")
   mobileGui.Name = "AtomicHubMobileButtons"
   mobileGui.ResetOnSpawn = false
   mobileGui.Parent = IsMobile and LP:WaitForChild("PlayerGui") or CoreGui

   local function makeBtn(actionKey, name, text, x, y, accentColor)
       local btn = Instance.new("TextButton")
       btn.Name = name
       btn.Size = UDim2.new(
