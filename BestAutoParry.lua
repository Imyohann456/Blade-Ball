if getgenv().executed then return end

local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local LocalPlayer = game:GetService("Players").LocalPlayer
local Balls = game:GetService("Workspace").Balls

local IsTargeted = false
local CanHit = false

function FindBall()
    local RealBall

    for i, v in pairs(Balls:GetChildren()) do
        if v:GetAttribute("realBall") == true then
            RealBall = v
        end
    end
    return RealBall
end
  
function IsTarget()
    local Ball = FindBall()
    
	
    if Ball and Ball:GetAttribute("target") == LocalPlayer.Name then
        return true
    end
    return false
end

function DetectBall()
    local Ball = FindBall()
    
  	if Ball then
        local BallVelocity = Ball.Velocity.Magnitude
        local BallPosition = Ball.Position
  
        local PlayerPosition = LocalPlayer.Character.HumanoidRootPart.Position
  
        local Distance = (BallPosition - PlayerPosition).Magnitude
        local PingAccountability = BallVelocity * (game.Stats.Network.ServerStatsItem["Data Ping"]:GetValue() / 1000)
  
        Distance -= PingAccountability
        Distance -= shared.config.adjustment
  
        local Hit = Distance / BallVelocity
  
        if Hit <= shared.config.hit_range then
            return true
        end
    end
    return false
end

function DeflectBall()
    if IsTargeted and DetectBall() then
        if shared.config.deflect_type == 'Key Press' then
            keypress(0x46)
        else
            ReplicatedStorage.Remotes.ParryButtonPress:Fire()
        end
    end
end

UserInputService.InputBegan:Connect(function(Input, IsTyping)
    if IsTyping then return end
    if shared.config.mode == 'Toggle' and Input.KeyCode == shared.config.keybind then
      CanHit = not CanHit
        if shared.config.notifications then
            game:GetService("StarterGui"):SetCore("SendNotification",{
                Title = "Blade Ball",
                Text = CanHit and 'Enabled!' or 'Disabled!',
            })
        end
    elseif shared.config.mode == 'Hold' and Input.KeyCode == shared.config.keybind and shared.config.notifications then
        game:GetService("StarterGui"):SetCore("SendNotification",{
            Title = "AutoParry",
            Text = 'True',
        })
    end
end)

UserInputService.InputEnded:Connect(function(Input, IsTyping)
    if IsTyping then return end
    if shared.config.mode == 'Hold' and Input.KeyCode == shared.config.keybind and shared.config.notifications then
        game:GetService("StarterGui"):SetCore("SendNotification",{
            Title = "AutoParry",
            Text = 'false',
        })
    end
end)

game:GetService('RunService').PostSimulation:Connect(function()
    IsTargeted = IsTarget()

    if shared.config.mode == 'Hold' and UserInputService:IsKeyDown(shared.config.keybind) then
        DeflectBall()
    elseif shared.config.mode == 'Toggle' and CanHit then
        DeflectBall()
    elseif shared.config.mode == 'Always' then
        DeflectBall()
    end
end)
local function getPlr()
    return game.Players.LocalPlayer
end

local function getPlrChar()
    local plrChar = getPlr().Character
    if plrChar then
        return plrChar
    end
end

local function getPlrRP()
    local plrRP = getPlrChar():FindFirstChild("HumanoidRootPart")
    if plrRP then
        return plrRP
    end
end

local function playerJump()
    pcall(function()
        game.Players.LocalPlayer.Character.Humanoid.Jump = true
    end)
end

local function getPlayersNumber()
    local alive = workspace:WaitForChild("Alive", 20):GetChildren()
    local playersNumber = 0
    for _, v in pairs(alive) do
        if v and v:FindFirstChild("Humanoid") and v.Humanoid.Health > 50 then
            playersNumber = playersNumber + 1
        end
    end
    return playersNumber
end

local function getProxyPlayer()
    local players = workspace:WaitForChild("Alive"):GetChildren()
    local distance = math.huge
    local plr = game.Players.LocalPlayer
    local plrRP = plr.Character:FindFirstChild("HumanoidRootPart")
    local player = nil

    for _, plr1 in pairs(players) do
        if plr1.Name ~= plr.Name and plrRP and plr1:FindFirstChild("HumanoidRootPart") and plr1:FindFirstChild("Humanoid") and plr1.Humanoid.Health > 50 then
            local magnitude = (plr1.HumanoidRootPart.Position - plrRP.Position).Magnitude
            if magnitude <= distance then
                distance = magnitude
                player = plr1
            end
        end
    end
    return player
end

local function clickButton()
    task.spawn(function()
        local plr = game.Players.LocalPlayer
        local plrFind = workspace.Alive:FindFirstChild(plr.Name)
        if plrFind then
            local plrs = 0
            for _, v in pairs(workspace:WaitForChild("Alive", 10):GetChildren()) do
                plrs = plrs + 1
            end
            if plrs > 1 then
                local args = {
                    [1] = 1.5,
                    [2] = CFrame.new(-254, 112, -119) * CFrame.Angles(-2, 0, 2),
                    [3] = {
                        ["2617721424"] = Vector3.new(-273, -724, -20),
                    },
                    [4] = {
                        [1] = 910,
                        [2] = 154,
                    },
                }
                game:GetService("ReplicatedStorage").Remotes.ParryAttempt:FireServer(unpack(args))
                task.wait()
            end
        end
    end)
end

task.spawn(function()
    while task.wait() do
        if getgenv().SpamClickA then
            clickButton()
        end
    end
end)

-- Spam Detection Function

local function detectSpam()
    local balls = workspace:WaitForChild("Balls", 20)

    local oldPos = Vector3.new()
    local oldTick1 = tick()

    local oldBall = balls
    local targetPlayer = ""
    local spamNum = 0
    local ballSpeed = 0
    local ballDistance = 0

    task.spawn(function()
        local oldTick = tick()
        local oldPos = Vector3.new()
        while getgenv().DetectSpam do
            task.wait()
            local plrRP = getPlrRP()
            local ball = balls:FindFirstChildOfClass("Part")
            if plrRP and ball then
                ballDistance = (plrRP.Position - ball.Position).Magnitude
                ballSpeed = (oldPos - ball.Position).Magnitude
                if tick() - oldTick >= 1 / 60 then
                    oldTick = tick()
                    oldPos = ball.Position
                end
            end
        end
    end)

    while getgenv().DetectSpam do
        task.wait()
        local ball = balls:FindFirstChildOfClass("Part")
        local plrRP = getPlrRP()
        local proxyPlayer = getProxyPlayer()

        if not ball then
            getgenv().SpamClickA = false
        end

        if ball and ball:GetAttribute("realBall") and oldBall ~= ball then
            ball.Changed:Connect(function()
                task.wait()
                local ball = balls:FindFirstChildOfClass("Part")

                if ball then
                    targetPlayer = ball:GetAttribute("target")

                    if proxyPlayer and targetPlayer == proxyPlayer.Name or getPlr() and targetPlayer == getPlr().Name then
                        spamNum = spamNum + 2
                    else
                        spamNum = 0
                    end

                    local args = proxyPlayer and proxyPlayer:FindFirstChild("HumanoidRootPart")
                    local HL1 = proxyPlayer and proxyPlayer:FindFirstChild("Highlight")
                    local HL2 = getPlrChar() and getPlrChar():FindFirstChild("Highlight")

                    if plrRP and HL1 and args or plrRP and HL2 and args then
                        local distancePlayer = (proxyPlayer.HumanoidRootPart.Position - plrRP.Position).Magnitude
                        local distanceBall = (ball.Position - plrRP.Position).Magnitude

                        if getPlayersNumber() < 5 then
                            if distancePlayer <= 30 and distanceBall <= 35 and spamNum >= 4 then
                                getgenv().SpamClickA = true
                            else
                                getgenv().SpamClickA = false
                            end
                        else
                            if distancePlayer <= 30 and distanceBall <= 35 and spamNum >= 6 then
                                getgenv().SpamClickA = true
                            else
                                getgenv().SpamClickA = false
                            end
                        end
                    else
                        getgenv().SpamClickA = false
                    end
                end
            end)
            oldBall = ball
        end
    end
end

-- Start the spam detection
getgenv().DetectSpam = true
detectSpam()
getgenv().executed = true