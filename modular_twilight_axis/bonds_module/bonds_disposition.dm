/datum/bond_disposition
	abstract_type = /datum/bond_disposition
	var/flaw_type
	var/list/category_scales

/datum/bond_disposition/proc/applies_to(mob/living/carbon/human/person)
	if(!flaw_type || !ishuman(person))
		return FALSE
	return person.has_flaw(flaw_type)

/datum/bond_disposition/masochist
	flaw_type = /datum/charflaw/addiction/masochist
	category_scales = list(
		BOND_CATEGORY_VIOLENCE = 0,
	)

/datum/bond_disposition/paranoid
	flaw_type = /datum/charflaw/paranoid
	category_scales = list(
		BOND_CATEGORY_VIOLENCE = 1.5,
		BOND_CATEGORY_KINDNESS = 0.5,
	)

/datum/bond_disposition/lonely
	flaw_type = /datum/charflaw/lonely
	category_scales = list(
		BOND_CATEGORY_KINDNESS = 1.5,
	)

/datum/bond_disposition/clingy
	flaw_type = /datum/charflaw/clingy
	category_scales = list(
		BOND_CATEGORY_KINDNESS = 1.5,
	)

/datum/controller/subsystem/bonds/proc/build_dispositions()
	dispositions = list()
	for(var/datum/bond_disposition/disposition_type as anything in typesof(/datum/bond_disposition))
		if(IS_ABSTRACT(disposition_type))
			continue
		dispositions += new disposition_type()
	bondlog("dispositions built: [dispositions.len]", BONDLOG_INFO)

/datum/controller/subsystem/bonds/proc/disposition_scale(mob/living/carbon/human/recipient, event_type)
	if(!ishuman(recipient))
		return 1
	var/datum/bond_event/prototype = get_event_prototype(event_type)
	if(!prototype)
		return 1
	var/scale = 1
	for(var/datum/bond_disposition/disposition as anything in dispositions)
		if(!disposition.applies_to(recipient))
			continue
		var/category_scale = disposition.category_scales?[prototype.category]
		if(isnull(category_scale))
			continue
		if(!category_scale)
			return 0
		scale *= category_scale
	return scale
