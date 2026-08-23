local library = loadstring(game:HttpGet('https://raw.githubusercontent.com/ericknick765/NikeHub/refs/heads/main/Library/Library.lua'))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualInputManager = game:GetService("VirtualInputManager")
local PathfindingService = game:GetService("PathfindingService")
local CoreGui = game:GetService("CoreGui")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")
local Teams = game:GetService("Teams")
local Workspace = game:GetService("Workspace")

local SessionName = "NIKE_HUB_SESSION"

local OldSession = getgenv()[SessionName]

if OldSession and OldSession.Destroy then
    OldSession:Destroy()
end

local Session = {
    Connections = {},
    Running = true,
}

getgenv()[SessionName] = Session


function Session:Connect(signal, callback)
    if not self.Running then
        return
    end

    local connection = signal:Connect(callback)

    table.insert(self.Connections, connection)

    return connection
end


function Session:Destroy()

    if not self.Running then
        return
    end

    print("Encerrando Nike Hub antigo...")

    self.Running = false

    for _, connection in ipairs(self.Connections) do
        if connection and connection.Connected then
            connection:Disconnect()
        end
    end

    table.clear(self.Connections)

    local oldGui = CoreGui:FindFirstChild("NIKE_HUB")
    if oldGui then
        oldGui:Destroy()
    end

    local oldBtn = CoreGui:FindFirstChild("MobileToggleGui")
    if oldBtn then
        oldBtn:Destroy()
    end

    if getgenv()[SessionName] == self then
        getgenv()[SessionName] = nil
    end

    print("Nike Hub antigo encerrado!")
end

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")
local ActiveGenerators = {}
local LastUpdateTick = 0
local LastFullESPRefresh = 0

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

local sector20 = section20.new_sector('Portal Teleport','Right')

local sector30 = section30.new_sector('Generator','Left')
local sector31 = section30.new_sector('Auto Parry','Left')

--// Variables \\--

local TouchID = 8822
local ActionPath = "Survivor-mob.Controls.action.check"
local UseItemPath ="Survivor-mob.Controls.Gui-mob"
local HeartbeatConnection = nil
local VisibilityConnection = nil
local IndicatorGui = nil

local SkillCheckGenerator = false

local ESP_NAME = "NIKE_ESP"

local EspKiller = false
local EspSurvivors = false
local EspGenerators = false

local Killer 

local config = {
    EspKillerColor = {
        Color = Color3.fromRGB(255, 0, 0)
    },

    SurvivorsEspColor = {
        Color = Color3.fromRGB(218, 255, 11)
    },

    GeneratorsEspColor = {
        Color = Color3.fromRGB(0, 119, 255)
    },
    AutoParry = {
        Distance = 4,
        ParryDelay = 0,
        AutoParry = false,
        HitboxVisible = false
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
    newEsp.FillTransparency = 0.3

    newEsp.OutlineColor = Color3.fromRGB(255, 255, 255)
    newEsp.OutlineTransparency = 0.9

    newEsp:SetAttribute("NIKE", true)
    newEsp:SetAttribute("EspType", action)

    newEsp.Parent = character
end

local function UpdateEsp()

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

        local wantedType

        if player ~= LocalPlayer then
            if EspKiller and player == Killer then
                wantedType = "killer"

            elseif EspSurvivors
                and player.Team
                and player.Team.Name == "Survivors" then

                wantedType = "survival"
            end
        end

        local esp = character:FindFirstChild(ESP_NAME)

        if wantedType then
            AddEsp(character, wantedType)

        elseif esp then
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
    Session:Connect(player.CharacterAdded, function(character)
    character:WaitForChild("Humanoid", 5)

    if not Session.Running then
        return
    end
    task.wait(0.1)
    UpdateEsp()

    end)

    Session:Connect(
    player:GetPropertyChangedSignal("Team"),
    function()
        if not Session.Running then
            return
        end

        UpdateEsp()
    end)
    
end

for _, player in Players:GetPlayers() do
    SetupPlayer(player)
end


Session:Connect(Players.PlayerAdded, function(player)
    SetupPlayer(player)
    UpdateEsp()
end)

Session:Connect(Players.PlayerRemoving, function(player)
    UpdateEsp()
end)

local function GetActionTarget()
    local current = PlayerGui
    for segment in string.gmatch(ActionPath, "[^%.]+") do
        current = current and current:FindFirstChild(segment)
    end
    return current
end

local function GetUseItemTarget()
    local current = PlayerGui
    for segment in string.gmatch(UseItemPath, "[^%.]+") do
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

local function WaitForUseItemTarget(timeout)
    timeout = timeout or 1
    local interval = 0.05
    local attempts = math.floor(timeout / interval)
    local target = GetUseItemTarget()
    local tries = 0
    while
        (not target or not target:IsA("GuiObject"))
        and tries < attempts
    do
        task.wait(interval)
        target = GetUseItemTarget()
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

local function UseItemMobileButton(timeout)
    local button = WaitForUseItemTarget(timeout)

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

local function DisconnectConnection(connection)
    if connection and connection.Connected then
        connection:Disconnect()
    end
end

local function AutoSkillCheck()
    if not Session.Running then
        return
    end

    local prompt = PlayerGui:FindFirstChild("SkillCheckPromptGui")
    if not prompt then
        return
    end

    local check = prompt:FindFirstChild("Check")
    if not check then
        return
    end

    local line = check:FindFirstChild("Line")
    local goal = check:FindFirstChild("Goal")

    if not line or not goal then
        return
    end

    local triggered = false
    local lastGoal = goal.Rotation

    local OFFSET = opcoes[math.random(1, 2)]

    -- Remove Heartbeat anterior
    if HeartbeatConnection then
        DisconnectConnection(HeartbeatConnection)
        HeartbeatConnection = nil
    end

    HeartbeatConnection = Session:Connect(
        RunService.Heartbeat,
        function()

            if not Session.Running then
                return
            end

            if not (
                LocalPlayer.Team
                and LocalPlayer.Team.Name == "Survivors"
                and check.Parent
                and check.Visible
            ) then
                return
            end


            if math.abs(goal.Rotation - lastGoal) > 1 then
                lastGoal = goal.Rotation
                triggered = false
            end

            if triggered then
                return
            end

            local lr = line.Rotation % 360
            local gr = (goal.Rotation + OFFSET) % 360

            local ss = (gr + 101) % 360
            local se = (gr + 115) % 360

            local inZone

            if ss > se then
                inZone = lr >= ss or lr <= se
            else
                inZone = lr >= ss and lr <= se
            end

            if inZone then
                triggered = true

                TriggerMobileButton(0.1)
            end
        end
    )

    if VisibilityConnection then
        VisibilityConnection:Disconnect()
        VisibilityConnection = nil
    end

    VisibilityConnection = Session:Connect(
        check:GetPropertyChangedSignal("Visible"),
        function()

            if not check.Visible then
                DisconnectConnection(HeartbeatConnection)
                HeartbeatConnection = nil
            end
        end
    )
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

local function IsKillerHitbox(part: Instance, userId: number): boolean
    return string.find(part.Name, tostring(userId), 1, true) ~= nil
end

local function CheckHitKiller(part: BasePart)
    local character = LocalPlayer.Character
    if not character then
        return
    end

    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then
        return
    end

    if config.AutoParry.HitboxVisible then
        part.Transparency = 0
        part.Color = Color3.fromRGB(255, 0, 0)
    end

    local distance = (hrp.Position - part.Position).Magnitude
    
    print("Player:", hrp.Position)
    print("Hitbox:", part.Position)
    print("Distance:", (hrp.Position - part.Position).Magnitude)

    if distance > config.AutoParry.Distance then
        return
    end

    task.delay(config.AutoParry.ParryDelay, function()
        UseItemMobileButton(0.1)
    end)
end

local function ParrySetup()
    if not Killer then
        return
    end

    if Killer:GetAttribute("AutoParryMonitoring") then
        return
    end

    local userId = Killer.UserId

    Killer:SetAttribute("AutoParryMonitoring", true)

    local connections = {}

    connections.ChildAdded = Workspace.ChildAdded:Connect(function(instance)
        
        if not instance:IsA("BasePart") then
            return
        end

        if not IsKillerHitbox(instance, userId) then
            return
        end
        print(instance)
        CheckHitKiller(instance)
    end)

    connections.TeamChanged = Killer:GetPropertyChangedSignal("Team"):Connect(function()
        for _, connection in pairs(connections) do
            connection:Disconnect()
        end
        Killer:SetAttribute("AutoParryMonitoring", false)
    end)

    connections.AncestryChanged = Killer.AncestryChanged:Connect(function(_, parent)
        if parent then
            return
        end
        for _, connection in pairs(connections) do
            connection:Disconnect()
        end
        Killer:SetAttribute("AutoParryMonitoring", false)
    end)
end

local function ClickHold()
    local Bool = Killer:GetAttribute("clickhold")
    print(Bool)
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

local button = sector30.element('Button', 'Walk to Generator', nil, function()
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
    config.EspKillerColor.Color = v.Color
    UpdateEspColors()
end)

local ToggleEspSurvivors = sector11.element('Toggle', 'Esp Survivors', false, function(v)
    EspSurvivors = v
    UpdateEsp()
end)

ToggleEspSurvivors:add_color({Color = config.SurvivorsEspColor.Color}, nil, function(v)
    config.SurvivorsEspColor.Color = v.Color
    UpdateEspColors()
end)

local button = sector30.element('Button', 'Walk Test', nil, function()
    local Test = workspace:WaitForChild("ericknick765")
    MoveToPosition(LocalPlayer.Character, Test.HumanoidRootPart.Position)
end)

local ToggleAutoSkillCheck = sector30.element('Toggle', 'Auto Skill Check', false, function(v)
    SkillCheckGenerator = v
end)

local buttonParry = sector31.element('Button', 'Parry Test', nil, function()
    UseItemMobileButton(0.1)
end)

local SliderDistanceAutoParry = sector31.element('Slider', 'Distance', {default = {min = 1, max = 5, default = 4}}, function(v)
   config.AutoParry.Distance = v
end)

local SliderDelayAutoParry = sector31.element('Slider', 'Delay', {default = {min = 0, max = 1, default = 0.1}}, function(v)
   config.AutoParry.ParryDelay = v
end)

local ToggleAutoParry = sector31.element('Toggle', 'Auto Parry', false, function(v)
    config.AutoParry.AutoParry = v
end)

local ToggleAutoParryHitBox = sector31.element('Toggle', 'Killer HitBox', false, function(v)
    config.AutoParry.HitboxVisible = v
end)


task.spawn(function()
    while Session.Running do
        task.wait(0.2)

        if not Session.Running then
            break
        end

        if SkillCheckGenerator then
            AutoSkillCheck()
        end
        if config.AutoParry.AutoParry then
            ParrySetup()
        end
    end
end)
