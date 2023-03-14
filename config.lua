local dataSaver = include("Morrowind World Randomizer.dataSaver")

local this = {}

this.fullyLoaded = false;

local globalConfigName = "MWWRandomizer_Global"
local configName = "MWWRandomizer_Config"

local function deepcopy(orig)
    local orig_type = type(orig)
    local copy
    if orig_type == 'table' then
        copy = {}
        for orig_key, orig_value in next, orig, nil do
            copy[deepcopy(orig_key)] = deepcopy(orig_value)
        end
        setmetatable(copy, deepcopy(getmetatable(orig)))
    else -- number, string, boolean, etc
        copy = orig
    end
    return copy
end

local function addMissing(toTable, fromTable)
    for label, val in pairs(fromTable) do
        if type(val) == "table" then
            if toTable[label] == nil then
                toTable[label] = deepcopy(val)
            else
                addMissing(toTable[label], val)
            end
        elseif toTable[label] == nil then
            toTable[label] = val
        end
    end
end

local function applyChanges(toTable, fromTable)
    for label, val in pairs(fromTable) do
        if type(val) == "table" then
            if toTable[label] == nil then
                toTable[label] = deepcopy(val)
            else
                applyChanges(toTable[label], val)
            end
        else
            toTable[label] = val
        end
    end
end

this.global = mwse.loadConfig(globalConfigName)
this.data = nil

this.globalDefault = {
    dataTables = {
        forceTRData = false,
        usePregeneratedItemData = false,
        usePregeneratedCreatureData = false,
        usePregeneratedHeadHairData = false,
        usePregeneratedSpellData = false,
        usePregeneratedHerbData = false,
        usePregeneratedTravelData = false,
    },
    globalConfig = true,
}

if this.global == nil then
    this.global = deepcopy(this.globalDefault)
else
    addMissing(this.global, this.globalDefault)
end

this.default = {
    enabled = true,
    trees = {
        randomize = true,
        exceptScale = 2.5,
    },
    stones = {
        randomize = true,
        exceptScale = 2.5,
    },
    herbs = {
        randomize = true,
        herbSpeciesPerCell = 5,
    },
    containers = {
        items = {
            randomize = true,
            region = {min = 0.1, max = 0.1},
        },
        lock = {
            randomize = true,
            region = {min = 0.3, max = 0.3},
            add = {
                chance = 0.1,
                levelMultiplier = 5,
            },
        },
        trap = {
            randomize = true,
            region = {min = 1, max = 1},
            add = {
                chance = 0.1,
                levelMultiplier = 5,
                onlyDestructionSchool = false,
            },
        },
    },
    items = {
        randomize = true,
        region = {min = 0.1, max = 0.1},
    },
    soulGems = {
        maxCapacity = 400,
        soul = {
            randomize = true,
            region = {min = 0.2, max = 0.2},
        },
    },
    gold = {
        randomize = true,
        region = {min = 0.25, max = 1.75},
    },
    creatures = {
        randomize = true,
        region = {min = 0.1, max = 0.1},
        items = {
            randomize = true,
            region = {min = 0.1, max = 0.1},
        },
        attack = {
            randomize = true,
            region = {min = 0.75, max = 1.25},
        },
        spells = {
            randomize = true,
            region = {min = 0.1, max = 0.1},
            add = {
                chance = 0.1,
                count = 3,
                levelReference = 20,
            },
        },
        abilities = {
            randomize = false,
            region = {min = 0.5, max = 0.5},
            add = {
                chance = 1,
                count = 0,
            },
        },
        diseases = {
            randomize = false,
            region = {min = 0.1, max = 0.1},
            add = {
                chance = 0.1,
                count = 1,
            },
        },
        health = {
            randomize = true,
            region = {min = 0.5, max = 1.5},
        },
        magicka = {
            randomize = true,
            region = {min = 0.5, max = 1.5},
        },
        fatigue = {
            randomize = true,
            region = {min = 0.5, max = 1.5},
        },
        skills = {
            randomize = true,
            limit = 100,
            combat = {
                region = {min = 0.2, max = 0.2},
            },
            magic = {
                region = {min = 0.2, max = 0.2},
            },
            stealth = {
                region = {min = 0.2, max = 0.2},
            },
        },
        scale = {
            randomize = true,
            region = {min = 0.5, max = 1.5},
        },
        effects = {
            positive = {
                add = {
                    chance = 1,
                    count = 1,
                    region = {min = 0, max = 100},
                },
            },
            negative = {
                add = {
                    chance = 1,
                    count = 0,
                    region = {min = 0, max = 100},
                },
            },
        },
        ai = {
            fight = {
                randomize = true,
                region = {min = 0.2, max = 0.2},
            },
            flee = {
                randomize = true,
                region = {min = 0.2, max = 0.2},
            },
            alarm = {
                randomize = true,
                region = {min = 0.2, max = 0.2},
            },
            hello = {
                randomize = true,
                region = {min = 0.2, max = 0.2},
            },
        },
    },
    NPCs = {
        items = {
            randomize = true,
            region = {min = 0.1, max = 0.1},
        },
        spells = {
            randomize = true,
            region = {min = 0.1, max = 0.1},
            add = {
                chance = 1,
                count = 3,
                levelReference = 20,
            },
        },
        abilities = {
            randomize = true,
            region = {min = 0.1, max = 0.1},
            add = {
                chance = 1,
                count = 0,
            },
        },
        diseases = {
            randomize = false,
            region = {min = 0.1, max = 0.1},
            add = {
                chance = 0.05,
                count = 1,
            },
        },
        health = {
            randomize = true,
            region = {min = 0.5, max = 1.5},
        },
        magicka = {
            randomize = true,
            region = {min = 0.5, max = 1.5},
        },
        fatigue = {
            randomize = true,
            region = {min = 0.5, max = 1.5},
        },
        attributes = {
            randomize = true,
            limit = 100,
            region = {min = 0.5, max = 1.5},
        },
        skills = {
            randomize = true,
            limit = 100,
            combat = {
                region = {min = 0.2, max = 0.2},
            },
            magic = {
                region = {min = 0.2, max = 0.2},
            },
            stealth = {
                region = {min = 0.2, max = 0.2},
            },
        },
        head = {
            randomize = true,
            raceLimit = false,
            genderLimit = true,
        },
        hair = {
            randomize = true,
            raceLimit = false,
            genderLimit = false,
        },
        scale = {
            randomize = true,
            region = {min = 0.5, max = 1.5},
        },
        effects = {
            positive = {
                add = {
                    chance = 1,
                    count = 1,
                    region = {min = 0, max = 100},
                },
            },
            negative = {
                add = {
                    chance = 1,
                    count = 0,
                    region = {min = 0, max = 100},
                },
            },
        },
        ai = {
            fight = {
                randomize = true,
                region = {min = 0.2, max = 0.2},
            },
            flee = {
                randomize = true,
                region = {min = 0.2, max = 0.2},
            },
            alarm = {
                randomize = true,
                region = {min = 0.2, max = 0.2},
            },
            hello = {
                randomize = true,
                region = {min = 0.2, max = 0.2},
            },
        },
    },
    barterGold = {
        randomize = true,
        region = {min = 0.5, max = 1.5},
    },
    transport = {
        randomize = true,
        unrandomizedCount = 1,
        toDoorsCount = 0,
        toRandomPointCount = 0,
    },
    doors = {
        randomize = true,
        onlyNearest = true,
        nearestCellDepth = 2,
        chance = 1,
        cooldown = 10,
        restoreOriginal = true,
        lock = {
            randomize = true,
            region = {min = 0.3, max = 0.3},
            add = {
                chance = 0.1,
                levelMultiplier = 5,
            },
        },
        trap = {
            randomize = true,
            region = {min = 1, max = 1},
            add = {
                chance = 0.1,
                levelMultiplier = 5,
                onlyDestructionSchool = false,
            },
        },
    },
    weather = {
        randomize = true,
    },
}

this.data = deepcopy(this.default)

function this.getValueByPath(path)
    local value = this.data
    if value ~= nil and #path > 0 then
        for valStr in (path.."."):gmatch("(.-)".."[.]") do
            value = value[valStr]
            if value == nil then
                return nil
            end
        end
    end
    return value
end

function this.getConfig()
    if not this.fullyLoaded then
        this.load()
    end
    return this.data
end

function this.resetConfig()
    this.fullyLoaded = false
    applyChanges(this.data, this.default)
end

function this.resetToDefault()
    -- this.data = deepcopy(this.default)
    applyChanges(this.data, this.default)
    if not this.global and tes3.player then
        local playerData = dataSaver.getObjectData(tes3.player)
        if playerData then
            playerData.config = this.data
            tes3.player.modified = true
        end
    end
end

function this.save()
    mwse.saveConfig(globalConfigName, this.global)
    if this.global then
        mwse.saveConfig(configName, this.data)
    elseif tes3.player then
        local playerData = dataSaver.getObjectData(tes3.player)
        if playerData then
            playerData.config = this.data
            tes3.player.modified = true
        end
    end
end

function this.load()
    if this.global.globalConfig then
        local data = mwse.loadConfig(configName)
        if data == nil then
            applyChanges(this.data, this.default)
            -- this.data = deepcopy(this.default)
            this.fullyLoaded = true
        else
            -- addMissing(data, this.default)
            -- this.data = data
            applyChanges(this.data, data)
            this.fullyLoaded = true
        end
    elseif tes3.player then
        local playerData = dataSaver.getObjectData(tes3.player)
        if playerData then
            if playerData.config then
                -- addMissing(playerData.config, this.default)
                -- this.data = playerData.config
                applyChanges(this.data, playerData.config)
                this.fullyLoaded = true
            else
                -- this.data = deepcopy(this.default)
                applyChanges(this.data, this.default)
                playerData.config = this.data
                this.fullyLoaded = true
            end
        else
            mwse.log("[Morrowind World Randomizer] Failed to load config")
            this.fullyLoaded = false
            -- this.data = deepcopy(this.default)
        end
    else
        mwse.log("[Morrowind World Randomizer] Failed to load config")
        this.fullyLoaded = false
        -- this.data = deepcopy(this.default)
    end
end

if this.global.globalConfig then
    this.load()
end

return this