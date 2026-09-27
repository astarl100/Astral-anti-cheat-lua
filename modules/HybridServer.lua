local Players           = game:GetService("Players")
local RunService        = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(game.ServerScriptService.Astral.modules.HybridConfig)

local HybridServer = {
    _sessions = {},
    _challenges = {},
    _remote = nil,
    _initialized = false,
}

local function hash(str)
    local h = 0
    for i = 1, #str do
        h = (h * 31 + string.byte(str, i)) % 2147483647
    end
    return h
end

local function getGrace(player)
    local ping = player:GetNetworkPing() * 1000
    if ping > Config.PingHighThreshold then
        return Config.GraceVeryHigh
    elseif ping > Config.PingThreshold then
        return Config.GraceHighPing
    end
    return Config.GraceNormal
end

local function kick(player, reason)
    if player and player.Parent then
        player:Kick(reason)
    end
end

function HybridServer:_onHeartbeat(player, ts, fps, coreGuiCount)
    local session = self._sessions[player]
    if not session then return end

    if type(ts) ~= "number" then
        self:_fail(player, "BadHeartbeatFormat")
        return
    end

    local now = os.clock()
    local interval = now - session.lastHb
    session.lastHb = now
    session.missedHb = 0
    session.lastFps = fps
    session.lastCoreGui = coreGuiCount

    if session.lastInterval then
        local diff = math.abs(interval - session.lastInterval)
        if diff > 5 then
            session.irregular = (session.irregular or 0) + 1
            if session.irregular >= 3 then
                if _G.Astral then
                    _G.Astral:AddStrike(player, "HybridIrregular", 2)
                end
                session.irregular = 0
            end
        end
    end
    session.lastInterval = interval

    if type(fps) == "number" and fps > 240 then
        if _G.Astral then
            _G.Astral:AddStrike(player, "HybridFPS", 1)
        end
    end

    if type(coreGuiCount) == "number" and session.lastCoreGui then
        if coreGuiCount > session.lastCoreGui + 2 then
            if _G.Astral then
                _G.Astral:AddStrike(player, "HybridCoreGui", 3)
            end
        end
    end
end

function HybridServer:_onResponse(player, nonce, response)
    local challenge = self._challenges[player]
    if not challenge then return end

    local expected = hash(Config.Secret .. tostring(nonce))
    if response ~= expected then
        challenge.fails = challenge.fails + 1
        if challenge.fails >= Config.MaxChallengeFails then
            kick(player, "Astral Anti-Cheat: Invalid challenge response")
        end
    else
        challenge.answered = true
    end
end

function HybridServer:_sendChallenge(player)
    local nonce = math.random(100000, 999999)
    self._challenges[player] = {
        nonce = nonce,
        fails = 0,
        answered = false,
        sentAt = os.clock(),
    }

    if self._remote then
        self._remote:FireClient(player, "challenge", nonce)
    end
end

function HybridServer:_checkChallenges()
    local now = os.clock()
    for player, challenge in pairs(self._challenges) do
        if not player.Parent then
            self._challenges[player] = nil
            continue
        end
        if not challenge.answered and now - challenge.sentAt > Config.ChallengeTimeout then
            kick(player, "Astral Anti-Cheat: Challenge timeout")
            self._challenges[player] = nil
        end
    end
end

function HybridServer:_checkHeartbeats()
    local now = os.clock()
    for player, session in pairs(self._sessions) do
        if not player.Parent then
            self._sessions[player] = nil
            continue
        end

        local grace = getGrace(player)
        if now - session.lastHb > grace then
            session.missedHb = session.missedHb + 1
            if session.missedHb >= Config.MaxHeartbeatMiss then
                kick(player, Config.KickMessage)
                self._sessions[player] = nil
            end
        end
    end
end

function HybridServer:_fail(player, reason)
    kick(player, "Astral Anti-Cheat: " .. reason)
end

function HybridServer:Init()
    if self._initialized then return end
    self._initialized = true

    local remote = ReplicatedStorage:FindFirstChild("AstralHybrid")
    if not remote then
        remote = Instance.new("RemoteEvent")
        remote.Name = "AstralHybrid"
        remote.Parent = ReplicatedStorage
    end
    self._remote = remote

    remote.OnServerEvent:Connect(function(player, msgType, ...)
        if type(msgType) ~= "string" then return end

        if msgType == "hb" then
            self:_onHeartbeat(player, ...)
        elseif msgType == "response" then
            self:_onResponse(player, ...)
        elseif msgType == "hello" then
            if not self._sessions[player] then
                self._sessions[player] = {
                    lastHb = os.clock(),
                    missedHb = 0,
                    strikes = 0,
                }
            end
        end
    end)

    Players.PlayerAdded:Connect(function(player)
        self._sessions[player] = {
            lastHb = os.clock(),
            missedHb = 0,
            strikes = 0,
        }
    end)

    Players.PlayerRemoving:Connect(function(player)
        self._sessions[player] = nil
        self._challenges[player] = nil
    end)

    task.spawn(function()
        while task.wait(Config.ChallengeRate) do
            for _, player in ipairs(Players:GetPlayers()) do
                self:_sendChallenge(player)
            end
        end
    end)

    RunService.Heartbeat:Connect(function()
        self:_checkHeartbeats()
        self:_checkChallenges()
    end)
end

return HybridServer
