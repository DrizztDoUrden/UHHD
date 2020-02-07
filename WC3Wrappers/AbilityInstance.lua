do
    AbilityInstance = Class()

    function AbilityInstance:ctor(handle)
        self.handle = handle
    end

    function AbilityInstance:SetHpRegen(level, value)
        return BlzSetAbilityRealLevelField(self.handle, ABILITY_ILF_HIT_POINTS_REGENERATED_PER_SECOND, level, value)
    end

    function AbilityInstance:SetMpRegen(level, value)
        return BlzSetAbilityRealLevelField(self.handle, ABILITY_ILF_HIT_POINTS_REGENERATED_PER_SECOND, level, value)
    end
end
