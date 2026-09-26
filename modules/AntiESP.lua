return {
    Run = function(player, char, state, dt, Astral)
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        local tag = hrp:FindFirstChild("AstralTag")
        if not tag then
            tag = Instance.new("ObjectValue")
            tag.Name = "AstralTag"
            tag.Value = hrp
            tag.Parent = hrp
        end
    end
}
