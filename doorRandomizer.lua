local dataSaver = include("Morrowind World Randomizer.dataSaver")

local this = {}

this.forbiddenDoorIds = {
    ["chargen customs door"] = true,
    ["chargen door captain"] = true,
    ["chargen door exit"] = true,
    ["chargen door hall"] = true,
    ["chargen exit door"] = true,
    ["chargen_cabindoor"] = true,
    ["chargen_ship_trapdoor"] = true,
    ["chargen_shipdoor"] = true,
    ["chargendoorjournal"] = true,
}

this.config = nil

this.doorsData = {All = {}, InToIn = {}, InToEx = {}, ExToIn = {}, ExToEx = {}}

function this.initConfig(config)
    this.config = config
end

local function isValidDestination(destination)
    if destination == nil or destination.marker == nil then return false end
    local pos = destination.marker.position
    local rot = destination.marker.orientation
    return not (pos == nil or rot == nil or (pos.x == 0 and pos.y == 0 and pos.z == 0 and rot.x == 0 and rot.y == 0 and rot.z == 0))
end

function this.findDoors()
    mwse.log("Doors generation", tostring(os.time()))
    this.doorsData = {All = {}, InToIn = {}, InToEx = {}, ExToIn = {}, ExToEx = {}}

    for _, cell in pairs(tes3.dataHandler.nonDynamicData.cells) do
        for door in cell:iterateReferences(tes3.objectType.door) do
            mwse.log(door.id:lower())
            if not door.deleted and not door.disabled and not door.script and not this.forbiddenDoorIds[door.id:lower()] and isValidDestination(door.destination) then
                local destIsEx = door.destination.cell.isOrBehavesAsExterior
                local isEx = door.cell.isOrBehavesAsExterior
                if isEx and destIsEx then
                    table.insert(this.doorsData.ExToEx, door)
                elseif not isEx and destIsEx then
                    table.insert(this.doorsData.InToEx, door)
                elseif not isEx and not destIsEx then
                    table.insert(this.doorsData.InToIn, door)
                elseif isEx and not destIsEx then
                    table.insert(this.doorsData.ExToIn, door)
                end
                table.insert(this.doorsData.All, door)
            end
        end
    end

    mwse.log("#doors InToIn = %i, InToEx = %i, ExToIn = %i, ExToEx = %i", #this.doorsData.InToIn, #this.doorsData.InToEx, #this.doorsData.ExToIn, #this.doorsData.ExToEx)
end


local function findingCells_asEx(cells, cell, depth)
    depth = depth - 1
    if depth >= 0 then
        if cell.behavesAsExterior then
            cells[cell.id] = cell
            for door in cell:iterateReferences(tes3.objectType.door) do
                if door.destination and not cells[door.destination.cell.id] then
                    findingCells_asEx(cells, door.destination.cell, depth)
                end
            end
        end
    end
end

local function findingCells_Ex(cells, cell, depth)
    depth = depth - 1
    if depth >= 0 and cell then
        if cell.isOrBehavesAsExterior then
            cells[cell.id] = cell
            for i = cell.gridX - 1, cell.gridX + 1 do
                for j = cell.gridY - 1, cell.gridY + 1 do
                    findingCells_asEx(cells, tes3.getCell{x = i, y = j}, depth)
                end
            end
        end
    end
end

local function findingCells_In(cells, cell, depth)
    depth = depth - 1
    if depth >= 0 and cell then
        if not cell.isOrBehavesAsExterior then
            cells[cell.id] = cell
            for door in cell:iterateReferences(tes3.objectType.door) do
                if door.destination and not cells[door.destination.cell.id] then
                    findingCells_In(cells, door.destination.cell, depth)
                end
            end
        end
    end
end

local function saveDoorOrigDestination(reference)
    local data = dataSaver.getObjectData(reference)
    if data.origDestination == nil then
        local cellStr = reference.cell.editorName
        if reference.cell.isInterior == false then
            cellStr = ""
        end
        data.origDestination = {x = reference.destination.marker.position.x, y = reference.destination.marker.position.y,
            z = reference.destination.marker.position.z, rotZ = reference.destination.marker.orientation.z, cell = cellStr}
    end
end

function this.randomizeDoor(reference)
    local data = dataSaver.getObjectData(reference)
    if not this.forbiddenDoorIds[reference.baseObject.id:lower()] and this.config.data.doors.randomize and this.config.data.doors.chance >= math.random() and
            data ~= nil and (data.doorCDTimestamp == nil or data.doorCDTimestamp < tes3.getSimulationTimestamp()) and
            reference.object.objectType == tes3.objectType.door and reference.destination ~= nil then

        saveDoorOrigDestination(reference)

        local doors = {}
        if this.config.data.doors.onlyNearest then
            -- local destinations = {}
            if reference.destination.cell.isOrBehavesAsExterior then
                local cellsToCheck = {}
                if reference.destination.cell.behavesAsExterior then
                    findingCells_asEx(cellsToCheck, reference.destination.cell, this.config.data.doors.nearestCellDepth)
                else
                    findingCells_Ex(cellsToCheck, reference.destination.cell, this.config.data.doors.nearestCellDepth)
                end

                for cellId, cell in pairs(cellsToCheck) do
                    for door in cell:iterateReferences(tes3.objectType.door) do
                        if door.destination then
                            for ndoor in door.destination.cell:iterateReferences(tes3.objectType.door) do
                                if isValidDestination(ndoor.destination) and ndoor.destination.cell.id == cell.id then
                                    -- table.insert(destinations, ndoor.destination)
                                    local newDoorData = dataSaver.getObjectData(ndoor)
                                    if (newDoorData and (newDoorData.doorCDTimestamp == nil or newDoorData.doorCDTimestamp < tes3.getSimulationTimestamp())) then
                                        table.insert(doors, ndoor)
                                    end
                                end
                            end
                        end
                    end
                end
            elseif reference.cell.isOrBehavesAsExterior and not reference.destination.cell.isOrBehavesAsExterior then
                local cellsToCheck = {}
                if reference.cell.behavesAsExterior then
                    findingCells_asEx(cellsToCheck, reference.cell, this.config.data.doors.nearestCellDepth)
                else
                    findingCells_Ex(cellsToCheck, reference.cell, this.config.data.doors.nearestCellDepth)
                end

                for cellId, cell in pairs(cellsToCheck) do
                    for door in cell:iterateReferences(tes3.objectType.door) do
                        if isValidDestination(door.destination) then
                            -- table.insert(destinations, door.destination)
                            local newDoorData = dataSaver.getObjectData(door)
                            if (newDoorData and (newDoorData.doorCDTimestamp == nil or newDoorData.doorCDTimestamp < tes3.getSimulationTimestamp())) then
                                table.insert(doors, door)
                            end
                        end
                    end
                end

            elseif not reference.cell.isOrBehavesAsExterior and not reference.destination.cell.isOrBehavesAsExterior then
                local cellsToCheck = {}

                findingCells_In(cellsToCheck, reference.destination.cell, this.config.data.doors.nearestCellDepth)

                for cellId, cell in pairs(cellsToCheck) do
                    for door in cell:iterateReferences(tes3.objectType.door) do
                        if door.destination then
                            -- table.insert(destinations, door.destination)
                            local newDoorData = dataSaver.getObjectData(door)
                            if (newDoorData and (newDoorData.doorCDTimestamp == nil or newDoorData.doorCDTimestamp < tes3.getSimulationTimestamp())) then
                                table.insert(doors, door)
                            end
                        end
                    end
                end
            end
        else
            local newDoor
            if reference.destination.cell.isOrBehavesAsExterior and reference.cell.isOrBehavesAsExterior then
                if #this.doorsData.ExToEx > 0 then newDoor = this.doorsData.ExToEx[math.random(1, #this.doorsData.ExToEx)] end
            elseif reference.destination.cell.isOrBehavesAsExterior and not reference.cell.isOrBehavesAsExterior then
                if #this.doorsData.InToEx > 0 then newDoor = this.doorsData.InToEx[math.random(1, #this.doorsData.InToEx)] end
            elseif not reference.destination.cell.isOrBehavesAsExterior and reference.cell.isOrBehavesAsExterior then
                if #this.doorsData.ExToIn > 0 then newDoor = this.doorsData.ExToIn[math.random(1, #this.doorsData.ExToIn)] end
            elseif not reference.destination.cell.isOrBehavesAsExterior and not reference.cell.isOrBehavesAsExterior then
                if #this.doorsData.InToIn > 0 then newDoor = this.doorsData.InToIn[math.random(1, #this.doorsData.InToIn)] end
            end

            if newDoor then
                table.insert(doors, newDoor)
            end
        end

        if #doors > 0 then
            local newDoor = doors[math.random(1, #doors)]
            local oldDoorCell = reference.destination.cell
            local oldDoorOrient = reference.destination.marker.orientation
            local oldDoorPos = reference.destination.marker.position
            local newDoorCell = newDoor.destination.cell
            local newDoorOrient = newDoor.destination.marker.orientation
            local newDoorPos = newDoor.destination.marker.position

            data.doorCDTimestamp = tes3.getSimulationTimestamp() + this.config.data.doors.cooldown

            local newDoorData = dataSaver.getObjectData(newDoor)
            saveDoorOrigDestination(newDoor)
            newDoorData.doorCDTimestamp = tes3.getSimulationTimestamp() + this.config.data.doors.cooldown

            tes3.setDestination{ reference = reference, position = newDoorPos, orientation = newDoorOrient, cell = newDoorCell }
            tes3.setDestination{ reference = newDoor, position = oldDoorPos, orientation = oldDoorOrient, cell = oldDoorCell }
        end
    end
end

function this.resetDoorDestination(reference)
    local data = dataSaver.getObjectData(reference)
    if this.config.data.doors.restoreOriginal and data ~= nil and data.doorCDTimestamp ~= nil and data.doorCDTimestamp < tes3.getSimulationTimestamp() and
            reference.object.objectType == tes3.objectType.door and reference.destination ~= nil and data.origDestination ~= nil then
        local cell
        local dest = data.origDestination
        if dest.cell ~= "" then
            cell = tes3.getCell{ id = dest.Cell }
        end

        tes3.setDestination{ reference = reference, position = tes3vector3.new(dest.x, dest.y, dest.z),
            orientation = tes3vector3.new(0, 0, dest.rotZ), cell = cell }
    end
end

return this