local Players           = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService        = game:GetService("RunService")

local player = Players.LocalPlayer

local SECRET          = "Astral_S3cr3t_K3y_2026_x9"
local HEARTBEAT_RATE  = 3

local remote = ReplicatedStorage:WaitForChild("AstralHybrid", 30)
if not remote then return end

local function hash(str)
    local h = 0
    for i = 1, #str do
        h = (h * 31 + string.byte(str, i)) % 2147483647
    end
    return h
end

local function getFps()
    local ok, fps = pcall(function()
        return workspace:GetRealPhysicsFPS()
    end)
    if ok and type(fps) == "number" then
        return math.floor(fps)
    end
    return 60
end

local function getCoreGuiCount()
    local ok, count = pcall(function()
        local CoreGui = game:GetService("CoreGui")
        return #CoreGui:GetChildren()
    end)
    if ok and type(count) == "number" then
        return count
    end
    return 0
end

remote:FireServer("hello")

task.spawn(function()
    while task.wait(HEARTBEAT_RATE) do
        if not player.Parent then break end
        remote:FireServer("hb", tick(), getFps(), getCoreGuiCount())
    end
end)

remote.OnClientEvent:Connect(function(msgType, nonce)
    if msgType ~= "challenge" then return end
    if type(nonce) ~= "number" then return end

    local response = hash(SECRET .. tostring(nonce))
    remote:FireServer("response", nonce, response)
end)
