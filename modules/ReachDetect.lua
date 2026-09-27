local Players    = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = {
    MaxReach       = 10,
    CheckCooldown  = 0.15,
    MinDamage      = 1,
    IgnoreTeams    = true,
    Debug          = false,
}

local ReachDetect = {
    _lastHealth = {},
    _lastCheck  = {},
}

local function getRoot(character)
    if not character then return nil end
    return character:FindFirstChild("HumanoidRootPart")
end

local function getHumanoid(character)
    if not character then return nil end
    return character:FindFirstChildOfClass("Humanoid")
end

function ReachDetect:_onHealthChanged(victim, attacker)
    if not victim or not attacker then return end
    if victim == attacker then return end

    local vChar = victim.Character
    local aChar = attacker.Character
    if not vChar or not aChar then return end

    local vRoot = getRoot(vChar)
    local aRoot = getRoot(aChar)
    if not vRoot or not aRoot then return end

    if Config.IgnoreTeams and victim.Team and attacker.Team then
        if victim.Team == attacker.Team then return end
    end

    local now = os.clock()
    local key = attacker.UserId .. ":" .. victim.UserId
    if self._lastCheck[key] and now - self._lastCheck[key] < Config.CheckCooldown then
        return
    end
    self._lastCheck[key] = now

    local dist = (vRoot.Position - aRoot.Position).Magnitude
    if dist > Config.MaxReach then
        if _G.Astral then
            _G.Astral:AddStrike(attacker, "Reach", 2)
        end
        if Config.Debug then
            warn(("[ReachDetect] %s -> %s : %.1f studs"):format(attacker.Name, victim.Name, dist))
        end
    end
end

function ReachDetect:_watch(player)
    local function bindCharacter(char)
        local hum = getHumanoid(char)
        if not hum then return end

        hum.HealthChanged:Connect(function(newHealth)
            local key = player.UserId
            local old = self._lastHealth[key]

            if old and newHealth < old then
                local attacker = hum:FindFirstChild("LastAttacker")
                if attacker and attacker:IsA("ObjectValue") and attacker.Value then
                    local attPlayer = Players:GetPlayerFromCharacter(attacker.Value.Parent)
                    if attPlayer then
                        self:_onHealthChanged(player, attPlayer)
                    end
                else
                    local creators = hum:GetAttribute("LastAttackerUserId")
                    if creators then
                        local attPlayer = Players:GetPlayerByUserId(creators)
                        if attPlayer then
                            self:_onHealthChanged(player, attPlayer)
                        end
                    end
                end
            end

            self._lastHealth[key] = newHealth
        end)
    end

    player.CharacterAdded:Connect(bindCharacter)
    if player.Character then
        bindCharacter(player.Character)
    end
end

function ReachDetect:Run(player, char, state, dt, Astral)
    local hum = getHumanoid(char)
    if not hum then return end
    self._lastHealth[player.UserId] = hum.Health
end

return ReachDetect
