local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/ericknick765/NikeHub/refs/heads/main/Library/LibraryBot.Lua"))()

--// Services
local Players = game:GetService("Players")

--// Player
local LocalPlayer = Players.LocalPlayer
local RunService = game:GetService("RunService")

local Config = {
    ["SpeedCollect"] = 0.1,
    ["AutoCollect"] = false,
    ["ShowRange"] = false,
    ["SpeedDeploy"] = 1,
    ["DeployMode"] = false
}
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

MainWindow:Box("Speed Collect","0.1 a 1", function(SpeedBox)
    local Number = tonumber(SpeedBox)
    if Number then
        Config.SpeedCollect = Number
    end
end)

MainWindow:Toggle("Auto Collect", function(state)
    Config.AutoCollect = state
end)

MainWindow:Toggle("Show Range", function(state)
    Config.ShowRange = state
    ConfigUpdate()
end)

MainWindow:Box("Speed Deploy","0.1 a 1", function(SpeedBox)
    local Number = tonumber(SpeedBox)
    if Number then
        Config.SpeedDeploy = Number
    end
end)

MainWindow:Toggle("Deploy Mode", function(state)
    Config.DeployMode = state
end)