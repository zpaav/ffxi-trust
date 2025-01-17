local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local Event = require('cylibs/events/Luvent')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local Gambit = require('cylibs/gambits/gambit')
local GambitEditorStyle = require('ui/settings/menus/gambits/GambitEditorStyle')
local GambitLibraryMenuItem = require('ui/settings/menus/gambits/GambitLibraryMenuItem')
local GambitSettingsEditor = require('ui/settings/editors/GambitSettingsEditor')
local GambitTarget = require('cylibs/gambits/gambit_target')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesMenuItem = require('ui/settings/menus/ModesMenuItem')
local MultiPickerConfigItem = require('ui/settings/editors/config/MultiPickerConfigItem')

local GambitSettingsMenuItem = setmetatable({}, {__index = MenuItem })
GambitSettingsMenuItem.__index = GambitSettingsMenuItem

function GambitSettingsMenuItem:onGambitChanged()
    return self.gambitChanged
end

function GambitSettingsMenuItem.compact(trust, trustSettings, trustSettingsMode, trustModeSettings, settingsKey, abilityTargets, abilitiesForTargets, conditionTargets, modes, abilityCategory, abilityCategoryPlural, libraryCategoryFilter)
    local configItemForGambits = function(gambits)
        local configItem = MultiPickerConfigItem.new("Gambits", L{}, gambits, function(gambit)
            return gambit:getAbility():get_localized_name()
        end, abilityCategoryPlural, nil, function(gambit)
            return AssetManager.imageItemForAbility(gambit:getAbility():get_name())
        end)
        return configItem
    end

    local editorStyle = GambitEditorStyle.new(configItemForGambits, nil, abilityCategory, abilityCategoryPlural)

    local self = GambitSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, settingsKey, abilityTargets, abilitiesForTargets, conditionTargets, editorStyle, modes, libraryCategoryFilter)
    return self
end

function GambitSettingsMenuItem.new(trust, trustSettings, trustSettingsMode, trustModeSettings, settingsKey, abilityTargets, abilitiesForTargets, conditionTargets, editorStyle, modes, libraryCategoryFilter)
    editorStyle = editorStyle or GambitEditorStyle.new(function(gambits)
        local configItem = MultiPickerConfigItem.new("Gambits", L{}, gambits, function(gambit)
            return gambit:tostring()
        end)
        return configItem
    end, FFXIClassicStyle.WindowSize.Editor.ConfigEditorExtraLarge, "Gambit", "Gambits")

    local self = setmetatable(MenuItem.new(L{
        ButtonItem.default('Add', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Remove', 18),
        ButtonItem.default('Move Up', 18),
        ButtonItem.default('Move Down', 18),
        ButtonItem.default('Copy', 18),
        ButtonItem.default('Toggle', 18),
        ButtonItem.default('Reset', 18),
        ButtonItem.localized('Modes', i18n.translate('Button_Modes')),
    }, {}, nil, editorStyle:getDescription(true), "Configure "..editorStyle:getDescription(true)..".", false), GambitSettingsMenuItem)  -- changed keep views to false

    self.trust = trust
    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.trustModeSettings = trustModeSettings
    self.settingsKey = settingsKey
    self.abilityTargets = abilityTargets or S(GambitTarget.TargetType:keyset())
    self.abilitiesForTargets = abilitiesForTargets or function(targets)
        return self:getAbilitiesForTargets(targets)
    end
    self.conditionTargets = conditionTargets or L(Condition.TargetType.AllTargets)
    self.editorConfig = editorStyle
    self.modes = modes or L{ state.AutoGambitMode.value }
    self.libraryCategoryFilter = libraryCategoryFilter
    self.defaultGambitTags = L{}
    self.gambitChanged = Event.newEvent()
    self.disposeBag = DisposeBag.new()

    self.contentViewConstructor = function(_, infoView, _)
        local currentGambits = self:getSettings().Gambits

        local configItem = self.editorConfig:getConfigItem(currentGambits)

        local gambitSettingsEditor = FFXIPickerView.new(L{ configItem }, false, self.editorConfig:getViewSize())
        gambitSettingsEditor:setAllowsCursorSelection(true)

        gambitSettingsEditor:setNeedsLayout()
        gambitSettingsEditor:layoutIfNeeded()

        local itemsToUpdate = L{}
        for rowIndex = 1, gambitSettingsEditor:getDataSource():numberOfItemsInSection(1) do
            local indexPath = IndexPath.new(1, rowIndex)
            local item = gambitSettingsEditor:getDataSource():itemAtIndexPath(indexPath)
            item:setEnabled(currentGambits[rowIndex]:isEnabled() and currentGambits[rowIndex]:isValid())
            itemsToUpdate:append(IndexedItem.new(item, indexPath))
        end

        gambitSettingsEditor:getDataSource():updateItems(itemsToUpdate)

        gambitSettingsEditor:setNeedsLayout()
        gambitSettingsEditor:layoutIfNeeded()

        self.disposeBag:add(gambitSettingsEditor:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            local selectedGambit = currentGambits[indexPath.row]
            self.selectedGambit = selectedGambit

            gambitSettingsEditor.menuArgs['conditions'] = selectedGambit.conditions
            gambitSettingsEditor.menuArgs['targetTypes'] = S{ selectedGambit:getConditionsTarget() }
        end, gambitSettingsEditor:getDelegate():didSelectItemAtIndexPath()))

        self.disposeBag:add(gambitSettingsEditor:getDelegate():didMoveCursorToItemAtIndexPath():addAction(function(indexPath)
            local selectedGambit = currentGambits[indexPath.row]
            if selectedGambit then
                if not selectedGambit:isValid() then
                    infoView:setDescription("Unavailable on current job.")
                else
                    infoView:setDescription(selectedGambit:tostring())
                end
            end
        end), gambitSettingsEditor:getDelegate():didMoveCursorToItemAtIndexPath())

        if currentGambits:length() > 0 then
            gambitSettingsEditor:getDelegate():setCursorIndexPath(IndexPath.new(1, 1))
        end

        self.gambitSettingsEditor = gambitSettingsEditor

        return gambitSettingsEditor
    end

    self:reloadSettings()

    return self
end

function GambitSettingsMenuItem:destroy()
    MenuItem.destroy(self)

    self.gambitChanged:removeAllActions()

    self.disposeBag:destroy()
end

function GambitSettingsMenuItem:getSettings()
    return self.trustSettings:getSettings()[self.trustSettingsMode.value][self.settingsKey]
end

function GambitSettingsMenuItem:getConfigKey()
    return "gambits"
end

function GambitSettingsMenuItem:reloadSettings()
    self:setChildMenuItem("Add", self:getAddAbilityMenuItem())
    self:setChildMenuItem("Edit", self:getEditGambitMenuItem())
    self:setChildMenuItem("Remove", self:getRemoveAbilityMenuItem())
    self:setChildMenuItem("Copy", self:getCopyGambitMenuItem())
    self:setChildMenuItem("Move Up", self:getMoveUpGambitMenuItem())
    self:setChildMenuItem("Move Down", self:getMoveDownGambitMenuItem())
    self:setChildMenuItem("Toggle", self:getToggleMenuItem())
    self:setChildMenuItem("Reset", self:getResetGambitsMenuItem())
    self:setChildMenuItem("Modes", self:getModesMenuItem())
end

function GambitSettingsMenuItem:getAbilitiesForTargets(targets)
    return self.editorConfig:getAbilitiesForTargets(targets, self.trust)
end

---
-- Gets a list of abilities for a gambit target.
--
-- @tparam GambitTarget.TargetType gambitTarget Gambit target
-- @tparam boolean flatten If true, return as a single list
--
-- @treturn list List of abilities
--
function GambitSettingsMenuItem:getAbilities(gambitTarget, flatten)
    local gambitTargetMap = T{
        [GambitTarget.TargetType.Self] = S{'Self'},
        [GambitTarget.TargetType.Ally] = S{'Party', 'Corpse'},
        [GambitTarget.TargetType.Enemy] = S{'Enemy'}
    }
    local targets = gambitTargetMap[gambitTarget]

    local sections = self.abilitiesForTargets(targets)
    if flatten then
        sections = sections:flatten(false)
    end
    return sections
end

function GambitSettingsMenuItem:getAbilitiesByTargetType()
    local abilitiesByTargetType = T{}
    for abilityTarget in L(GambitTarget.TargetType:keyset()):it() do
        if self.abilityTargets:contains(abilityTarget) then
            abilitiesByTargetType[abilityTarget] = self:getAbilities(abilityTarget, true):compact_map()
        else
            abilitiesByTargetType[abilityTarget] = L{}
        end
    end
    return abilitiesByTargetType
end

function GambitSettingsMenuItem:getAddAbilityMenuItem()
    local newAbilityMenuItem = function(targetType)
        local blankGambitMenuItem = MenuItem.new(L{
            ButtonItem.localized('Confirm', i18n.translate('Button_Confirm')),
        }, {}, function(_, _, showMenu)
            local abilitiesByTargetType = self:getAbilitiesByTargetType()

            local abilityPickerItem = MultiPickerConfigItem.new('abilities', L{}, abilitiesByTargetType[targetType], function(ability)
                return ability:get_localized_name()
            end, "Choose an ability.", nil, function(ability)
                return AssetManager.imageItemForAbility(ability:get_name())
            end)

            local abilityPickerView = FFXIPickerView.withConfig(abilityPickerItem)

            abilityPickerView:getDisposeBag():add(abilityPickerView:on_pick_items():addAction(function(_, selectedItems)
                if selectedItems:length() > 0 then
                    local newGambit = Gambit.new(targetType, L{}, selectedItems[1], targetType, self.defaultGambitTags)

                    local currentGambits = self:getSettings().Gambits
                    currentGambits:append(newGambit)

                    self.trustSettings:saveSettings(true)

                    showMenu(self)

                    self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(IndexPath.new(1, currentGambits:length()))
                end
            end), abilityPickerView:on_pick_items())

            return abilityPickerView
        end, self:getTitleText(), "Add a new "..targetType.." "..self.editorConfig:getDescription()..".")
        return blankGambitMenuItem
    end

    local abilityTargetButtonItems = L(self.abilityTargets):map(function(targetType)
        return ButtonItem.localized(targetType, i18n.translate('AbilityTarget_'..targetType))
    end)

    local abilityTargetMenuItem = MenuItem.new(abilityTargetButtonItems, {}, nil, self:getTitleText(), "Add a new "..self.editorConfig:getDescription()..".")

    for targetType in L(self.abilityTargets):it() do
        abilityTargetMenuItem:setChildMenuItem(targetType, newAbilityMenuItem(targetType))
    end

    local addGambitMenuItem = MenuItem.new(L{
        ButtonItem.default('New', 18),
        ButtonItem.default('Browse', 18),
    }, {
        New = abilityTargetMenuItem,
        Browse = self:getGambitLibraryMenuItem()
    }, nil, self:getTitleText(), "Add a new "..self.editorConfig:getDescription()..".")

    return addGambitMenuItem
end

function GambitSettingsMenuItem:getEditGambitMenuItem()
    local editGambitMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm', 18),
        ButtonItem.default('Edit', 18),
        ButtonItem.default('Conditions', 18),
    }, {}, function(_, _, _)
        local abilitiesByTargetType = self:getAbilitiesByTargetType()

        local gambitEditor = GambitSettingsEditor.new(self.selectedGambit, self.trustSettings, self.trustSettingsMode, abilitiesByTargetType, self.conditionTargets)

        self.disposeBag:add(gambitEditor:onConfigChanged():addAction(function(newSettings, oldSettings)
            self:onGambitChanged():trigger(newSettings, oldSettings)
            gambitEditor:reloadSettings()
        end), gambitEditor:onConfigChanged())

        return gambitEditor
    end, self:getTitleText(), "Edit the selected "..self.editorConfig:getDescription()..".", false, function()
        return self.selectedGambit ~= nil
    end)

    local editAbilityMenuItem = MenuItem.new(L{
        ButtonItem.default('Confirm'),
    }, {
        Confirm = MenuItem.action(function(parent)
            parent:showMenu(editGambitMenuItem)
        end, self:getTitleText(), "Edit ability.")
    }, function(_, infoView, showMenu)
        local configItems = L{}
        if self.selectedGambit:getAbility().get_config_items then
            configItems = self.selectedGambit:getAbility():get_config_items(self.trust) or L{}
        end
        if not configItems:empty() then
            local editAbilityEditor = ConfigEditor.new(nil, self.selectedGambit:getAbility(), configItems, infoView, nil, showMenu)

            self.disposeBag:add(editAbilityEditor:onConfigChanged():addAction(function(newSettings, oldSettings)
                if self.selectedGambit:getAbility().on_config_changed then
                    self.selectedGambit:getAbility():on_config_changed(oldSettings)
                end
            end), editAbilityEditor:onConfigChanged())

            return editAbilityEditor
        end
        return nil
    end, self:getTitleText(), "Edit ability.", false, function()
        return self.selectedGambit ~= nil and self.selectedGambit:getAbility().get_config_items and self.selectedGambit:getAbility():get_config_items():length() > 0
    end)

    editGambitMenuItem:setChildMenuItem("Edit", editAbilityMenuItem)
    editGambitMenuItem:setChildMenuItem("Conditions", ConditionSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode))

    return editGambitMenuItem
end

function GambitSettingsMenuItem:getRemoveAbilityMenuItem()
    return MenuItem.action(function()
        local selectedIndexPath = self.gambitSettingsEditor:getDelegate():getCursorIndexPath()
        if selectedIndexPath then
            local item = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
            if item then
                local indexPath = selectedIndexPath
                local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value][self.settingsKey].Gambits
                currentGambits:remove(indexPath.row)

                self.gambitSettingsEditor:getDataSource():removeItem(indexPath)

                self.selectedGambit = nil
                self.trustSettings:saveSettings(true)

                if self.gambitSettingsEditor:getDataSource():numberOfItemsInSection(1) > 0 then
                    self.selectedGambit = currentGambits[1]
                    self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(IndexPath.new(1, 1))
                end
            end
        end
    end, self:getTitleText(), "Remove the selected "..self.editorConfig:getDescription()..".")
end

function GambitSettingsMenuItem:getCopyGambitMenuItem()
    local copyGambitMenuItem =  MenuItem.action(function(menu)
        if self.selectedGambit then
            local newGambit = self.selectedGambit:copy()

            local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value][self.settingsKey].Gambits
            currentGambits:append(newGambit)

            self.trustSettings:saveSettings(true)

            menu:showMenu(self)
        end
    end, self:getTitleText(), "Copy the selected "..self.editorConfig:getDescription()..".")

    copyGambitMenuItem.enabled = function()
        return self.selectedGambit ~= nil
    end

    return copyGambitMenuItem
end

function GambitSettingsMenuItem:getToggleMenuItem()
    local toggleMenuItem = MenuItem.action(function(_)
        local selectedIndexPath = self.gambitSettingsEditor:getDelegate():getCursorIndexPath()
        if selectedIndexPath then
            local item = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
            if item then
                item:setEnabled(not item:getEnabled())
                self.gambitSettingsEditor:getDataSource():updateItem(item, selectedIndexPath)

                local currentGambits = self:getSettings().Gambits
                currentGambits[selectedIndexPath.row]:setEnabled(not currentGambits[selectedIndexPath.row]:isEnabled())
            end
        end
    end, self:getTitleText(), "Temporarily enable or disable the selected "..self.editorConfig:getDescription().." until the addon reloads.")

    toggleMenuItem.enabled = function()
        if self.selectedGambit then
            return self.selectedGambit:isValid()
        end
        return true
    end

    return toggleMenuItem
end

function GambitSettingsMenuItem:getMoveUpGambitMenuItem()
    return MenuItem.action(function(menu)
        local currentGambits = self:getSettings().Gambits

        local selectedIndexPath = self.gambitSettingsEditor:getDelegate():getCursorIndexPath()
        if selectedIndexPath and selectedIndexPath.row > 1 then

            local newIndexPath = self.gambitSettingsEditor:getDataSource():getPreviousIndexPath(selectedIndexPath)
            local item1 = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
            local item2 = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(newIndexPath)
            if item1 and item2 then
                self.gambitSettingsEditor:getDataSource():swapItems(IndexedItem.new(item1, selectedIndexPath), IndexedItem.new(item2, newIndexPath))
                self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(newIndexPath)

                local temp = currentGambits[selectedIndexPath.row - 1]
                currentGambits[selectedIndexPath.row - 1] = currentGambits[selectedIndexPath.row]
                currentGambits[selectedIndexPath.row] = temp

                self.trustSettings:saveSettings(true)

                self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(IndexPath.new(selectedIndexPath.section, selectedIndexPath.row - 1))
            end
        end
    end, self:getTitleText(), "Move the selected "..self.editorConfig:getDescription().." up. "..self.editorConfig:getDescription(true).." get evaluated in order.")
end

function GambitSettingsMenuItem:getMoveDownGambitMenuItem()
    return MenuItem.action(function(_)
        local currentGambits = self:getSettings().Gambits

        local selectedIndexPath = self.gambitSettingsEditor:getDelegate():getCursorIndexPath()
        if selectedIndexPath and selectedIndexPath.row < currentGambits:length() then
            local newIndexPath = self.gambitSettingsEditor:getDataSource():getNextIndexPath(selectedIndexPath)-- IndexPath.new(indexPath.section, indexPath.row + 1)
            local item1 = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(selectedIndexPath)
            local item2 = self.gambitSettingsEditor:getDataSource():itemAtIndexPath(newIndexPath)
            if item1 and item2 then
                self.gambitSettingsEditor:getDataSource():swapItems(IndexedItem.new(item1, selectedIndexPath), IndexedItem.new(item2, newIndexPath))
                self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(newIndexPath)

                local temp = currentGambits[selectedIndexPath.row + 1]
                currentGambits[selectedIndexPath.row + 1] = currentGambits[selectedIndexPath.row]
                currentGambits[selectedIndexPath.row] = temp

                self.trustSettings:saveSettings(true)

                self.gambitSettingsEditor:getDelegate():selectItemAtIndexPath(IndexPath.new(selectedIndexPath.section, selectedIndexPath.row + 1))
            end
        end
    end, self:getTitleText(), "Move the selected "..self.editorConfig:getDescription().." down. "..self.editorConfig:getDescription(true).." get evaluated in order.")
end

function GambitSettingsMenuItem:getEditConditionsMenuItem()
    return ConditionSettingsMenuItem.new(self.trustSettings, self.trustSettingsMode, self)
end

function GambitSettingsMenuItem:getResetGambitsMenuItem()
    return MenuItem.action(function(menu)
        local defaultGambitSettings = self.trustSettings:getDefaultSettings().Default[self.settingsKey]
        if defaultGambitSettings and defaultGambitSettings.Gambits then
            local currentGambitSettings = self:getSettings()
            currentGambitSettings.Gambits:clear()
            for gambit in defaultGambitSettings.Gambits:it() do
                currentGambitSettings.Gambits:append(gambit:copy())
            end

            self.trustSettings:saveSettings(true)

            addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I've reset my "..self.editorConfig:getDescription(true).." to their factory settings!")

            menu:showMenu(self)
        end
    end, self:getTitleText(), "Reset to default "..self.editorConfig:getDescription(true)..".")
end

function GambitSettingsMenuItem:getGambitLibraryMenuItem()
    return GambitLibraryMenuItem.new(self.trustSettings, self.trustSettingsMode, self.libraryCategoryFilter)
end

function GambitSettingsMenuItem:getModesMenuItem()
    return ModesMenuItem.new(self.trustModeSettings, "Set modes for "..self.editorConfig:getDescription(true)..".", self.modes)
end

function GambitSettingsMenuItem:setDefaultGambitTags(tags)
    self.defaultGambitTags = tags
end

function GambitSettingsMenuItem:getDisposeBag()
    return self.disposeBag
end

return GambitSettingsMenuItem