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

local section20 = tab2.new_section('Teleports')

local section30 = tab3.new_section('Automatically')

-- // Sector \\ --
local sector = section.new_sector('OK', 'Left')
local sector1 = section.new_sector('BRUHHHH', 'Right')

local sector2 = section20.new_sector('Portal Teleport','Right')

local sector3 = section30.new_sector('Generator','Left')

--// Variables \\--

local SkillCheckGenerator = false
local EspKiller = false

local config{
    "EspKillerColor" = Color3.new(0.839216, 0.031373, 0.031373),
}

math.randomseed(os.time())
local opcoes = {5, 30}

local function UpdateEsp()
    if not EspKiller then return end
    
end

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

local ToggleEspKiller = sector.element('Toggle', 'Kill Aura', false, function(v)
    EspKiller = v
end)

ToggleEspKiller:add_color({Color = Color3.fromRGB(255, 0, 0)}, nil, function(v)
   config.EspKillerColor = v
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
