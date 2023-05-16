local esp_name = "Morrowind World Randomizer.ESP"

local dataSaver = include("Morrowind_World_Randomizer.dataSaver")
local randomizer = include("Morrowind_World_Randomizer.Randomizer")
local gui = include("Morrowind_World_Randomizer.gui")
local i18n = mwse.loadTranslations("Morrowind_World_Randomizer")
local log = include("Morrowind_World_Randomizer.log")
local generator = include("Morrowind_World_Randomizer.generator")
local itemLib = include("Morrowind_World_Randomizer.item")
local presetMenu = include("Morrowind_World_Randomizer.presetMenu")(i18n)
local storage = include("Morrowind_World_Randomizer.storage")
local saveRestore = include("Morrowind_World_Randomizer.saveRestore")
local inventoryEvents = include("Morrowind_World_Randomizer.inventoryEvents")

local function getCellLastRandomizeTime(cellId)
    local playerData = dataSaver.getObjectData(tes3.player)
    if playerData then
        if playerData.cellTimestamps == nil then playerData.cellTimestamps = {} end
        if playerData.cellTimestamps[cellId] then return playerData.cellTimestamps[cellId] end
    end
    return nil
end

local function setCellLastRandomizeTime(cellId, timestamp, gameTime)
    local playerData = dataSaver.getObjectData(tes3.player)
    if playerData then
        if playerData.cellTimestamps == nil then playerData.cellTimestamps = {} end
        playerData.cellTimestamps[cellId] = {timestamp = timestamp, gameTime = gameTime}
    end
end

local function forcedActorRandomization(reference)
    local mobile = reference.mobile
    if mobile then
        randomizer.randomizeMobileActor(mobile)
        randomizer.randomizeScale(reference)

        randomizer.randomizeActorBaseObject(mobile.object.baseObject, mobile.actorType)

        local configGroup
        if reference.object.objectType == tes3.objectType.npc then
            configGroup = randomizer.config.data.NPCs
        elseif reference.object.objectType == tes3.objectType.creature then
            configGroup = randomizer.config.data.creatures
        end
        if configGroup.items.randomize then
            randomizer.randomizeContainerItems(reference, configGroup.items.region.min, configGroup.items.region.max)
        end
        if configGroup.randomizeOnlyOnce then
            randomizer.StopRandomization(reference)
        else
            randomizer.StopRandomizationTemp(reference)
        end
        reference:updateEquipment()
    end
end

local function randomizeActor(reference)
    if not randomizer.isRandomizationStopped(reference) and not randomizer.isRandomizationStoppedTemp(reference) then
        forcedActorRandomization(reference)
    else
        reference:updateEquipment()
    end
end

local function randomizeCellOnly(cell)
    setCellLastRandomizeTime(cell.editorName, os.time(), tes3.getSimulationTimestamp())
    randomizer.randomizeWeatherChance(cell)
    timer.delayOneFrame(function() randomizer.randomizeCell(cell) end)
end

local function forcedCellRandomization(cell, isForcedActorRandomization)
    randomizeCellOnly(cell)

    for ref in cell:iterateReferences({ tes3.objectType.npc, tes3.objectType.creature }) do
        if isForcedActorRandomization then
            forcedActorRandomization(ref)
        else
            randomizeActor(ref)
        end
    end
end

local function randomizeLoadedCells(addedGameTime, forceCellRandomization, forceActorRandomization)
    if addedGameTime == nil then addedGameTime = 0 end
    local cells = tes3.getActiveCells()
    if cells ~= nil then
        for i, cell in pairs(cells) do
            local cellLastRandomizeTime = getCellLastRandomizeTime(cell.editorName)
            if forceCellRandomization or cellLastRandomizeTime == nil or not randomizer.config.getConfig().cells.randomizeOnlyOnce and
                    ((tes3.getSimulationTimestamp() - cellLastRandomizeTime.gameTime + addedGameTime) > randomizer.config.global.cellRandomizationCooldown_gametime or
                    (os.time() - cellLastRandomizeTime.timestamp) > randomizer.config.global.cellRandomizationCooldown) then
                forcedCellRandomization(cell, forceActorRandomization)
            end
        end
    end
end

local function generateRandomizedLandscapeTextureIndices()
    randomizer.config.global.landscape.textureIndices = generator.generateRandomizedLandscapeTextureIndices()
    randomizer.config.save()
end

local function loadRandomizedLandscapeTextures()
    if not randomizer.config.global.landscape.textureIndices then return end

    local textures = randomizer.config.global.landscape.textureIndices
    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        if cell.landscape then
            for i, val in pairs(cell.landscape.textureIndices) do
                local valStr = tostring(val)
                if textures[valStr] then
                    cell.landscape.textureIndices[i] = textures[valStr]
                end
            end
        end
    end
end

local function isLandscapeTexturesValid()
    if not randomizer.config.global.landscape.textureIndices then return false end

    local gameCount = 0
    local textures = randomizer.config.global.landscape.textureIndices
    for _, texture in pairs(tes3.dataHandler.nonDynamicData.landTextures) do
        if texture.filename and tes3.getFileSource("Textures\\"..texture.filename) then
            gameCount = gameCount + 1
            if not textures[tostring(texture.index)] then
                return false
            end
        end
    end
    local savedCount = 0
    for _, _ in pairs(randomizer.config.global.landscape.textureIndices) do
        savedCount = savedCount + 1
    end
    if savedCount ~= gameCount then
        return false
    end
    return true
end

local function itemDropped(e)
    if randomizer.config.getConfig().enabled then
        if e.reference ~= nil and e.reference.data ~= nil then
            randomizer.StopRandomization(e.reference)
        end
    end
end

local function cellActivated(e)
    if randomizer.config.getConfig().enabled then

        local cellLastRandomizeTime = getCellLastRandomizeTime(e.cell.editorName)
        if cellLastRandomizeTime == nil or not randomizer.config.getConfig().cells.randomizeOnlyOnce and
                ((tes3.getSimulationTimestamp() - cellLastRandomizeTime.gameTime) > randomizer.config.global.cellRandomizationCooldown_gametime or
                (os.time() - cellLastRandomizeTime.timestamp) > randomizer.config.global.cellRandomizationCooldown) then

            randomizeCellOnly(e.cell)

        elseif randomizer.config.getConfig().light.randomize then
            randomizer.restoreCellLight(e.cell)
        end

        timer.start{duration = 0.1, callback = function() itemLib.fixCell(e.cell) end}
    end
end

local function oneSecRealTimerCallback()
    randomizer.updatePlayerInventory()
end

local isDummyLoad = true
local function load(e)
    if isDummyLoad then
        storage.restoreAllActors(true)
        storage.restoreAllItems(true)
        randomizer.config.resetConfig()
        if not e.newGame and storage.loadFromFile(e.filename) then
            storage.restoreAllItems()
            storage.restoreAllActors()
            if tes3.dataHandler.nonDynamicData.lastLoadedFile and randomizer.config.global.allowDoubleLoading then
                isDummyLoad = false
                e.claim = true
                e.block = true
                tes3.loadGame(tes3.dataHandler.nonDynamicData.lastLoadedFile.filename)
            end
        end
    else
        isDummyLoad = true
    end
    inventoryEvents.reset()
end

local function save(e)
    if not e.filename then -- I do not how but once it happened
        tes3.messageBox({ message = "Save process failed",
            buttons = {tostring(tes3.findGMST("sOK").value),},})
    else
        storage.saveToFile(e.filename:sub(1, -5))
    end
end

local function loaded(e)
    timer.start{duration = 1, callback = oneSecRealTimerCallback, iterations = -1,
            persist  = false, type = timer.real}

    randomizer.config.getConfig()
    randomizer.genNonStaticData()
    randomizer.restoreItems() -- required for compatibility

    randomizer.restoreAllBaseActorData() -- required for compatibility

    if randomizer.config.getConfig().enabled then
        if mge.enabled() then
            if randomizer.config.getConfig().other.disableMGEDistantStatics == true and mge.render.distantStatics then
                mge.render.distantStatics = false
                mge.render.distantWater = false
            end
            if randomizer.config.getConfig().other.disableMGEDistantLand == true and (mge.render.distantLand or mge.render.distantWater) then
                mge.render.distantStatics = false
                mge.render.distantLand = false
                mge.render.distantWater = false
            end
        end

        randomizeLoadedCells()

    end
    inventoryEvents.saveInventoryChanges()
end

local goldToAdd = 0
local function leveledItemPicked(e)
    if randomizer.config.getConfig().enabled then
        if randomizer.config.data.containers.items.randomize and e.pick ~= nil and e.pick.id ~= nil and
                not randomizer.isRandomizationStoppedTemp(e.spawner) and not randomizer.isRandomizationStopped(e.spawner) then

            if e.pick.objectType == tes3.objectType.miscItem and e.pick.id == "Gold_001" and e.spawner ~= nil then

                local newCount = randomizer.config.data.gold.region.min + math.random() *
                    (randomizer.config.data.gold.region.max - randomizer.config.data.gold.region.min)

                goldToAdd = goldToAdd + newCount
                if goldToAdd >= 2 then
                    local count = math.floor(goldToAdd - 1)
                    tes3.addItem({ reference = e.spawner, item = e.pick.id, count = count, })
                    goldToAdd = goldToAdd - count
                end
                if goldToAdd < 1 then
                    e.block = true
                else
                    goldToAdd = goldToAdd - 1
                end

            end
            local newId = randomizer.getNewRandomItemId(e.pick.id)
            if newId then
                log("Leveled item picked %s to %s", tostring(e.pick.id), tostring(newId))
                local item = randomizer.getNewItem(newId)
                if item then
                    e.pick = item
                end
            end
        end
    end
end

local function leveledCreaturePicked(e)
    if randomizer.config.getConfig().enabled then
        if e.pick ~= nil and randomizer.config.data.creatures.randomize then
            local newId = randomizer.getRandomCreatureId(e.pick.id)
            log("Leveled creature picked %s to %s", tostring(e.pick.id), tostring(newId))
            if newId ~= nil then
                e.pick = tes3.getObject(newId)
            end
        end
    end
end

local function mobileActivated(e)
    if randomizer.config.getConfig().enabled then
        if (e.reference.object.objectType == tes3.objectType.npc or e.reference.object.objectType == tes3.objectType.creature) then
            randomizeActor(e.reference)
        end
    end
end

local function randomizeBaseItemsCallback(e)
    if e.button == 0 then
        randomizer.randomizeBaseItems()
    elseif e.button == 1 then
        randomizer.config.getConfig().item.stats.randomize = true
        randomizer.config.getConfig().item.enchantment.randomize = false
        randomizer.config.getConfig().item.changeParts = false
        randomizer.config.getConfig().item.changeMesh = false
        randomizer.randomizeBaseItems()
    elseif e.button == 2 then
        randomizer.config.getConfig().item.stats.randomize = false
        randomizer.config.getConfig().item.enchantment.randomize = false
        randomizer.config.getConfig().item.changeParts = true
        randomizer.config.getConfig().item.changeMesh = true
        randomizer.randomizeBaseItems()
    elseif e.button == 3 then
        randomizer.config.getConfig().item.stats.randomize = true
        randomizer.config.getConfig().item.enchantment.randomize = true
        randomizer.config.getConfig().item.changeParts = true
        randomizer.config.getConfig().item.changeMesh = true
        randomizer.randomizeBaseItems()
    end
end

local function randomizeBaseItemsMessage()
    tes3.messageBox({ message = i18n("modConfig.message.randItemStats"),
        buttons = {i18n("modConfig.label.randBaseItemToPreset"), i18n("modConfig.label.randBaseItemOnlyStats"),
            i18n("modConfig.label.randBaseItemOnlyModels"), i18n("modConfig.label.randBaseItemAll"), i18n("messageBox.enableRandomizer.button.no")},
        callback = randomizeBaseItemsCallback, showInDialog = false})
end

local function landscapeRandOptionCallback(e)
    if e.button == 0 then
        randomizer.config.global.landscape.randomize = true
        randomizer.config.save()
        if not isLandscapeTexturesValid() or not randomizer.config.global.landscape.randomizeOnlyOnce then
            generateRandomizedLandscapeTextureIndices()
        end
        loadRandomizedLandscapeTextures()
    end
    randomizeBaseItemsMessage()
end

local function showLandscapeRandOptionMessage()
    if not randomizer.config.global.landscape.randomize then
        tes3.messageBox({ message = i18n("messageBox.enableLandscapeRand.message"),
            buttons = {i18n("messageBox.enableRandomizer.button.yes"), i18n("messageBox.enableRandomizer.button.no")},
            callback = landscapeRandOptionCallback, showInDialog = false})
    else
        randomizeBaseItemsMessage()
    end
end

local function distantLandOptionsCallback(e)
    if e.button == 0 then
        randomizer.config.getConfig().other.disableMGEDistantLand = true
        mge.render.distantStatics = false
        mge.render.distantLand = false
        mge.render.distantWater = false
    elseif e.button == 1 then
        randomizer.config.getConfig().other.disableMGEDistantStatics = true
        mge.render.distantStatics = false
    elseif e.button == 2 then
        randomizer.config.getConfig().trees.randomize = false
        randomizer.config.getConfig().stones.randomize = false
    end
    randomizeLoadedCells()
    showLandscapeRandOptionMessage()
end

local function distLandMessage(e)
    if mge.enabled() and (mge.render.distantStatics or mge.render.distantLand) then
        tes3.messageBox({ message = i18n("messageBox.selectDistantLandOption.message"),
            buttons = {i18n("messageBox.selectDistantLandOption.button.disableDistantLand"), i18n("messageBox.selectDistantLandOption.button.disableDistantStatics"),
            i18n("messageBox.selectDistantLandOption.button.disableRandomization"), i18n("messageBox.selectDistantLandOption.button.doNothing")},
            callback = distantLandOptionsCallback, showInDialog = false})
    else
        randomizeLoadedCells()
        showLandscapeRandOptionMessage()
    end
end

local function randomizeOnceMessageCallback(e)
    if e.button == 0 then
        randomizer.config.getConfig().creatures.randomizeOnlyOnce = false
        randomizer.config.getConfig().NPCs.randomizeOnlyOnce = false
        randomizer.config.getConfig().cells.randomizeOnlyOnce = false
    elseif e.button == 1 then
        randomizer.config.getConfig().creatures.randomizeOnlyOnce = true
        randomizer.config.getConfig().NPCs.randomizeOnlyOnce = true
        randomizer.config.getConfig().cells.randomizeOnlyOnce = true
    end
    distLandMessage()
end

local function randomizeOnceMessage()
    tes3.messageBox({ message = i18n("messageBox.randomizeOnce.message"),
        buttons = {i18n("modConfig.label.randomizingAfterCertainPeriod"), i18n("modConfig.label.randomizingJustOnce"),
            i18n("modConfig.label.leaveAccordingToPreset"),},
        callback = randomizeOnceMessageCallback, showInDialog = false})
end

local function presetMessage()
    local func = function(preset)
        if preset then
            tes3.messageBox(i18n("modConfig.label.theProfileLoaded", {profile = preset}))
        end
        randomizeOnceMessage()
    end
    presetMenu.createMenu(func, func)
end

local function enableRandomizerCallback(e)
    if e.button == 0 then
        randomizer.config.getConfig().enabled = true
        presetMessage()
    end
end

local function activate(e)
    if randomizer.config.getConfig().enabled then
        if e.target  ~= nil and e.target.data ~= nil and (e.target.baseObject.objectType == tes3.objectType.container or
                (e.target.isDead == true and (e.target.baseObject.objectType == tes3.objectType.creature or
                e.target.baseObject.objectType == tes3.objectType.npc))) then

            randomizer.StopRandomization(e.target)

        elseif e.target  ~= nil and e.target.baseObject.objectType == tes3.objectType.door and
                not randomizer.config.data.doors.onlyOnCellRandomization then

            randomizer.doors.resetDoorDestination(e.target)
            randomizer.doors.randomizeDoor(e.target)

        end
    end
    if e.target.baseObject.id == "chargen_shipdoor" and not randomizer.config.global.globalConfig and
            dataSaver.getObjectData(tes3.player) and not dataSaver.getObjectData(tes3.player).messageShown and
            not randomizer.config.getConfig().enabled then

        dataSaver.getObjectData(tes3.player).messageShown = true
        e.block = true
        tes3.messageBox({ message = i18n("messageBox.enableRandomizer.message"), buttons = {i18n("messageBox.enableRandomizer.button.yes"),
            i18n("messageBox.enableRandomizer.button.no")}, callback = enableRandomizerCallback, showInDialog = false})
    end
end

local function calcRestInterrupt(e)
    if randomizer.config.getConfig().enabled then
        randomizeLoadedCells(e.hour)
    end
end

local function filterInventory(e)
    if randomizer.config.data.item.unique then
        local wasCreated = itemLib.isItemWasCreated(e.item.id)
        if e.item.sourceMod and not wasCreated and (e.item.objectType == tes3.objectType.weapon or e.item.objectType == tes3.objectType.armor or
                e.item.objectType == tes3.objectType.clothing) then
            e.filter = false
        end
    end
end

event.register(tes3.event.initialized, function(e)
    if not tes3.isModActive(esp_name) then
        gui.hide()
        return
    end
    include("Morrowind_World_Randomizer.magicEffect").init()
    randomizer.config.load()
    math.randomseed(os.time())
    randomizer.genStaticData()

    if randomizer.config.global.landscape.randomize then
        if not isLandscapeTexturesValid() or not randomizer.config.global.landscape.randomizeOnlyOnce then
            generateRandomizedLandscapeTextureIndices()
        end
        loadRandomizedLandscapeTextures()
    end

    event.register(tes3.event.itemDropped, itemDropped)
    event.register(tes3.event.cellActivated, cellActivated)
    event.register(tes3.event.load, load)
    event.register(tes3.event.save, save)
    event.register(tes3.event.loaded, loaded)
    event.register(tes3.event.leveledItemPicked, leveledItemPicked)
    event.register(tes3.event.leveledCreaturePicked, leveledCreaturePicked)
    event.register(tes3.event.mobileActivated, mobileActivated)
    event.register(tes3.event.activate, activate)
    event.register(tes3.event.calcRestInterrupt, calcRestInterrupt)
    event.register(tes3.event.filterInventory, filterInventory)
    -- event.register(tes3.event.filterBarterMenu, filterInventory)
    log("Morrowind World Randomizer is ready")
end)

gui.init(randomizer.config, i18n, {generateStaticFunc = randomizer.genStaticData, randomizeLoadedCellsFunc = function() enableRandomizerCallback({button = 0}) end,
    randomizeLoadedCells = randomizeLoadedCells, genRandLandTextureInd = generateRandomizedLandscapeTextureIndices, loadRandLandTextures = loadRandomizedLandscapeTextures,
    randomizeBaseItems = randomizer.randomizeBaseItems})
event.register(tes3.event.modConfigReady, gui.registerModConfig)