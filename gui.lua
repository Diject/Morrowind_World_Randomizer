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
                    mwse.log("Region %s %s", tostring(varTable.min), tostring(varTable.max))
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
                if self.callback then
                    self:callback()
                end
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
                    -- {
                    --     class = "OnOffButton",
                    --     label = "Enable Randomizer",
                    --     variable = {
                    --         id = "enabled",
                    --         class = "TableVariable",
                    --         table = this.config.data,
                    --         defaultSetting = false,
                    --     },
                    --     postCreate = function(self)
                    --         event.register(updateEventStr, function()
                    --             if this.config.fullyLoaded then
                    --                 -- self:enable()
                    --                 enableElement(self)
                    --             else
                    --                 disableElement(self)
                    --                 -- self:disable()
                    --             end
                    --             -- if self.callback then
                    --             --     self:callback()
                    --             -- end
                    --             -- self:update()
                    --         end)
                    --     end,
                    -- },
                    -- createOnOffIngameButton("Enable Randomizer", this.config.data, "enabled"),
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

                    createOnOffIngameButton("Randomize NPCs items", this.config.data.NPCs.items, "randomize"),
                    createSettingsBlock_region(this.config.data.NPCs.items.region, {label = "Region size %s%%", descr = regionDescr}),
                    createSettingsBlock_offset(this.config.data.NPCs.items.region, {label = "Offset %s%%", descr = regionDescr}),

                    createOnOffIngameButton("Randomize creatures items", this.config.data.creatures.items, "randomize"),
                    createSettingsBlock_region(this.config.data.creatures.items.region, {label = "Region size %s%%", descr = regionDescr}),
                    createSettingsBlock_offset(this.config.data.creatures.items.region, {label = "Offset %s%%", descr = regionDescr}),
                },
            },
        },
    }

    mwse.registerModConfig(this.name, EasyMCM.registerModData(data))
end

return this