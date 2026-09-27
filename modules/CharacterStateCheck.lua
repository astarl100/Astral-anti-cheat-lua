local Players = game:GetService("Players")

local Config = {
    RequiredParts = {
        "Head",
        "HumanoidRootPart",
        "Torso",
        "UpperTorso",
        "LowerTorso",
        "LeftLeg",
        "RightLeg",
        "LeftFoot",
        "RightFoot",
    },
    CheckRate    = 0.5,
    MaxMissing   = 1,
    Debug        = false,
}

local CharacterState = {
    _lastCheck = {},
}

local function isR15(char)
    return char:FindFirstChild("UpperTorso") ~= nil
end

function CharacterState:_checkParts(player, char)
    local missing = 0
    local missingNames = {}

    for _, partName in ipairs(Config.RequiredParts) do
        if not char:FindFirstChild(partName) then
            if partName == "Torso" and isR15(char) then
                continue
            end
            if (partName == "UpperTorso" or partName == "LowerTorso") and not isR15(char) then
                continue
            end

            missing = missing + 1
            table.insert(missingNames, partName)
        end
    end

    if missing >= Config.MaxMissing then
        if _G.Astral then
            _G.Astral:AddStrike(player, "CharacterState", 3)
        end
        if Config.Debug then
            warn(("[CharacterState] %s missing: %s"):format(player.Name, table.concat(missingNames, ", ")))
        end
    end
end

function CharacterState:Run(player, char, state, dt, Astral)
    local now = os.clock()
    if self._lastCheck[player.UserId] and now - self._lastCheck[player.UserId] < Config.CheckRate then
        return
    end
    self._lastCheck[player.UserId] = now

    self:_checkParts(player, char)
end

return CharacterState
