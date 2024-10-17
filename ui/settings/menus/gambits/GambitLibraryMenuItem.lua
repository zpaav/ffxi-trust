local AssetManager = require('ui/themes/ffxi/FFXIAssetManager')
local ButtonItem = require('cylibs/ui/collection_view/items/button_item')
local ConditionSettingsMenuItem = require('ui/settings/menus/conditions/ConditionSettingsMenuItem')
local ConfigEditor = require('ui/settings/editors/config/ConfigEditor')
local DisposeBag = require('cylibs/events/dispose_bag')
local FFXIClassicStyle = require('ui/themes/FFXI/FFXIClassicStyle')
local FFXIPickerView = require('ui/themes/ffxi/FFXIPickerView')
local Gambit = require('cylibs/gambits/gambit')
local GambitSettingsEditor = require('ui/settings/editors/GambitSettingsEditor')
local GambitTarget = require('cylibs/gambits/gambit_target')
local IndexedItem = require('cylibs/ui/collection_view/indexed_item')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local job_util = require('cylibs/util/job_util')
local MenuItem = require('cylibs/ui/menu/menu_item')
local ModesView = require('ui/settings/editors/config/ModeConfigEditor')
local PickerConfigItem = require('ui/settings/editors/config/PickerConfigItem')

local GambitLibraryMenuItem = setmetatable({}, {__index = MenuItem })
GambitLibraryMenuItem.__index = GambitLibraryMenuItem

function GambitLibraryMenuItem.new(trustSettings, trustSettingsMode, parentMenuItem)
    local gambitCategories = GambitLibraryMenuItem.getGambitCategories()

    local buttonItems = L(gambitCategories:map(function(category)
        return ButtonItem.default(category:getName(), 18)
    end))

    local self = setmetatable(MenuItem.new(buttonItems, {}, nil, "Gambits", "Browse gambits."), GambitLibraryMenuItem)

    for category in gambitCategories:it() do
        self:setChildMenuItem(category:getName(), self:getGambitCategoryMenuItem(category))
    end

    self.trustSettings = trustSettings
    self.trustSettingsMode = trustSettingsMode
    self.disposeBag = DisposeBag.new()

    return self
end

function GambitLibraryMenuItem:destroy()
    MenuItem.destroy(self)

    self.disposeBag:destroy()
end

function GambitLibraryMenuItem.getGambitCategories()
    return require('ui/settings/menus/gambits/library/GambitLibrary')
end

function GambitLibraryMenuItem:getGambitCategoryMenuItem(category)
    return MenuItem.new(L{
        ButtonItem.default('Add', 18),
        --ButtonItem.default('Add All', 18),
    }, {
        Add = self:getAddGambitsMenuItem()
    }, function(_, _)
        local gambitList = FFXIPickerView.withItems(category:getGambits():map(function(gambit) return gambit:tostring() end), L{}, false, nil, nil, FFXIClassicStyle.WindowSize.Editor.ConfigEditorLarge, true)
        gambitList:setAllowsCursorSelection(true)

        gambitList:setNeedsLayout()
        gambitList:layoutIfNeeded()

        self.disposeBag:add(gambitList:getDelegate():didSelectItemAtIndexPath():addAction(function(indexPath)
            self.selectedGambit = category:getGambits()[indexPath.row]
        end), gambitList:getDelegate():didSelectItemAtIndexPath())

        return gambitList
    end, category:getName(), category:getDescription())
end

function GambitLibraryMenuItem:getAddGambitsMenuItem()
    return MenuItem.action(function()
        if self.selectedGambit == nil then
            return
        end

        local currentGambits = self.trustSettings:getSettings()[self.trustSettingsMode.value].GambitSettings.Gambits
        currentGambits:append(self.selectedGambit)

        self.trustSettings:saveSettings(true)

        addon_message(260, '('..windower.ffxi.get_player().name..') '.."Alright, I'll add this gambit to my list!")
    end, "Gambits", "Add the selected gambit from the library.")
end

return GambitLibraryMenuItem