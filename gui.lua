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

local function createSettingsBlock_minmaxp(varRegionTable, varStr, min, max, step, labels)
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
                if varRegionTable ~= nil and varRegionTable.region ~= nil and varRegionTable.region[varStr] ~= nil then
                    return varRegionTable.region[varStr] * 100
                end
                return min
            end,
            set = function(self, val)
                if varRegionTable ~= nil and varRegionTable.region ~= nil then
                    varRegionTable.region[varStr] = val / 100
                    if varRegionTable.region.min > varRegionTable.region.max then
                        varRegionTable.region.max = varRegionTable.region.min
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
        buttonText = varTable[varId] and "On" or "Off"
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
                self.buttonText = varTable[varId] and "On" or "Off"
            else
                self.buttonText = strDisabled
            end
        end,
        postCreate = function(self)
            event.register(updateEventStr, function()
                if this.config.fullyLoaded then
                    -- self:enable()
                    self.buttonText = varTable[varId] and "On" or "Off"
                    enableElement(self)
                else
                    self.buttonText = strDisabled
                    disableElement(self)
                    -- self:disable()
                end
                -- if self.callback then
                --     self:callback()
                -- end
                -- self:update()
            end)
        end,
    }
    return data
end

function this.registerModConfig()
    local minData = {
        name = this.name,
        onClose = (function()
            this.config.save()
        end),
        pages = {
            label = "Global",
                class = "Page",
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
                            end,
                        },
                    },
                },
        }
    }

    local data = {
        name = this.name,
        onClose = (function()
            this.config.save()
        end),
        pages = {
            {
                label = "Main",
                class = "Page",
                postCreate = function(self)
                    event.trigger(updateEventStr)
                end,
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
                                -- this.config.resetConfig()
                                this.config.load()
                                event.trigger(updateEventStr)
                            end,
                        },
                    },
                },
            },
            {
                label = "Items",
                class = "FilterPage",
                postCreate = function(self)
                    event.trigger(updateEventStr)
                end,
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
                    createSettingsBlock_minmaxp(this.config.data.gold, "min", 0, 1000, 1, {label = "Minimum multiplier %s%%",}),
                    createSettingsBlock_minmaxp(this.config.data.gold, "max", 0, 1000, 1, {label = "Maximum multiplier %s%%",}),
                },
            },
            {
                label = "Creatures",
                class = "FilterPage",
                postCreate = function(self)
                    event.trigger(updateEventStr)
                end,
                components = {
                    createOnOffIngameButton("Randomize ceatures", this.config.data.creatures, "randomize"),
                    createSettingsBlock_region(this.config.data.creatures.region, {label = "Region size %s%%", descr = regionDescr}),
                    createSettingsBlock_offset(this.config.data.creatures.region, {label = "Offset %s%%", descr = regionDescr}),

                    createOnOffIngameButton("Randomize items", this.config.data.creatures.items, "randomize"),
                    createSettingsBlock_region(this.config.data.creatures.items.region, {label = "Region size %s%%", descr = regionDescr}),
                    createSettingsBlock_offset(this.config.data.creatures.items.region, {label = "Offset %s%%", descr = regionDescr}),

                    createOnOffIngameButton("Randomize health points", this.config.data.creatures.health, "randomize"),
                    createSettingsBlock_minmaxp(this.config.data.creatures.health, "min", 0, 1000, 1, {label = "Minimum multiplier %s%%",}),
                    createSettingsBlock_minmaxp(this.config.data.creatures.health, "max", 0, 1000, 1, {label = "Maximum multiplier %s%%",}),

                    createOnOffIngameButton("Randomize magicka points", this.config.data.creatures.magicka, "randomize"),
                    createSettingsBlock_minmaxp(this.config.data.creatures.magicka, "min", 0, 1000, 1, {label = "Minimum multiplier %s%%",}),
                    createSettingsBlock_minmaxp(this.config.data.creatures.magicka, "max", 0, 1000, 1, {label = "Maximum multiplier %s%%",}),

                    createOnOffIngameButton("Randomize fatigue points", this.config.data.creatures.fatigue, "randomize"),
                    createSettingsBlock_minmaxp(this.config.data.creatures.fatigue, "min", 0, 1000, 1, {label = "Minimum multiplier %s%%",}),
                    createSettingsBlock_minmaxp(this.config.data.creatures.fatigue, "max", 0, 1000, 1, {label = "Maximum multiplier %s%%",}),

                    createOnOffIngameButton("Randomize attack damage", this.config.data.creatures.attack, "randomize"),
                    createSettingsBlock_minmaxp(this.config.data.creatures.attack, "min", 0, 1000, 1, {label = "Minimum multiplier %s%%",}),
                    createSettingsBlock_minmaxp(this.config.data.creatures.attack, "max", 0, 1000, 1, {label = "Maximum multiplier %s%%",}),

                    createOnOffIngameButton("Randomize the object's scale", this.config.data.creatures.scale, "randomize"),
                    createSettingsBlock_minmaxp(this.config.data.creatures.scale, "min", 10, 1000, 1, {label = "Minimum multiplier %s%%",}),
                    createSettingsBlock_minmaxp(this.config.data.creatures.scale, "max", 10, 1000, 1, {label = "Maximum multiplier %s%%",}),

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
                            createOnOffIngameButton("Randomize creature spells", this.config.data.creatures.spells, "randomize"),
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
                            createOnOffIngameButton("Randomize creature abilities", this.config.data.creatures.abilities, "randomize"),
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
                },
            },
        },
    }

    mwse.registerModConfig(this.name, EasyMCM.registerModData(data))
end

return this