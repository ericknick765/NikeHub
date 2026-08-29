local Players = game:GetService("Players")

local PlayerName = "ericknick765"

local Player = Players:FindFirstChild(PlayerName)

if not Player then
	warn("Player não encontrado:", PlayerName)
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