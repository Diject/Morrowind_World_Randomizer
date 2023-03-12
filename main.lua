local dataSaver = include("Morrowind World Randomizer.dataSaver")
local randomizer = require("Morrowind World Randomizer.Randomizer")
local gui = require("Morrowind World Randomizer.gui")
gui.init(randomizer.config)
event.register(tes3.event.modConfigReady, gui.registerModConfig)

local cellLastRandomizeTime = {}

event.register(tes3.event.itemDropped, function(e)
    if randomizer.config.getConfig().enabled then
        if e.reference ~= nil and e.reference.data ~= nil then
            randomizer.StopRandomization(e.reference)
        end
    end
end)

event.register(tes3.event.activate, function(e)
    if randomizer.config.getConfig().enabled then
        if e.target  ~= nil and e.target.data ~= nil and (e.target.baseObject.objectType == tes3.objectType.container or
                (e.target.isDead == true and (e.target.baseObject.objectType == tes3.objectType.creature or
                e.target.baseObject.objectType == tes3.objectType.npc))) then

            randomizer.StopRandomization(e.target)
        end
        -- mwse.log("Activate=%s", tostring(e.target))
        randomizer.doors.resetDoorDestination(e.target)
        randomizer.doors.randomizeDoor(e.target)
    end
end)

event.register(tes3.event.cellActivated, function(e)
    mwse.log("%s CellActivated=%s", tostring(os.time()), tostring(e.cell.editorName))
    if randomizer.config.getConfig().enabled then

        if cellLastRandomizeTime[e.cell.editorName] == nil then
            randomizer.randomizeWeatherChance(e.cell)
            timer.delayOneFrame(function() randomizer.randomizeCell(e.cell) end)
            cellLastRandomizeTime[e.cell.editorName] = os.time()
        end
    end

    -- mwse.log("%s CellActivated=%s", tostring(os.time()), tostring(e.cell.editorName))
end)

event.register(tes3.event.cellDeactivated, function(e)
    mwse.log("%s CellDeactivated=%s", tostring(os.time()), tostring(e.cell.editorName))
end)

local function enableRandomizerCallback(e)
    if e.button == 0 then
        local cells = tes3.getActiveCells()
        if cells ~= nil then
            for i, cell in pairs(cells) do
                timer.delayOneFrame(function() randomizer.randomizeCell(cell) end)
            end
        end
    end
end

event.register(tes3.event.cellChanged, function(e)
    mwse.log("CHAR GEN %s", tostring(tes3.worldController.charGenState.value))
    mwse.log("%s CellChanged=%s %s", tostring(os.time()), tostring(e.cell.editorName), tostring(e.previousCell))
end)

event.register(tes3.event.load, function(e)
    cellLastRandomizeTime = {}
    randomizer.config.resetConfig()
    mwse.log("Pl %s", tostring(tes3.player))
    mwse.log("%s Load", tostring(os.time()))
end)

event.register(tes3.event.loaded, function(e)
    randomizer.doors.findDoors()
    randomizer.genNonStaticData()
    timer.start{ duration = 1, iterations = 1, type = timer.simulate, callback = function()
        if tes3.worldController.charGenState.value == -1 then
            tes3.messageBox({ message = "Would you like to enable randomizer? It cannot be undone,", buttons = {"Yes, enable it", "No"},
                callback = enableRandomizerCallback, showInDialog = false})
        end
    end }
    if randomizer.config.getConfig().enabled then
        local cells = tes3.getActiveCells()
        if cells ~= nil then
            for i, cell in pairs(cells) do
                timer.delayOneFrame(function() randomizer.randomizeCell(cell) end)
            end
        end
    end

    mwse.log("Pl %s", tostring(tes3.player))
    mwse.log("%s Loaded", tostring(os.time()))
end)

local goldToAdd = 0
event.register(tes3.event.leveledItemPicked, function(e)
    mwse.log("it p Pl %s", tostring(tes3.player))
    if randomizer.config.getConfig().enabled then
        if randomizer.config.data.containers.items.randomize and e.pick ~= nil and e.pick.id ~= nil and
                not randomizer.isRandomizationStoppedTemp(e.spawner) then

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
            if newId ~= nil then
                e.pick = tes3.getObject(newId)
            end
        end
    end
end)

event.register(tes3.event.leveledCreaturePicked, function(e)
    if randomizer.config.getConfig().enabled then
        if e.pick ~= nil and randomizer.config.data.creatures.randomize then
            local newId = randomizer.getRandomCreatureId(e.pick.id)
            if newId ~= nil then
                e.pick = tes3.getObject(newId)
            end
        end
    end
    -- mwse.log("%s Creature Picked=%s", tostring(os.time()), tostring(e.pick or ""))
end)

event.register(tes3.event.initialized, function(e)
    math.randomseed(os.time())
    for i, mod in pairs(tes3.dataHandler.nonDynamicData.activeMods) do
        mwse.log("Path %s", tostring(mod.filename))
        if mod.filename:lower() == "tamriel_data.esm" then
            mwse.log("Ver %i", tonumber(string.match(mod.description, "%d+")))
        end
    end
    randomizer.genStaticData()
end)

event.register(tes3.event.mobileActivated, function(e)
    if randomizer.config.getConfig().enabled then
        if (e.reference.object.objectType == tes3.objectType.npc or e.reference.object.objectType == tes3.objectType.creature) and
                not randomizer.isRandomizationStopped(e.reference) and not randomizer.isRandomizationStoppedTemp(e.reference) then
            -- mwse.log("MActivated=%s", tostring(e.reference))
            if e.reference.object.objectType == tes3.objectType.npc then
                randomizer.randomizeContainerItems(e.reference, randomizer.config.data.NPCs.items.region.min, randomizer.config.data.NPCs.items.region.max)
            elseif e.reference.object.objectType == tes3.objectType.creature then
                randomizer.randomizeContainerItems(e.reference, randomizer.config.data.creatures.items.region.min, randomizer.config.data.creatures.items.region.max)
            end

            randomizer.randomizeMobileActor(e.mobile)
            randomizer.randomizeBody(e.mobile)
            randomizer.randomizeScale(e.reference)
            randomizer.StopRandomizationTemp(e.reference)
            randomizer.randomizeActorBaseObject(e.mobile.object.baseObject, e.mobile.actorType)
        end
    end
end)