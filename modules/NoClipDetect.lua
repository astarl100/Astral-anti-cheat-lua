local Config = require(game.ServerScriptService.Astral.config)

return {
    Run = function(player, char, state, dt, Astral)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        local now = os.clock()
        if now - state.data.lastCheck < Config.NoClipCheckRate then return end
        state.data.lastCheck = now

        local params = RaycastParams.new()
        params.FilterDescendantsInstances = { char }
        params.FilterType = Enum.RaycastFilterType.Exclude

        local origin = hrp.Position
        local inside = false
        for _, dir in ipairs({
            Vector3.new(1,0,0), Vector3.new(-1,0,0),
            Vector3.new(0,0,1), Vector3.new(0,0,-1)
        }) do
            local hit = workspace:Raycast(origin, dir * 1.5, params)
            if hit and hit.Instance.CanCollide then inside = true end
        end

        local moving = hrp.AssemblyLinearVelocity.Magnitude > 2
        if inside and moving then
            Astral:AddStrike(player, "NoClip")
        end
    end
}
