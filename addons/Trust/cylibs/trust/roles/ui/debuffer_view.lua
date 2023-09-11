local buff_util = require('cylibs/util/buff_util')
local CollectionView = require('cylibs/ui/collection_view/collection_view')
local CollectionViewDataSource = require('cylibs/ui/collection_view/collection_view_data_source')
local Color = require('cylibs/ui/views/color')
local IndexPath = require('cylibs/ui/collection_view/index_path')
local Padding = require('cylibs/ui/style/padding')
local TextCollectionViewCell = require('cylibs/ui/collection_view/cells/text_collection_view_cell')
local TextItem = require('cylibs/ui/collection_view/items/text_item')
local TextStyle = require('cylibs/ui/style/text_style')
local VerticalFlowLayout = require('cylibs/ui/collection_view/layouts/vertical_flow_layout')

local DebufferView = setmetatable({}, {__index = CollectionView })
DebufferView.__index = DebufferView

TextStyle.DebufferView = {
    Text = TextStyle.new(
            Color.clear,
            Color.clear,
            "Arial",
            11,
            Color.white,
            Color.green,
            2,
            0,
            0,
            false
    ),
}

function DebufferView.new(debuffer, battle_target)
    local dataSource = CollectionViewDataSource.new(function(item)
        local cell = TextCollectionViewCell.new(item)
        cell:setItemSize(20)
        return cell
    end)

    local self = setmetatable(CollectionView.new(dataSource, VerticalFlowLayout.new(2, Padding.new(10, 15, 0, 0))), DebufferView)

    local debuffSpells = debuffer:get_debuff_spells()
    if debuffSpells:length() > 0 then
        dataSource:addItem(TextItem.new("Spells", TextStyle.DebufferView.Text), IndexPath.new(1, 1))
        local currentRow = 2
        for spell in debuffSpells:it() do
            local item = TextItem.new('• '..spell:description(), TextStyle.DebufferView.Text)
            local indexPath = IndexPath.new(1, currentRow)
            dataSource:addItem(item, indexPath)
            local debuff = buff_util.debuff_for_spell(spell:get_spell().id)
            if debuff and battle_target and battle_target:has_debuff(debuff.id) then
                self:getDelegate():highlightItemAtIndexPath(item, indexPath)
            end
            currentRow = currentRow + 1
        end
    end

    return self
end

return DebufferView