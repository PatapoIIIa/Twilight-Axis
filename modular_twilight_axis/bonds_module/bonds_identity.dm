/proc/bonds_identity_visible(mob/living/carbon/human/person)
	if(!ishuman(person))
		return FALSE
	if(!person.real_name)
		return FALSE
	return person.get_visible_name() == person.real_name

/proc/bonds_build_snapshot(mob/living/carbon/human/person)
	if(!ishuman(person))
		return null
	var/datum/job/role = person.mind?.assigned_role
	return list(
		"name" = person.real_name,
		"vcolor" = person.voice_color,
		"job" = role ? role.get_informed_title(person) : (person.job || "Unknown"),
		"job_key" = role ? role.title : (person.job || "Unknown"),
		"species" = person.dna?.species?.name || "Unknown",
		"gender" = person.gender,
		"age" = person.age,
	)

/proc/bonds_mind_of(mob/living/carbon/human/person)
	if(!ishuman(person))
		return null
	return person.mind
