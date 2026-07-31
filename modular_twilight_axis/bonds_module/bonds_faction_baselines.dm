/datum/faction_baseline
	abstract_type = /datum/faction_baseline
	var/faction_a = ""
	var/faction_b = ""
	var/warmth = 0
	var/weight = 0

/datum/faction_baseline/noble_court
	faction_a = BOND_FACTION_NOBLE
	faction_b = BOND_FACTION_COURT
	warmth = 45
	weight = 60

/datum/faction_baseline/noble_retinue
	faction_a = BOND_FACTION_NOBLE
	faction_b = BOND_FACTION_RETINUE
	warmth = 40
	weight = 55

/datum/faction_baseline/noble_peasant
	faction_a = BOND_FACTION_NOBLE
	faction_b = BOND_FACTION_PEASANT
	warmth = -20
	weight = 35

/datum/faction_baseline/retinue_garrison
	faction_a = BOND_FACTION_RETINUE
	faction_b = BOND_FACTION_GARRISON
	warmth = 30
	weight = 45

/datum/faction_baseline/garrison_citywatch
	faction_a = BOND_FACTION_GARRISON
	faction_b = BOND_FACTION_CITYWATCH
	warmth = -15
	weight = 50

/datum/faction_baseline/church_inquisition
	faction_a = BOND_FACTION_CHURCH
	faction_b = BOND_FACTION_INQUISITION
	warmth = -30
	weight = 70

/datum/faction_baseline/burgher_atc
	faction_a = BOND_FACTION_BURGHER
	faction_b = BOND_FACTION_ATC
	warmth = -20
	weight = 55

/datum/faction_baseline/burgher_peasant
	faction_a = BOND_FACTION_BURGHER
	faction_b = BOND_FACTION_PEASANT
	warmth = 15
	weight = 40

/datum/faction_baseline/church_peasant
	faction_a = BOND_FACTION_CHURCH
	faction_b = BOND_FACTION_PEASANT
	warmth = 25
	weight = 45

/datum/faction_baseline/garrison_outlaw
	faction_a = BOND_FACTION_GARRISON
	faction_b = BOND_FACTION_OUTLAW
	warmth = -70
	weight = 80

/datum/faction_baseline/citywatch_outlaw
	faction_a = BOND_FACTION_CITYWATCH
	faction_b = BOND_FACTION_OUTLAW
	warmth = -70
	weight = 80

/datum/faction_baseline/inquisition_outlaw
	faction_a = BOND_FACTION_INQUISITION
	faction_b = BOND_FACTION_OUTLAW
	warmth = -80
	weight = 75

/datum/faction_baseline/sidefolk_outlaw
	faction_a = BOND_FACTION_SIDEFOLK
	faction_b = BOND_FACTION_OUTLAW
	warmth = 20
	weight = 35

/datum/faction_baseline/sidefolk_citywatch
	faction_a = BOND_FACTION_SIDEFOLK
	faction_b = BOND_FACTION_CITYWATCH
	warmth = -30
	weight = 45

/datum/faction_baseline/wanderer_sidefolk
	faction_a = BOND_FACTION_WANDERER
	faction_b = BOND_FACTION_SIDEFOLK
	warmth = 20
	weight = 30
