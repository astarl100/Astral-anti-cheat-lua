local Config = require(game.ServerScriptService.Astral.config)

return {
    Run = function(player, char, state, dt, Astral)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hrp or not hum then return end

        local speed = (Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z)).Magnitude
        local maxAllowed = math.max(hum.WalkSpeed, Config.MaxWalkSpeed) + Config.SpeedTolerance

        if hum:GetState() == Enum.HumanoidStateType.Physics then return end
        if char:FindFirstChildOfClass("Tool") then return end

        if speed > maxAllowed then
            Astral:AddStrike(player, "Speed")
        end
    end
}
