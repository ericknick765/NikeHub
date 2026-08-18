local library = loadstring(game:HttpGet('https://raw.githubusercontent.com/nickexeqq-sketch/SailorPiecePro/refs/heads/main/library.lua'))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local PathfindingService = game:GetService("PathfindingService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ActiveGenerators = {}
local LastUpdateTick = 0
local LastFullESPRefresh = 0

local TouchID = 8822
local ActionPath = "Survivor-mob.Controls.action.check"
local HeartbeatConnection = nil
local VisibilityConnection = nil
local IndicatorGui = nil

-- // Window \\ --
local window = library.new('Nike Hub', 'leadmarker')

-- // Tabs \\ --
local tab = window.new_tab('rbxassetid://135134402309970')
local tab1 = window.new_tab('rbxassetid://86376494832390') 
local tab2 = window.new_tab('rbxassetid://118454203190440')
local tab3 = window.new_tab('rbxassetid://129505109777226')

-- // Sections \\ --
local section = tab.new_section('Bruh XD')
local section2 = tab.new_section(':DDD HI')
local section3 = tab.new_section('Boss')

local section10 = tab1.new_section('Esps')

local section20 = tab2.new_section('Teleports')

local section30 = tab3.new_section('Automatically')

-- // Sector \\ --
local sector = section.new_sector('OK', 'Left')
local sector1 = section.new_sector('BRUHHHH', 'Right')

local sector10 = section10.new_sector('Killer Esp', 'Left')
local sector11 = section10.new_sector('Survivors Esp', 'Left')

local sector2 = section20.new_sector('Portal Teleport','Right')

local sector3 = section30.new_sector('Generator','Left')

--// Variables \\--

local SkillCheckGenerator = false

local ESP_NAME = "NIKE_ESP"

local EspKiller = false
local EspSurvivors = false
local EspGenerators = false

local config = {
    ["EspKillerColor"] = {
       ["Color"] = Color3.fromRGB(255, 0, 0)
    },
    ["SurvivorsEspColor"] = {
        ["Color"] = Color3.fromRGB(218, 255, 11)
    },
    ["GeneratorsEspColor"] = {
        ["Color"] = Color3.fromRGB(0, 119, 255)
    }
}

math.randomseed(os.time())
local opcoes = {5, 30}


local function GetEspColor(action)
    if action == "killer" then
        return config.EspKillerColor.Color

    elseif action == "survival" then
        return config.SurvivorsEspColor.Color

    elseif action == "generator" then
        return config.GeneratorsEspColor.Color
    end

    return nil
end

local function RemoveEsp(character)
    if not character then
        return
    end

    local esp = character:FindFirstChild(ESP_NAME)

    if esp and esp:IsA("Highlight") then
        esp:Destroy()
    end
end

local function AddEsp(character, action)
    if not character or not character:IsA("Model") then
        return
    end

    local color = GetEspColor(action)

    if not color then
        return
    end

    local esp = character:FindFirstChild(ESP_NAME)

    -- Já existe
    if esp and esp:IsA("Highlight") then
        esp.FillColor = color
        esp:SetAttribute("EspType", action)
        return
    end

    local newEsp = Instance.new("Highlight")

    newEsp.Name = ESP_NAME
    newEsp.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop

    newEsp.FillColor = color
    newEsp.FillTransparency = 0.5

    newEsp.OutlineColor = Color3.fromRGB(255, 255, 255)
    newEsp.OutlineTransparency = 0.9

    newEsp:SetAttribute("NIKE", true)
    newEsp:SetAttribute("EspType", action)

    newEsp.Parent = character
end

local function UpdateEsp()
    local Killer

    -- Procura o Killer atual
    for _, player in Players:GetPlayers() do
        if player.Team and player.Team.Name == "Killer" then
            Killer = player
            break
        end
    end


    for _, player in Players:GetPlayers() do
        local character = player.Character

        if not character then
            continue
        end

        local esp = character:FindFirstChild(ESP_NAME)
        local espType = esp and esp:GetAttribute("EspType")


        -- =========================
        -- KILLER
        -- =========================

        if player == Killer
            and player ~= LocalPlayer
            and EspKiller then

            AddEsp(character, "killer")

        elseif espType == "killer" then

            RemoveEsp(character)
        end


        -- =========================
        -- SURVIVOR
        -- =========================

        if player ~= LocalPlayer
            and player.Team
            and player.Team.Name == "Survivors"
            and EspSurvivors then

            AddEsp(character, "survival")

        elseif espType == "survival" then

            RemoveEsp(character)
        end
    end
end

local function UpdateEspColors()
    for _, player in Players:GetPlayers() do
        local character = player.Character

        if not character then
            continue
        end

        local esp = character:FindFirstChild(ESP_NAME)

        if not esp or not esp:IsA("Highlight") then
            continue
        end

        local espType = esp:GetAttribute("EspType")

        if espType == "killer" then
            esp.FillColor = config.EspKillerColor.Color

        elseif espType == "survival" then
            esp.FillColor = config.SurvivorsEspColor.Color

        elseif espType == "generator" then
            esp.FillColor = config.GeneratorsEspColor.Color
        end
    end
end

local function RemoveAllEsp()
    for _, player in Players:GetPlayers() do
        if player.Character then
            RemoveEsp(player.Character)
        end
    end
end

local function SetupPlayer(player)
    player.CharacterAdded:Connect(function(character)
        character:WaitForChild("Humanoid", 5)
        task.wait(0.1)
        UpdateEsp()
    end)
    player:GetPropertyChangedSignal("Team"):Connect(function()
        UpdateEsp()
    end)
end

for _, player in Players:GetPlayers() do
    SetupPlayer(player)
end

Players.PlayerAdded:Connect(function(player)
    SetupPlayer(player)
    UpdateEsp()
end)

Players.PlayerRemoving:Connect(function()
    UpdateEsp()
end)

local function GetActionTarget()
    local current = PlayerGui
    for segment in string.gmatch(ActionPath, "[^%.]+") do current = current and current:FindFirstChild(segment) end
    return current
end

local function WaitForActionTarget(timeout)
    timeout = timeout or 1 -- segundos
    local interval = 0.05
    local attempts = math.floor(timeout / interval)

    local b = GetActionTarget()
    local tries = 0

    while (not b or not b:IsA("GuiObject")) and tries < attempts do
        task.wait(interval)
        b = GetActionTarget()
        tries += 1
    end

    if b and b:IsA("GuiObject") then
        return b
    end

    return nil
end

local function TriggerMobileButton(timeout)
    local b = WaitForActionTarget(timeout)

    if not b then
        return false
    end

    local p, s, i = b.AbsolutePosition, b.AbsoluteSize, GuiService:GetGuiInset()
    local cx, cy = p.X + (s.X / 2) + i.X, p.Y + (s.Y / 2) + i.Y

    pcall(function()
        VirtualInputManager:SendTouchEvent(TouchID, 0, cx, cy)
        task.wait(0.01)
        VirtualInputManager:SendTouchEvent(TouchID, 2, cx, cy)
    end)

    return true
end

local function AutoSkillCheck()
    task.spawn(function()
        local prompt = PlayerGui:WaitForChild("SkillCheckPromptGui", 10)
        local check = prompt and prompt:WaitForChild("Check", 10)
        if not check then return end
        local line, goal = check:WaitForChild("Line"), check:WaitForChild("Goal")

        local triggered = false
        local lastGoal = goal.Rotation

        local OFFSET = opcoes[math.random(1, 2)]

        if HeartbeatConnection then HeartbeatConnection:Disconnect() end
        HeartbeatConnection = RunService.Heartbeat:Connect(function()
            if not (LocalPlayer.Team and LocalPlayer.Team.Name == "Survivors" and check.Visible) then
                return
            end

            if math.abs(goal.Rotation - lastGoal) > 1 then
                lastGoal = goal.Rotation
                triggered = false
            end

            if triggered then return end

            local lr, gr = line.Rotation % 360, (goal.Rotation + OFFSET) % 360
            local ss, se = (gr + 101) % 360, (gr + 115) % 360
            local inZone = (ss > se and (lr >= ss or lr <= se)) or (lr >= ss and lr <= se)

            if inZone then
                triggered = true
                TriggerMobileButton(0.1)
            end
            
        end)

        if VisibilityConnection then VisibilityConnection:Disconnect() end
        VisibilityConnection = check:GetPropertyChangedSignal("Visible"):Connect(function()
            if not check.Visible and HeartbeatConnection then
                HeartbeatConnection:Disconnect()
                HeartbeatConnection = nil
            end
        end)
    end)
end

local function getClosestGen()
    local Map = workspace:FindFirstChild("Map")
    local MapGen = nil

    if Map then
        for _, child in ipairs(Map:GetChildren()) do
            if child:IsA("Folder") and child.Name:lower():find("generator") and #child:GetChildren() > 0 then
                MapGen = child
                break
            end
        end
    end

    local character = LocalPlayer.Character
    local root = character and character:FindFirstChild("HumanoidRootPart")

    local closestGen = nil
    local closestAction = nil
    local closestDistance = math.huge

    if not MapGen or not root then
        return nil, nil
    end


    for _, model in ipairs(MapGen:GetChildren()) do
        if not model:IsA("Model") then
            continue
        end

        local progress = model:GetAttribute("RepairProgress")

        if progress ~= nil and progress >= 100 then
            continue
        end

        for _, point in ipairs(model:GetDescendants()) do
            if not point.Name:lower():find("generatorpoint") then
                continue
            end

            local repairing = point:GetAttribute("IsReparing")

            if repairing == true then
                continue
            end

            local position

            if point:IsA("BasePart") then
                position = point.Position
            elseif point:IsA("Attachment") then
                position = point.WorldPosition
            end
            if position then
                local distance = (root.Position - position).Magnitude

                if distance < closestDistance then
                    closestDistance = distance
                    closestGen = model
                    closestAction = point
                end
            end
        end -- fecha loop de point
    end -- fecha loop de model

    return closestGen, closestAction -- agora fora dos dois loops
end

local function filterWaypoints(waypoints)
    if #waypoints <= 2 then
        return waypoints
    end

    local filtered = {waypoints[1]}

    for i = 2, #waypoints - 1 do
        local prev = filtered[#filtered].Position
        local curr = waypoints[i].Position
        local nextPoint = waypoints[i + 1].Position

        local dir1 = (curr - prev).Unit
        local dir2 = (nextPoint - curr).Unit

        -- se a direção muda pouco, pula esse waypoint (é quase uma linha reta)
        if dir1:Dot(dir2) < 0.98 then
            table.insert(filtered, waypoints[i])
        end
    end

    table.insert(filtered, waypoints[#waypoints])

    return filtered
end


local function MoveToPosition(character, targetPosition, maxAttempts, callback)
    maxAttempts = maxAttempts or 3

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")

    if not humanoid or not root then
        if callback then
            callback(false)
        end
        return false
    end

    for attempt = 1, maxAttempts do
        if not character.Parent or humanoid.Health <= 0 then
            if callback then
                callback(false)
            end
            return false
        end

        local path = PathfindingService:CreatePath({
            AgentRadius = 3,
            AgentHeight = 5,
            AgentCanJump = false,
            AgentCanClimb = false,
            WaypointSpacing = 5,
        })

        local success, err = pcall(function()
            path:ComputeAsync(root.Position, targetPosition)
        end)

        if not success then
            warn("🔴 Erro no Pathfinding:", err)
            if callback then
                callback(false)
            end
            return false
        end

        if path.Status ~= Enum.PathStatus.Success then
            task.wait(0.2)
            continue
        end

        local waypoints = filterWaypoints(path:GetWaypoints())
        local blocked = false

        local blockedConnection = path.Blocked:Connect(function()
            blocked = true
        end)

        local failed = false

        for i, waypoint in ipairs(waypoints) do

            if not character.Parent or humanoid.Health <= 0 then
                failed = true
                break
            end

            if blocked then
                failed = true
                break
            end

            humanoid:MoveTo(waypoint.Position)

            local reachedThreshold = 5
            local startTime = os.clock()
            local timeout = 3

            while (root.Position - waypoint.Position).Magnitude > reachedThreshold do
                if not character.Parent or humanoid.Health <= 0 then
                    failed = true
                    break
                end

                if blocked then
                    failed = true
                    break
                end

                if os.clock() - startTime > timeout then
                    failed = true
                    break
                end

                task.wait()
            end

            if failed then
                break
            end
        end

        blockedConnection:Disconnect()

        if not failed then
            if callback then
                callback(true)
            end
            return true
        end

        task.wait(0.1)
    end

    if callback then
        callback(false)
    end
    
    return false
end

-- // Elements \\ -- (Type, Name, State, Callback)

local button = sector3.element('Button', 'Walk to Generator', nil, function()
    local generator, action = getClosestGen()

    if not action then
        warn("Nenhum gerador disponível encontrado")
        return
    end

    local targetPosition
    if action:IsA("BasePart") then
        targetPosition = action.Position
    elseif action:IsA("Attachment") then
        targetPosition = action.WorldPosition
    end

    if targetPosition then
        MoveToPosition(LocalPlayer.Character, targetPosition, 3, function(success)
            if success then
                TriggerMobileButton(1)
            end
        end)
    end
end)

local ToggleEspKiller = sector10.element('Toggle', 'Esp Killer', false, function(v)
    EspKiller = v
    UpdateEsp()
end)

ToggleEspKiller:add_color({Color = config.EspKillerColor.Color}, nil, function(v)
    config.EspKillerColor.Color = v
    UpdateEspColors()
end)

local ToggleEspSurvivors = sector11.element('Toggle', 'Esp Survivors', false, function(v)
    EspSurvivors = v
    UpdateEsp()
end)

ToggleEspSurvivors:add_color({Color = config.SurvivorsEspColor.Color}, nil, function(v)
    config.SurvivorsEspColor.Color = v
    UpdateEspColors()
end)

local button = sector3.element('Button', 'Walk Test', nil, function()
    local Test = workspace:WaitForChild("ericknick765")

    MoveToPosition(LocalPlayer.Character, Test.HumanoidRootPart.Position)
end)

local ToggleAutoSkillCheck = sector3.element('Toggle', 'Auto Skill Check', false, function(v)
    SkillCheckGenerator = v
end)



task.spawn(function()
    while task.wait(0.2) do
        if SkillCheckGenerator then
            AutoSkillCheck()
        end
    end
end)
