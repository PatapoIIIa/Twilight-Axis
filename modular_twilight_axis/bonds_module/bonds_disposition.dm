// What an act means to the person on the receiving end.
//
// The same blow is not the same experience for everyone. A masochist being struck is not being
// wronged, and building them a grudge out of it is simply wrong: their flaw says they want this.
// The same logic runs the other way - a lonely character values a kind word more than someone
// who is never short of company.
//
// So the recipient's disposition scales what the event does to THEIR side of the bond only.
// The aggressor's own side is untouched: how you feel about hitting someone is your business,
// not theirs.
//
// Scales are per category. A missing entry means 1.0.

/datum/bond_disposition
	abstract_type = /datum/bond_disposition
	var/flaw_type
	/// Assoc of BOND_CATEGORY_* -> multiplier applied to the recipient's side.
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

/// Multiplier for what `event_type` does to `recipient`'s side of the bond.
/// Several dispositions stack multiplicatively; any zero wins outright.
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
