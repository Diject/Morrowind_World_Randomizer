local dataSaver = include("Morrowind World Randomizer.dataSaver")
local random = require("Morrowind World Randomizer.Random")

local treesData = require("Morrowind World Randomizer.Data.TreesData")
local rocksData = require("Morrowind World Randomizer.Data.RocksData")

local generator = require("Morrowind World Randomizer.generator")

local itemsData = json.loadfile("mods\\Morrowind World Randomizer\\Data\\Items")
local creaturesData = json.loadfile("mods\\Morrowind World Randomizer\\Data\\Creatures")
local herbsData = json.loadfile("mods\\Morrowind World Randomizer\\Data\\Herbs")
local headPartsData = json.loadfile("mods\\Morrowind World Randomizer\\Data\\HeadsHairs")
local travelDestinationsData = json.loadfile("mods\\Morrowind World Randomizer\\Data\\TravelDestinations")
local spellsData = json.loadfile("mods\\Morrowind World Randomizer\\Data\\Spells")


local this = {}

this.config = require("Morrowind World Randomizer.config")
this.doors = require("Morrowind World Randomizer.doorRandomizer")
this.doors.initConfig(this.config)

function this.genStaticData()
    local TRDataVersion = 0
    for i, mod in pairs(tes3.dataHandler.nonDynamicData.activeMods) do
        if mod.filename:lower() == "tamriel_data.esm" then
            TRDataVersion = tonumber(string.match(mod.description, "%d+") or "0")
        end
    end

    if this.config.global.dataTables.forceTRData or TRDataVersion >= 9 then
        treesData = require("Morrowind World Randomizer.Data.TreesData_TR")
        rocksData = require("Morrowind World Randomizer.Data.RocksData_TR")
    end

    if this.config.global.dataTables.usePregeneratedItemData then
        if this.config.global.dataTables.forceTRData or TRDataVersion >= 9 then
            itemsData = json.loadfile("mods\\Morrowind World Randomizer\\Data\\Items_TR")
        end
    else
        itemsData = generator.fillItems()
    end

    if this.config.global.dataTables.usePregeneratedCreatureData then
        if this.config.global.dataTables.forceTRData or TRDataVersion >= 9 then
            creaturesData = json.loadfile("mods\\Morrowind World Randomizer\\Data\\Creatures_TR")
        end
    else
        creaturesData = generator.fillCreatures()
    end

    if this.config.global.dataTables.usePregeneratedHeadHairData then
        if this.config.global.dataTables.forceTRData or TRDataVersion >= 9 then
            headPartsData = json.loadfile("mods\\Morrowind World Randomizer\\Data\\HeadsHairs_TR")
        end
    else
        headPartsData = generator.fillHeadsHairs()
    end

    if this.config.global.dataTables.usePregeneratedSpellData then
        if this.config.global.dataTables.forceTRData or TRDataVersion >= 9 then
            spellsData = json.loadfile("mods\\Morrowind World Randomizer\\Data\\Spells_TR")
        end
    else
        spellsData = generator.fillSpells()
    end

    if this.config.global.dataTables.usePregeneratedHerbData then
        if this.config.global.dataTables.forceTRData or TRDataVersion >= 9 then
            herbsData = json.loadfile("mods\\Morrowind World Randomizer\\Data\\Herbs_TR")
        end
    else
        herbsData = generator.fillHerbs()
    end

    if this.config.global.dataTables.usePregeneratedTravelData then
        if this.config.global.dataTables.forceTRData or TRDataVersion >= 9 then
            travelDestinationsData = json.loadfile("mods\\Morrowind World Randomizer\\Data\\TravelDestinations_TR")
        end
    else
        travelDestinationsData = generator.findTravelDestinations()
    end

    -- json.savefile("mods\\Morrowind World Randomizer\\Data\\Items_TR", itemsData)
    -- json.savefile("mods\\Morrowind World Randomizer\\Data\\Creatures_TR", creaturesData)
    -- json.savefile("mods\\Morrowind World Randomizer\\Data\\HeadsHairs_TR", headPartsData)
    -- json.savefile("mods\\Morrowind World Randomizer\\Data\\Spells_TR", spellsData)
    -- json.savefile("mods\\Morrowind World Randomizer\\Data\\Herbs_TR", herbsData)
    -- json.savefile("mods\\Morrowind World Randomizer\\Data\\TravelDestinations_TR", travelDestinationsData)
end

function this.genNonStaticData()
    
end

local function iterItems(ref)
    local function iterator()
        for _, stack in pairs(ref.object.inventory) do
            ---@cast stack tes3itemStack
            local item = stack.object

            -- Account for restocking items,
            -- since their count is negative
            local count = math.abs(stack.count)

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

local function getGroundZ(vector)
    local res = tes3.rayTest {
        position = vector,
        direction = tes3vector3.new(0, 0, -1),
        root = tes3.game.worldLandscapeRoot,
        maxDistance = 6000
    }
    if res == nil then
        res = tes3.rayTest {
            position = vector,
            direction = tes3vector3.new(0, 0, 1),
            root = tes3.game.worldLandscapeRoot,
            maxDistance = 6000
        }
    end
    if res ~= nil then
        return res.intersection.z
    end
    return nil
end

local function getGroundPos(vector, offset)
    local res = getGroundZ(vector)
    if res ~= nil then
        return tes3vector3.new(vector.x, vector.y, res + offset)
    end
    return nil
end

local pointOnCircleSin = {}
local pointOnCircleCos = {}
for i = 1, 8 do
    pointOnCircleSin[i] = math.sin((math.pi / 4) * i)
    pointOnCircleCos[i] = math.cos((math.pi / 4) * i)
end

local function getMinGroundPosInCircle(vector, radius, offset)
    local minZ = math.huge
    for i = 1, 8 do
        local posVector = tes3vector3.new(vector.x + radius * pointOnCircleCos[i], vector.y + radius * pointOnCircleSin[i], vector.z)
        local z = getGroundZ(posVector)
        if z ~= nil then
            minZ = math.min(minZ, z)
        end
    end
    local z = getGroundZ(vector)
    if z ~= nil then
        minZ = math.min(minZ, z)
    end
    if minZ ~= math.huge then
        return tes3vector3.new(vector.x, vector.y, minZ + offset)
    end
    return nil
end

local function minDistanceBetweenVectors(vector, vectorArray)
    local distance = math.huge
    for i, vector2 in pairs(vectorArray) do
        distance = math.min(distance, vector:distance(vector2))
    end
    return distance
end

local function putOriginMark(object)
    local data = dataSaver.getObjectData(object)
    data.origin = true
end

local function deleteOriginMark(object)
    local data = dataSaver.getObjectData(object)
    data.origin = nil
end

local function randomizeSoulgemItemData(itemData)
    local config = this.config.data.soulGems
    if config.soul.randomize and itemData ~= nil and itemData.soul ~= nil then
        local soulCrea = creaturesData.Creatures[itemData.soul.id:lower()]
        if soulCrea ~= nil then
            local creaGroup = creaturesData.CreatureGroups[soulCrea.SubType]
            local newCreaId = creaGroup.Items[random.GetRandom(soulCrea.Position, creaGroup.Count,
                config.soul.region.min, config.soul.region.max)]
            itemData.soul = tes3.getObject(newCreaId)
        end
    end
end

function this.isOrigin(object)
    local data = dataSaver.getObjectData(object)
    return data.origin or false
end

function this.StopRandomizationTemp(object)
    local data = dataSaver.getObjectTempData(object)
    data.stopRand = true
end

function this.StopRandomization(object)
    local data = dataSaver.getObjectData(object)
    data.stopRand = true
end

function this.isRandomizationStoppedTemp(object)
    local data = dataSaver.getObjectTempData(object)
    if data ~= nil and data.stopRand == true then
        return true
    end
    return false
end

function this.isRandomizationStopped(object)
    local data = dataSaver.getObjectData(object)
    if data ~= nil and data.stopRand == true then
        return true
    end
    return false
end

function this.getNewRandomItemId(oldItemId, min, max)
    local newId
    local itemAdvData = itemsData.Items[oldItemId]
    if itemAdvData ~= nil then

        local newItemGroup = itemsData.ItemGroups[itemAdvData.Type][itemAdvData.SubType]
        newId = newItemGroup.Items[random.GetRandom(itemAdvData.Position, newItemGroup.Count,
            min or this.config.data.containers.items.region.min, max or this.config.data.containers.items.region.max)]

    end
    return newId
end

function this.getRandomCreatureId(oldCreatureId)
    local creaId = oldCreatureId:lower()
    local creature = creaturesData.Creatures[creaId]
    if creature ~= nil then
        local newCreaGroup = creaturesData.CreatureGroups[creature.SubType]
        local newCreaId = newCreaGroup.Items[random.GetRandom(creature.Position, newCreaGroup.Count,
            this.config.data.creatures.region.min, this.config.data.creatures.region.max)]
        return newCreaId
    end
    return nil
end

function this.randomizeContainerItems(reference, regionMin, regionMax)
    local config = this.config.data
    local newItems = {}
    local oldItems = {}
    for stack, item, count, itemData in iterItems(reference) do

        if item.id ~= nil then
            local itemId = item.id:lower()
            local itemAdvData = itemsData.Items[itemId]
            if itemAdvData ~= nil and reference ~= nil then

                local newItemGroup = itemsData.ItemGroups[itemAdvData.Type][itemAdvData.SubType]
                local newItemId = newItemGroup.Items[random.GetRandom(itemAdvData.Position, newItemGroup.Count, regionMin, regionMax)]
                table.insert(newItems, {id = newItemId, count = count, itemData = itemData})
                table.insert(oldItems, {id = item.id, count = count})

            elseif stack.object.isGold and config.gold.randomize then

                local newCount = math.floor(math.max(count * (config.gold.region.min + math.random() * (config.gold.region.max - config.gold.region.min)), 1))
                stack.count = newCount

            elseif stack.object.isSoulGem and config.soulGems.soul.randomize then

                randomizeSoulgemItemData(stack.itemData)

            end
        end
    end

    for i, item in pairs(oldItems) do
        tes3.removeItem({ reference = reference, item = item.id, count = item.count, updateGUI = false })
    end

    for i, item in pairs(newItems) do
        tes3.addItem({ reference = reference, item = item.id, count = item.count, updateGUI = false })
    end
    reference:updateEquipment()
end

function this.createObject(object)
    local newObject = tes3.getObject(object.id)
    if newObject ~= nil then
        local reference = tes3.createReference{ object = newObject, position = object.pos, orientation = object.rot, cell = object.cell, scale = object.scale or 1 }
        if reference ~= nil then
            dataSaver.getObjectData(reference).isCreated = true
            this.StopRandomizationTemp(reference)
            if object.itemData ~= nil then
                if object.itemData.owner ~= nil or object.itemData.requirement ~= nil then
                    tes3.setOwner({ reference = reference, owner = object.itemData.owner, requiredRank = object.itemData.requirement })
                end
                reference.itemData.count = object.itemData.count
            end
        end
    end
end

function this.randomizeCell(cell)
    local newObjects = {}
    local config = this.config.data

    local newTreeGroupId = math.random(1, treesData.GroupsCount)
    -- if newTreeGroupId == 2 then newTreeGroupId = treesData.GroupsCount - 2 end
    -- if newTreeGroupId == 3 then newTreeGroupId = treesData.GroupsCount - 1 end
    local newRockGroupId = math.random(1, rocksData.GroupsCount)
    local newTreeGroup = treesData.TreesGroups[newTreeGroupId]
    local newRockGroup = rocksData.RocksGroups[newRockGroupId]

    local herbsList = {}
    local herbsToListCount = config.herbs.herbSpeciesPerCell
    local herbsTempTable = {}
    while herbsToListCount > 0 do
        local dt = herbsData.HerbsObjectList[math.random(1, herbsData.HerbsListCount)]:lower()
        if herbsTempTable[dt] == nil then
            herbsToListCount = herbsToListCount - 1
            herbsTempTable[dt] = true
        end
    end
    for id, _ in pairs(herbsTempTable) do
        table.insert(herbsList, id)
    end

    local doorPoss = {}
    for door in cell:iterateReferences(tes3.objectType.door) do
        if door ~= nil and door.disabled ~= true then
            table.insert(doorPoss, door.position)
            this.doors.resetDoorDestination(door)
        end
    end

    for object in cell:iterateReferences() do
        if object ~= nil and object.data ~= nil and object.deleted ~= true and
                object.data.stopRand ~= true and object.tempData.stopRand ~= true then
            local objectId = object.id:lower()
            local objectPos = object.position
            local objectRot = object.orientation
            local objectScale = object.scale or 1
            local objectData = dataSaver.getObjectData(object)


            if objectData ~= nil and objectData.isCreated == true and not object.isDead then
                object:delete()

            elseif object.baseObject.objectType == tes3.objectType.static and object.cell.isOrBehavesAsExterior then

                local treeAdvData = treesData.TreesOffset[objectId]
                local rockAdvData = rocksData.RocksOffset[objectId]
                if treeAdvData ~= nil and objectScale < config.trees.exceptScale then
                    if config.trees.randomize and (this.isOrigin(object) or not object.disabled) then
                        local newId = newTreeGroup.Items[math.random(1, newTreeGroup.Count)]
                        local newAdvData = treesData.TreesOffset[newId:lower()]
                        local newOffset
                        if newAdvData == nil then
                            newOffset = 0
                        else
                            newOffset = newAdvData.Offset
                        end

                        local posVector = getMinGroundPosInCircle(objectPos, 200, (newOffset - math.random(0, 100)) * objectScale)
                        if posVector == nil then
                            posVector = tes3vector3.new(objectPos.x, objectPos.y, (newOffset - treeAdvData.Offset - math.random(0, 100)) * objectScale)
                        end
                        table.insert(newObjects, {id = newId, pos = posVector, rot = objectRot, scale = objectScale, cell = cell})
                        putOriginMark(object)
                        object:disable()

                    elseif this.isOrigin(object) and object.disabled then
                        this.deleteOriginMark(object)
                        object:enable()
                    end

                elseif rockAdvData ~= nil and objectScale < config.stones.exceptScale then
                    if config.stones.randomize and (this.isOrigin(object) or not object.disabled) then
                        local newId = newRockGroup.Items[math.random(1, newRockGroup.Count)]
                        if newId then
                            local newAdvData = rocksData.RocksOffset[newId:lower()]
                            local newRockOffset
                            if newAdvData == nil then
                                newRockOffset = 0
                            else
                                newRockOffset = newAdvData.Offset
                            end
                            local scale = objectScale

                            if newRockOffset >= 450 then
                                scale = math.min(objectScale, 1.0)
                            elseif newRockOffset >= 250 then
                                scale = math.min(objectScale, 2.0)
                            end

                            scale = (0.5 + math.random() * 0.5) * scale

                            if objectScale <= 0.4 and scale > 0.4 then
                                scale = objectScale
                            end

                            local distanceToDoor =  minDistanceBetweenVectors(objectPos, doorPoss)
                            if distanceToDoor < 300 then
                                scale = math.min(scale, 0.25)
                            elseif distanceToDoor < 1000 then
                                scale = math.min(scale, 0.25 + 0.75 * distanceToDoor / 1000)
                            end

                            local offset = newRockOffset
                            if newRockOffset >= 600 then
                                offset = offset + math.random(100, 200)
                            elseif newRockOffset >= 150 then
                                offset = offset + math.random(0, 100)
                            end

                            local posVector = getMinGroundPosInCircle(objectPos, 500, offset * scale)

                            if posVector == nil then
                                posVector = tes3vector3.new(objectPos.x, objectPos.y, (newRockOffset - rockAdvData.Offset) * scale)
                            end

                            table.insert(newObjects, {id = newId, pos = posVector, rot = objectRot, scale = scale, cell = cell})
                            putOriginMark(object)
                            object:disable()
                        end

                    elseif this.isOrigin(object) and object.disabled then
                        this.deleteOriginMark(object)
                        object:enable()
                    end

                end

            elseif object.baseObject.objectType == tes3.objectType.container then

                local herbAdvData = herbsData.Herbs[objectId]
                if herbAdvData ~= nil then
                    if config.herbs.randomize and object.cell.isOrBehavesAsExterior and (this.isOrigin(object) or not object.disabled) then
                        local newId = herbsList[math.random(1, #herbsList)]
                        local newHerbAdvData = herbsData.Herbs[newId]
                        if newHerbAdvData ~= nil then
                            local posVector = getGroundPos(objectPos, (newHerbAdvData.Offset - math.random(0, 5)) * objectScale)
                            if posVector == nil then
                                posVector = tes3vector3.new(objectPos.x, objectPos.y, (newHerbAdvData.Offset - herbAdvData.Offset - math.random(0, 5)) * objectScale)
                            end

                            local rot = objectRot:copy()
                            if newId:sub(1, -4) == "flora_bc_shelffungus" then
                                rot.y = rot.y + 1.65
                            end

                            this.StopRandomizationTemp(object)
                            table.insert(newObjects, {id = newId, pos = posVector, rot = rot, scale = objectScale, cell = cell})
                            putOriginMark(object)
                            object:disable()

                        end
                    elseif this.isOrigin(object) and object.disabled then
                        this.deleteOriginMark(object)
                        object:enable()
                    end

                else
                    this.randomizeContainerItems(object, this.config.data.containers.items.region.min, this.config.data.containers.items.region.max)
                    this.randomizeLockTrap(object)
                end

            elseif (object.baseObject.objectType == tes3.objectType.weapon or
                    object.baseObject.objectType == tes3.objectType.alchemy or
                    object.baseObject.objectType == tes3.objectType.apparatus or
                    object.baseObject.objectType == tes3.objectType.armor or
                    object.baseObject.objectType == tes3.objectType.book or
                    object.baseObject.objectType == tes3.objectType.clothing or
                    object.baseObject.objectType == tes3.objectType.ingredient or
                    object.baseObject.objectType == tes3.objectType.lockpick or
                    object.baseObject.objectType == tes3.objectType.probe or
                    object.baseObject.objectType == tes3.objectType.repairItem) then

                local itemAdvData = itemsData.Items[objectId]
                if itemAdvData ~= nil then
                    local newItemGroup = itemsData.ItemGroups[itemAdvData.Type][itemAdvData.SubType]
                    local newItemId = newItemGroup.Items[random.GetRandom(itemAdvData.Position, newItemGroup.Count,
                        this.config.data.items.region.min, this.config.data.items.region.max)]
                    table.insert(newObjects, {id = newItemId, pos = objectPos, rot = objectRot, scale = objectScale, itemData = object.itemData,
                        objectType = object.object.objectType, cell = cell})
                    object:disable()
                end

            elseif object.baseObject.objectType == tes3.objectType.miscItem then

                if object.object.isSoulGem then

                    randomizeSoulgemItemData(object.itemData)

                end

            elseif not object.isDead and object.baseObject.objectType == tes3.objectType.creature and object.leveledBaseReference ~= true then

                -- local actorId = objectId:sub(1, -9)
                local actorId = object.baseObject.id:lower()
                local creature = creaturesData.Creatures[actorId]
                if creature ~= nil then
                    object.mobile:kill()
                    object:disable()
                    local newCreaGroup = creaturesData.CreatureGroups[creature.SubType]
                    local newCreaId = newCreaGroup.Items[random.GetRandom(creature.Position, newCreaGroup.Count,
                        this.config.data.creatures.region.min, this.config.data.creatures.region.max)]
                    table.insert(newObjects, {id = newCreaId, cell = cell, pos = objectPos, rot = objectRot, scale = objectScale})
                end

            -- elseif object.baseObject.objectType == tes3.objectType.npc then

            --     this.randomizeContainerItems(object, this.config.data.NPCs.items.region.min, this.config.data.NPCs.items.region.max)

            elseif object.baseObject.objectType == tes3.objectType.door then

                this.randomizeLockTrap(object)

            end

        elseif object ~= nil and object.baseObject.objectType == tes3.objectType.miscItem and object.itemData ~= nil and
                object.object.isGold and config.gold.randomize then

            local newCount = math.floor(math.max(object.itemData.count *
                (config.gold.region.min + math.random() * (config.gold.region.max - config.gold.region.min)), 1))
            object.itemData.count = newCount

        end
    end

    for i, object in pairs(newObjects) do
        this.createObject(object)
    end
end

local positiveAttrs = { "chameleon", "waterBreathing", "waterWalking", "swiftSwim", }
local negativeAttrs = { "sound", "silence", "blind", "paralyze" }
local bothAttrs = { "resistNormalWeapons", "sanctuary", "attackBonus", "resistMagicka", "resistFire", "resistFrost", "resistShock", "resistCommonDisease", "resistBlightDisease", "resistCorprus", "resistPoison", "resistParalysis", "shield" }
local combatSkillIds = {tes3.skill.block, tes3.skill.armorer,  tes3.skill.mediumArmor, tes3.skill.heavyArmor, tes3.skill.bluntWeapon, tes3.skill.longBlade, tes3.skill.axe, tes3.skill.spear, tes3.skill.athletics,}
local magicSkillIds = {tes3.skill.enchant, tes3.skill.destruction,  tes3.skill.alteration, tes3.skill.illusion, tes3.skill.conjuration, tes3.skill.mysticism, tes3.skill.restoration, tes3.skill.alchemy, tes3.skill.unarmored,}
local stealthSkillIds = {tes3.skill.security, tes3.skill.sneak,  tes3.skill.acrobatics, tes3.skill.lightArmor, tes3.skill.shortBlade, tes3.skill.marksman, tes3.skill.mercantile, tes3.skill.speechcraft, tes3.skill.handToHand,}

function this.randomizeMobileActor(mobile)
    local objectData = dataSaver.getObjectData(mobile.reference)
    local configData = this.config.data
    local configTable
    if mobile.actorType == tes3.actorType.npc then
        configTable = configData.NPCs
    elseif mobile.actorType == tes3.actorType.creature then
        configTable = configData.creatures
    end

    if configTable == nil or objectData == nil then
        return
    end

    -- Save or restore initial data
    if objectData.actorData == nil then objectData.actorData = {} end

    if objectData.actorData.skills == nil then
        objectData.actorData.skills = {}
        for i, skillVal in ipairs(mobile.skills) do
            objectData.actorData.skills[i] = skillVal.base
        end
    else
        for i, skillVal in ipairs(mobile.skills) do
            mobile.skills[i].base = objectData.actorData.skills[i]
        end
    end

    if objectData.actorData.attributes == nil then
        objectData.actorData.attributes = {}
        for i, attributeVal in ipairs(mobile.attributes) do
            objectData.actorData.attributes[i] = attributeVal.base
        end
    else
        for i, attributeVal in ipairs(mobile.attributes) do
            mobile.attributes[i].base = objectData.actorData.attributes[i]
        end
    end

    if objectData.actorData.health == nil then
        objectData.actorData.health = mobile.health.base
        objectData.actorData.magicka = mobile.magicka.base
        objectData.actorData.fatigue = mobile.fatigue.base
    else
        mobile.health.base = objectData.actorData.health
        mobile.magicka.base = objectData.actorData.magicka
        mobile.fatigue.base = objectData.actorData.fatigue
    end

    if objectData.actorData.ai == nil then
        objectData.actorData.ai = {}
        for label, data in ipairs(configTable.ai) do
            objectData.actorData.ai[label] = mobile[label]
        end
    else
        for label, data in ipairs(configTable.ai) do
            mobile[label] = objectData.actorData.ai[label]
        end
    end

    if objectData.actorData.effects == nil then
        objectData.actorData.effects = {}
        for i, effAttr in ipairs(mobile.effectAttributes) do
            objectData.actorData.effects[i] = effAttr
        end
    else
        for i, effAttr in ipairs(mobile.effectAttributes) do
            mobile.effectAttributes[i] = objectData.actorData.effects[i]
        end
    end

    local setNew = function(attribute, region, limit, useRangeVal)
        if limit == nil then limit = math.huge end
        local base = attribute.base
        local normalized = attribute.normalized
        local newVal = useRangeVal and random.GetRandom(base, limit, region.min, region.max) or
            math.floor(math.min(base * (region.min + math.random() * (region.max - region.min)), limit))
        attribute.base = newVal
        attribute.current = newVal * normalized
    end


    if mobile.actorType == tes3.actorType.npc then
        if configTable.attributes.randomize then
            for i, attributeVal in ipairs(mobile.attributes) do
                setNew(attributeVal, configTable.attributes.region, configTable.attributes.limit)
            end
        end
    end
    if configTable.skills.randomize then
        if mobile.actorType == tes3.actorType.npc then
            for _, skillId in pairs(combatSkillIds) do
                setNew(mobile.skills[skillId + 1], configTable.skills.combat.region, configTable.skills.limit, true)
            end
            for _, skillId in pairs(magicSkillIds) do
                setNew(mobile.skills[skillId + 1], configTable.skills.magic.region, configTable.skills.limit, true)
            end
            for _, skillId in pairs(stealthSkillIds) do
                setNew(mobile.skills[skillId + 1], configTable.skills.stealth.region, configTable.skills.limit, true)
            end
        elseif mobile.actorType == tes3.actorType.creature then
            setNew(mobile.skills[tes3.specialization.combat + 1], configTable.skills.combat.region, configTable.skills.limit, true)
            setNew(mobile.skills[tes3.specialization.magic + 1], configTable.skills.magic.region, configTable.skills.limit, true)
            setNew(mobile.skills[tes3.specialization.stealth + 1], configTable.skills.stealth.region, configTable.skills.limit, true)
        end
    end

    if configTable.health.randomize then
        setNew(mobile.health, configTable.health.region)
    end
    if configTable.fatigue.randomize then
        setNew(mobile.fatigue, configTable.fatigue.region)
    end
    if configTable.magicka.randomize then
        setNew(mobile.magicka, configTable.magicka.region)
    end

    for label, data in pairs(configTable.ai) do
        mobile[label] = random.GetRandom(mobile[label], 100, data.region.min, data.region.max)
    end

    local posListCount = #positiveAttrs
    local bothListCount = #bothAttrs
    local negListCount = #negativeAttrs

    local posEffectsAddCount = configTable.effects.positive.add.count
    local posEffects = {}
    local posRepeat = 50
    while posEffectsAddCount > 0 and posRepeat > 0 do
        if configTable.effects.positive.add.chance > math.random() then
            local count = posListCount + bothListCount
            local pos = math.random(1, count)
            local param
            local val = math.random(configTable.effects.positive.add.region.min, configTable.effects.positive.add.region.max)
            if pos <= posListCount then
                param = positiveAttrs[pos]
            else
                param = bothAttrs[pos - posListCount]
            end

            if param == "attackBonus" then
                val = math.ceil(val * 0.1)
            end

            if posEffects[param] == nil then
                posEffectsAddCount = posEffectsAddCount - 1
            end

            posEffects[param] = val
        end
        posRepeat = posRepeat - 1
    end
    local negEffectsAddCount = configTable.effects.negative.add.count
    local negEffects = {}
    local negRepeat = 50
    while negEffectsAddCount > 0 and negRepeat > 0 do
        if configTable.effects.negative.add.chance > math.random() then
            local count = negListCount + bothListCount
            local pos = math.random(1, count)
            local param
            local val = math.random(configTable.effects.negative.add.region.min, configTable.effects.negative.add.region.max)
            if pos <= negListCount then
                param = negativeAttrs[pos]
            else
                param = bothAttrs[pos - negListCount]
                val = -val
            end

            if param == "attackBonus" then
                val = math.floor(val * 0.1)
            end

            if negEffects[param] == nil then
                negEffectsAddCount = negEffectsAddCount - 1
            end

            negEffects[param] = val
        end
        negRepeat = negRepeat - 1
    end

    for param, val in pairs(posEffects) do
        mobile[param] = mobile[param] + val
    end

    for param, val in pairs(negEffects) do
        mobile[param] = mobile[param] + val
    end

    mobile.reference.modified = true
    mobile:updateDerivedStatistics()
    mobile:updateOpacity()
end

local actorObjectsInitialData = {}

function this.randomizeActorBaseObject(object, actorType)
    if actorObjectsInitialData[object.id] == nil then actorObjectsInitialData[object.id] = {} end
    local objectData = actorObjectsInitialData[object.id]
    local configData = this.config.data
    local configTable
    if object.actorType == tes3.actorType.npc or actorType == tes3.actorType.npc then
        configTable = configData.NPCs
    elseif object.actorType == tes3.actorType.creature or actorType == tes3.actorType.creature then
        configTable = configData.creatures
    end

    if configTable == nil or objectData == nil then
        return
    end

    -- Save or restore initial data
    if objectData.actorData == nil then objectData.actorData = {} end

    if objectData.actorData.spells == nil then
        objectData.actorData.spells = {}
        for i, spell in pairs(object.spells) do
            table.insert(objectData.actorData.spells, spell.id)
        end
        objectData.actorData.barterGold = object.barterGold

        if object.aiConfig.travelDestinations ~= nil then
            objectData.actorData.travelDestinations = {}
            for i, destination in pairs(object.aiConfig.travelDestinations) do
                objectData.actorData.travelDestinations[i] = {cell = destination.cell, marker = destination.marker}
            end
        end
    else
        for i, spell in pairs(object.spells) do
            object.spells:remove(spell)
        end
        for i, spellId in ipairs(objectData.actorData.spells) do
            object.spells:add(spellId)
        end

        object.barterGold = objectData.actorData.barterGold

        if object.aiConfig.travelDestinations ~= nil and objectData.actorData.travelDestinations ~= nil then
            for i, destination in pairs(object.aiConfig.travelDestinations) do
                destination.cell = objectData.actorData.travelDestinations[i].cell
                destination.marker = objectData.actorData.travelDestinations[i].marker
            end
        end
    end

    if configTable.attack ~= nil and configTable.attack.randomize and object.attacks ~= nil then
        for i, val in ipairs(object.attacks) do
            local min = val.min * math.random () * (configTable.attack.region.min + (configTable.attack.region.max - configTable.attack.region.min))
            local max = val.max * math.random () * (configTable.attack.region.min + (configTable.attack.region.max - configTable.attack.region.min))
            if min > max then max = min end
            val.min = min
            val.max = max
        end
    end

    local tesAI = object.aiConfig

    if tesAI.travelDestinations ~= nil and configData.transport.randomize then
        local arrWithPos = {}
        local destCount = #tesAI.travelDestinations
        for i = 1, destCount do
            table.insert(arrWithPos, i)
        end
        for i = 1, destCount do
            local rnd = math.random(1, destCount)
            arrWithPos[i], arrWithPos[rnd] = arrWithPos[rnd], arrWithPos[i]
        end

        local toDoors = configData.transport.toDoorsCount
        local toRandomPoint = configData.transport.toRandomPointCount
        for i, pos in ipairs(arrWithPos) do

            if i > configData.transport.unrandomizedCount then

                local destination = tesAI.travelDestinations[arrWithPos[pos]]
                if toDoors > 0 then
                    toDoors = toDoors - 1
                    local door = this.doors.doorsData.All[math.random(1, #this.doors.doorsData.All)]
                    if door ~= nil then
                        destination.cell = door.destination.cell
                        destination.marker = door.destination.marker
                    end

                elseif toRandomPoint > 0 then -- TODO
                    toRandomPoint = toRandomPoint - 1
                    local x = math.random(-20000, 20000)
                    local y = math.random(-20000, 20000)
                    destination.cell = tes3.getCell{ x = math.floor(x / 8192), y = math.floor(y / 8192)}
                    destination.marker.position = tes3vector3.new(x, y, 4000)
                    destination.marker.orientation = tes3vector3.new(0, 0, 0)

                else
                    local newDest = travelDestinationsData[math.random(1, #travelDestinationsData)]
                    destination.cell = newDest.cell
                    destination.marker.position = tes3vector3.new(newDest.marker.position.x, newDest.marker.position.y, newDest.marker.position.z)
                    destination.marker.orientation = tes3vector3.new(newDest.marker.orientation.x, newDest.marker.orientation.y, newDest.marker.orientation.z)
                end
            end
        end
    end


    local spellList = object.spells
    local newSpells = {}
    local configGroupByType = {"spells", "abilities", "diseases", "diseases"}
    for i, spell in pairs(spellList) do
        local spellId = spell.id:lower()
        local spellData = spellsData.Spells[spellId]
        local spellType = spell.castType
        if spellData ~= nil then
            if (spellType == tes3.spellType.spell and configTable.spells.randomize) or
                    (spellType == tes3.spellType.ability and configTable.abilities.randomize) or
                    ((spellType == tes3.spellType.blight or spellType == tes3.spellType.disease) and configTable.diseases.randomize) then
                local spellEffectData = spellData[math.random(1, #spellData)]
                local spellGroup = spellsData.SpellGroups[tostring(spellEffectData.SubType)]
                local pos = random.GetRandom(spellEffectData.Position, spellGroup.Count,
                    configTable[configGroupByType[spellType + 1]].region.min, configTable[configGroupByType[spellType + 1]].region.max)
                local i = 20
                while i > 0 and newSpells[spellGroup.Items[pos]] ~= nil do
                    i = i - 1
                    pos = random.GetRandom(spellEffectData.Position, spellGroup.Count,
                        configTable[configGroupByType[spellType + 1]].region.min, configTable[configGroupByType[spellType + 1]].region.max)
                end
                newSpells[spellGroup.Items[pos]] = true
                spellList:remove(spell)
            end
        end
    end

    local spellsAddCount = configTable.spells.add.count
    for i = 1, spellsAddCount do
        if configTable.spells.add.chance > math.random() then
            local newSpellGroup = spellsData.SpellGroups[tostring(math.random(10, 15))]
            local pos = random.GetRandom(math.floor(math.min(newSpellGroup.Count * (object.level / configTable.spells.add.levelReference), newSpellGroup.Count)),
                newSpellGroup.Count, configTable.spells.region.min, configTable.spells.region.max)
            local j = 20
            while j > 0 and newSpells[newSpellGroup.Items[pos]] ~= nil do
                j = j - 1
                pos = random.GetRandom(math.floor(math.min(newSpellGroup.Count * (object.level / configTable.spells.add.levelReference), newSpellGroup.Count)),
                    newSpellGroup.Count, configTable.spells.region.min, configTable.spells.region.max)
            end
            newSpells[newSpellGroup.Items[pos]] = true
        end
    end

    local abilitiesAddCount = configTable.abilities.add.count
    for i = 1, abilitiesAddCount do
        if configTable.abilities.add.chance > math.random() then
            local newSpellGroup = spellsData.SpellGroups["200"]
            local pos = math.random(1, newSpellGroup.Count)
            local j = 20
            while j > 0 and newSpells[newSpellGroup.Items[pos]] ~= nil do
                j = j - 1
                pos = math.random(1, newSpellGroup.Count)
            end
            newSpells[newSpellGroup.Items[pos]] = true
        end
    end

    local diseasesAddCount = configTable.diseases.add.count
    for i = 1, diseasesAddCount do
        if configTable.diseases.add.chance > math.random() then
            local newSpellGroup = spellsData.SpellGroups["201"]
            local pos = math.random(1, newSpellGroup.Count)
            local j = 20
            while j > 0 and newSpells[newSpellGroup.Items[pos]] ~= nil do
                j = j - 1
                pos = math.random(1, newSpellGroup.Count)
            end
            newSpells[newSpellGroup.Items[pos]] = true
        end
    end

    for spell, _ in pairs(newSpells) do
            spellList:add(spell)
    end

    if configData.barterGold.randomize and object.barterGold ~= nil then
        object.barterGold = math.floor(object.barterGold * (configData.barterGold.region.min + math.random() *
            (configData.barterGold.region.max - configData.barterGold.region.min)))
    end
end

local races = {}
for race, val in pairs(headPartsData.Parts) do
    table.insert(races, race)
end

function this.randomizeBody(mobile)
    local configData = this.config.data
    if mobile.actorType == tes3.actorType.npc then
        local race = mobile.object.race.id:lower()
        if configData.NPCs.hair.randomize and headPartsData.Parts[race] ~= nil then
            local newRace = race
            local genderId = mobile.object.female and 1 or 0
            if not configData.NPCs.hair.raceLimit then
                local newRaceId = math.random(1, #races)
                newRace = races[newRaceId]
            end
            if not configData.NPCs.hair.genderLimit then
                genderId = math.random(0, 1)
            end

            local hairList = headPartsData.Parts[newRace]["1"][tostring(genderId)]

            mobile.object.baseObject.hair = tes3.getObject(hairList[math.random(1, #hairList)])
        end
        if configData.NPCs.head.randomize and headPartsData.Parts[race] ~= nil then
            local newRace = race
            local genderId = mobile.object.female and 1 or 0
            if not configData.NPCs.head.raceLimit then
                local newRaceId = math.random(1, #races)
                newRace = races[newRaceId]
            end
            if not configData.NPCs.head.genderLimit then
                genderId = math.random(0, 1)
            end

            local headList = headPartsData.Parts[newRace]["0"][tostring(genderId)]

            mobile.object.baseObject.head = tes3.getObject(headList[math.random(1, #headList)])
        end
    end
end

function this.randomizeScale(reference)
    local configData
    if reference.mobile.actorType == tes3.actorType.npc then
        configData = this.config.data.NPCs
    elseif reference.mobile.actorType == tes3.actorType.creature then
        configData = this.config.data.creatures
    end

    if configData ~= nil then
        if configData.scale.randomize then
            reference.scale = reference.object.scale * (configData.scale.region.min + math.random() * (configData.scale.region.max - configData.scale.region.min))
        end
    end
end

function this.randomizeWeatherChance(cell)
    if this.config.data.weather.randomize and cell ~= nil and cell.region ~= nil then
        local weatherChances = {0, 0, 0, 0, 0, 0, 0, 0, 0, 0}
        for i = 1, 10 do
            local pos = math.random(1, 10)
            weatherChances[pos] = weatherChances[pos] + 10
        end
        cell.region.weatherChanceAsh = weatherChances[1]
        cell.region.weatherChanceBlight = weatherChances[2]
        cell.region.weatherChanceBlizzard = weatherChances[3]
        cell.region.weatherChanceClear = weatherChances[4]
        cell.region.weatherChanceCloudy = weatherChances[5]
        cell.region.weatherChanceFoggy = weatherChances[6]
        cell.region.weatherChanceOvercast = weatherChances[7]
        cell.region.weatherChanceRain = weatherChances[8]
        cell.region.weatherChanceSnow = weatherChances[9]
        cell.region.weatherChanceThunder = weatherChances[10]
    end
end

local function saveLockTrapInitialState(reference)
    local data = dataSaver.getObjectData(reference)
    if data and not data.lockNode and reference.lockNode then
        data.lockNode = {
            level = reference.lockNode.level,
            locked = reference.lockNode.locked,
        }
        if reference.lockNode.trap and reference.lockNode.trap.id then
            data.lockNode.trapId = reference.lockNode.trap.id
        end
    end
end

local function getLockTrapCDTimestamp(data)
    return data.lockTrapCDTimestamp or 0
end

local function setLockTrapCDTimestamp(data, value)
    data.lockTrapCDTimestamp = value
end

function this.resetLockTrapToDefault(reference)
    local data = dataSaver.getObjectData(reference)
    if data and data.lockNode and getLockTrapCDTimestamp(data) < tes3.getSimulationTimestamp() then
        if data.lockNode.level ~= reference.lockNode.level then
            tes3.setLockLevel{ reference = reference, level = data.lockNode.level }
        end
        if data.lockNode.locked ~= reference.lockNode.locked then
            reference.lockNode.locked = data.lockNode.locked
        end
        if reference.lockNode.trap and data.lockNode.trapId and reference.lockNode.trap.id ~= data.lockNode.trapId then
            tes3.setTrap{ reference = reference, spell = data.lockNode.trapId }
        end
    end
end

function this.randomizeLockTrap(reference)
    local configTable
    if reference.baseObject.objectType == tes3.objectType.door then
        if this.doors.forbiddenDoorIds[reference.baseObject.id:lower()] then
            return
        end
        configTable = this.config.data.doors
    elseif reference.baseObject.objectType == tes3.objectType.container then
        configTable = this.config.data.containers
    end
    local data = dataSaver.getObjectData(reference)
    if configTable and data and getLockTrapCDTimestamp(data) < tes3.getSimulationTimestamp() then
        saveLockTrapInitialState(reference)
        this.resetLockTrapToDefault(reference)
        setLockTrapCDTimestamp(data, tes3.getSimulationTimestamp() + configTable.lockTrapCooldown)

        if reference.lockNode ~= nil and configTable.lock.randomize and reference.lockNode.level > 0 then
            local newLevel = random.GetRandom(reference.lockNode.level, 100, configTable.lock.region.min, configTable.lock.region.max)

            tes3.setLockLevel{ reference = reference, level = newLevel }
        end
        if (reference.lockNode == nil or reference.lockNode.level == 0) and configTable.lock.add.chance > math.random() then
            local newLevel = math.random(1, math.min(100, configTable.lock.add.levelMultiplier * tes3.player.object.level))

            tes3.setLockLevel{ reference = reference, level = newLevel }
            reference.lockNode.locked = true
        end
        if reference.lockNode ~= nil and configTable.trap.randomize and reference.lockNode.trap ~= nil and reference.lockNode.trap.id ~= nil then
            local trap = spellsData.TouchRange[reference.lockNode.trap.id:lower()][1]
            if trap ~= nil then
                local trapGroup = spellsData.SpellGroups[tostring(trap.SubType)]
                if trapGroup ~= nil then
                    local newTrapSpellId = random.GetRandom(trap.Position, trapGroup.Count, configTable.trap.region.min, configTable.trap.region.max)
                    local newTrapSpell = tes3.getObject(trapGroup.Items[newTrapSpellId])
                    if newTrapSpell ~= nil then
                        reference.lockNode.trap = newTrapSpell
                    end
                end
            end
        end
        if (reference.lockNode == nil or reference.lockNode.trap == nil) and configTable.trap.add.chance > math.random() then
            local newGroup
            if configTable.trap.add.onlyDestructionSchool then
                newGroup = spellsData.SpellGroups["110"]
            else
                newGroup = spellsData.SpellGroups[tostring(math.random(110, 115))]
            end
            local newTrapSpellPos = math.random(1, math.floor(math.min(newGroup.Count,
                newGroup.Count * configTable.trap.add.levelMultiplier * tes3.player.object.level * 0.01)))
            local newSpell = tes3.getObject(newGroup.Items[newTrapSpellPos])
            local trapped = tes3.setTrap({ reference = reference, spell = newSpell })
        end
    end
end

return this