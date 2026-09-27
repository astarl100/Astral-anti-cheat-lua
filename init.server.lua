-- Services
local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Config + Modules
local Config  = require(script.Parent.config)
local Modules = script.Parent.modules

-- Astral table
local Astral = {
    Version = "1.0.0",
    Players = {},
}

-- Load detectors
local detectors = {}
for _, child in ipairs(Modules:GetChildren()) do
    if child:IsA("ModuleScript") then
        local ok, mod = pcall(require, child)
        if ok and type(mod) == "table" and mod.Run then
            table.insert(detectors, mod)
            print(("[Astral] Loaded: %s"):format(child.Name))
        else
            warn(("[Astral] Failed: %s"):format(child.Name))
        end
    end
end

-- AddStrike
function Astral:AddStrike(player, reason, weight)
    local p = self.Players[player]
    if not p then return end
    p.strikes[reason] = (p.strikes[reason] or 0) + (weight or 1)
    p.lastStrike = os.clock()

    warn(("[Astral] %s — %s (%d)"):format(player.Name, reason, p.strikes[reason]))

    if p.strikes[reason] >= (Config[reason .. "Strikes"] or 3) then
        self:Punish(player, reason)
    end
end

-- Punish
function Astral:Punish(player, reason)
    print(("[Astral] PUNISH %s — %s"):format(player.Name, reason))
    if Config.PunishAction == "kick" then
        player:Kick("Astral Anti-Cheat: " .. reason)
    elseif Config.PunishAction == "ban" then
        player:Kick("Astral: Banned — " .. reason)
    end
end

-- ReachDetect hook
local ReachDetect = require(Modules:WaitForChild("ReachDetect"))

Players.PlayerAdded:Connect(function(player)
    ReachDetect:_watch(player)
end)

for _, player in ipairs(Players:GetPlayers()) do
    ReachDetect:_watch(player)
end

-- RemoteGuard
local RemoteGuard = require(Modules:WaitForChild("RemoteGuard"))
RemoteGuard:Init()

RemoteGuard:Scan(ReplicatedStorage, {
    rate  = 10,
    burst = 20,
})

RemoteGuard:Scan(script.Parent, {
    rate  = 5,
    burst = 10,
})

-- Honeypot
local Honeypot = require(Modules:WaitForChild("Honeypot"))
Honeypot:Start()

-- MessageScript
local MessageScript = require(Modules:WaitForChild("MessageScript"))
MessageScript.Init(Astral)

-- Player events
Players.PlayerAdded:Connect(function(player)
    Astral.Players[player] = {
        strikes = {},
        lastStrike = 0,
        data = {
            lastPos   = nil,
            airStart  = nil,
            lastAim   = nil,
            lastCheck = 0,
        }
    }
end)

Players.PlayerRemoving:Connect(function(player)
    Astral.Players[player] = nil
end)

-- Heartbeat loop
RunService.Heartbeat:Connect(function(dt)
    for _, player in ipairs(Players:GetPlayers()) do
        local state = Astral.Players[player]
        if not state then continue end

        local char = player.Character
        if not char or not char:FindFirstChild("HumanoidRootPart") then continue end

        if os.clock() - state.lastStrike > Config.StrikeDecay then
            for k in pairs(state.strikes) do state.strikes[k] = 0 end
        end

        for _, detector in ipairs(detectors) do
            pcall(detector.Run, player, char, state, dt, Astral)
        end
    end
end)

-- Global export
_G.Astral = Astral
