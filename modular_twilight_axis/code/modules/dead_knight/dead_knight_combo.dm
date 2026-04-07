// ============================================================
// Dead Knight combo component
// Three input types: Blood (1), Ice (2), Unholy (3)
// Combo strikes:
//   4) Runic Strike  (B,I,U)  — 2x AoE around target
//   7) Death Strike   (B,B,U) — hit + heal reduction
//   8) Plague Strike  (U,U,B) — armor pen + spreading disease
// ============================================================

/datum/component/combo_core/dead_knight
	parent_type = /datum/component/combo_core/combat_style
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/list/granted_spells = list()
	var/spells_granted = FALSE

	var/obj/item/rogueweapon/sword/long/runic_blade/blade = null
	var/stance_active = FALSE

/datum/component/combo_core/dead_knight/Initialize(_combo_window, _max_history)
	. = ..((_combo_window || DK_COMBO_WINDOW), (_max_history || DK_MAX_HISTORY))
	if(. == COMPONENT_INCOMPATIBLE)
		return .

	RegisterSignal(owner, COMSIG_ATTACK_TRY_CONSUME, PROC_REF(_sig_try_consume), override = TRUE)
	RegisterSignal(owner, COMSIG_DK_STANCE_TOGGLED, PROC_REF(_sig_stance_toggled))

	GrantSpells()
	return .

/datum/component/combo_core/dead_knight/Destroy(force)
	if(owner)
		UnregisterSignal(owner, COMSIG_ATTACK_TRY_CONSUME)
		UnregisterSignal(owner, COMSIG_DK_STANCE_TOGGLED)
		RevokeSpells()

	if(blade && !QDELETED(blade))
		qdel(blade)
	blade = null

	owner = null
	return ..()

// ------------------------------------------------------------
// combo rules
// ------------------------------------------------------------

/datum/component/combo_core/dead_knight/DefineRules()
	// 4) Runic Strike: Blood -> Ice -> Unholy = AoE 2x damage
	RegisterRule("runic_strike",  list(DK_INPUT_BLOOD, DK_INPUT_ICE, DK_INPUT_UNHOLY), 50, PROC_REF(_cb_combo))
	// 7) Death Strike: Blood -> Blood -> Unholy = hit + heal reduction
	RegisterRule("death_strike",  list(DK_INPUT_BLOOD, DK_INPUT_BLOOD, DK_INPUT_UNHOLY), 30, PROC_REF(_cb_combo))
	// 8) Plague Strike: Unholy -> Unholy -> Blood = disease on armor pen
	RegisterRule("plague_strike", list(DK_INPUT_UNHOLY, DK_INPUT_UNHOLY, DK_INPUT_BLOOD), 30, PROC_REF(_cb_combo))

/datum/component/combo_core/dead_knight/proc/_cb_combo(rule_id, mob/living/target, zone)
	if(!owner || !stance_active)
		return FALSE
	if(!blade || QDELETED(blade) || !blade.is_held_by_owner())
		return FALSE

	switch(rule_id)
		if("runic_strike")
			return ExecuteCombo_RunicStrike(target, zone)
		if("death_strike")
			return ExecuteCombo_DeathStrike(target, zone)
		if("plague_strike")
			return ExecuteCombo_PlagueStrike(target, zone)
	return FALSE

// ------------------------------------------------------------
// 4) Runic Strike — 2x damage AoE around target
// ------------------------------------------------------------

/datum/component/combo_core/dead_knight/proc/find_nearest_enemy()
	if(!owner)
		return null
	for(var/mob/living/L in oview(2, owner))
		if(L.stat == DEAD)
			continue
		if(L.faction_check_mob(owner))
			continue
		return L
	return null

/datum/component/combo_core/dead_knight/proc/ExecuteCombo_RunicStrike(mob/living/target, zone)
	if(!target)
		target = find_nearest_enemy()
	if(!target)
		return FALSE

	var/turf/target_turf = get_turf(target)
	if(!target_turf)
		return FALSE

	var/base_damage = blade.force * 2
	var/skill_mult = owner.mind ? (owner.get_skill_level(/datum/skill/combat/swords) * 0.1 + 0.5) : 1
	var/total_damage = round(base_damage * skill_mult)

	owner.visible_message(
		span_userdanger("[owner] swings the runic blade in a devastating arc!"),
		span_danger("Runic Strike!")
	)

	for(var/mob/living/L in range(1, target_turf))
		if(L == owner)
			continue
		if(L.faction_check_mob(owner))
			continue
		var/eff_zone = GetEffectiveHitZone(L, zone)
		L.apply_damage(total_damage, BRUTE, eff_zone)
		to_chat(L, span_userdanger("The runic blade tears through you!"))

	SEND_SIGNAL(owner, COMSIG_DK_COMBO_FIRED, "runic_strike")
	return TRUE

// ------------------------------------------------------------
// 7) Death Strike — normal hit + heal reduction debuff
// ------------------------------------------------------------

/datum/component/combo_core/dead_knight/proc/ExecuteCombo_DeathStrike(mob/living/target, zone)
	if(!target)
		target = find_nearest_enemy()
	if(!target)
		return FALSE

	var/base_damage = blade.force * 1.3
	var/total_damage = round(base_damage)

	owner.visible_message(
		span_danger("[owner] delivers a chilling death blow to [target]!"),
		span_danger("Death Strike!")
	)

	var/eff_zone = GetEffectiveHitZone(target, zone)
	target.apply_damage(total_damage, BRUTE, eff_zone)
	target.apply_status_effect(/datum/status_effect/debuff/dk_heal_reduction)
	to_chat(target, span_userdanger("A deathly numbness spreads through your wounds — healing is weakened!"))

	SEND_SIGNAL(owner, COMSIG_DK_COMBO_FIRED, "death_strike")
	return TRUE

// ------------------------------------------------------------
// 8) Plague Strike — armor pen + spreading disease
// ------------------------------------------------------------

/datum/component/combo_core/dead_knight/proc/ExecuteCombo_PlagueStrike(mob/living/target, zone)
	if(!target)
		target = find_nearest_enemy()
	if(!target)
		return FALSE

	var/base_damage = blade.force * 1.1
	var/total_damage = round(base_damage)

	owner.visible_message(
		span_danger("[owner] strikes [target] with a pestilent blade!"),
		span_danger("Plague Strike!")
	)

	var/eff_zone = GetEffectiveHitZone(target, zone)
	target.apply_damage(total_damage, BRUTE, eff_zone, armour_penetration = 30)

	if(ishuman(target))
		var/mob/living/carbon/human/H = target
		var/obj/item/bodypart/BP = H.get_bodypart(eff_zone)
		if(BP)
			var/armor_val = H.run_armor_check(BP, "melee")
			if(total_damage > armor_val || prob(40))
				target.apply_status_effect(/datum/status_effect/debuff/dk_plague_disease, owner)
				to_chat(target, span_userdanger("The blade penetrates your armor and infects you with plague!"))
	else
		if(prob(50))
			target.apply_status_effect(/datum/status_effect/debuff/dk_plague_disease, owner)

	SEND_SIGNAL(owner, COMSIG_DK_COMBO_FIRED, "plague_strike")
	return TRUE

// ------------------------------------------------------------
// history / visual overrides
// ------------------------------------------------------------

/datum/component/combo_core/dead_knight/OnHistoryChanged()
	UpdateStacksFromInput()

/datum/component/combo_core/dead_knight/OnHistoryCleared(reason)
	return

/datum/component/combo_core/dead_knight/OnComboExpired()
	return

// ------------------------------------------------------------
// stack management
// ------------------------------------------------------------

/datum/component/combo_core/dead_knight/proc/UpdateStacksFromInput()
	if(!owner || !length(history))
		return

	var/datum/combo_input_entry/last_entry = history[length(history)]
	if(!last_entry)
		return

	var/datum/status_effect/buff/dk_stacks/stacks = owner.has_status_effect(/datum/status_effect/buff/dk_stacks)
	if(!stacks)
		stacks = owner.apply_status_effect(/datum/status_effect/buff/dk_stacks)
	if(!stacks)
		return

	switch(last_entry.skill_id)
		if(DK_INPUT_BLOOD)
			stacks.add_blood()
			to_chat(owner, span_danger("Blood +1 ([stacks.blood])"))
		if(DK_INPUT_ICE)
			stacks.add_ice()
			to_chat(owner, span_notice("Ice +1 ([stacks.ice])"))
		if(DK_INPUT_UNHOLY)
			stacks.add_unholy()
			to_chat(owner, span_boldwarning("Unholy +1 ([stacks.unholy])"))

// ------------------------------------------------------------
// stance
// ------------------------------------------------------------

/datum/component/combo_core/dead_knight/proc/ToggleStance()
	if(!owner)
		return
	if(stance_active)
		DeactivateStance()
	else
		ActivateStance()

/datum/component/combo_core/dead_knight/proc/ActivateStance()
	if(!owner || stance_active)
		return

	var/obj/item/W = owner.get_active_held_item()
	if(!istype(W, /obj/item/rogueweapon/sword/long/runic_blade))
		to_chat(owner, span_warning("You must hold the runic blade to enter the stance."))
		return

	stance_active = TRUE
	owner.apply_status_effect(/datum/status_effect/buff/dk_stance)
	to_chat(owner, span_danger("You adopt the Runic Stance. The runes flare to life."))

/datum/component/combo_core/dead_knight/proc/DeactivateStance()
	if(!owner || !stance_active)
		return

	stance_active = FALSE
	owner.remove_status_effect(/datum/status_effect/buff/dk_stance)
	ClearHistory("stance_off")
	to_chat(owner, span_notice("You relax your stance. The runes dim."))

// ------------------------------------------------------------
// blade summoning
// ------------------------------------------------------------

/datum/component/combo_core/dead_knight/proc/SummonBlade()
	if(!owner)
		return

	var/obj/item/rogueweapon/sword/long/runic_blade/new_blade = new(get_turf(owner), owner)
	if(owner.put_in_hands(new_blade))
		blade = new_blade
		to_chat(owner, span_danger("The runic blade coalesces from dark mist into your grasp."))
		SEND_SIGNAL(owner, COMSIG_DK_BLADE_SUMMONED)
	else
		to_chat(owner, span_warning("Your hands are full — the blade falls to the ground."))
		blade = new_blade

// ------------------------------------------------------------
// signals
// ------------------------------------------------------------

/datum/component/combo_core/dead_knight/proc/_sig_try_consume(datum/source, atom/target_atom, zone)
	SIGNAL_HANDLER
	return 0

/datum/component/combo_core/dead_knight/proc/_sig_stance_toggled(datum/source, active)
	SIGNAL_HANDLER
	stance_active = active

// ------------------------------------------------------------
// spells lifecycle
// ------------------------------------------------------------

/datum/component/combo_core/dead_knight/proc/GrantSpells()
	return

/datum/component/combo_core/dead_knight/proc/RevokeSpells()
	return
