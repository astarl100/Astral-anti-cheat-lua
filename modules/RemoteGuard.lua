local Config = {
    DefaultRate    = 10,
    DefaultBurst   = 20,
    WindowSize     = 1,
    StrikeWeight   = 1,
    MaxStrikes     = 5,
    Debug          = false,
}

local RemoteGuard = {
    _remotes = {},
    _players = {},
    _initialized = false,
}

local function key(player, remote)
    return player.UserId .. ":" .. remote:GetFullName()
end

function RemoteGuard:Register(remote, options)
    assert(typeof(remote) == "Instance", "RemoteGuard:Register — нужен Instance")
    assert(
        remote:IsA("RemoteEvent") or remote:IsA("RemoteFunction") or remote:IsA("UnreliableRemoteEvent"),
        "RemoteGuard:Register — не Remote"
    )

    options = options or {}
    self._remotes[remote] = {
        rate   = options.rate   or Config.DefaultRate,
        burst  = options.burst  or Config.DefaultBurst,
        window = options.window or Config.WindowSize,
        custom = options.custom,
    }

    if remote:IsA("RemoteEvent") or remote:IsA("UnreliableRemoteEvent") then
        remote.OnServerEvent:Connect(function(player, ...)
            if not self:_allow(player, remote) then return end
            if self._remotes[remote].custom then
                self._remotes[remote].custom(player, ...)
            end
        end)
    elseif remote:IsA("RemoteFunction") then
        remote.OnServerInvoke = function(player, ...)
            if not self:_allow(player, remote) then
                return nil
            end
            if self._remotes[remote].custom then
                return self._remotes[remote].custom(player, ...)
            end
            return nil
        end
    end

    if Config.Debug then
        print(("[RemoteGuard] Зарегистрирован: %s"):format(remote:GetFullName()))
    end
end

function RemoteGuard:_allow(player, remote)
    local cfg = self._remotes[remote]
    if not cfg then return false end

    local state = self._players[player]
    if not state then return false end

    local k = key(player, remote)
    local bucket = state[k]

    if not bucket then
        bucket = { tokens = cfg.burst, last = os.clock() }
        state[k] = bucket
    end

    local now = os.clock()
    local elapsed = now - bucket.last
    bucket.last = now

    bucket.tokens = math.min(cfg.burst, bucket.tokens + elapsed * cfg.rate)

    if bucket.tokens < 1 then
        self:_strike(player, remote, "RemoteSpam")
        return false
    end

    bucket.tokens = bucket.tokens - 1
    return true
end

function RemoteGuard:_strike(player, remote, reason)
    if Config.Debug then
        warn(("[RemoteGuard] %s — %s (%s)"):format(player.Name, reason, remote:GetFullName()))
    end

    if _G.Astral and _G.Astral.AddStrike then
        _G.Astral:AddStrike(player, reason, Config.StrikeWeight)
    end
end

function RemoteGuard:Init()
    if self._initialized then return end
    self._initialized = true

    local Players = game:GetService("Players")

    Players.PlayerAdded:Connect(function(player)
        self._players[player] = {}
    end)

    Players.PlayerRemoving:Connect(function(player)
        self._players[player] = nil
    end)

    for _, player in ipairs(Players:GetPlayers()) do
        self._players[player] = {}
    end

    if Config.Debug then
        print("[RemoteGuard] Инициализирован")
    end
end

function RemoteGuard:Scan(parent, options)
    options = options or {}
    local count = 0
    for _, obj in ipairs(parent:GetDescendants()) do
        if obj:IsA("RemoteEvent") or obj:IsA("RemoteFunction") or obj:IsA("UnreliableRemoteEvent") then
            self:Register(obj, options)
            count = count + 1
        end
    end
    if Config.Debug then
        print(("[RemoteGuard] Авто-скан: %d Remotes"):format(count))
    end
    return count
end

return RemoteGuard
