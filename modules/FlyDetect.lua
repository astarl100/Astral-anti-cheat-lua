local Config = require(game.ServerScriptService.Astral.config)

return {
    Run = function(player, char, state, dt, Astral)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        local now = os.clock()
        local grounded = hum.FloorMaterial ~= Enum.Material.Air

        if grounded then
            state.data.airStart = nil
            return
        end

        if not state.data.airStart then
            state.data.airStart = now
            return
        end

        local airTime = now - state.data.airStart
        if airTime > Config.MaxAirTime then
            Astral:AddStrike(player, "Fly")
            state.data.airStart = now
        end

        local vel = hrp.AssemblyLinearVelocity
        if vel.Y > Config.MaxVerticalRise then
            Astral:AddStrike(player, "Fly")
        end
    end
}
