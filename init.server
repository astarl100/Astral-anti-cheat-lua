local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config  = require(script.Parent.config)
local Modules = script.Parent.modules

local Astral = {
    Version = "1.0.0",
    Players = {},
}

local detectors = {}
for _, child in ipairs(Modules:GetChildren()) do
    if child:IsA("ModuleScript") then
        local ok, mod = pcall(require, child)
        if ok and type(mod) == "table" and mod.Run then
            table.insert(detectors, mod)
            print(("[Astral] Загружен модуль: %s"):format(child.Name))
        else
            warn(("[Astral] Не удалось загрузить %s"):format(child.Name))
        end
    end
end

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

function Astral:Punish(player, reason)
    print(("[Astral] PUNISH %s — %s"):format(player.Name, reason))
    if Config.PunishAction == "kick" then
        player:Kick("Astral Anti-Cheat: " .. reason)
    elseif Config.PunishAction == "ban" then
        player:Kick("Astral: Banned — " .. reason)
    end
end

Players.PlayerAdded:Connect(function(player)
    Astral.Players[player] = {
        strikes = {},
        lastStrike = 0,
        data = {
            lastPos = nil,
            airStart = nil,
            lastAim = nil,
            lastCheck = 0,
        }
    }
end)

Players.PlayerRemoving:Connect(function(player)
    Astral.Players[player] = nil
end)

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

_G.Astral = Astral
