local this = {}

local EasyMCM = require("easyMCM.EasyMCM")

this.name = "Morrowind World Randomizer"

-- local strYes = tes3.findGMST(tes3.gmst.sYes).value
-- local strNo = tes3.findGMST(tes3.gmst.sNo).value
local strDisabled = "---"

local updateEventStr = "MWWRandomizer_UpdateGUI_event"

this.config = nil

local regionDescr = "Principle of the randomizer: First, the position of the object (or value) to be randomized is found in the sorted list, then the boundary values of the region are calculated relative to it. The object's position is in the center of the region. Offset shifts the center of the region."..
    "\n\nFor example, in a list of 100 objects, you need to randomize the 50th with a region of 20% and an offset of -10%. The result will be a random object with a range of 30 to 50."

function this.init(config)
    this.config = config
end

local function enableElement(self)
    if self and self.elements and self.elements.label then
        self.elements.label.color = tes3ui.getPalette("normal_color")
    end
end

local function disableElement(self)
    if self and self.elements and self.elements.label then
        self.elements.label.color = tes3ui.getPalette("disabled_color")
    end
end

local function createSettingsBlock_slider(varTable, varStr, varMul, min, max, step, labels)
    local slider = {
        class = "Slider",
        label = labels.label or "",
        description = labels.descr or "",
        min = min,
        max = max,
        step = step,
        jump = step * 10,
        variable = EasyMCM.createVariable{
            get = function(self)
                if varTable ~= nil and varTable[varStr] ~= nil then
                    return varTable[varStr] * varMul
                end
                return min
            end,
            set = function(self, val)
                if varTable ~= nil and varTable[varStr] ~= nil then
                    varTable[varStr] = val / varMul
                end
            end,
        },
        postCreate = function(self)
            event.register(updateEventStr, function()
                if this.config.fullyLoaded then
                    enableElement(self)
                else
                    disableElement(self)
                end
            end)
        end,
    }
    return slider
end

local function createSettingsBlock_minmaxp(varRegionTable, varStr, varMul, min, max, step, labels)
    local slider = {
        class = "Slider",
        label = labels.label or "",
        description = labels.descr or "",
        min = min,
        max = max,
        step = step,
        jump = step * 10,
        variable = EasyMCM.createVariable{
            get = function(self)
                if varRegionTable ~= nil and varRegionTable[varStr] ~= nil then
                    return varRegionTable[varStr] * varMul
                end
                return min
            end,
            set = function(self, val)
                if varRegionTable ~= nil then
                    varRegionTable[varStr] = val / varMul
                    if varRegionTable.min > varRegionTable.max then
                        varRegionTable.max = varRegionTable.min
                    end
                end
            end,
        },
        postCreate = function(self)
            event.register(updateEventStr, function()
                if this.config.fullyLoaded then
                    enableElement(self)
                else
                    disableElement(self)
                end
            end)
        end,
    }
    return slider
end

local function createSettingsBlock_region(varTable, labels)
    local slider = {
        class = "Slider",
        label = labels.label or "",
        description = labels.descr or "",
        min = 0,
        max = 200,
        step = 1,
        jump = 5,
        variable = EasyMCM.createVariable{
            get = function(self)
                if varTable ~= nil then
                    return math.floor((varTable.max - -varTable.min) * 100 + 0.5)
                end
                return 0
            end,
            set = function(self, val)
                if varTable ~= nil then
                    local offset = (varTable.max - -varTable.min) / 2
                    varTable.min = varTable.min - offset + val / 200
                    varTable.max = varTable.max - offset + val / 200
                end
            end,
        },
        postCreate = function(self)
            event.register(updateEventStr, function()
                if this.config.fullyLoaded then
                    enableElement(self)
                    -- self:enable()
                else
                    disableElement(self)
                    -- self:disable()
                end
                -- self:update()
            end)
        end,
    }
    return slider
end

local function createSettingsBlock_offset(varTable, labels)
    local slider = {
        class = "Slider",
        label = labels.label or "",
        description = labels.descr or "",
        min = -100,
        max = 100,
        step = 1,
        jump = 5,
        variable = EasyMCM.createVariable{
            get = function(self)
                if varTable ~= nil then
                    return math.floor((-varTable.min + (varTable.max - -varTable.min) / 2) * 100  + 0.5)
                end
                return 0
            end,
            set = function(self, val)
                if varTable ~= nil then
                    local offset = -varTable.min + (varTable.max - -varTable.min) / 2
                    varTable.min = varTable.min + offset - val / 100
                    varTable.max = varTable.max - offset + val / 100
                end
            end,
        },
        postCreate = function(self)
            event.register(updateEventStr, function()
                if this.config.fullyLoaded then
                    enableElement(self)
                    -- self:enable()
                else
                    disableElement(self)
                    -- self:disable()
                end
                -- self:update()
            end)
        end,
    }
    return slider
end

local function createOnOffIngameButton(label, varTable, varId)
    local buttonText
    if this.config.fullyLoaded then
        buttonText = varTable[varId] and tes3.findGMST(tes3.gmst.sOn).value or tes3.findGMST(tes3.gmst.sOff).value
    else
        buttonText = strDisabled
    end
    local data = {
        class = "Button",
        label = label,
        buttonText = buttonText,
        callback = function (self)
            if varTable ~= nil and varTable[varId] ~= nil and this.config.fullyLoaded then
                varTable[varId] = not varTable[varId]
                self.buttonText = varTable[varId] and tes3.findGMST(tes3.gmst.sOn).value or tes3.findGMST(tes3.gmst.sOff).value
            else
                self.buttonText = strDisabled
            end
            self:setText(self:getText())
            -- self:update()
        end,
        postCreate = function(self)
            event.register(updateEventStr, function()
                if this.config.fullyLoaded then
                    self.buttonText = varTable[varId] and tes3.findGMST(tes3.gmst.sOn).value or tes3.findGMST(tes3.gmst.sOff).value
                    enableElement(self)
                else
                    self.buttonText = strDisabled
                    disableElement(self)
                end
                -- if self.elements and self.elements.button and self.elements.button.text then
                --     self:setText(self:getText())
                --     -- self:update()
                --     mwse.log("TEST"..tostring(os.time()))
                -- end
            end)
        end,
    }
    return data
end

function this.registerModConfig()
    local data = {
        name = this.name,
        onClose = (function()
            this.config.save()
        end),
        pages = {
            {
                label = "Main",
                class = "Page",
                -- postCreate = function(self)
                --     event.trigger(updateEventStr)
                -- end,
                components = {
                    createOnOffIngameButton("Enable Randomizer", this.config.data, "enabled"),
                },
            },
            {
                label = "Global",
                class = "Page",
                postCreate = function(self)
                    event.trigger(updateEventStr)
                end,
                components = {
                    {
                        label = "Use a separate config for each character",
                        class = "OnOffButton",
                        variable = {
                            class = "Variable",
                            get = function(self)
                                return not this.config.global.globalConfig
                            end,
                            set = function(self, val)
                                this.config.global.globalConfig = not val
                                this.config.load()
                                event.trigger(updateEventStr)
                            end,
                        },
                    },

                    {
                        class = "Category",
                        label = "Pregenerated data tables",
                        description = "",
                        components = {
                            {
                                label = "Force to use Tamriel Rebuilt data",
                                class = "OnOffButton",
                                variable = {
                                    class = "TableVariable",
                                    table = this.config.global.dataTables,
                                    id = "forceTRData",
                                },
                            },
                            {
                                label = "Use pregenerated item data",
                                class = "OnOffButton",
                                variable = {
                                    class = "TableVariable",
                                    table = this.config.global.dataTables,
                                    id = "usePregeneratedItemData",
                                },
                            },
                            {
                                label = "Use pregenerated creature data",
                                class = "OnOffButton",
                                variable = {
                                    class = "TableVariable",
                                    table = this.config.global.dataTables,
                                    id = "usePregeneratedCreatureData",
                                },
                            },
                            {
                                label = "Use pregenerated head/hairs data",
                                class = "OnOffButton",
                                variable = {
                                    class = "TableVariable",
                                    table = this.config.global.dataTables,
                                    id = "usePregeneratedHeadHairData",
                                },
                            },
                            {
                                label = "Use pregenerated spell data",
                                class = "OnOffButton",
                                variable = {
                                    class = "TableVariable",
                                    table = this.config.global.dataTables,
                                    id = "usePregeneratedSpellData",
                                },
                            },
                            {
                                label = "Use pregenerated herb data",
                                class = "OnOffButton",
                                variable = {
                                    class = "TableVariable",
                                    table = this.config.global.dataTables,
                                    id = "usePregeneratedHerbData",
                                },
                            },
                            {
                                label = "Use pregenerated travel destination data",
                                class = "OnOffButton",
                                variable = {
                                    class = "TableVariable",
                                    table = this.config.global.dataTables,
                                    id = "usePregeneratedTravelData",
                                },
                            },
                        },
                    },
                },
            },
            {
                label = "Items",
                class = "FilterPage",
                -- postCreate = function(self)
                --     event.trigger(updateEventStr)
                -- end,
                components = {
                    createOnOffIngameButton("Randomize items in containers", this.config.data.containers.items, "randomize"),
                    createSettingsBlock_region(this.config.data.containers.items.region, {label = "Region size %s%%", descr = regionDescr}),
                    createSettingsBlock_offset(this.config.data.containers.items.region, {label = "Offset %s%%", descr = regionDescr}),

                    createOnOffIngameButton("Randomize items without a container", this.config.data.items, "randomize"), -- ????
                    createSettingsBlock_region(this.config.data.items.region, {label = "Region size %s%%", descr = regionDescr}),
                    createSettingsBlock_offset(this.config.data.items.region, {label = "Offset %s%%", descr = regionDescr}),

                    createOnOffIngameButton("Randomize items in NPCs", this.config.data.NPCs.items, "randomize"),
                    createSettingsBlock_region(this.config.data.NPCs.items.region, {label = "Region size %s%%", descr = regionDescr}),
                    createSettingsBlock_offset(this.config.data.NPCs.items.region, {label = "Offset %s%%", descr = regionDescr}),

                    createOnOffIngameButton("Randomize items in creatures", this.config.data.creatures.items, "randomize"),
                    createSettingsBlock_region(this.config.data.creatures.items.region, {label = "Region size %s%%", descr = regionDescr}),
                    createSettingsBlock_offset(this.config.data.creatures.items.region, {label = "Offset %s%%", descr = regionDescr}),

                    createOnOffIngameButton("Randomize souls in soulgems", this.config.data.soulGems.soul, "randomize"),
                    createSettingsBlock_region(this.config.data.soulGems.soul.region, {label = "Region size %s%%", descr = regionDescr}),
                    createSettingsBlock_offset(this.config.data.soulGems.soul.region, {label = "Offset %s%%", descr = regionDescr}),

                    createOnOffIngameButton("Randomize the amount of gold", this.config.data.gold, "randomize"),
                    createSettingsBlock_minmaxp(this.config.data.gold.region, "min", 100, 0, 1000, 1, {label = "Minimum multiplier %s%%",}),
                    createSettingsBlock_minmaxp(this.config.data.gold.region, "max", 100, 0, 1000, 1, {label = "Maximum multiplier %s%%",}),
                },
            },
            {
                label = "Creatures",
                class = "FilterPage",
                -- postCreate = function(self)
                --     event.trigger(updateEventStr)
                -- end,
                components = {
                    {
                        class = "Category",
                        label = "Creatures",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize ceatures", this.config.data.creatures, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.creatures.region, {label = "Offset %s%%", descr = regionDescr}),
                        },
                    },

                    {
                        class = "Category",
                        label = "Items",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize items", this.config.data.creatures.items, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.items.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.creatures.items.region, {label = "Offset %s%%", descr = regionDescr}),
                        },
                    },

                    {
                        class = "Category",
                        label = "Health",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize health points", this.config.data.creatures.health, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.creatures.health.region, "min", 100, 0, 1000, 1, {label = "Minimum multiplier %s%%",}),
                            createSettingsBlock_minmaxp(this.config.data.creatures.health.region, "max", 100, 0, 1000, 1, {label = "Maximum multiplier %s%%",}),
                        },
                    },

                    {
                        class = "Category",
                        label = "Magicka",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize magicka points", this.config.data.creatures.magicka, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.creatures.magicka.region, "min", 100, 0, 1000, 1, {label = "Minimum multiplier %s%%",}),
                            createSettingsBlock_minmaxp(this.config.data.creatures.magicka.region, "max", 100, 0, 1000, 1, {label = "Maximum multiplier %s%%",}),
                        },
                    },

                    {
                        class = "Category",
                        label = "Fatigue",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize fatigue points", this.config.data.creatures.fatigue, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.creatures.fatigue.region, "min", 100, 0, 1000, 1, {label = "Minimum multiplier %s%%",}),
                            createSettingsBlock_minmaxp(this.config.data.creatures.fatigue.region, "max", 100, 0, 1000, 1, {label = "Maximum multiplier %s%%",}),
                        },
                    },

                    {
                        class = "Category",
                        label = "Attack damage",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize attack damage", this.config.data.creatures.attack, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.creatures.attack.region, "min", 100, 0, 1000, 1, {label = "Minimum multiplier %s%%",}),
                            createSettingsBlock_minmaxp(this.config.data.creatures.attack.region, "max", 100, 0, 1000, 1, {label = "Maximum multiplier %s%%",}),
                        },
                    },

                    {
                        class = "Category",
                        label = "Scale",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize the object's scale", this.config.data.creatures.scale, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.creatures.scale.region, "min", 100, 10, 1000, 1, {label = "Minimum multiplier %s%%",}),
                            createSettingsBlock_minmaxp(this.config.data.creatures.scale.region, "max", 100, 10, 1000, 1, {label = "Maximum multiplier %s%%",}),
                        },
                    },

                    {
                        class = "Category",
                        label = "Skills",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize skill values", this.config.data.creatures.skills, "randomize"),
                            createSettingsBlock_slider(this.config.data.creatures.skills, "limit", 1, 1, 255, 1, {label = "The maximum value of a skill is %s"}),

                            {
                                class = "Category",
                                label = "Combat skills",
                                description = "",
                                components = {
                                    createSettingsBlock_region(this.config.data.creatures.skills.combat.region, {label = "Region size %s%%", descr = regionDescr}),
                                    createSettingsBlock_offset(this.config.data.creatures.skills.combat.region, {label = "Offset %s%%", descr = regionDescr}),
                                },
                            },

                            {
                                class = "Category",
                                label = "Magic skills",
                                description = "",
                                components = {
                                    createSettingsBlock_region(this.config.data.creatures.skills.magic.region, {label = "Region size %s%%", descr = regionDescr}),
                                    createSettingsBlock_offset(this.config.data.creatures.skills.magic.region, {label = "Offset %s%%", descr = regionDescr}),
                                },
                            },

                            {
                                class = "Category",
                                label = "Stealth skills",
                                description = "",
                                components = {
                                    createSettingsBlock_region(this.config.data.creatures.skills.stealth.region, {label = "Region size %s%%", descr = regionDescr}),
                                    createSettingsBlock_offset(this.config.data.creatures.skills.stealth.region, {label = "Offset %s%%", descr = regionDescr}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = "AI",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize fight parameter", this.config.data.creatures.ai.fight, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.ai.fight.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.creatures.ai.fight.region, {label = "Offset %s%%", descr = regionDescr}),

                            createOnOffIngameButton("Randomize flee parameter", this.config.data.creatures.ai.flee, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.ai.flee.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.creatures.ai.flee.region, {label = "Offset %s%%", descr = regionDescr}),

                            createOnOffIngameButton("Randomize alarm parameter", this.config.data.creatures.ai.alarm, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.ai.alarm.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.creatures.ai.alarm.region, {label = "Offset %s%%", descr = regionDescr}),

                            createOnOffIngameButton("Randomize hello parameter", this.config.data.creatures.ai.hello, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.ai.hello.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.creatures.ai.hello.region, {label = "Offset %s%%", descr = regionDescr}),
                        },
                    },

                    {
                        class = "Category",
                        label = "Spells",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize spells", this.config.data.creatures.spells, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.spells.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.creatures.spells.region, {label = "Offset %s%%", descr = regionDescr}),

                            {
                                class = "Category",
                                label = "Add new spells",
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.creatures.spells.add, "chance", 100, 0, 100, 1, {label = "%s%% chance to add", descr = "Chance to add for each new spell."}),
                                    createSettingsBlock_slider(this.config.data.creatures.spells.add, "count", 1, 0, 50, 1, {label = "Add %s more spells"}),
                                    createSettingsBlock_slider(this.config.data.creatures.spells.add, "levelReference", 1, 1, 50, 1, {label = "Level limiter %s", descr = "The level of the creature, in proportion to which the list of spells is limited. If a creature has this level, the whole spell list will be available for randomization."}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = "Abilities",
                        description = "Abilities like the dunmer fire resistance.",
                        components = {
                            createOnOffIngameButton("Randomize abilities", this.config.data.creatures.abilities, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.abilities.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.creatures.abilities.region, {label = "Offset %s%%", descr = regionDescr}),

                            {
                                class = "Category",
                                label = "Add new abilities",
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.creatures.abilities.add, "chance", 100, 0, 100, 1, {label = "%s%% chance to add", descr = "Chance to add for each new ability."}),
                                    createSettingsBlock_slider(this.config.data.creatures.abilities.add, "count", 1, 0, 50, 1, {label = "Add %s more abilities"}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = "Diseases",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize creature diseases", this.config.data.creatures.diseases, "randomize"),
                            createSettingsBlock_region(this.config.data.creatures.diseases.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.creatures.diseases.region, {label = "Offset %s%%", descr = regionDescr}),

                            {
                                class = "Category",
                                label = "Add new diseases",
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.creatures.diseases.add, "chance", 100, 0, 100, 1, {label = "%s%% chance to add", descr = "Chance to add for each new disease."}),
                                    createSettingsBlock_slider(this.config.data.creatures.diseases.add, "count", 1, 0, 50, 1, {label = "Add %s more diseases"}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = "Add positive or negative effects",
                        description = "",
                        components = {
                            {
                                class = "Category",
                                label = "Positive effects",
                                description = "Positive effects are \"Chameleon\", \"Water Breathing\", \"Water Walking\", \"Swift Swim\", \"Resist Normal Weapons\", \"Sanctuary\", \"Attack Bonus\", \"Resist Magicka\", \"Resist Fire\", \"Resist Frost\", \"Resist Shock\", \"Resist Common Disease\", \"Resist Blight Disease\", \"Resist Corprus\", \"Resist Poison\", \"Resist Paralysis\", \"Shield\"",
                                components = {
                                    createSettingsBlock_slider(this.config.data.creatures.effects.positive.add, "chance", 100, 0, 100, 1, {label = "%s%% chance to add", descr = "Chance to add for each new effect."}),
                                    createSettingsBlock_slider(this.config.data.creatures.effects.positive.add, "count", 1, 0, 10, 1, {label = "Add %s more effects"}),

                                    createSettingsBlock_minmaxp(this.config.data.creatures.effects.positive.add.region, "min", 1, 0, 100, 1, {label = "Minimum effect value %s",}),
                                    createSettingsBlock_minmaxp(this.config.data.creatures.effects.positive.add.region, "max", 1, 0, 100, 1, {label = "Maximum effect value %s",}),
                                },
                            },

                            {
                                class = "Category",
                                label = "Negative effects",
                                description = "Negative effects are \"Sound\", \"Silence\", \"Blind\", \"Paralyze\" and \"Resist Normal Weapons\", \"Sanctuary\", \"Attack Bonus\", \"Resist Magicka\", \"Resist Fire\", \"Resist Frost\", \"Resist Shock\", \"Resist Common Disease\", \"Resist Blight Disease\", \"Resist Corprus\", \"Resist Poison\", \"Resist Paralysis\", \"Shield\" with negative value",
                                components = {
                                    createSettingsBlock_slider(this.config.data.creatures.effects.negative.add, "chance", 100, 0, 100, 1, {label = "%s%% chance to add", descr = "Chance to add for each new effect."}),
                                    createSettingsBlock_slider(this.config.data.creatures.effects.negative.add, "count", 1, 0, 10, 1, {label = "Add %s more effects"}),

                                    createSettingsBlock_minmaxp(this.config.data.creatures.effects.negative.add.region, "min", 1, 0, 100, 1, {label = "Minimum effect value %s",}),
                                    createSettingsBlock_minmaxp(this.config.data.creatures.effects.negative.add.region, "max", 1, 0, 100, 1, {label = "Maximum effect value %s",}),
                                },
                            },
                        },
                    },
                },
            },
            {
                label = "NPCs",
                class = "FilterPage",
                -- postCreate = function(self)
                --     event.trigger(updateEventStr)
                -- end,
                components = {
                    {
                        class = "Category",
                        label = "Items",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize items", this.config.data.NPCs.items, "randomize"),
                            createSettingsBlock_region(this.config.data.NPCs.items.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.NPCs.items.region, {label = "Offset %s%%", descr = regionDescr}),
                        },
                    },

                    {
                        class = "Category",
                        label = "Health",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize health points", this.config.data.NPCs.health, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.NPCs.health.region, "min", 100, 0, 1000, 1, {label = "Minimum multiplier %s%%",}),
                            createSettingsBlock_minmaxp(this.config.data.NPCs.health.region, "max", 100, 0, 1000, 1, {label = "Maximum multiplier %s%%",}),
                        },
                    },

                    {
                        class = "Category",
                        label = "Magicka",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize magicka points", this.config.data.NPCs.magicka, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.NPCs.magicka.region, "min", 100, 0, 1000, 1, {label = "Minimum multiplier %s%%",}),
                            createSettingsBlock_minmaxp(this.config.data.NPCs.magicka.region, "max", 100, 0, 1000, 1, {label = "Maximum multiplier %s%%",}),
                        },
                    },

                    {
                        class = "Category",
                        label = "Fatigue",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize fatigue points", this.config.data.NPCs.fatigue, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.NPCs.fatigue.region, "min", 100, 0, 1000, 1, {label = "Minimum multiplier %s%%",}),
                            createSettingsBlock_minmaxp(this.config.data.NPCs.fatigue.region, "max", 100, 0, 1000, 1, {label = "Maximum multiplier %s%%",}),
                        },
                    },

                    {
                        class = "Category",
                        label = "Scale",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize the object's scale", this.config.data.NPCs.scale, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.NPCs.scale.region, "min", 100, 10, 1000, 1, {label = "Minimum multiplier %s%%",}),
                            createSettingsBlock_minmaxp(this.config.data.NPCs.scale.region, "max", 100, 10, 1000, 1, {label = "Maximum multiplier %s%%",}),
                        },
                    },

                    {
                        class = "Category",
                        label = "Head",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize the object's head", this.config.data.NPCs.head, "randomize"),
                            createOnOffIngameButton("Limit by race", this.config.data.NPCs.head, "raceLimit"),
                            createOnOffIngameButton("Limit by gender", this.config.data.NPCs.head, "genderLimit"),
                        },
                    },

                    {
                        class = "Category",
                        label = "Hairs",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize the object's hairs", this.config.data.NPCs.hair, "randomize"),
                            createOnOffIngameButton("Limit by race", this.config.data.NPCs.hair, "raceLimit"),
                            createOnOffIngameButton("Limit by gender", this.config.data.NPCs.hair, "genderLimit"),
                        },
                    },

                    {
                        class = "Category",
                        label = "Skills",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize skill values", this.config.data.NPCs.skills, "randomize"),
                            createSettingsBlock_slider(this.config.data.NPCs.skills, "limit", 1, 1, 255, 1, {label = "The maximum value of a skill is %s"}),

                            {
                                class = "Category",
                                label = "Combat skills",
                                description = "",
                                components = {
                                    createSettingsBlock_region(this.config.data.NPCs.skills.combat.region, {label = "Region size %s%%", descr = regionDescr}),
                                    createSettingsBlock_offset(this.config.data.NPCs.skills.combat.region, {label = "Offset %s%%", descr = regionDescr}),
                                },
                            },

                            {
                                class = "Category",
                                label = "Magic skills",
                                description = "",
                                components = {
                                    createSettingsBlock_region(this.config.data.NPCs.skills.magic.region, {label = "Region size %s%%", descr = regionDescr}),
                                    createSettingsBlock_offset(this.config.data.NPCs.skills.magic.region, {label = "Offset %s%%", descr = regionDescr}),
                                },
                            },

                            {
                                class = "Category",
                                label = "Stealth skills",
                                description = "",
                                components = {
                                    createSettingsBlock_region(this.config.data.NPCs.skills.stealth.region, {label = "Region size %s%%", descr = regionDescr}),
                                    createSettingsBlock_offset(this.config.data.NPCs.skills.stealth.region, {label = "Offset %s%%", descr = regionDescr}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = "Attributes",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize attributes", this.config.data.NPCs.attributes, "randomize"),
                            createSettingsBlock_slider(this.config.data.NPCs.attributes, "limit", 1, 1, 255, 1, {label = "The maximum value of a attribute is %s"}),

                            createSettingsBlock_minmaxp(this.config.data.NPCs.attributes.region, "min", 100, 0, 100, 1, {label = "Minimum attribute value %s%% relative to the limit",}),
                            createSettingsBlock_minmaxp(this.config.data.NPCs.attributes.region, "max", 100, 0, 100, 1, {label = "Maximum attribute value %s%% relative to the limit",}),
                        },
                    },

                    {
                        class = "Category",
                        label = "AI",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize fight parameter", this.config.data.NPCs.ai.fight, "randomize"),
                            createSettingsBlock_region(this.config.data.NPCs.ai.fight.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.NPCs.ai.fight.region, {label = "Offset %s%%", descr = regionDescr}),

                            createOnOffIngameButton("Randomize flee parameter", this.config.data.NPCs.ai.flee, "randomize"),
                            createSettingsBlock_region(this.config.data.NPCs.ai.flee.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.NPCs.ai.flee.region, {label = "Offset %s%%", descr = regionDescr}),

                            createOnOffIngameButton("Randomize alarm parameter", this.config.data.NPCs.ai.alarm, "randomize"),
                            createSettingsBlock_region(this.config.data.NPCs.ai.alarm.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.NPCs.ai.alarm.region, {label = "Offset %s%%", descr = regionDescr}),

                            createOnOffIngameButton("Randomize hello parameter", this.config.data.NPCs.ai.hello, "randomize"),
                            createSettingsBlock_region(this.config.data.NPCs.ai.hello.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.NPCs.ai.hello.region, {label = "Offset %s%%", descr = regionDescr}),
                        },
                    },

                    {
                        class = "Category",
                        label = "Spells",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize spells", this.config.data.NPCs.spells, "randomize"),
                            createSettingsBlock_region(this.config.data.NPCs.spells.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.NPCs.spells.region, {label = "Offset %s%%", descr = regionDescr}),

                            {
                                class = "Category",
                                label = "Add new spells",
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.NPCs.spells.add, "chance", 100, 0, 100, 1, {label = "%s%% chance to add", descr = "Chance to add for each new spell."}),
                                    createSettingsBlock_slider(this.config.data.NPCs.spells.add, "count", 1, 0, 50, 1, {label = "Add %s more spells"}),
                                    createSettingsBlock_slider(this.config.data.NPCs.spells.add, "levelReference", 1, 1, 50, 1, {label = "Level limiter %s", descr = "The level of the creature, in proportion to which the list of spells is limited. If a creature has this level, the whole spell list will be available for randomization."}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = "Abilities",
                        description = "Abilities like the dunmer fire resistance.",
                        components = {
                            createOnOffIngameButton("Randomize creature abilities", this.config.data.NPCs.abilities, "randomize"),
                            createSettingsBlock_region(this.config.data.NPCs.abilities.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.NPCs.abilities.region, {label = "Offset %s%%", descr = regionDescr}),

                            {
                                class = "Category",
                                label = "Add new abilities",
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.NPCs.abilities.add, "chance", 100, 0, 100, 1, {label = "%s%% chance to add", descr = "Chance to add for each new ability."}),
                                    createSettingsBlock_slider(this.config.data.NPCs.abilities.add, "count", 1, 0, 50, 1, {label = "Add %s more abilities"}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = "Diseases",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize creature diseases", this.config.data.NPCs.diseases, "randomize"),
                            createSettingsBlock_region(this.config.data.NPCs.diseases.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.NPCs.diseases.region, {label = "Offset %s%%", descr = regionDescr}),

                            {
                                class = "Category",
                                label = "Add new diseases",
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.NPCs.diseases.add, "chance", 100, 0, 100, 1, {label = "%s%% chance to add", descr = "Chance to add for each new disease."}),
                                    createSettingsBlock_slider(this.config.data.NPCs.diseases.add, "count", 1, 0, 50, 1, {label = "Add %s more diseases"}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = "Add positive or negative effects",
                        description = "",
                        components = {
                            {
                                class = "Category",
                                label = "Positive effects",
                                description = "Positive effects are \"Chameleon\", \"Water Breathing\", \"Water Walking\", \"Swift Swim\", \"Resist Normal Weapons\", \"Sanctuary\", \"Attack Bonus\", \"Resist Magicka\", \"Resist Fire\", \"Resist Frost\", \"Resist Shock\", \"Resist Common Disease\", \"Resist Blight Disease\", \"Resist Corprus\", \"Resist Poison\", \"Resist Paralysis\", \"Shield\"",
                                components = {
                                    createSettingsBlock_slider(this.config.data.NPCs.effects.positive.add, "chance", 100, 0, 100, 1, {label = "%s%% chance to add", descr = "Chance to add for each new effect."}),
                                    createSettingsBlock_slider(this.config.data.NPCs.effects.positive.add, "count", 1, 0, 10, 1, {label = "Add %s more effects"}),

                                    createSettingsBlock_minmaxp(this.config.data.NPCs.effects.positive.add.region, "min", 1, 0, 100, 1, {label = "Minimum effect value %s",}),
                                    createSettingsBlock_minmaxp(this.config.data.NPCs.effects.positive.add.region, "max", 1, 0, 100, 1, {label = "Maximum effect value %s",}),
                                },
                            },

                            {
                                class = "Category",
                                label = "Negative effects",
                                description = "Negative effects are \"Sound\", \"Silence\", \"Blind\", \"Paralyze\" and \"Resist Normal Weapons\", \"Sanctuary\", \"Attack Bonus\", \"Resist Magicka\", \"Resist Fire\", \"Resist Frost\", \"Resist Shock\", \"Resist Common Disease\", \"Resist Blight Disease\", \"Resist Corprus\", \"Resist Poison\", \"Resist Paralysis\", \"Shield\" with negative value",
                                components = {
                                    createSettingsBlock_slider(this.config.data.NPCs.effects.negative.add, "chance", 100, 0, 100, 1, {label = "%s%% chance to add", descr = "Chance to add for each new effect."}),
                                    createSettingsBlock_slider(this.config.data.NPCs.effects.negative.add, "count", 1, 0, 10, 1, {label = "Add %s more effects"}),

                                    createSettingsBlock_minmaxp(this.config.data.NPCs.effects.negative.add.region, "min", 1, 0, 100, 1, {label = "Minimum effect value %s",}),
                                    createSettingsBlock_minmaxp(this.config.data.NPCs.effects.negative.add.region, "max", 1, 0, 100, 1, {label = "Maximum effect value %s",}),
                                },
                            },
                        },
                    },
                },
            },
            {
                label = "Barter/Transport",
                class = "FilterPage",
                components = {
                    {
                        class = "Category",
                        label = "Barter gold",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize merchant's gold supply", this.config.data.barterGold, "randomize"),
                            createSettingsBlock_minmaxp(this.config.data.barterGold.region, "min", 100, 0, 1000, 1, {label = "Minimum multiplier %s%%",}),
                            createSettingsBlock_minmaxp(this.config.data.barterGold.region, "max", 100, 0, 1000, 1, {label = "Maximum multiplier %s%%",}),
                        },
                    },

                    {
                        class = "Category",
                        label = "Transporters",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize transport destinations", this.config.data.transport, "randomize"),
                            createSettingsBlock_slider(this.config.data.transport, "unrandomizedCount", 1, 0, 4, 1, {label = "Number of Destinations without randomization %s"}),
                            createSettingsBlock_slider(this.config.data.transport, "toDoorsCount", 1, 0, 4, 1, {label = "Number of Destinations to a door %s"}),
                        },
                    },
                },
            },
            {
                label = "Containers",
                class = "FilterPage",
                components = {
                    {
                        class = "Category",
                        label = "Items",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize items in containers", this.config.data.containers.items, "randomize"),
                            createSettingsBlock_region(this.config.data.containers.items.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.containers.items.region, {label = "Offset %s%%", descr = regionDescr}),
                        },
                    },

                    {
                        class = "Category",
                        label = "A lock",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize lock value", this.config.data.containers.lock, "randomize"),
                            createSettingsBlock_region(this.config.data.containers.lock.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.containers.lock.region, {label = "Offset %s%%", descr = regionDescr}),
                            {
                                class = "Category",
                                label = "Lock object without a look",
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.containers.lock.add, "chance", 100, 0, 100, 1, {label = "%s%% chance to lock"}),
                                    createSettingsBlock_slider(this.config.data.containers.lock.add, "levelMultiplier", 1, 0, 100, 1, {label = "Lock level multiplier %s", descr = "New lock level = random (1, multiplier * player level)"}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = "A trap",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize trap spells", this.config.data.containers.trap, "randomize"),
                            createSettingsBlock_region(this.config.data.containers.trap.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.containers.trap.region, {label = "Offset %s%%", descr = regionDescr}),
                            {
                                class = "Category",
                                label = "Add a trap to an object without it",
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.containers.trap.add, "chance", 100, 0, 100, 1, {label = "%s%% chance to add"}),
                                    createSettingsBlock_slider(this.config.data.containers.trap.add, "levelMultiplier", 1, 0, 100, 1, {label = "Multiplier of the maximum value of the trap spell list %s", descr = "Spell list size %% = multiplier * player level"}),
                                    createOnOffIngameButton("Use only destruction spells", this.config.data.containers.trap.add, "onlyDestructionSchool"),
                                },
                            },
                        },
                    },
                },
            },
            {
                label = "Doors",
                class = "FilterPage",
                components = {
                    {
                        class = "Category",
                        label = "Destination",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize door destinations", this.config.data.doors, "randomize"),
                            createSettingsBlock_slider(this.config.data.doors, "chance", 100, 0, 100, 1, {label = "%s%% chance to randomize"}),
                            createSettingsBlock_slider(this.config.data.doors, "cooldown", 1, 0, 500, 1, {label = "Cooldown %s game hours"}),
                            createOnOffIngameButton("Change destination to nearest doors only", this.config.data.doors, "onlyNearest"),
                            createSettingsBlock_slider(this.config.data.doors, "nearestCellDepth", 1, 0, 10, 1, {label = "Radius in cells for list of nearest cells"}),
                        },
                    },

                    {
                        class = "Category",
                        label = "Locks",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize lock value", this.config.data.doors.lock, "randomize"),
                            createSettingsBlock_region(this.config.data.doors.lock.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.doors.lock.region, {label = "Offset %s%%", descr = regionDescr}),
                            {
                                class = "Category",
                                label = "Lock object without a look",
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.doors.lock.add, "chance", 100, 0, 100, 1, {label = "%s%% chance to lock"}),
                                    createSettingsBlock_slider(this.config.data.doors.lock.add, "levelMultiplier", 1, 0, 100, 1, {label = "Lock level multiplier %s", descr = "New lock level = random (1, multiplier * player level)"}),
                                },
                            },
                        },
                    },

                    {
                        class = "Category",
                        label = "Traps",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize trap spells", this.config.data.doors.trap, "randomize"),
                            createSettingsBlock_region(this.config.data.doors.trap.region, {label = "Region size %s%%", descr = regionDescr}),
                            createSettingsBlock_offset(this.config.data.doors.trap.region, {label = "Offset %s%%", descr = regionDescr}),
                            {
                                class = "Category",
                                label = "Add a trap to an object without it",
                                description = "",
                                components = {
                                    createSettingsBlock_slider(this.config.data.doors.trap.add, "chance", 100, 0, 100, 1, {label = "%s%% chance to add"}),
                                    createSettingsBlock_slider(this.config.data.doors.trap.add, "levelMultiplier", 1, 0, 100, 1, {label = "Multiplier of the maximum value of the trap spell list %s", descr = "Spell list size %% = multiplier * player level"}),
                                    createOnOffIngameButton("Use only destruction spells", this.config.data.doors.trap.add, "onlyDestructionSchool"),
                                },
                            },
                        },
                    },
                },
            },
            {
                label = "World",
                class = "FilterPage",
                components = {
                    {
                        class = "Category",
                        label = "Herbs",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize herbs", this.config.data.herbs, "randomize"),
                            createSettingsBlock_slider(this.config.data.herbs, "herbSpeciesPerCell", 1, 1, 20, 1, {label = "Number of herb species per cell %s"}),
                        },
                    },
                    {
                        class = "Category",
                        label = "Trees",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize trees", this.config.data.trees, "randomize"),
                        },
                    },
                    {
                        class = "Category",
                        label = "Stones",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize stones", this.config.data.stones, "randomize"),
                        },
                    },
                    {
                        class = "Category",
                        label = "Weather",
                        description = "",
                        components = {
                            createOnOffIngameButton("Randomize weather", this.config.data.weather, "randomize"),
                        },
                    },
                },
            },
        },
    }

    mwse.registerModConfig(this.name, EasyMCM.registerModData(data))
end

return this