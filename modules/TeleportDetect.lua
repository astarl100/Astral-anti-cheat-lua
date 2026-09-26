local Config = require(game.ServerScriptService.Astral.config)

return {
    Run = function(player, char, state, dt, Astral)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end

        local pos = hrp.Position
        if state.data.lastPos then
            local dist = (pos - state.data.lastPos).Magnitude
            local speed = dist / math.max(dt, 0.001)
            if speed > Config.MaxTeleportDist / 0.1 then
                Astral:AddStrike(player, "Teleport")
            end
        end
        state.data.lastPos = pos
    end
}
