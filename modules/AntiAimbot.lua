local Config = require(game.ServerScriptService.Astral.config)

return {
    Run = function(player, char, state, dt, Astral)
        local head = char:FindFirstChild("Head")
        local hrp  = char:FindFirstChild("HumanoidRootPart")
        if not head or not hrp then return end

        local look = hrp.CFrame.LookVector
        local vel  = hrp.AssemblyLinearVelocity
        if vel.Magnitude < 1 then return end

        local moveDir = vel.Unit
        local dot = look:Dot(moveDir)

        if dot < -0.7 then
            Astral:AddStrike(player, "Aimbot")
        end
    end
}
