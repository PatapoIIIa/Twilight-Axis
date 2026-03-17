// ---- Necromantic Monolith: spell holder & outfit grants ----

/obj/effect/proc_holder/spell/invoked/necromantic_monolith
	name = "Necromantic Monolith"
	desc = "Raise a necromantic monolith that fixes several routes toward the throne and periodically births aggressive skeletons to march along them."
	clothes_req = FALSE
	overlay_state = "animate"
	range = 7
	sound = list('sound/magic/magnet.ogg')
	releasedrain = 60
	chargetime = 1 SECONDS
	warnie = "spellwarning"
	no_early_release = TRUE
	charging_slowdown = 1
	chargedloop = /datum/looping_sound/invokegen
	gesture_required = TRUE
	associated_skill = /datum/skill/magic/arcane
	recharge_time = 90 SECONDS
	spell_tier = 4
	zizo_spell = TRUE
	hide_charge_effect = TRUE
	invocations = list("ZIZO, ANCHOR MY DEAD TO THE THRONE!")
	invocation_type = "shout"
	var/datum/weakref/active_monolith

/obj/effect/proc_holder/spell/invoked/necromantic_monolith/cast(list/targets, mob/living/user)
	. = ..()

	if(!HAS_TRAIT(user, TRAIT_CABAL))
		to_chat(user, span_warning("The dead do not heed me."))
		revert_cast()
		return FALSE

	var/obj/structure/necromantic_monolith/existing_monolith = active_monolith?.resolve()
	if(existing_monolith && !QDELETED(existing_monolith))
		to_chat(user, span_warning("A necromantic monolith is already bound to me."))
		revert_cast()
		return FALSE

	if(istype(get_area(user), /area/rogue/indoors/ravoxarena))
		to_chat(user, span_userdanger("Something in this place chokes the rite before it can root."))
		revert_cast()
		return FALSE

	if(!length(targets))
		revert_cast()
		return FALSE

	var/turf/target_turf = get_turf(targets[1])
	var/place_failure = can_place_necromonolith_on(target_turf, user)
	if(place_failure)
		to_chat(user, span_warning(place_failure))
		revert_cast()
		return FALSE

	var/list/setup = prepare_necromonolith_routes(target_turf, user)
	if(!setup)
		to_chat(user, span_warning("The dead cannot find a road from that place to the throne."))
		revert_cast()
		return FALSE

	user.visible_message(span_warning("[user] begins shaping a jagged monolith from necromantic force."), span_notice("I begin anchoring a necromantic monolith."))
	if(!do_after(user, NECROMONOLITH_BUILD_TIME, target_turf))
		to_chat(user, span_warning("My concentration breaks before the monolith can take shape."))
		return FALSE

	place_failure = can_place_necromonolith_on(target_turf, user)
	if(place_failure)
		to_chat(user, span_warning(place_failure))
		return FALSE

	setup = prepare_necromonolith_routes(target_turf, user)
	if(!setup)
		to_chat(user, span_warning("The throne's roads slip away before the rite can be finished."))
		return FALSE

	var/obj/structure/necromantic_monolith/monolith = new(target_turf, user, setup["throne"], setup["routes"])
	if(QDELETED(monolith))
		to_chat(user, span_warning("The rite collapses before the monolith can stabilize."))
		return FALSE

	active_monolith = WEAKREF(monolith)
	monolith.visible_message(span_userdanger("A necromantic monolith claws its way into reality, humming with tethered routes."))
	return TRUE

// ---- Outfit grants ----

/datum/outfit/job/roguetown/wretch/necromancer/post_equip(mob/living/carbon/human/H, visualsOnly = FALSE)
	. = ..()
	if(visualsOnly || !H?.mind)
		return
	if(!H.mind.has_spell(/obj/effect/proc_holder/spell/invoked/necromantic_monolith))
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/necromantic_monolith)

/datum/outfit/job/roguetown/lich/post_equip(mob/living/carbon/human/H)
	..()
	var/datum/antagonist/lich/lichman = H.mind.has_antag_datum(/datum/antagonist/lich)
	var/obj/item/phylactery/new_phylactery = new(H.loc)
	lichman.phylacteries += new_phylactery
	new_phylactery.possessor = lichman
	H.equip_to_slot_or_del(new_phylactery, SLOT_IN_BACKPACK, TRUE)
	if(!H.mind.has_spell(/obj/effect/proc_holder/spell/invoked/necromantic_monolith))
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/necromantic_monolith)
