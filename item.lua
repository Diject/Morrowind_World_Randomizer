local this = {}

local log = include("Morrowind_World_Randomizer.log")
local random = include("Morrowind_World_Randomizer.Random")
local effectLib = include("Morrowind_World_Randomizer.magicEffect")
this.config = include("Morrowind_World_Randomizer.config").data

function this.iterItems(inventory)
    local function iterator()
        for _, stack in pairs(inventory) do
            ---@cast stack tes3itemStack
            local item = stack.object

            local count = stack.count

            -- first yield stacks with custom data
            if stack.variables then
                for _, data in pairs(stack.variables) do
                    if data then
                        coroutine.yield(stack, item, data.count, data)
                        count = count - data.count
                    end
                end
            end
            -- then yield all the remaining copies
            if count > 0 then
                coroutine.yield(stack, item, count)
            end
        end
    end
    return coroutine.wrap(iterator)
end

function this.getEnchantPower(enchantment)
    local enchVal = 0
    if enchantment then
        for _, effect in pairs(enchantment.effects) do
            if effect.id >= 0 then
                enchVal = enchVal + effectLib.calculateEffectCost(effect)
            end
        end
    end
    return enchVal
end

local function chooseGroup(enchType, isConstant)
    local rangeType = enchType == tes3.enchantmentType.onStrike and tes3.effectRange.target or
        isConstant and tes3.effectRange.self or math.random(0, 2)
    local groupType = isConstant and "selfMagnitude" or rangeType
    local effGroup_p = effectLib.effectsData.forEnchant.positive[groupType]
    local effGroup_n = effectLib.effectsData.forEnchant.negative[groupType]
    return rangeType, effGroup_p, effGroup_n
end

function this.randomizeEnchantment(enchantment, enchType, power, effectCount, config)
    local isConstant = enchType == tes3.enchantmentType.constant
    local enchPower = (isConstant or enchType == tes3.enchantmentType.castOnce) and power or
        power / random.GetBetween(1, config.enchanting.maxNumberOfCasts)
    if enchPower < 1 then enchPower = 1 end
    if enchPower > config.enchanting.maxCost then enchPower = config.enchanting.maxCost end
    log("Enchantment randomization id %s type %i maxCharge %s charge %s", tostring(enchantment), enchType, tostring(power), tostring(enchPower))
    local newEnch = enchantment ~= nil and enchantment or
        tes3.createObject{objectType = tes3.objectType.enchantment, castType = enchType, chargeCost = enchPower, maxCharge = power}
    newEnch.maxCharge = power
    local effCount = math.random(1, effectCount or config.enchanting.effects.maxCount)
    local thresholdVal = enchPower * config.enchanting.effects.threshold
    local oneType = config.enchanting.effects.oneTypeChance > math.random()
    local effGroup_p
    local effGroup_n
    local rangeType
    if oneType then
        rangeType, effGroup_p, effGroup_n = chooseGroup(enchType, isConstant)
    end

    --clear old data
    for i = 1, 8 do
        newEnch.effects[i].id = -1
    end

    --add a new effect with a minimum value until it reaches the threshold
    local addedCount = 0
    local enchVal = 0
    for i = 1, effCount do
        if enchVal < thresholdVal then
            if not oneType then
                rangeType, effGroup_p, effGroup_n = chooseGroup(enchType, isConstant)
            end
            local configChance = rangeType ~= tes3.effectRange.self and config.enchanting.effects.chanceToNegativeForTarget or
                config.enchanting.effects.chanceToNegative
            local group = math.random() < configChance and effGroup_n or effGroup_p
            local effectId = random.GetRandomFromGroup(group, (config.enchanting.effects.safeMode and isConstant) and
                effectLib.effectsData.forbiddenForConstantType or {}) or -1

            local iteration = 0
            while (effectLib.effectsData.cost[effectId] or 0) > thresholdVal - enchVal and iteration < 20 do
                iteration = iteration + 1
                effectId = random.GetRandomFromGroup(group, (config.enchanting.effects.safeMode and isConstant) and
                    effectLib.effectsData.forbiddenForConstantType or {}) or -1
            end
            if (effectLib.effectsData.cost[effectId] or 0) > thresholdVal - enchVal then break end

            local magicEffect = effectLib.effectsData.effect[effectId]
            newEnch.effects[i].id = effectId
            newEnch.effects[i].min = 1
            newEnch.effects[i].max = 1
            newEnch.effects[i].duration = ((not magicEffect.isHarmful or magicEffect.appliesOnce) and not magicEffect.hasNoDuration) and 1 or 0
            newEnch.effects[i].radius = 0
            newEnch.effects[i].rangeType = rangeType
            newEnch.effects[i].skill = math.random(0, 26)
            newEnch.effects[i].attribute = math.random(0, 7)
            if (rangeType == tes3.effectRange.self and magicEffect.isHarmful) or
                    (rangeType ~= tes3.effectRange.self and not magicEffect.isHarmful) then
                enchVal = enchVal - (isConstant and effectLib.calculateEffectCostForConstant(newEnch.effects[i]) or
                    effectLib.calculateEffectCost(newEnch.effects[i]))
            else
                enchVal = enchVal + (isConstant and effectLib.calculateEffectCostForConstant(newEnch.effects[i]) or
                    effectLib.calculateEffectCost(newEnch.effects[i]))
            end
            addedCount = addedCount + 1
        else
            break
        end
    end

    if addedCount == 0 then return nil end

    --tune new effects
    local effects = {}
    for i = 1, addedCount do
        local effect = newEnch.effects[i]
        if effect.id >= 0 then
            effects[i] = {id = effect.id, min = effect.min, max = effect.max, duration = effect.duration, radius = effect.radius,}
        else
            break
        end
    end
    local iterations = 4 * enchPower / config.enchanting.effects.tuneStepsCount
    local stepPow = (enchPower - enchVal) / config.enchanting.effects.tuneStepsCount
    while enchVal < enchPower and iterations > 0 do
        iterations = iterations - 1
        local effectPos = math.random(1, addedCount)
        local effect = newEnch.effects[effectPos]
        local effectData = effects[effectPos]
        local effectCost = (isConstant and effectLib.calculateEffectCostForConstant(effectData) or effectLib.calculateEffectCost(effectData))
        local magicEffect = effectLib.effectsData.effect[effect.id]
        if magicEffect == nil then goto continue end
        local baseCost = magicEffect.baseMagickaCost
        local rnd = isConstant and 0 or math.random()
        if rnd < 0.4 and not magicEffect.hasNoMagnitude then
            local mul = effect.rangeType == tes3.effectRange.target and 1.5 or 1
            local mulConst = isConstant and 100 or 1
            local magnitude = (((40 * (effectCost + stepPow) / (baseCost * mul)) - effectData.radius) / ((effectData.duration + 1) * mulConst) -
                (effectData.min + effectData.max)) * 0.5
            local min = random.GetBetween(0, 0.5 * magnitude)
            local max = random.GetBetween(0, 1.5 * magnitude)
            if min > max then min = max end
            effectData.min = math.min(effectData.min + min, config.enchanting.effects.maxMagnitude)
            effectData.max = math.min(effectData.max + max, config.enchanting.effects.maxMagnitude)

        elseif rnd < 0.8 and not magicEffect.hasNoDuration and not isConstant then
            local mul = effect.rangeType == tes3.effectRange.target and 1.5 or 1
            local magnitude = ((40 * (effectCost + stepPow) / (baseCost * mul)) - effectData.radius) / (effectData.min + effectData.max) -
                (effectData.duration + 1)
            effectData.duration = math.min(effectData.duration + random.GetBetween(0, magnitude), config.enchanting.effects.maxDuration)

        elseif not isConstant then
            local mul = effect.rangeType == tes3.effectRange.target and 1.5 or 1
            local magnitude = (40 * (effectCost + stepPow) / (baseCost * mul)) - (effectData.min + effectData.max) * (effectData.duration + 1) -
                effectData.radius
            effectData.radius = math.min(effectData.radius + random.GetBetween(0, magnitude), config.enchanting.effects.maxRadius)
        end
        if (rangeType == tes3.effectRange.self and magicEffect.isHarmful) or
                (rangeType ~= tes3.effectRange.self and not magicEffect.isHarmful) then
            enchVal = enchVal - (isConstant and effectLib.calculateEffectCostForConstant(effectData) or
                effectLib.calculateEffectCost(effectData)) + effectCost
        else
            enchVal = enchVal + (isConstant and effectLib.calculateEffectCostForConstant(effectData) or
                effectLib.calculateEffectCost(effectData)) - effectCost
        end
        ::continue::
    end

    for i = 1, addedCount do
        local data = effects[i]
        if data then
            local effect = newEnch.effects[i]
            effect.min = math.ceil(data.min)
            effect.max = math.ceil(data.max)
            effect.duration = math.ceil(data.duration)
            effect.radius = math.ceil(data.radius)
            log("id %s min %s max %s dur %s r %s", tostring(effect.id), tostring(effect.min), tostring(effect.max), tostring(effect.duration), tostring(effect.radius))
        end
    end

    return newEnch
end

function this.randomizeStats(object, minMul, maxMul)
    local intVars = {"enchantCapacity", "armorRating", "maxCondition"}
    local floatVars_p = {"quality"}
    local floatVars_n = {"speed", "weight"}
    log("Item stats id %s", tostring(object))
    if object.value then
        object.value = object.objectType ~= tes3.objectType.clothing and math.floor(math.max(0, object.value * random.GetBetween(minMul, maxMul))) or
            tes3.objectType.clothing and math.floor(math.min(65535, math.max(0, object.value * random.GetBetween(minMul, maxMul))))
        log("value %s", tostring(object.value))
    end
    for _, var in pairs(intVars) do
        if object[var] then
            object[var] = math.floor(math.max(0, object[var] * random.GetBetween(minMul, maxMul)))
            log("%s %s", var, tostring(object[var]))
        end
    end
    for _, var in pairs(floatVars_p) do
        if object[var] then
            object[var] = math.max(0, object[var] * random.GetBetween(minMul, maxMul))
            log("%s %s", var, tostring(object[var]))
        end
    end
    for _, var in pairs(floatVars_n) do
        if object[var] then
            object[var] = math.max(0, object[var] / (1 + random.GetBetween(minMul, maxMul)))
            log("%s %s", var, tostring(object[var]))
        end
    end
    if object.chopMin then
        object.chopMin = math.min(65535, math.max(0, object.chopMin * random.GetBetween(minMul, maxMul)))
        object.chopMax = math.min(65535, math.max(0, object.chopMax * random.GetBetween(minMul, maxMul)))
        if object.chopMax < object.chopMin then object.chopMax = object.chopMin end
        log("chop %s %s", tostring(object.chopMin), tostring(object.chopMax))
    end
    if object.slashMin then
        object.slashMin = math.min(65535, math.max(0, object.slashMin * random.GetBetween(minMul, maxMul)))
        object.slashMax = math.min(65535, math.max(0, object.slashMax * random.GetBetween(minMul, maxMul)))
        if object.slashMax < object.slashMin then object.slashMax = object.slashMin end
        log("slash %s %s", tostring(object.slashMin), tostring(object.slashMax))
    end
    if object.thrustMin then
        object.thrustMin = math.min(65535, math.max(0, object.thrustMin * random.GetBetween(minMul, maxMul)))
        object.thrustMax = math.min(65535, math.max(0, object.thrustMax * random.GetBetween(minMul, maxMul)))
        if object.thrustMax < object.thrustMin then object.thrustMax = object.thrustMin end
        log("thrust %s %s", tostring(object.thrustMin), tostring(object.thrustMax))
    end
end

function this.randomizeBaseItem(object, createNewItem, modifiedFlag, effectCount, enchCost, newEnchValue)
    if object == nil then return end

    log("Base object randomization %s", tostring(object))
    if object.objectType == tes3.objectType.weapon or object.objectType == tes3.objectType.armor or
            object.objectType == tes3.objectType.clothing then

        local newBase = createNewItem and object:createCopy() or object

        if this.config.item.stats.randomize then
            this.randomizeStats(newBase, this.config.item.stats.region.min, this.config.item.stats.region.max)
        end

        if this.config.item.enchanting.randomize then
            local newEnch = object.enchantment
            local enchPower = enchCost or 0
            if newEnch ~= nil then
                if this.config.item.enchanting.remove.chance > math.random() then
                    newEnch = nil
                else
                    if enchCost == nil then
                        for _, effect in pairs(object.enchantment) do
                            enchPower = enchPower + effectLib.calculateEffectCost(effect)
                        end
                    end
                end

            elseif this.config.item.enchanting.add.chance > math.random() then
                enchPower = (newEnchValue or 1) *
                    random.GetBetween(this.config.item.enchanting.add.region.min, this.config.item.enchanting.add.region.max)
            end

            if enchPower > this.config.item.enchanting.minCost then
                enchPower = ((newEnch and newEnch.maxCharge) and newEnch.maxCharge or enchPower) *
                    random.GetBetween(this.config.item.enchanting.region.min, this.config.item.enchanting.region.max)
                local enchType = object.objectType == tes3.objectType.weapon and tes3.enchantmentType.onStrike or math.random(2, 3)
                if object.objectType == tes3.objectType.weapon then
                    if object.isProjectile then
                        enchType = tes3.enchantmentType.onStrike
                    elseif object.enchantment then
                        enchType = object.enchantment.castType
                    elseif object.isRanged then
                        enchType = math.random(2, 3)
                    else
                        enchType = math.random(1, 3)
                    end
                else
                    enchType = math.random(2, 3)
                end

                newEnch = this.randomizeEnchantment(newEnch, enchType, enchPower, effectCount, this.config.item)
                if newEnch then newEnch.modified = modifiedFlag end
            end
            newBase.enchantment = newEnch
        end
        newBase.modified = modifiedFlag
        return newBase
    end
    return nil
end

function this.generateData()
    local items = {}
    local out = {}
    items[tes3.objectType.alchemy] = {}
    items[tes3.objectType.ingredient] = {}
    items[tes3.objectType.apparatus] = {}
    items[tes3.objectType.armor] = {}
    items[tes3.objectType.book] = {}
    items[tes3.objectType.clothing] = {}
    items[tes3.objectType.lockpick] = {}
    items[tes3.objectType.probe] = {}
    items[tes3.objectType.repairItem] = {}
    items[tes3.objectType.weapon] = {}
    items[tes3.objectType.miscItem] = {}

    log("Item data generation...")
    for _, object in pairs(tes3.dataHandler.nonDynamicData.objects) do
        if object ~= nil and not object.deleted and items[object.objectType] ~= nil and object.name ~= nil and object.name ~= "" and
                object.name ~= "<Deprecated>" and (object.icon == nil or object.icon ~= "default icon.dds") then

            table.insert(items[object.objectType], object)
        end
    end
    for objType, data in pairs(items) do
        table.sort(data, function(a, b) return a.value < b.value end)
        local enchantVals = {0,}
        local enchValData = {}
        for i, item in pairs(data) do
            if item.enchantment then
                local enchVal = this.getEnchantPower(item.enchantment)
                if enchVal > 0 then
                    table.insert(enchantVals, enchVal)
                    enchValData[item.id] = enchVal
                end
            end
        end
        table.sort(enchantVals)
        out[objType] = {
            items = data, enchantValues = enchValData, maxValue = data[#data].value, medianValue = data[math.floor(#data / 2)].value,
            maxEnchant = enchantVals[#enchantVals], medianEnchant = enchantVals[math.floor(#enchantVals / 2)],
            enchant90 = enchantVals[math.floor(#enchantVals * 0.9)] or 0, value90 = data[math.floor(#data * 0.9)],
        }
    end

    log("Item data generation comleted")
    return out
end

function this.randomizeItems(itemsData)
    for itType, data in pairs(itemsData) do
        local count = #data.items
        for i, item in pairs(data.items) do
            local enchVal = data.enchantValues[item.id]
            local mul = (i / count) ^ this.config.item.enchanting.powMul
            local encCount = math.max(1, this.config.item.enchanting.effects.maxCount * (mul ^ this.config.item.enchanting.effects.countPowMul))
            this.randomizeBaseItem(item, false, true, encCount, enchVal, mul * data.enchant90)
        end
    end
end

function this.fixItemData(itemData, item)
    if not itemData or not item then return end
    if item.enchantment and (itemData.charge == -1 or itemData.charge > item.enchantment.maxCharge) then
        itemData.charge = item.enchantment.maxCharge
    end
    if item.maxCondition and itemData.condition and itemData.condition > item.maxCondition then
        itemData.condition = item.maxCondition
    end
end

function this.fixInventory(inventory)
    if not inventory then return end
    for stack, item, count, itemData in this.iterItems(inventory) do
        this.fixItemData(itemData, item)
    end
end

function this.fixCell(cell)
    for ref in cell:iterateReferences() do
        if ref.object.inventory then
            this.fixInventory(ref.object.inventory)
        end
        if ref.itemData then
            this.fixItemData(ref.itemData, ref.baseObject)
        end
    end
end

return this