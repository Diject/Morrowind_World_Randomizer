local this = {}

local csIds = {
    [tes3.objectType.alchemy] = "ALCH",
    [tes3.objectType.apparatus] = "APPA",
    [tes3.objectType.armor] = "ARMO",
    [tes3.objectType.book] = "BOOK",
    [tes3.objectType.clothing] = "CLOT",
    [tes3.objectType.ingredient] = "INGR",
    [tes3.objectType.lockpick] = "LOCK",
    [tes3.objectType.probe] = "PROB",
    [tes3.objectType.repairItem] = "REPA",
    [tes3.objectType.weapon] = "WEAP",
}

local forbiddenEffectsIds = { -- for abilities and diseases
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
}

local forbiddenIds = {
    ["war_axe_airan_ammu"] = true,
    ["shadow_shield"] = true,
    ["bonebiter_bow_unique"] = true,
    ["heart_of_fire"] = true,
    ["T_WereboarRobe"] = true,


    ["vivec_god"] = true,
    ["wraith_sul_senipul"] = true,
}

local forbiddenModels = { -- lowercase
    ["pc\\f\\pc_help_deprec_01.nif"] = true,
}

local scriptWhiteList = {
    ["LegionUniform"] = true,
    ["OrdinatorUniform"] = true,
}

local skillByEffectId = {[0]=11,[1]=11,[2]=11,[3]=11,[4]=11,[5]=11,[6]=11,[7]=11,[8]=11,[9]=11,[10]=11,[11]=11,[12]=11,[13]=11,[14]=10,[15]=10,[16]=10,[17]=10,[18]=10,[19]=10,[20]=10,[21]=10,[22]=10,[23]=10,[24]=10,[25]=10,[26]=10,[27]=10,[28]=10,[29]=10,[30]=10,[31]=10,[32]=10,[33]=10,[34]=10,[35]=10,[36]=10,[37]=10,[38]=10,[39]=12,[40]=12,[41]=12,[42]=12,[43]=12,[44]=12,[45]=12,[46]=12,[47]=12,[48]=12,[49]=12,[50]=12,[51]=12,[52]=12,[53]=14,[54]=12,[55]=12,[56]=12,[57]=14,[58]=14,[59]=14,[60]=14,[61]=14,[62]=14,[63]=14,[64]=14,[65]=14,[66]=14,[67]=14,[68]=14,[69]=15,[70]=15,[71]=15,[72]=15,[73]=15,[74]=15,[75]=15,[76]=15,[77]=15,[78]=15,[79]=15,[80]=15,[81]=15,[82]=15,[83]=15,[84]=15,[85]=14,[86]=14,[87]=14,[88]=14,[89]=14,[90]=15,[91]=15,[92]=15,[93]=15,[94]=15,[95]=15,[96]=15,[97]=15,[98]=15,[99]=15,[100]=15,[101]=13,[102]=13,[103]=13,[104]=13,[105]=13,[106]=13,[107]=13,[108]=13,[109]=13,[110]=13,[111]=13,[112]=13,[113]=13,[114]=13,[115]=13,[116]=13,[117]=15,[118]=13,[119]=13,[120]=13,[121]=13,[122]=13,[123]=13,[124]=13,[125]=13,[126]=13,[127]=13,[128]=13,[129]=13,[130]=13,[131]=13,[132]=10,[133]=10,[134]=13,[135]=10,[136]=10,[137]=nil,[138]=13,[139]=13,[140]=13,}

local herbsOffsets = {["flora_bittergreen_07"]=70,["flora_bittergreen_06"]=40,["flora_bittergreen_08"]=50,["flora_bittergreen_09"]=60,["flora_bittergreen_10"]=50,["flora_sedge_01"]=25,["flora_sedge_02"]=25,["flora_kreshweed_02"]=120,["flora_green_lichen_02"]=0,["flora_green_lichen_01"]=5,["flora_ash_yam_02"]=10,["flora_muckspunge_01"]=80,["flora_kreshweed_01"]=80,["flora_muckspunge_05"]=110,["flora_muckspunge_06"]=100,["flora_muckspunge_02"]=90,["flora_ash_yam_01"]=20,["flora_kreshweed_03"]=90,["flora_muckspunge_04"]=80,["flora_muckspunge_03"]=80,["flora_stoneflower_02"]=45,["flora_marshmerrow_02"]=60,["flora_bc_mushroom_07"]=0,["flora_marshmerrow_03"]=70,["flora_saltrice_01"]=50,["flora_bc_mushroom_06"]=10,["flora_saltrice_02"]=50,["flora_bc_mushroom_05"]=15,["flora_wickwheat_01"]=40,["flora_bc_mushroom_03"]=15,["flora_wickwheat_03"]=20,["flora_wickwheat_04"]=25,["flora_bc_shelffungus_03"]=0,["flora_bc_shelffungus_04"]=0,["flora_bc_shelffungus_02"]=0,["flora_chokeweed_02"]=100,["flora_roobrush_02"]=30,["flora_marshmerrow_01"]=70,["flora_wickwheat_02"]=20,["flora_bc_mushroom_01"]=15,["flora_bc_shelffungus_01"]=0,["flora_stoneflower_01"]=40,["flora_plant_05"]=30,["flora_black_lichen_02"]=5,["flora_plant_02"]=30,["flora_black_lichen_01"]=5,["flora_plant_03"]=20,["flora_plant_06"]=30,["flora_plant_08"]=-10,["flora_plant_07"]=5,["flora_fire_fern_01"]=30,["flora_fire_fern_03"]=20,["flora_black_anther_02"]=20,["flora_bc_podplant_01"]=10,["flora_fire_fern_02"]=20,["flora_bc_podplant_02"]=10,["flora_heather_01"]=5,["flora_rm_scathecraw_02"]=70,["flora_comberry_01"]=50,["flora_rm_scathecraw_01"]=100,["flora_bc_mushroom_02"]=15,["flora_bc_mushroom_04"]=15,["flora_bc_mushroom_08"]=10,["flora_plant_04"]=20,["flora_bc_fern_01"]=70,["flora_black_anther_01"]=50,["flora_gold_kanet_01"]=30,["flora_bm_belladonna_01"]=30,["flora_corkbulb"]=0,["flora_bm_belladonna_02"]=30,["flora_gold_kanet_02"]=30,["flora_bittergreen_01"]=60,["flora_bm_holly_02"]=160,["flora_bm_holly_04"]=160,["flora_bm_holly_01"]=160,["flora_bm_holly_05"]=160,["flora_gold_kanet_02_uni"]=30,["flora_bm_belladonna_03"]=30,["flora_bm_wolfsbane_01"]=25,["tramaroot_04"]=40,["flora_bittergreen_04"]=20,["tramaroot_05"]=30,["flora_bittergreen_05"]=50,["tramaroot_03"]=45,["flora_bittergreen_02"]=50,["tramaroot_02"]=85,["flora_willow_flower_01"]=40,["flora_willow_flower_02"]=30,["flora_bittergreen_03"]=80,["contain_trama_shrub_05"]=140,["contain_trama_shrub_01"]=120,["flora_bc_podplant_03"]=10,["flora_bc_podplant_04"]=10,["flora_red_lichen_01"]=5,["flora_red_lichen_02"]=5,["flora_hackle-lo_02"]=20,["flora_hackle-lo_01"]=20,["contain_trama_shrub_02"]=140,["tramaroot_01"]=50,["contain_trama_shrub_03"]=70,["contain_trama_shrub_04"]=120,["contain_trama_shrub_06"]=120,["kollop_01_pearl"]=5,["kollop_02_pearl"]=5,["kollop_03_pearl"]=5,}

local function addItemToTable(out, objectId, objectTypeId, objectSubTypeId)
    local objectTypeStr = mwse.longToString(objectTypeId)
    local objectSubTypeStr = tostring(objectSubTypeId)
    if not out.ItemGroups[objectTypeStr] then out.ItemGroups[objectTypeStr] = {} end
    if not out.ItemGroups[objectTypeStr][objectSubTypeStr] then
        out.ItemGroups[objectTypeStr][objectSubTypeStr] = {Count = 0, Items = {}}
    end
    local gr = out.ItemGroups[objectTypeStr][objectSubTypeStr]
    gr.Count = gr.Count + 1
    out.Items[objectId:lower()] = {Type = objectTypeStr, SubType = objectSubTypeStr, Position = gr.Count}
    table.insert(gr.Items, objectId)
end

function this.fillItems()
    local items = {data = {}}
    local out = {Items = {}, ItemGroups = {}}
    items.data[tes3.objectType.alchemy] = {}
    items.data[tes3.objectType.ingredient] = {}
    items.data[tes3.objectType.apparatus] = {}
    items.data[tes3.objectType.armor] = {}
    items.data[tes3.objectType.book] = {}
    items.data[tes3.objectType.clothing] = {}
    items.data[tes3.objectType.lockpick] = {}
    items.data[tes3.objectType.probe] = {}
    items.data[tes3.objectType.repairItem] = {}
    items.data[tes3.objectType.weapon] = {}

    mwse.log("Items gen tms = %s", tostring(os.time()))
    for _, object in pairs(tes3.dataHandler.nonDynamicData.objects) do
        if object ~= nil and not object.deleted and (object.script == nil or scriptWhiteList[object.script.id]) then
            if items.data[object.objectType] ~= nil and object.name ~= nil and not forbiddenIds[object.id] and
                    object.name ~= "<Deprecated>" and (object.icon == nil or object.icon ~= "default icon.dds") and
                    object.weight > 0 and not forbiddenModels[(object.mesh or "err"):lower()] then

                table.insert(items.data[object.objectType], object)
            end
        end
    end
    for objType, data in pairs(items.data) do
        table.sort(data, function(a, b) return a.value < b.value end)
    end


    for i, object in ipairs(items.data[tes3.objectType.book]) do
        local objSubType = 1
        if object.type then
            objSubType = object.type
        elseif object.slot then
            objSubType = object.slot
        end

        if object.enchantment ~= nil or object.skill ~= -1 then
            addItemToTable(out, object.id, tes3.objectType.book, objSubType)
        end
    end
    for typeId, data in pairs(items.data) do
        if typeId ~= tes3.objectType.book then
            for i, object in ipairs(data) do
                local objSubType = 1
                if object.type then
                    objSubType = object.type
                elseif object.slot then
                    objSubType = object.slot
                end

                if (typeId ~= tes3.objectType.armor or typeId ~= tes3.objectType.clothing) and object.enchantment ~= nil then
                    local forbidden = false
                    for i, effect in pairs(object.enchantment.effects) do
                        if forbiddenEffectsIds[effect.id] then
                            forbidden = true
                        end
                    end
                    if not forbidden then
                        addItemToTable(out, object.id, typeId, objSubType)
                    end
                else
                    addItemToTable(out, object.id, typeId, objSubType)
                end
            end
        end
    end

    for type, data in pairs(out.ItemGroups) do
        for subType, gr in pairs(data) do
            mwse.log("%s %s %s", type, subType, gr.Count)
        end
    end

    mwse.log("tme = %s", tostring(os.time()))
    return out
end

function this.fillCreatures()
    local creatures = {}
    local out = {Creatures = {}, CreatureGroups = {}}

    mwse.log("Creatures gen tms = %s", tostring(os.time()))
    for _, object in pairs(tes3.dataHandler.nonDynamicData.objects) do
        local idLow = object.id:lower()
        if object ~= nil and object.objectType == tes3.objectType.creature and not object.deleted and
                (object.script == nil or scriptWhiteList[object.script.id] or string.find(object.script.id, "^disease[A-Z].+")) and
                not string.find(idLow, "kwama queen_") and not string.find(idLow, ".+_summon") and
                not forbiddenIds[object.id] and object.name ~= "<Deprecated>" and object.health > 0 and
                not forbiddenModels[(object.mesh or "err"):lower()] then

            local objSubType = object.type
            if object.swims then
                objSubType = 4
            end
            if creatures[objSubType] == nil then creatures[objSubType] = {} end
            table.insert(creatures[objSubType], object)
        end
    end
    for objType, data in pairs(creatures) do
        table.sort(data, function(a, b) return a.level < b.level end)
    end

    for subType, data in pairs(creatures) do
        for i, object in ipairs(data) do
            if not out.CreatureGroups[tostring(subType)] then
                out.CreatureGroups[tostring(subType)] = {Count = 0, Items = {}}
            end
            local gr = out.CreatureGroups[tostring(subType)]
            gr.Count = gr.Count + 1
            table.insert(gr.Items, object.id)
            out.Creatures[object.id:lower()] = {SubType = tostring(subType), Position = gr.Count}
        end
    end

    for subType, data in pairs(out.CreatureGroups) do
        mwse.log("%s %s %s", "CREA", subType, data.Count)
    end

    mwse.log("tme = %s", tostring(os.time()))
    return out
end

function this.fillHeadsHairs()
    local data = {}
    local out = {Parts = {}}

    mwse.log("BodyParts gen tms = %s", tostring(os.time()))
    for _, object in pairs(tes3.dataHandler.nonDynamicData.objects) do
        if object ~= nil and object.objectType == tes3.objectType.bodyPart and not object.deleted and object.raceName and
                object.partType == tes3.activeBodyPartLayer.base and object.part <= 1 and not forbiddenModels[(object.mesh or "err"):lower()] then

            local raceLow = object.raceName:lower()
            if data[raceLow] == nil then data[raceLow] = {} end
            if data[raceLow][object.part] == nil then data[raceLow][object.part] = {} end
            table.insert(data[raceLow][object.part], object)
        end
    end

    for raceName, dt in pairs(data) do
        for partId, objectArr in pairs(dt) do
            if not out.Parts[raceName] then out.Parts[raceName] = {} end
            if not out.Parts[raceName][tostring(partId)] then out.Parts[raceName][tostring(partId)] = {} end
            for _, object in pairs(objectArr) do
                local femaleId = 0
                if object.female then femaleId = 1 end
                if not out.Parts[raceName][tostring(partId)][tostring(femaleId)] then out.Parts[raceName][tostring(partId)][tostring(femaleId)] = {} end

                table.insert(out.Parts[raceName][tostring(partId)][tostring(femaleId)], object.id)
            end
        end
    end

    mwse.log("tme = %s", tostring(os.time()))
    return out
end

function this.fillSpells()
    local spells = {}
    local out = {Spells = {}, SpellGroups = {}, TouchRange = {}}

    mwse.log("Spells gen tms = %s", tostring(os.time()))
    for _, object in pairs(tes3.dataHandler.nonDynamicData.spells) do
        if object ~= nil and not object.deleted and object.effects then
            if spells[object.castType] == nil then spells[object.castType] = {} end

            local baseCost = 0
            local effectCount = 0
            for _, effect in pairs(object.effects) do
                if effect.id > 0 then
                    baseCost = baseCost + effect.cost
                    effectCount = effectCount + 1
                end
            end
            if effectCount > 0 then
                table.insert(spells[object.castType], {object = object, cost = baseCost})
            end
        end
    end
    for objType, data in pairs(spells) do
        table.sort(data, function(a, b) return a.cost < b.cost end)
    end

    for ctype, dt in pairs(spells) do
        for _, data in ipairs(dt) do
            local idLow = data.object.id:lower()
            local object = data.object
            local effectsExistion = {}
            local isTouch = false
            local containsForbiddenEffect = false
            for _, effect in pairs(object.effects) do
                local id = skillByEffectId[effect.id]
                if id then
                    effectsExistion[id] = true
                    if effect.rangeType == tes3.effectRange.touch then isTouch = true end
                    if forbiddenEffectsIds[effect.id] then containsForbiddenEffect = true end
                end
            end
            if not (containsForbiddenEffect and (ctype == tes3.spellType.disease or ctype == tes3.spellType.blight or tes3.spellType.ability)) then
                out.Spells[idLow] = {}
                if isTouch then out.TouchRange[idLow] = {} end
                for schoolId, _ in pairs(effectsExistion) do
                    local id = schoolId

                    if ctype == tes3.spellType.ability then id = 200
                    elseif ctype == tes3.spellType.disease or ctype == tes3.spellType.blight then id = 201 end

                    if out.SpellGroups[tostring(id)] == nil then out.SpellGroups[tostring(id)] = {Count = 0, Items = {}} end
                    local gr = out.SpellGroups[tostring(id)]
                    gr.Count = gr.Count + 1
                    table.insert(gr.Items, data.object.id)
                    table.insert(out.Spells[idLow], {SubType = id, Position = gr.Count})

                    if isTouch then
                        id = id + 100
                        if out.SpellGroups[tostring(id)] == nil then out.SpellGroups[tostring(id)] = {Count = 0, Items = {}} end
                        gr = out.SpellGroups[tostring(id)]
                        gr.Count = gr.Count + 1
                        table.insert(gr.Items, data.object.id)
                        table.insert(out.TouchRange[idLow], {SubType = id, Position = gr.Count})
                    end
                end
            end
        end
    end

    for subType, data in pairs(out.SpellGroups) do
        mwse.log("%s %s %s", "SPEL", subType, data.Count)
    end

    mwse.log("tme = %s", tostring(os.time()))
    return out
end

function this.fillHerbs()
    local data = {}
    local out = {Herbs = {}, HerbsObjectList = {}}

    mwse.log("Herbs gen tms = %s", tostring(os.time()))
    for _, object in pairs(tes3.dataHandler.nonDynamicData.objects) do
        if object ~= nil and object.objectType == tes3.objectType.container and (object.script == nil or scriptWhiteList[object.script.id]) and
                not object.deleted and object.organic and object.respawns and object.capacity < 5 and
                not string.find(object.id, "^T_Mw_Mine+") and not forbiddenModels[(object.mesh or "err"):lower()] then

            table.insert(data, object)
        end
    end

    local pos = 0
    for _, object in pairs(data) do
        pos = pos + 1
        local idLow = object.id:lower()
        out.Herbs[idLow] = {Offset = herbsOffsets[idLow] or 0, Position = pos}

        table.insert(out.HerbsObjectList, object.id)
    end
    out.HerbsListCount = pos

    mwse.log("tme = %s", tostring(os.time()))
    return out
end

local function isValidDestination(destination)
    if destination == nil or destination.marker == nil then return false end
    local pos = destination.marker.position
    local rot = destination.marker.orientation
    return not (pos == nil or rot == nil or (pos.x == 0 and pos.y == 0 and pos.z == 0 and rot.x == 0 and rot.y == 0 and rot.z == 0))
end

function this.findTravelDestinations()
    mwse.log("Travel destinations gen tms = %s", tostring(os.time()))
    local out = {}

    for _, object in pairs(tes3.dataHandler.nonDynamicData.objects) do
        if object ~= nil and (object.objectType == tes3.objectType.npc or object.objectType == tes3.objectType.creature) and not object.deleted and
                object.aiConfig and object.aiConfig.travelDestinations then
            for _, dest in pairs(object.aiConfig.travelDestinations) do
                if isValidDestination(dest) then
                    local newDest = {marker = {position = dest.marker.position, orientation = dest.marker.orientation}, cell = dest.cell}
                    table.insert(out, newDest)
                end
            end
        end
    end

    mwse.log("Travel destinations = %i", #out)
    mwse.log("tme = %s", tostring(os.time()))
    return out
end

return this