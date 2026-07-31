/datum/bond_event/struck_by
	category = BOND_CATEGORY_VIOLENCE
	warmth_transient = -18
	weight_transient = 22
	warmth_commit = -4
	weight_commit = 5
	timeout = 8 MINUTES
	tag_applied = BOND_TAG_SHED_BLOOD
	history_label = "Насилие"

/datum/bond_event/struck_by/build_story(datum/social_bond/context)
	return "[context.display_name()] поднял на меня оружие."

/datum/bond_event/struck_them
	category = BOND_CATEGORY_VIOLENCE
	warmth_transient = -6
	weight_transient = 12
	warmth_commit = -1
	weight_commit = 3
	timeout = 8 MINUTES
	history_label = "Насилие"

/datum/bond_event/struck_them/build_story(datum/social_bond/context)
	return "Я поднял оружие на [context.display_name()]."

/datum/bond_event/beaten_by
	category = BOND_CATEGORY_VIOLENCE
	warmth_transient = -10
	weight_transient = 14
	warmth_commit = -2
	weight_commit = 3
	timeout = 6 MINUTES
	history_label = "Драка"

/datum/bond_event/beaten_by/build_story(datum/social_bond/context)
	return "[context.display_name()] распустил на меня руки."

/datum/bond_event/beat_them
	category = BOND_CATEGORY_VIOLENCE
	warmth_transient = -4
	weight_transient = 8
	warmth_commit = -1
	weight_commit = 2
	timeout = 6 MINUTES
	history_label = "Драка"

/datum/bond_event/beat_them/build_story(datum/social_bond/context)
	return "Я распустил руки на [context.display_name()]."

/datum/bond_event/killed_by
	category = BOND_CATEGORY_DEATH
	warmth_transient = -60
	weight_transient = 70
	warmth_commit = -35
	weight_commit = 45
	timeout = 30 MINUTES
	tag_applied = BOND_TAG_KILLED_ME
	history_label = "Смерть"

/datum/bond_event/killed_by/build_story(datum/social_bond/context)
	return "[context.display_name()] меня убил."

/datum/bond_event/killed_them
	category = BOND_CATEGORY_DEATH
	warmth_transient = -20
	weight_transient = 45
	warmth_commit = -8
	weight_commit = 25
	timeout = 30 MINUTES
	tag_applied = BOND_TAG_KILLED_THEM
	history_label = "Смерть"

/datum/bond_event/killed_them/build_story(datum/social_bond/context)
	return "Я убил [context.display_name()]."
