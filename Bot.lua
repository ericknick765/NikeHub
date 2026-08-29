local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ericknick765/NikeHub/refs/heads/main/Library/LibraryBot.Lua"))()

local Players = game:GetService("Players")

local MainWindow = library:Window("Auto Race Start Bot")

local MonitoringAttibute = false

local TargetPlayer

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
				LastValue,
				"->",
				NewValue
			)

			Attributes[AttributeName] = NewValue
		end)
	end
end


MainWindow:Box("Player Name", "Name", function(BoxPlayer)
    TargetPlayer = tostring(BoxPlayer)
    library:Notify("Agora detectando: " .. TargetPlayer, 5)
end)

MainWindow:Toggle("Auto-Start", function(state)
    MonitoringAttibute = state
    if state then
        library:Notify("Monitoring Started", 3)
        TargetPlayerSetup()
    else
        library:Notify("Monitoring Desativated!", 3)
    end
end)