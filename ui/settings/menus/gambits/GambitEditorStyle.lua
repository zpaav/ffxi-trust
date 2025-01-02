local GambitEditorStyle = {}
GambitEditorStyle.__index = GambitEditorStyle

function GambitEditorStyle.new(configItemForGambits, viewSize, abilityCategory, abilityCategoryPlural)
    local self = setmetatable({}, GambitEditorStyle)
    self.configItemForGambits = configItemForGambits
    self.viewSize = viewSize
    self.abilityCategory = abilityCategory or "Gambit"
    self.abilityCategoryPlural = abilityCategoryPlural or "Gambits"
    return self
end

function GambitEditorStyle:getConfigItem(gambits)
    return self.configItemForGambits(gambits)
end

function GambitEditorStyle:getViewSize()
    return self.viewSize
end

function GambitEditorStyle:getDescription(plural, lower)
    local description
    if plural then
        description = self.abilityCategoryPlural
    else
        description = self.abilityCategory
    end
    if lower then
        description = description:lower()
    end
    return description
end

function GambitEditorStyle:getAbilitiesForTargets(targets, trust)
    local sections = L{
        trust:get_job():get_spells(function(spellId)
            local spell = res.spells[spellId]
            if spell then
                local spellTargets = L(spell.targets)
                if spell.type == 'Geomancy' and spellTargets:length() == 1 and spellTargets[1] == 'Self' then
                    spellTargets:append('Party')
                end
                return not S{ 'Trust', 'BardSong' }:contains(spell.type) and S(spellTargets):intersection(targets):length() > 0
            end
            return false
        end):map(function(spellId)
            return Spell.new(res.spells[spellId].en)
        end),
        L(player_util.get_job_abilities()):filter(function(jobAbilityId)
            local jobAbility = res.job_abilities[jobAbilityId]
            return S(jobAbility.targets):intersection(targets):length() > 0
        end):map(function(jobAbilityId)
            return JobAbility.new(res.job_abilities[jobAbilityId].en)
        end),
        L(windower.ffxi.get_abilities().weapon_skills):filter(function(weaponSkillId)
            local weaponSkill = res.weapon_skills[weaponSkillId]
            return S(weaponSkill.targets):intersection(targets):length() > 0
        end):map(function(weaponSkillId)
            return WeaponSkill.new(res.weapon_skills[weaponSkillId].en)
        end),
        L{ Approach.new(), RangedAttack.new(), TurnAround.new(), TurnToFace.new(), RunAway.new(), RunTo.new(), Engage.new() }:filter(function(_)
            return targets:contains('Enemy')
        end),
        L{ UseItem.new(), Command.new() }:filter(function(_)
            return targets:contains('Self')
        end),
    }
    return sections
end

return GambitEditorStyle