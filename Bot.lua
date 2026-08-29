local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ericknick765/NikeHub/refs/heads/main/Library/LibraryBot.Lua"))()

local Players = game:GetService("Players")
local PlayerNames = {}

for _, Player in ipairs(Players:GetPlayers()) do
	table.insert(PlayerNames, Player.Name)
end

local MainWindow = library:Window("Farm Xp Bot")

local MonitoringAttibute = false
local TargetPlayer

Players.PlayerAdded:Connect(function(player)
	table.insert(PlayerNames, player.Name)
end)

Players.PlayerRemoving:Connect(function(player)
	local index = table.find(PlayerNames, player.Name)

	if index then
		table.remove(PlayerNames, index)
	end
end)

local function TargetPlayerSetup()
	local Player = Players:FindFirstChild(TargetPlayer)

	if not Player then
		warn("Player não encontrado:", TargetPlayer)
		return
	end

	local Attributes = {
		EXP = Player:GetAttribute("EXP"),
		ExpinRound = Player:GetAttribute("ExpinRound"),
	}

	for AttributeName, LastValue in Attributes do
		print(AttributeName, "inicial:", LastValue)

		Player:GetAttributeChangedSignal(AttributeName):Connect(function()
			local NewValue = Player:GetAttribute(AttributeName)

			print(
				AttributeName,
				"mudou:",
				math.floor(LastValue),
				"->",
				math.floor(NewValue)
			)

			LastValue = NewValue

			Attributes[AttributeName] = NewValue
		end)
	end
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
    end
end)