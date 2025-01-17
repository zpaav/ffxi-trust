local Trust = require('cylibs/trust/trust')
local ScholarTrust = setmetatable({}, {__index = Trust })
ScholarTrust.__index = ScholarTrust

local Scholar = require('cylibs/entity/jobs/SCH')

local Buffer = require('cylibs/trust/roles/buffer')
local Debuffer = require('cylibs/trust/roles/debuffer')
local Dispeler = require('cylibs/trust/roles/dispeler')
local DisposeBag = require('cylibs/events/dispose_bag')
local Healer = require('cylibs/trust/roles/healer')
local MagicBurster = require('cylibs/trust/roles/magic_burster')
local ManaRestorer = require('cylibs/trust/roles/mana_restorer')
local Nuker = require('cylibs/trust/roles/nuker')
local Puller = require('cylibs/trust/roles/puller')
local StatusRemover = require('cylibs/trust/roles/status_remover')

state.AutoArtsMode = M{['description'] = 'Auto Arts Mode', 'Off', 'LightArts', 'DarkArts'}

function ScholarTrust.new(settings, action_queue, battle_settings, trust_settings)
    local self = setmetatable(Trust.new(action_queue, S{
        Buffer.new(action_queue, L{}, L{}),
        Debuffer.new(action_queue, trust_settings.DebuffSettings),
    }, trust_settings, Scholar.new(trust_settings)), ScholarTrust)

    self.settings = settings
    self.battle_settings = battle_settings
    self.action_queue = action_queue
    self.current_arts_mode = 'Off'
    self.arts_roles = S{}
    self.dispose_bag = DisposeBag.new()

    return self
end

function ScholarTrust:destroy()
    Role.destroy(self)

    self.dispose_bag:destroy()
end

function ScholarTrust:on_init()
    Trust.on_init(self)

    self:on_trust_settings_changed():addAction(function(_, new_trust_settings)
        self:get_job():set_trust_settings(new_trust_settings)

        local puller = self:role_with_type("puller")
        if puller then
            puller:set_pull_settings(new_trust_settings.PullSettings)
        end

        local buffer = self:role_with_type("buffer")
        if buffer then
            if self.current_arts_mode == 'LightArts' then
                buffer:set_self_buffs(self:get_job():get_light_arts_self_buffs())
                buffer:set_party_buffs(self:get_job():get_light_arts_party_buffs())
            elseif self.current_arts_mode == 'DarkArts' then
                buffer:set_self_buffs(self:get_job():get_dark_arts_self_buffs())
                buffer:set_party_buffs(self:get_job():get_dark_arts_party_buffs())
            else
                buffer:set_self_buffs(L{})
                buffer:set_party_buffs(L{})
            end
        end

        local debuffer = self:role_with_type("debuffer")
        debuffer:set_debuff_settings(new_trust_settings.DebuffSettings)

        local nuker_roles = self:roles_with_types(L{ "nuker", "magicburster" })
        for role in nuker_roles:it() do
            role:set_nuke_settings(new_trust_settings.NukeSettings)
        end
    end)

    if self:get_job():is_light_arts_active() then
        self:switch_arts('LightArts')
    elseif self:get_job():is_dark_arts_active() then
        self:switch_arts('DarkArts')
    end

    self.dispose_bag:add(self:get_party():get_player():on_gain_buff():addAction(function(_, buff_id)
        local buff_name = buff_util.buff_name(buff_id)
        if L{'Light Arts', 'Addendum: White'}:contains(buff_name) then
            self:switch_arts('LightArts')
        elseif L{'Dark Arts', 'Addendum: Black'}:contains(buff_name) then
            self:switch_arts('DarkArts')
        end
    end, self:get_party():get_player():on_gain_buff()))

    coroutine.schedule(function()
        if not (self:get_job():is_light_arts_active() or self:get_job():is_dark_arts_active()) then
            addon_system_error("Scholar settings are currently restricted until Light Arts or Dark Arts is activated.")
        end
    end, 0.1)
end

function ScholarTrust:tic(old_time, new_time)
    Trust.tic(self, old_time, new_time)

    self:check_gambits(self.gambits)
end

function ScholarTrust:switch_arts(new_arts_mode)
    if self.current_arts_mode == new_arts_mode then
        return
    end
    logger.notice("Switching to", new_arts_mode, "from", self.current_arts_mode, "AutoArtsMode: ", state.AutoArtsMode.value)

    self.current_arts_mode = new_arts_mode

    self:update_for_arts(self.current_arts_mode)

    if hud then
        hud:reloadMainMenuItem()
    end
end

function ScholarTrust:update_for_arts(new_arts_mode)
    for role in self.arts_roles:it() do
        self:remove_role(role)
    end
    self.arts_roles = S{}

    if new_arts_mode == 'LightArts' then
        self.arts_roles = S{
            Buffer.new(self.action_queue, self:get_job():get_light_arts_self_buffs(), self:get_job():get_light_arts_party_buffs()),
            Debuffer.new(self.action_queue, self:get_trust_settings().DebuffSettings),
            Healer.new(self.action_queue, self:get_job()),
            ManaRestorer.new(self.action_queue, L{'Myrkr', 'Spirit Taker'}, L{}, 40),
            Puller.new(self.action_queue, self:get_trust_settings().PullSettings.Targets, self:get_trust_settings().PullSettings.Abilities or L{ Spell.new('Stone') }:compact_map()),
            StatusRemover.new(self.action_queue, self:get_job()),
        }
    elseif new_arts_mode == 'DarkArts' then
        self.arts_roles = S{
            Buffer.new(self.action_queue, self:get_job():get_dark_arts_self_buffs(), self:get_job():get_dark_arts_party_buffs()),
            Debuffer.new(self.action_queue, self:get_trust_settings().DebuffSettings),
            Dispeler.new(self.action_queue, L{ Spell.new('Dispel', L{'Addendum: Black'}) }, L{}, true),
            MagicBurster.new(self.action_queue, self:get_trust_settings().NukeSettings, 0.8, L{ 'Ebullience' }, self:get_job()),
            ManaRestorer.new(self.action_queue, L{'Myrkr', 'Spirit Taker'}, L{}, 40),
            Nuker.new(self.action_queue, self:get_trust_settings().NukeSettings, 0.8, L{}, self:get_job()),
            Puller.new(self.action_queue, self:get_trust_settings().PullSettings.Targets, self:get_trust_settings().PullSettings.Abilities or L{ Spell.new('Stone') }:compact_map()),
        }
    end

    for role in self.arts_roles:it() do
        self:add_role(role)
    end
end

return ScholarTrust