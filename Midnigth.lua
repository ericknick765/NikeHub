local library = loadstring(game:HttpGet("https://raw.githubusercontent.com/nickexeqq-sketch/Test/refs/heads/main/Library.lua"))()

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local VirtualUser = game:GetService("VirtualUser")

local player = Players.LocalPlayer

local mainWindow = library:Window("Auto Race Start Bot")

local SavedRemotes = {}
local Waiting = false
local AutoStart = false
local LastDetect = {}
local TargetPlayer
local WaitPlayer 

-- Hook
local mt = getrawmetatable(game)
local old = mt.__namecall

setreadonly(mt, false)

mt.__namecall = newcclosure(function(self, ...)
    
    local args = {...}
    local method = getnamecallmethod()

    if method == "FireServer" and Waiting then
        
        local alreadySaved = false

        for _, data in ipairs(SavedRemotes) do
            
            if data.Remote == self then
                alreadySaved = true
                break
            end
        end

        if not alreadySaved then
            
            table.insert(SavedRemotes, {
                Remote = self,
                Args = args
            })

            print("\n======= REMOTE "..#SavedRemotes.." SALVO =======")
            print("Nome:", self.Name)
            print("Path:", self:GetFullName())

            for i, v in ipairs(args) do
                print("Arg", i, v)
            end

            print("================================")

            library:Notify(
                "Remote "..#SavedRemotes.." salvo!",
                3
            )
        end

        if #SavedRemotes >= 2 then
            
            Waiting = false

            library:Notify(
                "2 remotes configurados com sucesso!",
                5
            )
        end
    end

    return old(self, ...)
end)

local function MainStart()
       task.wait(WaitPlayer)
        if #SavedRemotes >= 2 then
                    
                    print("Executando remotes...")

                    for i, data in ipairs(SavedRemotes) do
                        
                        pcall(function()
                            data.Remote:FireServer(unpack(data.Args))
                        end)

                        print("Remote "..i.." executado")

                        task.wait(1)
                    end
                else
                    
                    library:Notify(
                        "Configure os remotes primeiro!",
                        4
                    )
                end
          task.wait(15)
end

local function PlayerDetected(player)

    local currentTime = tick()

    if LastDetect[player.Name] then
        
        local seconds = math.floor(currentTime - LastDetect[player.Name])

        library:Notify(
            player.Name.." apareceu novamente após "..seconds.."s",
            5
        )
    else
        
        library:Notify(
            player.Name.." entrou no servidor!",
            5
        )
    end

    LastDetect[player.Name] = currentTime

    MainStart()
end

player.Idled:Connect(function()
    
    VirtualUser:CaptureController()
    VirtualUser:ClickButton2(Vector2.new())

end)

for _, player in ipairs(Players:GetPlayers()) do
    
    if player.Name == TargetPlayer then
        
        PlayerDetected(player)
    end
end


Players.PlayerAdded:Connect(function(player)
    
    if player.Name == TargetPlayer then
        
        PlayerDetected(player)
    end
end)


mainWindow:Toggle("Auto-Start", function(state)

    AutoStart = state

    if state then
        
        library:Notify(
            "Auto-Start ativado!",
            3
        )

        task.spawn(function()

            while AutoStart do
                  MainStart()
            end
        end)
    else
        
        library:Notify(
            "Auto-Start desativado!",
            3
        )
    end
end)

mainWindow:Box("Player Finder", "Name", function(BoxPlayer)

    TargetPlayer = tostring(BoxPlayer)

    library:Notify(
        "Agora detectando: "..TargetPlayer,
        5
    )
end)


mainWindow:Box("Wait Load Player", "Time", function(WaitV)

    WaitPlayer = tonumber(WaitV)
end)


mainWindow:Button("configure remotes", function()
    
    table.clear(SavedRemotes)

    Waiting = true

    library:Notify(
        "Esperando 2 remotes...",
        5
    )

    print("Faça a ação da corrida manualmente.")
end)
