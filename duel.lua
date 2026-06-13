-- ============================================================
--  ATOMIC HUB INTERFACE CONFIGURATION
-- ============================================================
local ATOMIC_COLORS = {
    TOXIC = Color3.fromRGB(57, 255, 20),      -- Neon Green
    CORE = Color3.fromRGB(30, 241, 222),       -- Cyber Cyan
    INPUT = Color3.fromRGB(28, 28, 32),        -- Dark Slate
    TEXT_DARK = Color3.fromRGB(140, 140, 150)  -- Muted Gray
}

local ACCENT = ATOMIC_COLORS.TOXIC
local ICE = ATOMIC_COLORS.CORE
local BG_BTN = ATOMIC_COLORS.INPUT
local TXT_C = ATOMIC_COLORS.TEXT_DARK

function buildMobileButtons()
   local function makeBtn(actionKey, name, text, x, y, accentColor)
       local function setActive(isOn)
           TS:Create(btn, TweenInfo.new(0.15), {TextColor3 = isOn and accentColor or TXT_C}):Play()
       end
       btn.MouseEnter:Connect(function()
           if not isOn then
               TS:Create(st, TweenInfo.new(0.12), {Transparency=0.02, Thickness=1.35}):Play()
               TS:Create(f, TweenInfo.new(0.12), {BackgroundColor3=Color3.fromRGB(22,22,27)}):Play()
           end
       end)
       btn.MouseLeave:Connect(function()
           if not isOn then
               TS:Create(st, TweenInfo.new(0.12), {Transparency=0.34, Thickness=1}):Play()
               TS:Create(f, TweenInfo.new(0.12), {BackgroundColor3=BG_BTN}):Play()
           end
       end)
       btn.Activated:Connect(function()
           local action = MobileButtonActions[actionKey]
           if action then action(setActive, isOn) end
       end)
       return setActive
   end
   
   MobileButtonActions = {}
   MobileButtonActions.AutoLeft = function(sa, on)
       sa(not on); autoLeftEnabled = not on
       if autoLeftEnabled then startAutoLeft() else stopAutoLeft() end
       if autoLeftToggle then autoLeftToggle(autoLeftEnabled) end
   end
   MobileButtonActions.AutoRight = function(sa, on)
       sa(not on); autoRightEnabled = not on
       if autoRightEnabled then startAutoRight() else stopAutoRight() end
       if autoRightToggle then autoRightToggle(autoRightEnabled) end
   end
   MobileButtonActions.AutoBat = function(sa, on)
       sa(not on)
       if not on then
           startBatAimbot()
           if aimbotKeyBtn then aimbotKeyBtn.BackgroundColor3 = ATOMIC_COLORS.CORE end
       else
           stopBatAimbot()
           if aimbotKeyBtn then aimbotKeyBtn.BackgroundColor3 = ATOMIC_COLORS.INPUT end
       end
   end
   MobileButtonActions.CarrySpeed = function(sa, on)
       speedMode = not on
       sa(speedMode)
       if laggerToggled and speedMode then modeValLbl.Text = "Overcharged Carry"
       elseif laggerToggled then modeValLbl.Text = "Reactor Lag"
       elseif speedMode then modeValLbl.Text = "Velocity"
       else modeValLbl.Text = "Stable" end
   end
   MobileButtonActions.DropBrainrot = function(sa, on)
       sa(true); runDrop(); task.wait(0.5); sa(false)
   end
   MobileButtonActions.TPDown = function(sa, on)
       sa(true); runTPFloor(); sa(false)
   end
   MobileButtonActions.LaggerCarry = function(sa, on)
       local enabled = not (laggerToggled and speedMode)
       laggerToggled = enabled; speedMode = enabled
       sa(laggerToggled and speedMode)
       if laggerToggled and speedMode then modeValLbl.Text = "Overcharged Carry"
       elseif laggerToggled then modeValLbl.Text = "Reactor Lag"
       elseif speedMode then modeValLbl.Text = "Velocity"
       else modeValLbl.Text = "Stable" end
   end
   MobileButtonActions.LaggerSpeed = function(sa, on)
       laggerToggled = not on
       sa(laggerToggled)
       if laggerToggled and speedMode then modeValLbl.Text = "Overcharged Carry"
       elseif laggerToggled then modeValLbl.Text = "Reactor Lag"
       elseif speedMode then modeValLbl.Text = "Velocity"
       else modeValLbl.Text = "Stable" end
   end
   MobileButtonActions.ToggleGUI = function()
       if main.Visible then hideGui() else showGui() end
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
       setAB(autoBatEnabled)
       setLG(laggerToggled)
       setSP(speedMode)
       setLC(laggerToggled and speedMode)
   end)
end

function setupKeybinds()
   UIS.InputBegan:Connect(function(input, gpe)
       if gpe or UIS:GetFocusedTextBox() or _anyKeyListening then return end
       local kc = input.KeyCode
       if kc == Enum.KeyCode.Q then
           speedMode = not speedMode
           if laggerToggled and speedMode then modeValLbl.Text = "Overcharged Carry"
           elseif laggerToggled then modeValLbl.Text = "Reactor Lag"
           elseif speedMode then modeValLbl.Text = "Velocity"
           else modeValLbl.Text = "Stable" end
       elseif kc == Enum.KeyCode.R then
           laggerToggled = not laggerToggled
           if laggerToggled and speedMode then modeValLbl.Text = "Overcharged Carry"
           elseif laggerToggled then modeValLbl.Text = "Reactor Lag"
           elseif speedMode then modeValLbl.Text = "Velocity"
           else modeValLbl.Text = "Stable" end
       elseif kc == Enum.KeyCode.X then runDrop()
       elseif kc == Enum.KeyCode.F then runTPFloor()
       elseif kc == Enum.KeyCode.Z then
           autoLeftEnabled = not autoLeftEnabled
           if autoLeftToggle then autoLeftToggle(autoLeftEnabled) end
           if autoLeftEnabled then startAutoLeft() else stopAutoLeft() end
       elseif kc == Enum.KeyCode.C then
           autoRightEnabled = not autoRightEnabled
           if autoRightToggle then autoRightToggle(autoRightEnabled) end
           if autoRightEnabled then startAutoRight() else stopAutoRight() end
       elseif kc == Enum.KeyCode.E then
           if not autoBatActive then
               startBatAimbot()
               autoBatActive = true
               if aimbotKeyBtn then aimbotKeyBtn.BackgroundColor3 = ATOMIC_COLORS.CORE end
           else
               stopBatAimbot()
               autoBatActive = false
               if aimbotKeyBtn then aimbotKeyBtn.BackgroundColor3 = ATOMIC_COLORS.INPUT end
           end
       elseif kc == Enum.KeyCode.LeftControl then
           if main.Visible then hideGui() else showGui() end
       end
   end)
end

-- ============================================================
--  EXECUTION
-- ============================================================
local page = buildMainFrame()
buildProgressBar(gui)
buildSpeedValues(page)
buildSpeedKeybinds(page)
buildBatAimbot(page)
buildInstaGrab(page)
buildSkyTheme(page)
buildMovement(page)
buildVisuals(page)
buildSettings(page)
buildMobileButtons()
setupKeybinds()
showGui()
print("Atomic Hub Loaded Successfully.")
