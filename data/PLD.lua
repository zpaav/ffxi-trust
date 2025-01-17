-- Settings file for PLD
return {
    Version = 2,
    Default = {
        SelfBuffs = L{
            Spell.new("Phalanx", L{}, nil, nil, L{}),
            Spell.new("Crusade", L{}, nil, nil, L{}),
            Spell.new("Reprisal", L{}, nil, nil, L{}),
            Spell.new("Protect V", L{}, nil, nil, L{}),
            JobAbility.new('Majesty', L{InBattleCondition.new()}),
            JobAbility.new('Rampart', L{InBattleCondition.new()}),
        },
        CureSettings = {
            Thresholds = {
                ["Cure IV"] = 1000,
                Emergency = 25,
                Default = 78,
                ["Cure II"] = 0,
                ["Cure III"] = 400
            },
            Delay = 2,
            StatusRemovals = {
                Blacklist = L{

                }
            },
            MinNumAOETargets = 3
        },
        PartyBuffs = L{

        },
        NukeSettings = {
            Delay = 10,
            MinManaPointsPercent = 60,
            MinNumMobsToCleave = 2,
            GearswapCommand = "gs c set MagicBurstMode Single",
            Spells = L{
                Spell.new('Holy II'),
                Spell.new('Holy'),
                Spell.new('Banish II'),
            },
            JobAbilities = L{

            },
            Blacklist = L{

            },
        },
        DebuffSettings = {
            Gambits = L{
            }
        },
        PullSettings = {
            Abilities = L{
                Spell.new("Flash", L{}, L{}),
                Spell.new("Banish", L{}, L{})
            },
            Targets = L{
                "Locus Ghost Crab",
                "Locus Dire Bat",
                "Locus Armet Beetle",
            },
            Distance = 20
        },
        TargetSettings = {
            Retry = true
        },
        GambitSettings = {
            Gambits = L{
                Gambit.new("Ally", L{MaxHitPointsPercentCondition.new(80), InBattleCondition.new()}, JobAbility.new("Cover", L{}, L{}), "Ally", L{}),
                Gambit.new("Enemy", L{InBattleCondition.new()}, JobAbility.new("Shield Bash", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{MinTacticalPointsCondition.new(2000), MaxManaPointsPercentCondition.new(30)}, JobAbility.new("Chivalry", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{MaxHitPointsPercentCondition.new(25), InBattleCondition.new()}, JobAbility.new("Sentinel", L{}, L{}), "Self", L{}),
                Gambit.new("Self", L{NotCondition.new(L{HasBuffCondition.new("Food")}), ModeCondition.new("AutoFoodMode", "Auto"), MainJobCondition.new("PLD")}, UseItem.new("Miso Ramen", L{ItemCountCondition.new("Miso Ramen", 1, ">=")}), "Self", L{"food"})
            }
        },
        GearSwapSettings = {
            Enabled = true
        },
    }
}