local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ericknick765/NikeHub/refs/heads/main/Library/LibraryBot.Lua"))()

--// Services
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

--// Player
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local V = LocalPlayer.PlayerGui
    .HaystackHUD
    .Canvas
    .Top
    .Counters
    .CARRYING
    .V

local Config = {
    ["SpeedCollect"] = 0.1,
    ["AutoCollect"] = false,
    ["ShowRange"] = false,
    ["SpeedDeploy"] = 1,
    ["DeployMode"] = false
}

local DisturbedTiles = workspace:WaitForChild("DisturbedTiles")
local PullRequestEvent = ReplicatedStorage
    :WaitForChild("HaystackRemotes")
    :WaitForChild("PullRequest")

local DropRequestEvent = ReplicatedStorage
    :WaitForChild("HaystackRemotes")
    :WaitForChild("DropAllRequest")

local ClearPos = CFrame.new(53, 3, 84)

--// Window
local MainWindow = library:Window("Find the Needle")

--////// Show Range //////--

-- ==== CONFIGURAÇÕES ====
local RAIO = 16          -- studs (raio do círculo)
local NUM_TRACOS = 20     -- quantidade de traços na borda
local FRACAO_TRACO = 0.7  -- % do espaço ocupado por cada traço (maior = traços mais longos, menor = gaps maiores)
local ESPESSURA = 0.3     -- espessura radial do traço (largura)
local ALTURA_TRACO = 0.2  -- grossura vertical do traço
local COR = Color3.fromRGB(0, 200, 255)
local TRANSPARENCIA = 0.3
local ALTURA_ACIMA_DO_CHAO = 0.1
-- ========================
 
local pasta = Instance.new("Folder")
pasta.Name = "RangeCircleBorda"
pasta.Parent = workspace
 
local tracos = {}
local anguloTraco = 360 / NUM_TRACOS
local comprimentoTraco = (2 * math.pi * RAIO / NUM_TRACOS) * FRACAO_TRACO

local function SetRangeTransparency(transparency)
    for _, traco in ipairs(tracos) do
        traco.Transparency = transparency
    end
end

local function ConfigUpdate()
    if Config.ShowRange then
        SetRangeTransparency(0.3)
    else
        SetRangeTransparency(1)
    end
end
 
for i = 1, NUM_TRACOS do
	local traco = Instance.new("Part")
	traco.Name = "Traco"
	traco.Size = Vector3.new(ESPESSURA, ALTURA_TRACO, comprimentoTraco)
	traco.Material = Enum.Material.Neon
	traco.Color = COR
	traco.Transparency = TRANSPARENCIA
	traco.CanCollide = false
	traco.CanQuery = false
	traco.Anchored = true
	traco.Parent = pasta
	tracos[i] = traco
end

local connection
 
local function atualizarPosicoes(centerPos)
	for i, traco in ipairs(tracos) do
		local anguloRad = math.rad((i - 1) * anguloTraco)
		local x = math.cos(anguloRad) * RAIO
		local z = math.sin(anguloRad) * RAIO
		local tangente = Vector3.new(-math.sin(anguloRad), 0, math.cos(anguloRad))
 
		local posicao = Vector3.new(
			centerPos.X + x,
			centerPos.Y - ALTURA_ACIMA_DO_CHAO,
			centerPos.Z + z
		)
 
		traco.CFrame = CFrame.lookAt(posicao, posicao + tangente, Vector3.new(0, 1, 0))
	end
end
 
local function conectarPersonagem(character)
	if connection then
		connection:Disconnect()
	end
 
	local hrp = character:WaitForChild("HumanoidRootPart")
 
	connection = RunService.Heartbeat:Connect(function()
		if hrp and hrp.Parent then
			local pos = hrp.Position
			atualizarPosicoes(Vector3.new(pos.X, pos.Y - hrp.Size.Y / 2, pos.Z))
		end
	end)
end
 
if LocalPlayer.Character then
	conectarPersonagem(LocalPlayer.Character)
end
 
LocalPlayer.CharacterAdded:Connect(conectarPersonagem)

--/////// Final Show Range ///////--

--/////// Auto Collect ///////--

local function GetNearestS()
    local Character = LocalPlayer.Character
    if not Character then
        return
    end

    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not HRP then
        return
    end

    local NearestPart = nil
    local NearestTile = nil
    local NearestNumber = nil
    local NearestDistance = 16

    for _, Object in ipairs(DisturbedTiles:GetDescendants()) do

        if Object:IsA("BasePart") then
            local Number = Object.Name:match("^S(%d+)$")

            if Number then
                local Tile = Object:FindFirstAncestorWhichIsA("Model")

                if not Tile then
                    Tile = Object:FindFirstAncestorWhichIsA("Folder")
                end

                local Current = Object.Parent

                while Current and Current ~= DisturbedTiles do
                    local TileName = Current.Name:match("^(T_%d+)_live$")

                    if TileName then
                        Tile = Current
                        break
                    end

                    Current = Current.Parent
                end

                if Tile then
                    local TileName = Tile.Name:match("^(T_%d+)_live$")

                    if TileName then
                        local Distance = (HRP.Position - Object.Position).Magnitude

                        if Distance < NearestDistance then
                            NearestDistance = Distance
                            NearestPart = Object
                            NearestTile = TileName
                            NearestNumber = tonumber(Number)
                        end
                    end
                end
            end
        end
    end

    return NearestPart, NearestTile, NearestNumber, NearestDistance
end


local function PullNearest()
    local Part, TileName, Number, Distance = GetNearestS()

    if not Part then
        return
    end

    if not TileName or not Number then
        return
    end

    PullRequestEvent:FireServer(TileName, Number)
end

local function Teleport(Offset)
	Offset = Offset or CFrame.new()

    local Character = LocalPlayer.Character
    if not Character then return end

    local HRP = Character:FindFirstChild("HumanoidRootPart")
    if not HRP then return end

    local PosSave = HRP.CFrame 

    HRP.CFrame = ClearPos * Offset
    task.wait(Config.SpeedDeploy)
    DropRequestEvent:FireServer(
				CFrame.new(47.79959487915, 4.2953653335571, 80.743003845215, 0.73176431655884, 0.035197224467993, -0.68064832687378, -0.048043582588434, 0.99884533882141, -2.1000516881031e-09, 0.67986232042313, 0.032700788229704, 0.73261028528214),
				Vector3.new(0.73176431655884, -0.048043582588434, 0.67986238002777)
			)
    HRP.CFrame = PosSave
end

local function CheckCarrying()
    local Current, Max = V.Text:match("(%d+)%s*/%s*(%d+)")

    Current = tonumber(Current)
    Max = tonumber(Max)

    if Current and Max and Current >= Max then
		if Config.DeployMode then
			Teleport()
		else
			Teleport(CFrame.new(5, 0, 0))
		end
    end
end

V:GetPropertyChangedSignal("Text"):Connect(CheckCarrying)

CheckCarrying()


MainWindow:Box("Speed Collect","0.1 to 1", function(SpeedBox)
    local Number = tonumber(SpeedBox)
    if Number then
        Config.SpeedCollect = math.clamp(Number, 0.05, 1)
    end
end)

MainWindow:Toggle("Auto Collect", function(state)
    Config.AutoCollect = state
end)

MainWindow:Toggle("Show Range", function(state)
    Config.ShowRange = state
    ConfigUpdate()
end)

MainWindow:Box("Speed Deploy","0.1 to 1", function(SpeedBox)
    local Number = tonumber(SpeedBox)
    if Number then
        Config.SpeedDeploy = math.clamp(Number, 0.05, 1)
    end
end)

MainWindow:Toggle("Deploy Mode", function(state)
    Config.DeployMode = state
end)

task.spawn(function()
    while true do
        if Config.AutoCollect then
            PullNearest()
        end
        task.wait(Config.SpeedCollect)
    end
end)