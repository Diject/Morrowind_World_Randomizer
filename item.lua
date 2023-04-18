local this = {}

local log = include("Morrowind_World_Randomizer.log")
local random = include("Morrowind_World_Randomizer.Random")
local effectLib = include("Morrowind_World_Randomizer.magicEffect")
local genData = include("Morrowind_World_Randomizer.generatorData")
local dataSaver = include("Morrowind_World_Randomizer.dataSaver")
this.config = include("Morrowind_World_Randomizer.config").data

this.itemTypeWhiteList = {
    [tes3.objectType.alchemy] = true,
    [tes3.objectType.ingredient] = true,
    [tes3.objectType.apparatus] = true,
    [tes3.objectType.armor] = true,
    [tes3.objectType.book] = true,
    [tes3.objectType.clothing] = true,
    [tes3.objectType.lockpick] = true,
    [tes3.objectType.probe] = true,
    [tes3.objectType.repairItem] = true,
    [tes3.objectType.weapon] = true,
    [tes3.objectType.miscItem] = true,
}

this.itemTypeForEnchantment = {
    [tes3.objectType.armor] = true,
    [tes3.objectType.book] = true,
    [tes3.objectType.clothing] = true,
    [tes3.objectType.weapon] = true,
}

this.itemTypeForEffects = {
    [tes3.objectType.alchemy] = true,
}

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

function this.getEffectsPower(effects)
    local enchVal = 0
    if effects then
        for _, effect in pairs(effects) do
            if effect.id >= 0 then
                enchVal = enchVal + effectLib.calculateEffectCost(effect)
            end
        end
    end
    return enchVal
end

function this.getEnchantPower(enchantment)
    local enchVal = 0
    if enchantment then
        local calcFunc = enchantment.castType == tes3.enchantmentType.constant and effectLib.calculateEffectCostForConstant or
            effectLib.calculateEffectCost
        for _, effect in pairs(enchantment.effects) do
            if effect.id >= 0 then
                enchVal = enchVal + calcFunc(effect)
            end
        end
        enchVal = enchVal
    end
    return enchVal
end

local function chooseGroup(enchType, isConstant)
    local rangeType = enchType == tes3.enchantmentType.onStrike and tes3.effectRange.touch or
        isConstant and tes3.effectRange.self or math.random(0, 2)
    local groupType = isConstant and "selfMagnitude" or rangeType
    local effGroup_p = effectLib.effectsData.forEnchant.positive[groupType]
    local effGroup_n = effectLib.effectsData.forEnchant.negative[groupType]
    return rangeType, effGroup_p, effGroup_n
end


function this.randomizeEffects(effects, effData, config)
    local effCount = effData.effectCount
    local thresholdVal = effData.thresholdValue
    local oneType = effData.oneType
    local rangeType, effGroup_p, effGroup_n = effData.rangeType, effData.effGroup_p, effData.effGroup_n
    local enchType = effData.enchantmentType
    local isConstant = effData.isConstant
    local enchPower = effData.power
    local strongThreshold = effData.strongThreshold or true
    --clear old data
    for i = 1, 8 do
        effects[i].id = -1
        effects[i].skill = 0
        effects[i].attribute = 0
        effects[i].min = 0
        effects[i].max = 0
        effects[i].duration = 0
        effects[i].radius = 0
    end

    --add a new effect with a minimum value until it reaches the threshold
    local effectUniqueness = {}
    local addedCount = 0
    local enchVal = 0
    for i = 1, effCount do
        if enchVal < thresholdVal then
            if not oneType then
                rangeType, effGroup_p, effGroup_n = chooseGroup(enchType, isConstant)
            end
            local configChance = rangeType ~= tes3.effectRange.self and config.enchantment.effects.chanceToNegativeForTarget or
                config.enchantment.effects.chanceToNegative
            local group = math.random() < configChance and effGroup_n or effGroup_p
            local effectId = random.GetRandomFromGroup(group, (config.enchantment.effects.safeMode and isConstant) and
                effectLib.effectsData.forbiddenForConstantType or {}) or -1

            local iteration = 0
            while (((effectLib.effectsData.cost[effectId] or 0) > thresholdVal - enchVal and strongThreshold) or effectUniqueness[effectId]) and iteration < 20 do
                iteration = iteration + 1
                effectId = random.GetRandomFromGroup(group, (config.enchantment.effects.safeMode and isConstant) and
                    effectLib.effectsData.forbiddenForConstantType or {}) or -1
            end

            effectUniqueness[effectId] = true
            effects[i].id = effectId
            local magicEffect = effects[i].object
            if not magicEffect.hasNoMagnitude then
                effects[i].min = 1
                effects[i].max = 1
            end

            if not magicEffect.hasNoDuration then
                effects[i].duration = 1
            end
            effects[i].radius = 0
            effects[i].rangeType = rangeType
            log("range %s", tostring(rangeType))
            if magicEffect.targetsSkills then
                effects[i].skill = math.random(0, 26)
                log("skill %s", tostring(effects[i].skill))
            end
            if magicEffect.targetsAttributes then
                effects[i].attribute = math.random(0, 7)
                log("attribute %s", tostring(effects[i].attribute))
            end
            if (rangeType == tes3.effectRange.self and magicEffect.isHarmful) or
                    (rangeType ~= tes3.effectRange.self and not magicEffect.isHarmful) then
                enchVal = enchVal - (isConstant and effectLib.calculateEffectCostForConstant(effects[i]) or
                    effectLib.calculateEffectCost(effects[i]))
            else
                enchVal = enchVal + (isConstant and effectLib.calculateEffectCostForConstant(effects[i]) or
                    effectLib.calculateEffectCost(effects[i]))
            end
            addedCount = addedCount + 1
        else
            break
        end
    end

    if addedCount == 0 then return nil end

    --tune new effects
    local effs = {}
    for i = 1, addedCount do
        local effect = effects[i]
        if effect.id >= 0 then
            effs[i] = {id = effect.id, min = effect.min, max = effect.max, duration = effect.duration, radius = effect.radius,}
        else
            break
        end
    end
    local iterations = 2 * config.enchantment.effects.tuneStepsCount
    local stepPow = (enchPower - enchVal) / config.enchantment.effects.tuneStepsCount
    while enchVal < enchPower and iterations > 0 do
        iterations = iterations - 1
        local effectPos = math.random(1, addedCount)
        local effect = effects[effectPos]
        local effectData = effs[effectPos]
        local effectCost = (isConstant and effectLib.calculateEffectCostForConstant(effectData) or effectLib.calculateEffectCost(effectData))
        local magicEffect = effect.object
        if magicEffect == nil then goto continue end
        local baseCost = magicEffect.baseMagickaCost
        local rnd = isConstant and 0 or math.random()
        if rnd < 0.6 and not magicEffect.hasNoMagnitude then
            local mul = effect.rangeType == tes3.effectRange.target and 1.5 or 1
            local mulConst = isConstant and 100 or 1
            local magnitude = (((40 * (effectCost + stepPow) / (baseCost * mul)) - effectData.radius) / ((effectData.duration + 1) * mulConst) -
                (effectData.min + effectData.max)) * 0.5
            local min = random.GetBetween(0, 0.5 * magnitude)
            local max = random.GetBetween(0, 1.5 * magnitude)
            if min > max then min = max end
            effectData.min = math.min(effectData.min + min, config.enchantment.effects.maxMagnitude)
            effectData.max = math.min(effectData.max + max, config.enchantment.effects.maxMagnitude)

        elseif rnd < 0.95 and not magicEffect.hasNoDuration and not isConstant then
            local mul = effect.rangeType == tes3.effectRange.target and 1.5 or 1
            local magnitude = ((40 * (effectCost + stepPow) / (baseCost * mul)) - effectData.radius) / (effectData.min + effectData.max) -
                (effectData.duration + 1)
            effectData.duration = math.min(effectData.duration + random.GetBetween(0, magnitude), config.enchantment.effects.maxDuration)

        elseif not isConstant and effect.rangeType ~= tes3.effectRange.self then
            local mul = effect.rangeType == tes3.effectRange.target and 1.5 or 1
            local magnitude = (40 * (effectCost + stepPow) / (baseCost * mul)) - (effectData.min + effectData.max) * (effectData.duration + 1) -
                effectData.radius
            effectData.radius = math.min(effectData.radius + random.GetBetween(0, magnitude), config.enchantment.effects.maxRadius)
        end
        if (effect.rangeType == tes3.effectRange.self and magicEffect.isHarmful) or
                (effect.rangeType ~= tes3.effectRange.self and not magicEffect.isHarmful) then
            enchVal = enchVal - (isConstant and effectLib.calculateEffectCostForConstant(effectData) or
                effectLib.calculateEffectCost(effectData)) + effectCost
        else
            enchVal = enchVal + (isConstant and effectLib.calculateEffectCostForConstant(effectData) or
                effectLib.calculateEffectCost(effectData)) - effectCost
        end
        ::continue::
    end

    for i = 1, addedCount do
        local data = effs[i]
        if data then
            local effect = effects[i]
            effect.min = math.ceil(data.min)
            effect.max = math.ceil(data.max)
            effect.duration = math.ceil(data.duration)
            effect.radius = math.ceil(data.radius)
            log("id %s min %s max %s dur %s r %s", tostring(effect.id), tostring(effect.min), tostring(effect.max), tostring(effect.duration), tostring(effect.radius))
        end
    end
end

local enchantLastRand = {}

--cannot randomise more than once every 2 seconds for an enchantment
function this.randomizeEnchantment(enchantment, enchType, power, canBeUsedOnce, effectCount, config)
    if enchantment then
        local time = enchantLastRand[enchantment.id]
        if not time then
            enchantLastRand[enchantment.id] = os.time()
        elseif time > os.time() + 1 then
            return enchantment
        else
            enchantLastRand[enchantment.id] = os.time()
        end
    end
    local isConstant = enchType == tes3.enchantmentType.constant
    local enchPower = (isConstant or enchType == tes3.enchantmentType.castOnce or canBeUsedOnce) and power or
        power / random.GetBetween(1, config.enchantment.maxNumberOfCasts)
    if enchPower < 1 then enchPower = 1 end
    if enchPower > config.enchantment.maxCost then enchPower = config.enchantment.maxCost end
    local chargeCost
    local maxCharge
    if not isConstant then
        chargeCost = math.floor(enchPower)
        maxCharge = math.floor(power)
    end
    local newEnch = enchantment ~= nil and enchantment or
        tes3.createObject{objectType = tes3.objectType.enchantment, castType = enchType, chargeCost = chargeCost, maxCharge = maxCharge}
    log("Enchantment randomization id %s type %i maxCharge %s charge %s", tostring(newEnch), enchType, tostring(power), tostring(enchPower))
    newEnch.maxCharge = power
    local effCount = math.random(1, effectCount or config.enchantment.effects.maxCount)
    local thresholdVal = enchPower * config.enchantment.effects.threshold
    local oneType = config.enchantment.effects.oneTypeChance > math.random()
    local effGroup_p
    local effGroup_n
    local rangeType
    if oneType then
        rangeType, effGroup_p, effGroup_n = chooseGroup(enchType, isConstant)
    end

    this.randomizeEffects(newEnch.effects, {
        effectCount = effCount,
        thresholdValue = thresholdVal,
        oneType = oneType,
        rangeType = rangeType,
        effGroup_p = effGroup_p,
        effGroup_n = effGroup_n,
        enchantmentType = enchType,
        isConstant = isConstant,
        power = enchPower,
        strongThreshold = false,
    }, config)

    return newEnch
end

local objLastRand = {}

--cannot randomise more than once every 2 seconds for an object
function this.randomizeStats(object, minMul, maxMul)
    if object then
        local time = objLastRand[object.id]
        if not time then
            objLastRand[object.id] = os.time()
        elseif time > os.time() + 1 then
            return object
        else
            objLastRand[object.id] = os.time()
        end
    end
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
            local div = random.GetBetween(minMul, maxMul)
            if div == 0 then div = 0.05 end
            object[var] = math.max(0, object[var] / div)
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

    if this.itemTypeWhiteList[object.objectType] then

        local newBase = createNewItem and object:createCopy() or object

        if this.config.item.stats.randomize then
            this.randomizeStats(newBase, this.config.item.stats.region.min, this.config.item.stats.region.max)
        end

        if this.config.item.enchantment.randomize and (this.itemTypeForEnchantment[object.objectType] or this.itemTypeForEffects[object.objectType]) and
                (object.objectType ~= tes3.objectType.book or object.type == tes3.bookType.scroll) and
                not (this.config.item.enchantment.exceptAlchemy and object.objectType == tes3.objectType.alchemy) and
                not (this.config.item.enchantment.exceptScrolls and object.objectType == tes3.objectType.book) then
            local newEnch = object.enchantment
            local enchPower = enchCost or 0
            if newEnch ~= nil then
                if this.config.item.enchantment.remove.chance > math.random() then
                    newEnch = nil
                    enchPower = -1
                else
                    if enchCost == nil then
                        enchCost = this.getEnchantPower(object.enchantment)
                    end
                end

            elseif this.config.item.enchantment.add.chance > math.random() then
                enchPower = (newEnchValue or 1) *
                    random.GetBetween(this.config.item.enchantment.add.region.min, this.config.item.enchantment.add.region.max)
            end

            local shouldAddEnchant = false
            if enchPower > this.config.item.enchantment.minCost then
                if this.itemTypeForEffects[object.objectType] and object.effects then
                    this.randomizeEffects(object.effects, {
                        effectCount = this.config.item.enchantment.effects.maxAlchemyCount,
                        thresholdValue = enchPower * this.config.item.enchantment.effects.threshold,
                        oneType = true,
                        rangeType = tes3.effectRange.self,
                        effGroup_p = effectLib.effectsData.forEnchant.positive[tes3.effectRange.self],
                        effGroup_n = effectLib.effectsData.forEnchant.negative[tes3.effectRange.self],
                        enchantmentType = tes3.enchantmentType.castOnce,
                        isConstant = false,
                        power = enchPower,
                        strongThreshold = false,
                    }, this.config.item)
                else
                    enchPower = ((newEnch and newEnch.maxCharge) and newEnch.maxCharge or enchPower) *
                        random.GetBetween(this.config.item.enchantment.region.min, this.config.item.enchantment.region.max)
                    local enchType = object.objectType == tes3.objectType.weapon and tes3.enchantmentType.onStrike or math.random(2, 3)
                    local usedOnce = false
                    if object.objectType == tes3.objectType.weapon then
                        if object.isProjectile or object.isAmmo then
                            enchType = tes3.enchantmentType.onStrike
                            usedOnce = true
                        elseif object.enchantment then
                            enchType = object.enchantment.castType
                        elseif object.isRanged then
                            enchType = math.random(2, 3)
                        else
                            enchType = math.random(1, 3)
                        end
                    elseif object.objectType == tes3.objectType.book then
                        enchType = tes3.enchantmentType.castOnce
                    else
                        enchType = math.random(2, 3)
                    end

                    newEnch = this.randomizeEnchantment(newEnch, enchType, enchPower, usedOnce, effectCount, this.config.item)
                    if newEnch then newEnch.modified = modifiedFlag end
                end
            end
            if this.itemTypeForEnchantment[object.objectType] then newBase.enchantment = newEnch end
        end
        newBase.modified = modifiedFlag
        return newBase
    end
    return nil
end

function this.randomizeBaseItemVisuals(item, itemsData, meshesData)
    if item.mesh and this.config.item.changeMesh then
        local mesh = meshesData[math.random(1, #meshesData)]
        log("Item mesh %s %s", tostring(item), tostring(mesh))
        item.mesh = mesh
    end
    if item.parts and this.config.item.changeParts then
        local objSubType
        if item.type then
            objSubType = item.type
        elseif item.slot then
            objSubType = item.slot
        end
        local partArr = itemsData.parts[item.objectType][objSubType][math.random(1, #itemsData.parts[item.objectType][objSubType])]
        if partArr then
            for pos = 1, #item.parts do
                local newPartData = partArr[pos]
                local part = item.parts[pos]
                if newPartData then
                    log("Item part %s %s %s %s", tostring(item), tostring(newPartData[1]), tostring(newPartData[2]), tostring(newPartData[3]))
                    part.type = newPartData[1]
                    part.female = newPartData[2] and tes3.getObject(newPartData[2]) or nil
                    part.male = newPartData[3] and tes3.getObject(newPartData[3]) or nil
                else
                    part.type = 255
                    part.female = nil
                    part.male = nil
                end
            end
        end
    end
end

function this.generateData()
    local items = {}
    local out = {parts = {}, itemGroup = {}}
    for itType, val in pairs(this.itemTypeWhiteList) do
        if val then
            items[itType] = {}
        end
    end

    log("Item data generation...")
    for _, object in pairs(tes3.dataHandler.nonDynamicData.objects) do
        if genData.checkRequirementsForItem(object) and items[object.objectType] ~= nil then

            table.insert(items[object.objectType], object)

            if object.parts then
                local data = {}
                for _, part in pairs(object.parts) do
                    if part.type ~= 255 then
                        local female
                        local male
                        if part.female ~= nil and not part.female.deleted and not part.female.disabled and
                                tes3.getFileSource("meshes\\"..part.female.mesh) then
                            female = part.female.id
                        end
                        if part.male ~= nil and not part.male.deleted and not part.male.disabled and
                                tes3.getFileSource("meshes\\"..part.male.mesh) then
                            male = part.male.id
                        end
                        if female or male then table.insert(data, {part.type, female, male}) end
                    end
                end
                local objSubType
                if object.type then
                    objSubType = object.type
                elseif object.slot then
                    objSubType = object.slot
                end
                if not out.parts[object.objectType] then out.parts[object.objectType] = {} end
                if not out.parts[object.objectType][objSubType] then out.parts[object.objectType][objSubType] = {} end
                if #data > 0 then table.insert(out.parts[object.objectType][objSubType], data) end
            end
        end
    end

    for objType, data in pairs(items) do
        table.sort(data, function(a, b) return a.value < b.value end)
        local meshes = {}
        local enchantVals = {0,}
        local enchValData = {}
        for i, item in pairs(data) do
            local enchVal = 0
            if item.enchantment then
                enchVal = this.getEnchantPower(item.enchantment)
            elseif objType == tes3.objectType.alchemy then
                enchVal = this.getEffectsPower(item.effects)
            end
            if enchVal > 0 then
                table.insert(enchantVals, enchVal)
                enchValData[item.id] = enchVal
            end
            if item.mesh and tes3.getFileSource("meshes\\"..item.mesh) then
                meshes[item.mesh] = true
            end
        end
        local meshList = {}
        for mesh, _ in pairs(meshes) do
            table.insert(meshList, mesh)
        end
        table.sort(enchantVals)
        out.itemGroup[objType] = {
            items = data, meshes = meshList, enchantValues = enchValData, maxValue = data[#data].value,
            medianValue = data[math.floor(#data / 2)].value,
            maxEnchant = enchantVals[#enchantVals], medianEnchant = enchantVals[math.floor(#enchantVals / 2)],
            enchant90 = enchantVals[math.floor(#enchantVals * 0.9)] or 0, value90 = data[math.floor(#data * 0.9)],
        }
    end

    log("Item data generation comleted")
    return out
end

function this.randomizeItems(itemsData)
    for itType, data in pairs(itemsData.itemGroup) do
        local count = #data.items
        for i, item in pairs(data.items) do
            local enchVal = data.enchantValues[item.id]
            local mul = (i / count) ^ this.config.item.enchantment.powMul
            local encCount = math.max(1, this.config.item.enchantment.effects.maxCount * (mul ^ this.config.item.enchantment.effects.countPowMul))
            this.randomizeBaseItemVisuals(item, itemsData, data.meshes)
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

function this.clearFixedCellTable()
    if tes3.player then
        local data = dataSaver.getObjectData(tes3.player)
        if data and data.fixedCellTable then
            data.fixedCellTable = {}
        end
    end
end

function this.addFixedCellTableCheckRequirement()
    if tes3.player then
        local data = dataSaver.getObjectData(tes3.player)
        if data then
            data.requireCellCheck = true
        end
    end
end

function this.addTofixedCellTable(cell)
    if tes3.player and cell and this.config.item.tryToFixZCoordinate then
        local data = dataSaver.getObjectData(tes3.player)
        if data then
            if not data.fixedCellTable then data.fixedCellTable = {} end
            data.fixedCellTable[cell.editorName] = true
        end
    end
end

function this.isCellFixed(cell)
    if tes3.player and cell then
        local data = dataSaver.getObjectData(tes3.player)
        if data and (not data.requireCellCheck or (data.fixedCellTable and data.fixedCellTable[cell.editorName])) then
            return true
        end
    end
    return false
end

local function getZ(vector, root)
    local res1 = tes3.rayTest {
        position = vector,
        direction = tes3vector3.new(0, 0, -1),
        observeAppCullFlag  = true,
        root = root,
        useBackTriangles = true,
        maxDistance = 500
    }
    -- local res2 = tes3.rayTest {
    --     position = tes3vector3.new(vector.x, vector.y, vector.z - 1),
    --     direction = tes3vector3.new(0, 0, 1),
    --     observeAppCullFlag = true,
    --     root = root,
    --     useBackTriangles = true,
    --     maxDistance = 500
    -- }
    if res1 and res2 then
        if math.abs(res1.intersection.z - vector.z) < math.abs(res2.intersection.z - vector.z) then
            return res1.intersection.z
        else
            return res2.intersection.z
        end
    end
    if res1 then return res1.intersection.z end
    if res2 then return res2.intersection.z end
    log("Ray tracing failed %s %s %s", tostring(vector.x), tostring(vector.y), tostring(vector.z))
    return nil
end

function this.fixCell(cell)
    for ref in cell:iterateReferences() do
        if this.itemTypeWhiteList[ref.baseObject.objectType] then
            if ref.object.inventory then
                this.fixInventory(ref.object.inventory)
            end
            if ref.itemData then
                if this.config.item.tryToFixZCoordinate and ref.baseObject.boundingBox and not this.isCellFixed(cell) then
                    local vector = tes3vector3.new(ref.position.x, ref.position.y, ref.position.z - ref.baseObject.boundingBox.min.z)
                    local z = getZ(vector, tes3.game.worldObjectRoot)
                    if not z then z = getZ(vector, tes3.game.worldLandscapeRoot) end
                    if z then
                        ref.position = tes3vector3.new(ref.position.x, ref.position.y, z - ref.baseObject.boundingBox.min.z)
                        log("position fixed %s", tostring(ref))
                    end
                end
                this.fixItemData(ref.itemData, ref.baseObject)
            end
        end
    end
    this.addTofixedCellTable(cell)
end

function this.fixPlayerInventory()
    local player = tes3.mobilePlayer
    if player then
        for stack, item, count, itemData in this.iterItems(player.inventory) do
            this.fixItemData(itemData, item)
        end
    end
end

return this