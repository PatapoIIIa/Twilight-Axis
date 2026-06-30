#define SUICIDE_MODE_TRAIT "suicide_mode"
#define SUICIDE_MODE_DUST_SOURCE "suicide_mode_elemental_death"

#define SUICIDE_MAGIC_GENERIC 0
#define SUICIDE_MAGIC_FIRE 1
#define SUICIDE_MAGIC_ICE 2
#define SUICIDE_MAGIC_LIGHTNING 3

/datum/status_effect/freon/suicide
	duration = 10 MINUTES
	can_melt = FALSE

/mob/living/carbon/human/verb/toggle_suicide_mode()
	set name = "Toggle Suicide Mode"
	set category = "IC"
	set desc = "Arm or disarm a mode that makes the next deliberate self-harming action critically injure you."

	if(HAS_TRAIT(src, SUICIDE_MODE_TRAIT))
		RemoveElement(/datum/element/suicide_mode)
		to_chat(src, span_notice("I step back from the brink. Suicide mode is disabled."))
		return

	if(!canSuicide())
		return

	var/old_key = ckey
	var/confirmation = alert(src, "Your next deliberate self-harming action will cause catastrophic injuries. Continue?", "Enable Suicide Mode", "Yes", "No")
	if(ckey != old_key || confirmation != "Yes" || !canSuicide())
		return

	AddElement(/datum/element/suicide_mode)
	to_chat(src, span_userdanger("Suicide mode is armed. My next deliberate self-harming action will be catastrophic."))

/datum/element/suicide_mode
	element_flags = ELEMENT_DETACH

/datum/element/suicide_mode/Attach(datum/target)
	. = ..()
	if(!ishuman(target))
		return ELEMENT_INCOMPATIBLE

	var/mob/living/carbon/human/human_target = target
	ADD_TRAIT(human_target, SUICIDE_MODE_TRAIT, type)
	RegisterSignal(human_target, COMSIG_MOVABLE_MOVED, PROC_REF(on_moved))
	RegisterSignal(human_target, COMSIG_ITEM_ATTACKED_SUCCESS, PROC_REF(on_item_attack))
	RegisterSignal(human_target, COMSIG_ATOM_BULLET_ACT, PROC_REF(on_projectile_hit))
	RegisterSignal(human_target, COMSIG_MOB_CAST_SPELL, PROC_REF(on_modern_spell_cast))
	RegisterSignal(human_target, COMSIG_MOB_LEGACY_SPELL_CAST, PROC_REF(on_legacy_spell_cast))

/datum/element/suicide_mode/Detach(mob/living/carbon/human/source, ...)
	REMOVE_TRAIT(source, SUICIDE_MODE_TRAIT, type)
	UnregisterSignal(source, list(
		COMSIG_MOVABLE_MOVED,
		COMSIG_ITEM_ATTACKED_SUCCESS,
		COMSIG_ATOM_BULLET_ACT,
		COMSIG_MOB_CAST_SPELL,
		COMSIG_MOB_LEGACY_SPELL_CAST,
	))
	return ..()

/datum/element/suicide_mode/proc/on_moved(mob/living/carbon/human/source, atom/old_location, direction, forced)
	SIGNAL_HANDLER

	var/turf/old_turf = get_turf(old_location)
	var/turf/new_turf = get_turf(source)
	var/fell_down = source.is_jumping && old_turf && new_turf && new_turf.z < old_turf.z

	if(istype(new_turf, /turf/open/lava/acid) && (fell_down || forced))
		if(!consume_mode(source, "entering acid"))
			return
		addtimer(CALLBACK(src, PROC_REF(apply_acid_death), WEAKREF(source)), world.tick_lag)
		return

	if(islava(new_turf) && (fell_down || forced))
		if(!consume_mode(source, "entering lava"))
			return
		addtimer(CALLBACK(src, PROC_REF(apply_lava_death), WEAKREF(source)), world.tick_lag)
		return

	if(fell_down && istype(new_turf, /turf/open/water))
		if(!consume_mode(source, "falling into water"))
			return
		addtimer(CALLBACK(src, PROC_REF(apply_water_death), WEAKREF(source)), world.tick_lag)
		return

	if(!fell_down)
		return
	if(!consume_mode(source, "jumping from a height"))
		return
	addtimer(CALLBACK(src, PROC_REF(apply_fall_trauma), WEAKREF(source)), world.tick_lag)

/datum/element/suicide_mode/proc/on_item_attack(mob/living/carbon/human/source, obj/item/weapon, mob/living/attacker)
	SIGNAL_HANDLER

	if(attacker != source)
		return

	var/zone = source.zone_selected || BODY_ZONE_CHEST
	var/bclass = source.used_intent?.blade_class || BCLASS_BLUNT
	var/weapon_name = weapon?.name || "weapon"
	if(!consume_mode(source, "attacking themselves with [weapon_name]"))
		return
	addtimer(CALLBACK(src, PROC_REF(apply_targeted_trauma), WEAKREF(source), zone, bclass, weapon_name), world.tick_lag)

/datum/element/suicide_mode/proc/on_projectile_hit(mob/living/carbon/human/source, obj/projectile/projectile, def_zone)
	SIGNAL_HANDLER

	if(projectile.firer != source)
		return

	var/projectile_name = projectile.name
	if(istype(projectile, /obj/projectile/magic))
		var/magic_kind = get_magic_kind(projectile)
		var/starting_fire_stacks = source.fire_stacks
		if(!consume_mode(source, "striking themselves with [projectile_name]"))
			return
		addtimer(CALLBACK(src, PROC_REF(apply_magic_trauma), WEAKREF(source), magic_kind, projectile_name, starting_fire_stacks), world.tick_lag)
		return

	var/zone = def_zone || source.zone_selected || BODY_ZONE_CHEST
	var/bclass = projectile.woundclass || ((projectile.damage_type == BURN) ? BCLASS_BURN : BCLASS_PIERCE)
	if(!consume_mode(source, "shooting themselves with [projectile_name]"))
		return
	addtimer(CALLBACK(src, PROC_REF(apply_targeted_trauma), WEAKREF(source), zone, bclass, projectile_name), world.tick_lag)

/datum/element/suicide_mode/proc/on_modern_spell_cast(mob/living/carbon/human/source, datum/action/cooldown/spell/spell, atom/cast_on)
	SIGNAL_HANDLER

	if(cast_on != source)
		return

	var/magic_kind = get_magic_kind(spell)
	var/starting_fire_stacks = source.fire_stacks
	if(!consume_mode(source, "casting [spell] on themselves"))
		return
	addtimer(CALLBACK(src, PROC_REF(apply_magic_trauma), WEAKREF(source), magic_kind, spell.name, starting_fire_stacks), world.tick_lag)

/datum/element/suicide_mode/proc/on_legacy_spell_cast(mob/living/carbon/human/source, obj/effect/proc_holder/spell/spell, list/targets)
	SIGNAL_HANDLER

	if(!islist(targets) || !(source in targets))
		return

	var/magic_kind = get_magic_kind(spell)
	var/starting_fire_stacks = source.fire_stacks
	if(!consume_mode(source, "casting [spell] on themselves"))
		return
	addtimer(CALLBACK(src, PROC_REF(apply_magic_trauma), WEAKREF(source), magic_kind, spell.name, starting_fire_stacks), world.tick_lag)

/datum/element/suicide_mode/proc/consume_mode(mob/living/carbon/human/source, method)
	if(!HAS_TRAIT(source, SUICIDE_MODE_TRAIT))
		return FALSE

	source.RemoveElement(/datum/element/suicide_mode)
	source.set_suicide(TRUE)
	source.log_message("triggered suicide mode by [method]", LOG_ATTACK)
	source.suicide_log()
	return TRUE

/datum/element/suicide_mode/proc/is_show_death(mob/living/carbon/human/source)
	return HAS_TRAIT(source, TRAIT_CRITICAL_WEAKNESS) || HAS_TRAIT(source, TRAIT_DNR)

/datum/element/suicide_mode/proc/announce_trauma(mob/living/carbon/human/source, normal_message, show_message, self_message)
	var/show_death = is_show_death(source)
	var/public_message = show_death ? show_message : normal_message
	if(show_death)
		if(HAS_TRAIT(source, TRAIT_CRITICAL_WEAKNESS))
			public_message += " Their catastrophically frail body turns the injury into spectacular ruin!"
		if(HAS_TRAIT(source, TRAIT_DNR))
			public_message += " Their lux gutters out in the same instant, leaving no road back to life!"
	source.visible_message(
		span_bigbold(span_crit(public_message)),
		span_bigbold(span_userdanger(self_message))
	)

/datum/element/suicide_mode/proc/create_bloodbath(mob/living/carbon/human/source, spectacular = FALSE)
	if(NOBLOOD in source.dna?.species?.species_traits)
		return

	var/turf/epicenter = get_turf(source)
	if(!epicenter)
		return

	var/radius = spectacular ? 2 : 1
	var/spill_chance = spectacular ? 75 : 45
	for(var/turf/nearby in range(radius, epicenter))
		if(!prob(spill_chance))
			continue
		source.add_splatter_floor(nearby)
		source.add_drip_floor(nearby, spectacular ? 40 : 20)
	source.add_splatter_wall(source, epicenter, spectacular ? 100 : 60, spectacular ? 12 : 7)
	source.blood_volume = max(source.blood_volume - (spectacular ? 300 : 180), 0)

/datum/element/suicide_mode/proc/ruin_organ(mob/living/carbon/human/source, organ_slot)
	var/obj/item/organ/organ = source.getorganslot(organ_slot)
	if(!organ)
		return
	organ.applyOrganDamage(organ.maxHealth)
	organ.organ_flags |= ORGAN_FAILING
	if(organ_slot == ORGAN_SLOT_HEART)
		source.set_heartattack(TRUE)

/datum/element/suicide_mode/proc/ruin_internal_organs(mob/living/carbon/human/source, include_brain = FALSE)
	for(var/obj/item/organ/organ as anything in source.internal_organs)
		if(!include_brain && organ.slot == ORGAN_SLOT_BRAIN)
			continue
		organ.applyOrganDamage(organ.maxHealth)
		organ.organ_flags |= ORGAN_FAILING
	source.set_heartattack(TRUE)

/datum/element/suicide_mode/proc/damage_every_bodypart(mob/living/carbon/human/source, brute_damage, burn_damage)
	for(var/obj/item/bodypart/bodypart as anything in source.bodyparts)
		bodypart.receive_damage(brute_damage, burn_damage, 0, 0, FALSE)
	source.updatehealth()
	source.update_damage_overlays()

/datum/element/suicide_mode/proc/fracture_every_bodypart(mob/living/carbon/human/source)
	for(var/obj/item/bodypart/bodypart as anything in source.bodyparts)
		switch(bodypart.body_zone)
			if(BODY_ZONE_HEAD)
				bodypart.add_wound(/datum/wound/fracture/head/shatter)
				bodypart.add_wound(/datum/wound/fracture/neck/shatter)
			if(BODY_ZONE_CHEST)
				bodypart.add_wound(/datum/wound/fracture/chest)
				bodypart.add_wound(/datum/wound/fracture/groin)
			else
				bodypart.add_wound(/datum/wound/fracture)

/datum/element/suicide_mode/proc/apply_fall_trauma(datum/weakref/source_ref)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	var/show_death = is_show_death(source)
	announce_trauma(
		source,
		"[source] strikes the ground with a sickening crack; skull, spine, ribs, and limbs all give way!",
		"[source] hits the ground like a dropped carcass and comes apart in an eruption of bone, organs, and blood!",
		"I hit the ground. Everything inside me breaks at once."
	)
	playsound(source, pick('sound/combat/fracture/fracturedry (1).ogg', 'sound/combat/fracture/fracturedry (2).ogg', 'sound/combat/fracture/fracturedry (3).ogg'), 120, FALSE)
	shake_camera(source, show_death ? 8 : 4, 4)
	damage_every_bodypart(source, 200, 0)
	fracture_every_bodypart(source)
	ruin_internal_organs(source, include_brain = TRUE)
	create_bloodbath(source, show_death)
	source.Unconscious(2 MINUTES)
	if(show_death)
		source.gib()

/datum/element/suicide_mode/proc/apply_lava_death(datum/weakref/source_ref)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	announce_trauma(
		source,
		"[source] sinks into the lava and erupts into a roaring pillar of flame, leaving only ash behind!",
		"[source] touches the lava and detonates like a funeral pyre, their silhouette blazing white before collapsing into ash!",
		"The lava takes me whole. Flesh, bone, and thought burn away together."
	)
	playsound(source, 'sound/misc/lava_death.ogg', 140, FALSE)
	ADD_TRAIT(source, TRAIT_DUSTABLE, SUICIDE_MODE_DUST_SOURCE)
	source.dust(just_ash = TRUE, drop_items = TRUE, force = TRUE)

/datum/element/suicide_mode/proc/apply_acid_death(datum/weakref/source_ref)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	announce_trauma(
		source,
		"[source] dissolves in the acid with a violent hiss until nothing remains but smoking ash!",
		"[source] collapses into a foaming silhouette as acid strips flesh, organs, and bone away in seconds!",
		"The acid opens every part of me at once. I dissolve into nothing."
	)
	playsound(source, 'sound/misc/hiss.ogg', 120, FALSE)
	ADD_TRAIT(source, TRAIT_DUSTABLE, SUICIDE_MODE_DUST_SOURCE)
	source.dust(just_ash = TRUE, drop_items = TRUE, force = TRUE)

/datum/element/suicide_mode/proc/apply_water_death(datum/weakref/source_ref)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	var/show_death = is_show_death(source)
	if(prob(50))
		announce_trauma(
			source,
			"[source] disappears beneath the water; a torrent of bubbles marks the moment their lungs flood!",
			"[source] vanishes under the surface in a convulsive spray, their final breath exploding upward in a crown of foam!",
			"Water floods my lungs. The surface slips away forever."
		)
		source.Knockdown(2 MINUTES)
		source.setOxyLoss(max(source.getOxyLoss(), source.maxHealth + 50))
		if(show_death && source.stat != DEAD)
			source.death()
		return

	announce_trauma(
		source,
		"[source] strikes the water like stone; the impact crushes their entire body with a chorus of wet cracks!",
		"[source] hits the water hard enough to burst blood across the surface, their body folding around the impact!",
		"I strike the water with my whole body. Every bone answers at once."
	)
	playsound(source, pick('sound/foley/water_land1.ogg', 'sound/foley/water_land2.ogg', 'sound/foley/water_land3.ogg'), 130, FALSE)
	damage_every_bodypart(source, 180, 0)
	fracture_every_bodypart(source)
	ruin_internal_organs(source, include_brain = TRUE)
	create_bloodbath(source, show_death)
	source.Unconscious(2 MINUTES)
	if(show_death)
		source.gib()

/datum/element/suicide_mode/proc/apply_targeted_trauma(datum/weakref/source_ref, zone, bclass, weapon_name)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	var/show_death = is_show_death(source)
	var/obj/item/bodypart/target_part = source.get_bodypart(zone)
	var/body_zone = check_zone(zone)
	var/is_sharp = bclass in GLOB.artery_bclasses

	if(body_zone in list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		announce_trauma(
			source,
			"[source] drives [weapon_name] through their own [target_part?.name || "limb"], severing it in a fountain of blood!",
			"[source]'s [target_part?.name || "limb"] cartwheels away through a red curtain as [weapon_name] tears it completely free!",
			"I commit the blow. My [target_part?.name || "limb"] comes away in my own hands."
		)
		if(target_part && !target_part.dismember(BRUTE, is_sharp ? bclass : BCLASS_CHOP, source, target_part.body_zone, 999, skip_checks = TRUE))
			target_part.drop_limb()
		create_bloodbath(source, show_death)
		if(show_death && source.stat != DEAD)
			source.death()
		return

	var/obj/item/bodypart/head = source.get_bodypart(BODY_ZONE_HEAD)
	var/obj/item/bodypart/chest = source.get_bodypart(BODY_ZONE_CHEST)

	if(zone == BODY_ZONE_PRECISE_NECK)
		announce_trauma(
			source,
			is_sharp ? "[source] opens their own throat with [weapon_name]; the carotid parts in a crimson sheet!" : "[source] wrenches [weapon_name] into their neck until the spine snaps!",
			is_sharp ? "[source] carves through their own throat so completely that blood paints everything around them!" : "[source]'s neck folds with a cannon-crack, the ruined spine punching visibly beneath the skin!",
			is_sharp ? "I open my throat and feel my heartbeat leave through the wound." : "I force the blow through my neck. My spine gives way."
		)
		if(is_sharp)
			head?.add_wound(/datum/wound/artery/neck)
		else
			head?.add_wound(/datum/wound/fracture/neck/shatter)
		ruin_organ(source, ORGAN_SLOT_BRAIN)
		create_bloodbath(source, show_death)
		if(show_death)
			if(head && !head.dismember(BRUTE, BCLASS_CHOP, source, BODY_ZONE_PRECISE_NECK, 999, vorpal = TRUE, skip_checks = TRUE))
				source.death()
		return

	if(zone == BODY_ZONE_PRECISE_STOMACH || zone == BODY_ZONE_PRECISE_GROIN)
		announce_trauma(
			source,
			"[source] tears open their own belly with [weapon_name], spilling ruined organs into their hands!",
			"[source] rips themselves from groin to ribs; organs and blood pour out in a steaming avalanche!",
			"I open my own belly. Everything inside me spills free."
		)
		if(is_sharp)
			chest?.add_wound(/datum/wound/slash/disembowel)
		else
			chest?.add_wound(/datum/wound/fracture/groin)
		ruin_organ(source, ORGAN_SLOT_STOMACH)
		ruin_organ(source, ORGAN_SLOT_LIVER)
		create_bloodbath(source, show_death)
		if(show_death)
			source.gib()
		return

	if(body_zone == BODY_ZONE_CHEST)
		announce_trauma(
			source,
			is_sharp ? "[source] buries [weapon_name] in their own chest and punches straight through the heart!" : "[source] caves in their own chest with [weapon_name], pulping heart and lungs beneath broken ribs!",
			is_sharp ? "[source] transfixes their own heart; blood erupts from mouth and wound with every failing beat!" : "[source]'s ribcage bursts inward under [weapon_name], spraying blood and bone with the last beat of their heart!",
			is_sharp ? "I feel [weapon_name] enter my heart. Its last beat runs down my hands." : "I crush my own chest until my heart stops beneath the wreckage."
		)
		if(is_sharp)
			chest?.add_wound(/datum/wound/artery/chest)
		else
			chest?.add_wound(/datum/wound/fracture/chest)
		ruin_organ(source, ORGAN_SLOT_HEART)
		ruin_organ(source, ORGAN_SLOT_LUNGS)
		source.vomit(blood = TRUE)
		create_bloodbath(source, show_death)
		if(show_death)
			source.gib()
		return

	announce_trauma(
		source,
		is_sharp ? "[source] drives [weapon_name] through their own skull, opening the brain beneath it!" : "[source] crushes their own skull with [weapon_name] in a spray of blood and bone!",
		is_sharp ? "[source] skewers their own head so violently that skull and brain blossom outward around [weapon_name]!" : "[source]'s head caves in under [weapon_name], bursting apart with a thunderous crack!",
		is_sharp ? "I push [weapon_name] through my skull and into the darkness beneath." : "I feel my skull collapse around the blow."
	)
	if(is_sharp)
		head?.add_wound(/datum/wound/fracture/head/brain/shatter)
	else
		head?.add_wound(/datum/wound/fracture/head/shatter)
	ruin_organ(source, ORGAN_SLOT_BRAIN)
	create_bloodbath(source, show_death)
	if(show_death)
		if(head && !head.dismember(BRUTE, BCLASS_CHOP, source, BODY_ZONE_PRECISE_NECK, 999, vorpal = TRUE, skip_checks = TRUE))
			source.death()

/datum/element/suicide_mode/proc/get_magic_kind(datum/magic_source)
	if(istype(magic_source, /datum/action/cooldown/spell))
		var/datum/action/cooldown/spell/modern_spell = magic_source
		switch(modern_spell.attunement_school)
			if(ASPECT_NAME_PYROMANCY)
				return SUICIDE_MAGIC_FIRE
			if(ASPECT_NAME_CRYOMANCY)
				return SUICIDE_MAGIC_ICE
			if(ASPECT_NAME_FULGURMANCY)
				return SUICIDE_MAGIC_LIGHTNING

	var/search_text = lowertext("[magic_source?.type] [magic_source?.name]")
	if(findtext(search_text, "frost") || findtext(search_text, "ice") || findtext(search_text, "snow") || findtext(search_text, "cryo") || findtext(search_text, "cold") || findtext(search_text, "freeze") || findtext(search_text, "icicle"))
		return SUICIDE_MAGIC_ICE
	if(findtext(search_text, "lightning") || findtext(search_text, "thunder") || findtext(search_text, "fulgur") || findtext(search_text, "storm") || findtext(search_text, "electric"))
		return SUICIDE_MAGIC_LIGHTNING
	if(findtext(search_text, "fire") || findtext(search_text, "flame") || findtext(search_text, "burn") || findtext(search_text, "infernal") || findtext(search_text, "solar") || findtext(search_text, "astrata"))
		return SUICIDE_MAGIC_FIRE
	return SUICIDE_MAGIC_GENERIC

/datum/element/suicide_mode/proc/apply_magic_trauma(datum/weakref/source_ref, magic_kind, spell_name, starting_fire_stacks)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	var/show_death = is_show_death(source)
	switch(magic_kind)
		if(SUICIDE_MAGIC_FIRE)
			announce_trauma(
				source,
				"[source] turns [spell_name] inward; every part of their body erupts into ravenous flame!",
				"[source] becomes the heart of a firestorm, flesh peeling into incandescent ash as [spell_name] consumes them!",
				"I open myself to [spell_name]. Fire fills every vein and hollow."
			)
			ADD_TRAIT(source, TRAIT_DUSTABLE, SUICIDE_MODE_DUST_SOURCE)
			damage_every_bodypart(source, 0, 200)
			var/new_fire_stacks = max(source.fire_stacks - starting_fire_stacks, 0)
			source.adjust_fire_stacks(new_fire_stacks ? new_fire_stacks * 4 : 25)
			source.ignite_mob()
			if(show_death || source.getFireLoss() >= source.maxHealth * 4)
				source.dust(just_ash = TRUE, drop_items = TRUE, force = TRUE)
			return

		if(SUICIDE_MAGIC_ICE)
			announce_trauma(
				source,
				"[source] flash-freezes from the inside out, becoming a jagged human icicle!",
				"[source] crystallizes in a deafening instant; blood, organs, and bone become a glittering statue of fractured ice!",
				"Cold closes around every cell. I become a single shard of ice."
			)
			damage_every_bodypart(source, 120, 120)
			fracture_every_bodypart(source)
			ruin_internal_organs(source, include_brain = TRUE)
			source.adjust_bodytemperature(-1000)
			source.remove_status_effect(/datum/status_effect/freon)
			source.apply_status_effect(/datum/status_effect/freon/suicide)
			source.Unconscious(10 MINUTES)
			if(show_death && source.stat != DEAD)
				source.death()
			return

		if(SUICIDE_MAGIC_LIGHTNING)
			announce_trauma(
				source,
				"[source] draws [spell_name] through their own body and erupts into a blinding silhouette of ash!",
				"[source] becomes a living thunderbolt; the world flashes white and their body explodes into smoking dust!",
				"Lightning replaces my blood. For one white instant, I am nothing but thunder."
			)
			playsound(source, 'sound/magic/lightning.ogg', 140, FALSE)
			ADD_TRAIT(source, TRAIT_DUSTABLE, SUICIDE_MODE_DUST_SOURCE)
			source.dust(just_ash = TRUE, drop_items = TRUE, force = TRUE)
			return

	announce_trauma(
		source,
		"[source] turns [spell_name] inward; raw magic detonates through every limb and organ at once!",
		"[source] becomes the center of an arcyne catastrophe, bursting apart as [spell_name] tears body and lux in every direction!",
		"I let [spell_name] loose inside myself. Every part of me comes apart together."
	)
	damage_every_bodypart(source, 220, 120)
	fracture_every_bodypart(source)
	ruin_internal_organs(source, include_brain = TRUE)
	create_bloodbath(source, show_death)
	source.Unconscious(2 MINUTES)
	if(show_death)
		source.gib()

#undef SUICIDE_MAGIC_LIGHTNING
#undef SUICIDE_MAGIC_ICE
#undef SUICIDE_MAGIC_FIRE
#undef SUICIDE_MAGIC_GENERIC

#undef SUICIDE_MODE_DUST_SOURCE
#undef SUICIDE_MODE_TRAIT
