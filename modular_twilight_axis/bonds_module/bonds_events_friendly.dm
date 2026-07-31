/datum/bond_event/embraced_by
	category = BOND_CATEGORY_KINDNESS
	warmth_transient = 14
	weight_transient = 12
	warmth_commit = 4
	weight_commit = 3
	timeout = 10 MINUTES
	tag_applied = BOND_TAG_COMFORTED
	history_label = "Тепло"

/datum/bond_event/embraced_by/build_story(datum/social_bond/context)
	return "[context.display_name()] меня обнял."

/datum/bond_event/embraced_them
	category = BOND_CATEGORY_KINDNESS
	warmth_transient = 10
	weight_transient = 10
	warmth_commit = 3
	weight_commit = 3
	timeout = 10 MINUTES
	history_label = "Тепло"

/datum/bond_event/embraced_them/build_story(datum/social_bond/context)
	return "Я обнял [context.display_name()]."
