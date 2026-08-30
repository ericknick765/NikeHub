local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ericknick765/NikeHub/refs/heads/main/Library/LibraryBot.Lua"))()

local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local PlayerNames = {}

for _, Player in ipairs(Players:GetPlayers()) do
	if Player == LocalPlayer then return end
	table.insert(PlayerNames, Player.Name)
end

local MainWindow = library:Window("Farm Xp Bot")

local TouchID = 8822
local ActionPath = "Survivor-mob.Controls.action.check"

local MonitoringAttibute = false
local AttributeConnections = {}
local HookConnections = {}
local PlayersHooked = {}
local TargetPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local Config = {
	["TweenSpeed"] = 10,
	["TeleportMode"] = false,
	["AutoSave"] = false
}

Players.PlayerAdded:Connect(function(player)
	table.insert(PlayerNames, player.Name)
end)

Players.PlayerRemoving:Connect(function(player)
	local index = table.find(PlayerNames, player.Name)

	if index then
		table.remove(PlayerNames, index)
	end
end)

local function GetActionTarget()
    local current = PlayerGui
    for segment in string.gmatch(ActionPath, "[^%.]+") do
        current = current and current:FindFirstChild(segment)
    end
    return current
end

local function WaitForActionTarget(timeout)
    timeout = timeout or 1
    local interval = 0.05
    local attempts = math.floor(timeout / interval)
    local target = GetActionTarget()
    local tries = 0
    while
        (not target or not target:IsA("GuiObject"))
        and tries < attempts
    do
        task.wait(interval)
        target = GetActionTarget()
        tries += 1
    end
    if target and target:IsA("GuiObject") then
        return target
    end
    return nil
end

local function TriggerMobileButton(timeout)

    local button = WaitForActionTarget(timeout)

    if not button then
        return false
    end

    local position = button.AbsolutePosition
    local size = button.AbsoluteSize
    local inset = GuiService:GetGuiInset()

    local x = position.X + (size.X / 2) + inset.X
    local y = position.Y + (size.Y / 2) + inset.Y

    local success = pcall(function()
        VirtualInputManager:SendTouchEvent(TouchID,0,x,y)
        task.wait(0.01)
        VirtualInputManager:SendTouchEvent(TouchID,2,x,y)
    end)
    return success
end

local function TweenConstantSpeed(Object, Goal, Speed, Callback)
	if not Object or not Speed or Speed <= 0 then
		return
	end

	local StartPosition = Object.Position
	local TargetPosition = Goal.Position

	local Distance = (TargetPosition - StartPosition).Magnitude
	local Duration = Distance / Speed

	local TweenInfo = TweenInfo.new(
		Duration,
		Enum.EasingStyle.Linear,
		Enum.EasingDirection.InOut
	)

	local Tween = TweenService:Create(Object, TweenInfo, {
		Position = TargetPosition
	})

	if Callback then
		Tween.Completed:Connect(function()
			Callback()
		end)
	end

	Tween:Play()

	return Tween
end

local function TargetPlayerCleanup()
	for _, Connection in ipairs(AttributeConnections) do
		Connection:Disconnect()
	end

	table.clear(AttributeConnections)
end

local function TargetPlayerSetup()
	local Player = Players:FindFirstChild(TargetPlayer)

	if not Player then
		warn("Player não encontrado:", TargetPlayer)
		return
	end

	-- Desconecta conexões anteriores
	for _, Connection in pairs(AttributeConnections) do
		Connection:Disconnect()
	end

	table.clear(AttributeConnections)

	local Attributes = {
		EXP = Player:GetAttribute("EXP"),
		ExpinRound = Player:GetAttribute("ExpinRound"),
	}

	for AttributeName, LastValue in Attributes do
		print(AttributeName, "inicial:", LastValue)

		local Connection = Player:GetAttributeChangedSignal(AttributeName):Connect(function()
			local NewValue = Player:GetAttribute(AttributeName)

			if typeof(LastValue) ~= "number" or typeof(NewValue) ~= "number" then
				return
			end

			library:Notify(
				"Attributo: " .. AttributeName ..
				" Mudou: " .. math.floor(LastValue) ..
				" -> " .. math.floor(NewValue) ..
				" +" .. math.floor(NewValue - LastValue),
				5
			)

			LastValue = NewValue
			Attributes[AttributeName] = NewValue
		end)

		table.insert(AttributeConnections, Connection)
	end
end

local function UpdateHookedPlayer(Player)
	local Character = Player.Character
	if not Character then
		return
	end

	local hrp = Character:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end

	local LocalCharacter = LocalPlayer.Character
	if not LocalCharacter then
		return
	end

	local LocalHrp = LocalCharacter:FindFirstChild("HumanoidRootPart")
	if not LocalHrp then
		return
	end

	local IsHooked = Character:GetAttribute("HookProgressDepleting")
	local Index = table.find(PlayersHooked, Player)

	if IsHooked then
		if not Index then
			table.insert(PlayersHooked, Player)

			print(Player.Name, "está no Hook")

			local TargetPosition =
				hrp.Position + hrp.CFrame.LookVector * 10

			TweenConstantSpeed(
				LocalHrp,
				TargetPosition,
				Config.TweenSpeed,
				TriggerMobileButton(1)
			)
		end
	else
		if Index then
			table.remove(PlayersHooked, Index)

			print(Player.Name, "saiu do Hook")
		end
	end
end

local function StartHookMonitor()
	StopHookMonitor()

	for _, Player in ipairs(Players:GetPlayers()) do
		local Character = Player.Character

		if Character then
			UpdateHookedPlayer(Player)

			local Connection = Character:GetAttributeChangedSignal("HookProgressDepleting"):Connect(function()
				UpdateHookedPlayer(Player)
			end)

			table.insert(HookConnections, Connection)
		end
	end
end

function StopHookMonitor()
	for _, Connection in ipairs(HookConnections) do
		Connection:Disconnect()
	end

	table.clear(HookConnections)
	table.clear(PlayersHooked)
end

MainWindow:Dropdown("Player", PlayerNames, function(Selected)
	TargetPlayer = tostring(Selected)
    library:Notify("Agora detectando: " .. TargetPlayer, 5)
end)

MainWindow:Toggle("Monitoring", function(state)
    MonitoringAttibute = state
    if state then
        library:Notify("Monitoring Started", 3)
        TargetPlayerSetup()
    else
        library:Notify("Monitoring Desativated!", 3)
		TargetPlayerCleanup()
    end
end)

MainWindow:Box("Tween Speed", "Number", function(Box)
	local Speed = tonumber(Box)

	if not Speed or Speed <= 0 then
		return
	end

	Config.TweenSpeed = Speed
end)

MainWindow:Toggle("Teleport Mode", function(State)
	Config.TeleportMode = State
end)

MainWindow:Toggle("Auto Save", function(State)
	Config.AutoSave = State

	if State then
		StartHookMonitor()
	else
		StopHookMonitor()
	end
end)

