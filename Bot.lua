local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ericknick765/NikeHub/refs/heads/main/Library/LibraryBot.Lua"))()

--// Services
local TweenService = game:GetService("TweenService")
local VirtualInputManager = game:GetService("VirtualInputManager")
local GuiService = game:GetService("GuiService")
local Players = game:GetService("Players")

--// Players
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local PlayerNames = {}

for _, Player in ipairs(Players:GetPlayers()) do
	if Player ~= LocalPlayer then
		table.insert(PlayerNames, Player.Name)
	end
end

--// Window
local MainWindow = library:Window("Farm Xp Bot")

--// Constants
local TouchID = 8822
local ActionPath = "Survivor-mob.Controls.action.check"

--// State
local MonitoringAttribute = false
local TargetPlayer = nil

local AttributeConnections = {}
local HookConnections = {}
local PlayersHooked = {}

--// Config
local Config = {
	TweenSpeed = 10,
	TeleportMode = false,
	AutoSave = false
}


--//==================================================
--// PLAYER LIST
--//==================================================

Players.PlayerAdded:Connect(function(Player)
	if Player == LocalPlayer then
		return
	end

	if not table.find(PlayerNames, Player.Name) then
		table.insert(PlayerNames, Player.Name)
	end
end)

Players.PlayerRemoving:Connect(function(Player)
	local Index = table.find(PlayerNames, Player.Name)

	if Index then
		table.remove(PlayerNames, Index)
	end
end)


--//==================================================
--// ACTION BUTTON
--//==================================================

local function GetActionTarget()
	local Current = PlayerGui

	for Segment in string.gmatch(ActionPath, "[^%.]+") do
		Current = Current and Current:FindFirstChild(Segment)
	end

	return Current
end


local function WaitForActionTarget(Timeout)
	Timeout = Timeout or 1

	local Interval = 0.05
	local Attempts = math.floor(Timeout / Interval)

	local Target = GetActionTarget()
	local Tries = 0

	while (not Target or not Target:IsA("GuiObject")) and Tries < Attempts do
		task.wait(Interval)

		Target = GetActionTarget()
		Tries += 1
	end

	if Target and Target:IsA("GuiObject") then
		return Target
	end

	return nil
end


local function TriggerMobileButton(Timeout)
	local Button = WaitForActionTarget(Timeout)

	if not Button then
		return false
	end

	local Position = Button.AbsolutePosition
	local Size = Button.AbsoluteSize
	local Inset = GuiService:GetGuiInset()

	local X = Position.X + (Size.X / 2) + Inset.X
	local Y = Position.Y + (Size.Y / 2) + Inset.Y

	local Success = pcall(function()
		VirtualInputManager:SendTouchEvent(
			TouchID,
			0,
			X,
			Y
		)

		task.wait(0.01)

		VirtualInputManager:SendTouchEvent(
			TouchID,
			2,
			X,
			Y
		)
	end)

	return Success
end


--//==================================================
--// CONSTANT SPEED TWEEN
--//==================================================

local function TweenConstantSpeed(Object, Goal, Speed, Callback)
	if not Object or not Object.Parent then
		return
	end

	if not Goal or not Goal.Parent then
		return
	end

	if not Speed or Speed <= 0 then
		return
	end

	local StartPosition = Object.Position
	local TargetPosition = Goal.Position

	local Distance = (TargetPosition - StartPosition).Magnitude

	if Distance <= 0.01 then
		if Callback then
			Callback()
		end

		return
	end

	local Duration = Distance / Speed

	local Tween = TweenService:Create(
		Object,
		TweenInfo.new(
			Duration,
			Enum.EasingStyle.Linear,
			Enum.EasingDirection.InOut
		),
		{
			Position = TargetPosition
		}
	)

	if Callback then
		Tween.Completed:Connect(function(State)
			if State == Enum.PlaybackState.Completed then
				Callback()
			end
		end)
	end

	Tween:Play()

	return Tween
end


--//==================================================
--// ATTRIBUTE MONITOR
--//==================================================

local function TargetPlayerCleanup()
	for _, Connection in ipairs(AttributeConnections) do
		Connection:Disconnect()
	end

	table.clear(AttributeConnections)
end


local function TargetPlayerSetup()
	-- Remove conexões do alvo anterior
	TargetPlayerCleanup()

	if not TargetPlayer then
		warn("Nenhum Player selecionado.")
		return
	end

	local Player = Players:FindFirstChild(TargetPlayer)

	if not Player then
		warn("Player não encontrado:", TargetPlayer)
		return
	end

	local Attributes = {
		EXP = Player:GetAttribute("EXP"),
		ExpinRound = Player:GetAttribute("ExpinRound"),
	}

	for AttributeName, LastValue in pairs(Attributes) do
		print(AttributeName, "inicial:", LastValue)

		local Connection = Player:GetAttributeChangedSignal(AttributeName):Connect(function()
			local NewValue = Player:GetAttribute(AttributeName)

			if typeof(LastValue) ~= "number" or typeof(NewValue) ~= "number" then
				return
			end

			local Difference = math.floor(NewValue - LastValue)

			local Sign = Difference >= 0 and "+" or ""

			library:Notify(
				"Attributo: " .. AttributeName ..
				" Mudou: " .. math.floor(LastValue) ..
				" -> " .. math.floor(NewValue) ..
				" " .. Sign .. Difference,
				5
			)

			LastValue = NewValue
			Attributes[AttributeName] = NewValue
		end)

		table.insert(AttributeConnections, Connection)
	end
end


--//==================================================
--// HOOK MONITOR
--//==================================================

local function StopHookMonitor()
	for _, Connection in ipairs(HookConnections) do
		Connection:Disconnect()
	end

	table.clear(HookConnections)
	table.clear(PlayersHooked)
end


local function UpdateHookedPlayer(Player)
	local Character = Player.Character

	if not Character then
		return
	end

	local HRP = Character:FindFirstChild("HumanoidRootPart")

	if not HRP then
		return
	end

	local LocalCharacter = LocalPlayer.Character

	if not LocalCharacter then
		return
	end

	local LocalHRP = LocalCharacter:FindFirstChild("HumanoidRootPart")

	if not LocalHRP then
		return
	end

	local IsHooked = Character:GetAttribute("HookProgressDepleting")
	local Index = table.find(PlayersHooked, Player)

	if IsHooked then

		-- Evita duplicar o Player na tabela
		if not Index then
			table.insert(PlayersHooked, Player)

			print(Player.Name, "está no Hook")

			local TargetPosition =
				HRP.Position + HRP.CFrame.LookVector * 10

			TweenConstantSpeed(
				LocalHRP,
				{
					Position = TargetPosition
				},
				Config.TweenSpeed,
				function()
					print("Chegou na posição do Hook:", Player.Name)

					TriggerMobileButton(1)
				end
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
	-- Limpa monitor anterior
	StopHookMonitor()

	for _, Player in ipairs(Players:GetPlayers()) do

		if Player == LocalPlayer then
			continue
		end

		local Character = Player.Character

		if Character then
			UpdateHookedPlayer(Player)

			local Connection = Character:GetAttributeChangedSignal(
				"HookProgressDepleting"
			):Connect(function()
				UpdateHookedPlayer(Player)
			end)

			table.insert(HookConnections, Connection)
		end
	end
end


--//==================================================
--// UI
--//==================================================

MainWindow:Dropdown("Player", PlayerNames, function(Selected)
	TargetPlayer = tostring(Selected)

	library:Notify(
		"Agora detectando: " .. TargetPlayer,
		5
	)

	-- Se já estiver monitorando, troca o alvo imediatamente
	if MonitoringAttribute then
		TargetPlayerSetup()
	end
end)


MainWindow:Toggle("Monitoring", function(State)
	MonitoringAttribute = State

	if State then
		library:Notify(
			"Monitoring Started",
			3
		)

		TargetPlayerSetup()

	else
		library:Notify(
			"Monitoring Desativated!",
			3
		)

		TargetPlayerCleanup()
	end
end)


MainWindow:Box("Tween Speed", "Number", function(Box)
	local Speed = tonumber(Box)

	if not Speed or Speed <= 0 then
		library:Notify(
			"Tween Speed inválido!",
			3
		)

		return
	end

	Config.TweenSpeed = Speed

	print("Tween Speed:", Config.TweenSpeed)
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