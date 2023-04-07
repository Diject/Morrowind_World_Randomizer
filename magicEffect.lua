local this = {}

this.effectsData = {
    forEnchant = {positive = {canSelf = {}, canTarget = {}, canTouch = {},}, negative = {canSelf = {}, canTarget = {}, canTouch = {},}},
    forSpell = {positive = {canSelf = {}, canTarget = {}, canTouch = {},}, negative = {canSelf = {}, canTarget = {}, canTouch = {},}},
    cost = {},
    skill = {},
    forbiddenForConstantType = {
        [14] = true,
        [15] = true,
        [16] = true,
        [22] = true,
        [23] = true,
        [24] = true,
        [25] = true,
        [26] = true,
        [27] = true,
        [132] = true,
        [133] = true,
        [135] = true,
    },
}

function this.init()
    local fillEffGroup = function(effect, group)
        if effect.canCastSelf then table.insert(group.canSelf, effect.id) end
        if effect.canCastTarget then table.insert(group.canTarget, effect.id) end
        if effect.canCastTouch then table.insert(group.canTouch, effect.id) end
    end
    for id, effect in pairs(tes3.dataHandler.nonDynamicData.magicEffects) do
        this.effectsData.skill[effect.id] = effect.skill
        this.effectsData.cost[effect.id] = effect.baseMagickaCost
        if effect.isHarmful then
            if not effect.appliesOnce then
                this.effectsData.forbiddenForConstantType[effect.id] = true
            end
            if effect.allowSpellmaking then
                fillEffGroup(effect, this.effectsData.forSpell.negative)
            end
            if effect.allowEnchanting then
                fillEffGroup(effect, this.effectsData.forEnchant.negative)
            end
        else
            if effect.allowSpellmaking then
                fillEffGroup(effect, this.effectsData.forSpell.positive)
            end
            if effect.allowEnchanting then
                fillEffGroup(effect, this.effectsData.forEnchant.positive)
            end
        end

    end
end

function this.calculateEffectCost(effect)
    return ((effect.min + effect.max) * (effect.duration + 1) + effect.radius) * (this.effectsData.cost[effect.id] or 1) / 40
end

return this