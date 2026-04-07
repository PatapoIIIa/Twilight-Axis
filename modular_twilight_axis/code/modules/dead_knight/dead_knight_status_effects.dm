// ============================================================
// Dead Knight — status effects
// ============================================================

// --- Stack tracker (Blood / Ice / Unholy) ---

/atom/movable/screen/alert/status_effect/buff/dk_stacks
	name = "Runic Resonance"
	desc = "The runes on your blade thrum with accumulated power."
	icon_state = "buff"

/datum/status_effect/buff/dk_stacks
	id = "dk_stacks"
	status_type = STATUS_EFFECT_REFRESH
	duration = -1
	tick_interval = 1 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/buff/dk_stacks

	var/blood = 0
	var/ice = 0
	var/unholy = 0
	var/last_stack_time = 0

/datum/status_effect/buff/dk_stacks/on_apply()
	. = ..()
	last_stack_time = world.time
	return TRUE

/datum/status_effect/buff/dk_stacks/tick()
	if(world.time - last_stack_time >= DK_STACK_DECAY_TIME)
		decay_stacks()

/datum/status_effect/buff/dk_stacks/on_remove()
	blood = 0
	ice = 0
	unholy = 0
	. = ..()

/datum/status_effect/buff/dk_stacks/proc/add_blood(amount = 1)
	blood = min(blood + amount, DK_MAX_STACKS)
	last_stack_time = world.time
	SEND_SIGNAL(owner, COMSIG_DK_STACK_CHANGED, "blood", blood)
	update_alert()

/datum/status_effect/buff/dk_stacks/proc/add_ice(amount = 1)
	ice = min(ice + amount, DK_MAX_STACKS)
	last_stack_time = world.time
	SEND_SIGNAL(owner, COMSIG_DK_STACK_CHANGED, "ice", ice)
	update_alert()

/datum/status_effect/buff/dk_stacks/proc/add_unholy(amount = 1)
	unholy = min(unholy + amount, DK_MAX_STACKS)
	last_stack_time = world.time
	SEND_SIGNAL(owner, COMSIG_DK_STACK_CHANGED, "unholy", unholy)
	update_alert()

/datum/status_effect/buff/dk_stacks/proc/consume_blood(amount = 1)
	if(blood < amount)
		return FALSE
	blood -= amount
	SEND_SIGNAL(owner, COMSIG_DK_STACK_CHANGED, "blood", blood)
	update_alert()
	return TRUE

/datum/status_effect/buff/dk_stacks/proc/consume_ice(amount = 1)
	if(ice < amount)
		return FALSE
	ice -= amount
	SEND_SIGNAL(owner, COMSIG_DK_STACK_CHANGED, "ice", ice)
	update_alert()
	return TRUE

/datum/status_effect/buff/dk_stacks/proc/consume_unholy(amount = 1)
	if(unholy < amount)
		return FALSE
	unholy -= amount
	SEND_SIGNAL(owner, COMSIG_DK_STACK_CHANGED, "unholy", unholy)
	update_alert()
	return TRUE

/datum/status_effect/buff/dk_stacks/proc/consume_all()
	var/list/consumed = list("blood" = blood, "ice" = ice, "unholy" = unholy)
	blood = 0
	ice = 0
	unholy = 0
	SEND_SIGNAL(owner, COMSIG_DK_STACK_CHANGED, "all", 0)
	update_alert()
	return consumed

/datum/status_effect/buff/dk_stacks/proc/get_total()
	return blood + ice + unholy

/datum/status_effect/buff/dk_stacks/proc/decay_stacks()
	if(blood > 0)
		blood = max(blood - 1, 0)
	if(ice > 0)
		ice = max(ice - 1, 0)
	if(unholy > 0)
		unholy = max(unholy - 1, 0)

	last_stack_time = world.time
	SEND_SIGNAL(owner, COMSIG_DK_STACK_CHANGED, "decay", get_total())

	if(get_total() <= 0)
		owner.remove_status_effect(/datum/status_effect/buff/dk_stacks)
		return

	update_alert()

/datum/status_effect/buff/dk_stacks/proc/update_alert()
	if(!linked_alert)
		return
	linked_alert.desc = "Blood: [blood] | Ice: [ice] | Unholy: [unholy]"

// --- Stance status effect ---

/atom/movable/screen/alert/status_effect/buff/dk_stance
	name = "Runic Stance"
	desc = "You stand ready with the runic blade, channelling death's power."
	icon_state = "buff"

/datum/status_effect/buff/dk_stance
	id = "dk_stance"
	status_type = STATUS_EFFECT_UNIQUE
	duration = -1
	tick_interval = 0
	alert_type = /atom/movable/screen/alert/status_effect/buff/dk_stance

/datum/status_effect/buff/dk_stance/on_apply()
	. = ..()
	SEND_SIGNAL(owner, COMSIG_DK_STANCE_TOGGLED, TRUE)
	return TRUE

/datum/status_effect/buff/dk_stance/on_remove()
	SEND_SIGNAL(owner, COMSIG_DK_STANCE_TOGGLED, FALSE)
	. = ..()

// --- Plague Mark (ticking bomb on target) ---

/atom/movable/screen/alert/status_effect/debuff/dk_plague_mark
	name = "Plague Mark"
	desc = "A dark rune has been inscribed upon your flesh. It will detonate soon, spreading plague."
	icon_state = "debuff"

/datum/status_effect/debuff/dk_plague_mark
	id = "dk_plague_mark"
	status_type = STATUS_EFFECT_UNIQUE
	duration = 10 SECONDS
	tick_interval = 0
	alert_type = /atom/movable/screen/alert/status_effect/debuff/dk_plague_mark
	mob_effect_icon = 'icons/mob/mob_effects.dmi'
	mob_effect_icon_state = "eff_exposed"
	mob_effect_layer = ABOVE_MOB_LAYER + 0.15

	var/mob/living/caster

/datum/status_effect/debuff/dk_plague_mark/on_creation(mob/living/new_owner, mob/living/_caster)
	caster = _caster
	return ..()

/datum/status_effect/debuff/dk_plague_mark/on_apply()
	. = ..()
	to_chat(owner, span_userdanger("A dark rune sears into your flesh! Find a priest to cleanse it!"))
	return TRUE

/datum/status_effect/debuff/dk_plague_mark/on_remove()
	if(owner && owner.stat != DEAD)
		detonate()
	caster = null
	. = ..()

/datum/status_effect/debuff/dk_plague_mark/proc/detonate()
	if(!owner)
		return
	owner.visible_message(
		span_userdanger("The plague mark on [owner] erupts in a burst of pestilence!"),
		span_userdanger("The plague mark detonates!")
	)

	var/turf/epicenter = get_turf(owner)
	if(!epicenter)
		return

	owner.adjustBruteLoss(50)

	for(var/mob/living/L in range(2, epicenter))
		if(L == caster)
			continue
		if(L.stat == DEAD)
			continue
		L.apply_status_effect(/datum/status_effect/debuff/dk_plague_disease, caster)
		L.adjustToxLoss(30)
		to_chat(L, span_danger("The plague washes over you!"))

// --- Plague Disease (DoT + spread + debuff) ---

/atom/movable/screen/alert/status_effect/debuff/dk_plague_disease
	name = "Unholy Plague"
	desc = "A foul disease eats at your body, weakening you and threatening to spread."
	icon_state = "debuff"

/datum/status_effect/debuff/dk_plague_disease
	id = "dk_plague_disease"
	status_type = STATUS_EFFECT_REFRESH
	duration = 30 SECONDS
	tick_interval = 5 SECONDS
	alert_type = /atom/movable/screen/alert/status_effect/debuff/dk_plague_disease

	var/mob/living/plague_source
	var/spread_range = 2

/datum/status_effect/debuff/dk_plague_disease/on_creation(mob/living/new_owner, mob/living/_source)
	plague_source = _source
	return ..()

/datum/status_effect/debuff/dk_plague_disease/on_apply()
	. = ..()
	if(owner)
		owner.change_stat(STATKEY_CON, -2)
		owner.change_stat(STATKEY_STR, -2)
		owner.change_stat(STATKEY_SPD, -1)
	return TRUE

/datum/status_effect/debuff/dk_plague_disease/on_remove()
	if(owner)
		owner.change_stat(STATKEY_CON, 2)
		owner.change_stat(STATKEY_STR, 2)
		owner.change_stat(STATKEY_SPD, 1)
	plague_source = null
	. = ..()

/datum/status_effect/debuff/dk_plague_disease/tick()
	if(!owner || owner.stat == DEAD)
		return

	owner.adjustToxLoss(30)

	for(var/mob/living/L in range(spread_range, owner))
		if(L == owner || L == plague_source)
			continue
		if(L.stat == DEAD)
			continue
		if(L.has_status_effect(/datum/status_effect/debuff/dk_plague_disease))
			continue
		if(prob(25))
			L.apply_status_effect(/datum/status_effect/debuff/dk_plague_disease, plague_source)
			to_chat(L, span_danger("The plague spreads to you from [owner]!"))

// --- Ice Immovability (tank buff) ---

/atom/movable/screen/alert/status_effect/buff/dk_ice_immovability
	name = "Ice Immovability"
	desc = "Encased in runic ice, you cannot be moved and take reduced damage."
	icon_state = "buff"

/datum/status_effect/buff/dk_ice_immovability
	id = "dk_ice_immovability"
	status_type = STATUS_EFFECT_REPLACE
	duration = 8 SECONDS
	tick_interval = 0
	alert_type = /atom/movable/screen/alert/status_effect/buff/dk_ice_immovability

/datum/status_effect/buff/dk_ice_immovability/on_apply()
	. = ..()
	if(owner)
		ADD_TRAIT(owner, TRAIT_CRITICAL_RESISTANCE, "dk_ice")
		owner.change_stat(STATKEY_CON, 5)
		to_chat(owner, span_notice("Runic ice encases your body. You are immovable."))
	return TRUE

/datum/status_effect/buff/dk_ice_immovability/on_remove()
	if(owner)
		REMOVE_TRAIT(owner, TRAIT_CRITICAL_RESISTANCE, "dk_ice")
		owner.change_stat(STATKEY_CON, -5)
		to_chat(owner, span_notice("The ice around you shatters."))
	. = ..()

// --- Heal Reduction debuff (from Death Strike) ---

/atom/movable/screen/alert/status_effect/debuff/dk_heal_reduction
	name = "Death's Touch"
	desc = "Healing effects on you are greatly weakened."
	icon_state = "debuff"

/datum/status_effect/debuff/dk_heal_reduction
	id = "dk_heal_reduction"
	status_type = STATUS_EFFECT_REFRESH
	duration = 15 SECONDS
	tick_interval = 0
	alert_type = /atom/movable/screen/alert/status_effect/debuff/dk_heal_reduction

	var/heal_mult = 0.4

/datum/status_effect/debuff/dk_heal_reduction/on_apply()
	. = ..()
	if(owner)
		to_chat(owner, span_danger("A deathly chill grips you, stifling your body's ability to heal."))
	return TRUE
