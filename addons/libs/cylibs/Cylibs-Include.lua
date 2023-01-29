current_cylibs_include_version = 1

function init_include()
	print('Loaded Cylibs Version: %i':format(current_cylibs_include_version))

	require('cylibs/util/Modes')
	require('cylibs/util/States')

	-- Actions
	ActionQueue = require('cylibs/actions/action_queue')

	SpellAction = require('cylibs/actions/spell')
	WaitAction = require('cylibs/actions/wait')
	RunToAction = require('cylibs/actions/runto')
	RunAwayAction = require('cylibs/actions/runaway')
	RunBehindAction = require('cylibs/actions/runbehind')
	WalkAction = require('cylibs/actions/walk')
	EngageAction = require('cylibs/actions/engage')
	CommandAction = require('cylibs/actions/command')
	BloodPactRageAction = require('cylibs/actions/blood_pact_rage')
	BloodPactWardAction = require('cylibs/actions/blood_pact_ward')
	JobAbilityAction = require('cylibs/actions/job_ability')
	StrategemAction = require('cylibs/actions/strategem')
	WeaponSkillAction = require('cylibs/actions/weapon_skill')
	PullAction = require('cylibs/actions/pull')
	SequenceAction = require('cylibs/actions/sequence')
	BlockAction = require('cylibs/actions/block')

	-- Conditions
	Condition = require('cylibs/conditions/condition')
	InBattleCondition = require('cylibs/conditions/in_battle')
	IdleCondition = require('cylibs/conditions/idle')

	-- Battle
	MobTracker = require('cylibs/battle/mob_tracker')
	MonsterBuffTracker = require('cylibs/battle/monster_buff_tracker')
	Spell = require('cylibs/battle/spell')
	Buff = require('cylibs/battle/spells/buff')
	Debuff = require('cylibs/battle/spells/debuff')
	Roll = require('cylibs/battle/roll')

	-- Roles
	Role = require('cylibs/trust/roles/role')

	-- Util
	action_message_util = require('cylibs/util/action_message_util')
	player_util = require('cylibs/util/player_util')
	pet_util = require('cylibs/util/pet_util')
	buff_util = require('cylibs/util/buff_util')
	spell_util = require('cylibs/util/spell_util')
	geometry_util = require('cylibs/util/geometry_util')
	ffxi_util = require('cylibs/util/ffxi_util')
	battle_util = require('cylibs/util/battle_util')
	party_util = require('cylibs/util/party_util')
	pup_util = require('cylibs/util/pup_util')
	job_util = require('cylibs/util/job_util')
	
	Trust = require('cylibs/trust/trust')
	Monster = require('cylibs/battle/monster')

	-- Entities
	Player = require('cylibs/entity/player')
	PartyMember = require('cylibs/entity/party_member')
end

init_include()


