local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = {
    Enabled        = true,
    PunishStrike   = 10,
    DestroyDelay   = 0.5,
    RespawnDelay   = 3,

    Honeypots = {
        { name = "AdminPanel",       type = "RemoteEvent" },
        { name = "GiveMoney",        type = "RemoteFunction" },
        { name = "FreeRobux",        type = "RemoteEvent" },
        { name = "SetAdmin",         type = "RemoteEvent" },
        { name = "KickAll",          type = "RemoteEvent" },
        { name = "GodMode",          type = "RemoteEvent" },
        { name = "InfiniteJump",     type = "RemoteEvent" },
        { name = "SpawnItem",        type = "RemoteFunction" },
        { name = "UnlockAll",        type = "RemoteEvent" },
        { name = "AntiBan",          type = "RemoteEvent" },
    },
}

local Honeypot = {
    _active = {},
    _initialized = false,
}

local function onTriggered(player, remote)
    if not _G.Astral then return end
    _G.Astral:AddStrike(player, "Honeypot", Config.PunishStrike)
end

local function createHoneypot(def)
    local remote
    if def.type == "RemoteFunction" then
        remote = Instance.new("RemoteFunction")
        remote.OnServerInvoke = function(player)
            onTriggered(player, remote)
            return nil
        end
    else
        remote = Instance.new("RemoteEvent")
        remote.OnServerEvent:Connect(function(player)
            onTriggered(player, remote)
        end)
    end
    remote.Name = def.name
    remote.Parent = ReplicatedStorage

    Honeypot._active[def.name] = remote

    task.delay(Config.DestroyDelay, function()
        if remote then remote:Destroy() end
    end)
end

function Honeypot:Start()
    if not Config.Enabled then return end
    if self._initialized then return end
    self._initialized = true

    for _, def in ipairs(Config.Honeypots) do
        createHoneypot(def)
    end

    task.spawn(function()
        while task.wait(Config.RespawnDelay) do
            for _, def in ipairs(Config.Honeypots) do
                local existing = ReplicatedStorage:FindFirstChild(def.name)
                if not existing then
                    createHoneypot(def)
                end
            end
        end
    end)
end

return Honeypot
