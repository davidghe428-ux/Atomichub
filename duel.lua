-- ============================================================
--  ATOMIC HUB - COMPLETE WORKING CORE
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

-- Colors Configuration
local ATOMIC_COLORS = {
    TOXIC = Color3.fromRGB(57, 255, 20),      
    CORE = Color3.fromRGB(30, 241, 222),       
    INPUT = Color3.fromRGB(28, 28, 32),        
    TEXT_DARK = Color3.fromRGB(140, 140, 150),  
    BG = Color3.fromRGB(0,0,0), PANEL = Color3.fromRGB(0,0,0), CARD = Color3.fromRGB(9,9,12),
    TEXT = Color3.fromRGB(240,240,240), STROKE = Color3.fromRGB(24,28,36)
}

local ACCENT = ATOMIC_COLORS.TOXIC
local ICE = ATOMIC_COLORS.CORE
local BG_BTN = ATOMIC_COLORS.INPUT
local TXT_C = ATOMIC_COLORS.TEXT_DARK

local IsMobile = UIS.TouchEnabled and not UIS.KeyboardEnabled
local GUI_W, GUI_H = IsMobile and 248 or 360, IsMobile and 360 or 462

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

-- Drop and Teleport functions
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

-- ============================================================
--  ATOMIC HUB MOBILE SCREEN BUTTONS LAYOUT
-- ============================================================
function buildMobileButtons()
   local mobileGui = Instance.new("ScreenGui")
   mobileGui.Name = "AtomicHubMobileButtons"
   mobileGui.ResetOnSpawn = false
   mobileGui.Parent = IsMobile and LP:WaitForChild("PlayerGui") or CoreGui

   local function makeBtn(actionKey, name, text, x, y, accentColor)
       local btn = Instance.new("TextButton")
       btn.Name = name
       btn.Size = UDim2.new(0, 90, 0, 45)
       btn.Position = UDim2.new(0, 10 + (x-1)*100, 0, 100 + (y-1)*55)
       btn.BackgroundColor3 = BG_BTN
       btn.TextColor3 = TXT_C
       btn.Text = text
       btn.Font = Enum.Font.GothamBold
       btn.TextSize = 12
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
           local action = MobileButtonActions[actionKey]
           if action then action(setActive) end
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
       if not autoBatActive then
           startBatAimbot()
           autoBatActive = true
       else
           stopBatAimbot()
           autoBatActive = false
       end
   end
   MobileButtonActions.carry = function(sa)
       speedMode = not speedMode
   end
   MobileButtonActions.drop = function(sa) runDrop() end
   MobileButtonActions.tpDown = function(sa) runTPFloor() end
   MobileButtonActions.lagCarry = function(sa)
       local enabled = not (laggerToggled and speedMode)
       laggerToggled = enabled; speedMode = enabled
   end
   MobileButtonActions.lagger = function(sa)
       laggerToggled = not laggerToggled
   end
   
   local setAL = makeBtn("autoLeft", "AutoLeft", "ORBIT\nLEFT", 1, 1, ACCENT)
   local setAR = makeBtn("autoRight", "AutoRight", "ORBIT\nRIGHT", 2, 1, ICE)
   local setAB = makeBtn("autoBat", "AutoBat", "RADAR AIM", 1, 2, ICE)
   local setSP = makeBtn("carry", "CarrySpeed", "OVERDRIVE", 2, 2, ACCENT)
   makeBtn("drop", "DropBrainrot", "NUKEOUT", 1, 3, ACCENT)
   makeBtn("tpDown", "TPDown", "FALLOUT", 2, 3, ICE)
   local setLC = makeBtn("lagCarry", "LaggerCarry", "FISSION\nCARRY", 1, 4, ICE)
   local setLG = makeBtn("lagger", "LaggerSpeed", "FISSION\nSPEED", 2, 4, ACCENT)
   
   RunService.Heartbeat:Connect(function()
       setAL(autoLeftEnabled)
       setAR(autoRightEnabled)
       setAB(autoBatActive)
       setLG(laggerToggled)
       setSP(speedMode)
       setLC(laggerToggled and speedMode)
   end)
end

-- Execute mobile layers
buildMobileButtons()
print("Atomic Hub UI Systems Ready.")
