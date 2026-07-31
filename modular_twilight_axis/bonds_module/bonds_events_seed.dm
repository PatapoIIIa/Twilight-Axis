/datum/bond_event/seed
	abstract_type = /datum/bond_event/seed
	category = BOND_CATEGORY_SEED
	timeout = 0
	scored_propagation = FALSE
	var/flavor_key = ""
	var/flavor_label = ""
	var/opposite_type
	var/pickable = TRUE

/datum/bond_event/seed/served_together
	flavor_key = "served"
	flavor_label = "Служили вместе"
	warmth_commit = 22
	weight_commit = 30
	tag_applied = BOND_TAG_SERVED_TOGETHER
	history_label = "Прошлое"

/datum/bond_event/seed/served_together/build_story(datum/social_bond/context)
	return "Мы с [context.display_name()] когда-то тянули лямку бок о бок."

/datum/bond_event/seed/drinking_mates
	flavor_key = "drink"
	flavor_label = "Собутыльники"
	warmth_commit = 28
	weight_commit = 24
	history_label = "Прошлое"

/datum/bond_event/seed/drinking_mates/build_story(datum/social_bond/context)
	return "Мы с [context.display_name()] не раз просыпались под одним столом."

/datum/bond_event/seed/bad_blood
	flavor_key = "badblood"
	flavor_label = "Старая вражда"
	warmth_commit = -30
	weight_commit = 35
	history_label = "Прошлое"

/datum/bond_event/seed/bad_blood/build_story(datum/social_bond/context)
	return "Между мной и [context.display_name()] давно пробежала кошка."

/datum/bond_event/seed/debtor
	flavor_key = "debt"
	flavor_label = "Старый долг"
	warmth_commit = -8
	weight_commit = 30
	tag_applied = BOND_TAG_OWES_DEBT
	history_label = "Прошлое"
	opposite_type = /datum/bond_event/seed/creditor

/datum/bond_event/seed/debtor/build_story(datum/social_bond/context)
	return "Я задолжал [context.display_name()] и всё никак не отдам."

/datum/bond_event/seed/creditor
	flavor_key = "debt"
	flavor_label = "Старый долг"
	warmth_commit = -14
	weight_commit = 34
	history_label = "Прошлое"
	opposite_type = /datum/bond_event/seed/debtor
	pickable = FALSE

/datum/bond_event/seed/creditor/build_story(datum/social_bond/context)
	return "[context.display_name()] мне должен и не спешит рассчитаться."
