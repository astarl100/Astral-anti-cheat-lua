return {
    Run = function(player, char, state, dt, Astral)
        local suspicious = {
            "Synapse", "Krnl", "ScriptWare", "SirHurt",
            "InfiniteYield", "DarkDex", "SimpleSpy"
        }

        for _, obj in ipairs(char:GetDescendants()) do
            for _, name in ipairs(suspicious) do
                if obj.Name:lower():find(name:lower(), 1, true) then
                    Astral:AddStrike(player, "GUI", 2)
                    return
                end
            end
        end

        if not char:FindFirstChild("Humanoid") then
            Astral:AddStrike(player, "GUI")
        end
    end
}
