// ============================================================
// Dead Knight — Spells & Abilities
// ============================================================

// --- Base spell ---

/obj/effect/proc_holder/spell/self/dead_knight
	name = "Dead Knight Ability"
	desc = "Base dead knight technique."
	clothes_req = FALSE
	charge_type = "recharge"
	associated_skill = /datum/skill/combat/swords
	cost = 0
	xp_gain = FALSE

	releasedrain = 0
	chargedrain = 0
	chargetime = 0
	recharge_time = 0

	warnie = "spellwarning"
	no_early_release = TRUE
	movement_interrupt = FALSE
	spell_tier = 1

	invocations = list()
	invocation_type = "none"
	hide_charge_effect = TRUE
	charging_slowdown = 0
	chargedloop = null
	overlay_state = null

	action_icon = 'modular_twilight_axis/icons/roguetown/misc/roninspells.dmi'

/obj/effect/proc_holder/spell/self/dead_knight/cast(list/targets, mob/living/user)
	. = ..()
	if(!isliving(user))
		return
	if(user.incapacitated())
		return

// ============================================================
// COMBO INPUTS (Blood / Ice / Unholy)
// ============================================================

/obj/effect/proc_holder/spell/self/dead_knight/blood_strike
	name = "Blood Strike"
	desc = "A visceral slash that draws upon the essence of blood. Generates a Blood stack."
	overlay_state = "cut_horizontal"

/obj/effect/proc_holder/spell/self/dead_knight/blood_strike/cast(list/targets, mob/living/user)
	. = ..()
	if(!user || user.incapacitated())
		return
	if(!dk_check_stance(user))
		return
	SEND_SIGNAL(user, COMSIG_COMBO_CORE_REGISTER_INPUT, DK_INPUT_BLOOD, null, user.zone_selected)

/obj/effect/proc_holder/spell/self/dead_knight/ice_strike
	name = "Ice Strike"
	desc = "A frigid blow that crystallises the air. Generates an Ice stack."
	overlay_state = "cut_vertical"

/obj/effect/proc_holder/spell/self/dead_knight/ice_strike/cast(list/targets, mob/living/user)
	. = ..()
	if(!user || user.incapacitated())
		return
	if(!dk_check_stance(user))
		return
	SEND_SIGNAL(user, COMSIG_COMBO_CORE_REGISTER_INPUT, DK_INPUT_ICE, null, user.zone_selected)

/obj/effect/proc_holder/spell/self/dead_knight/unholy_strike
	name = "Unholy Strike"
	desc = "A desecrating slash empowered by profane energy. Generates an Unholy stack."
	overlay_state = "cut_diagonal"

/obj/effect/proc_holder/spell/self/dead_knight/unholy_strike/cast(list/targets, mob/living/user)
	. = ..()
	if(!user || user.incapacitated())
		return
	if(!dk_check_stance(user))
		return
	SEND_SIGNAL(user, COMSIG_COMBO_CORE_REGISTER_INPUT, DK_INPUT_UNHOLY, null, user.zone_selected)

// ============================================================
// STANCE & BLADE
// ============================================================

/obj/effect/proc_holder/spell/self/dead_knight/summon_blade
	name = "Summon Runic Blade"
	desc = "Materialise the runic blade in your grasp."
	overlay_state = "blade_bind"
	recharge_time = 15 SECONDS

/obj/effect/proc_holder/spell/self/dead_knight/summon_blade/cast(list/targets, mob/living/user)
	. = ..()
	if(!isliving(user) || user.incapacitated())
		return
	var/datum/component/combo_core/dead_knight/C = user.GetComponent(/datum/component/combo_core/dead_knight)
	if(!C)
		to_chat(user, span_warning("You lack the power to summon this blade."))
		return
	C.SummonBlade()

/obj/effect/proc_holder/spell/self/dead_knight/toggle_stance
	name = "Runic Stance"
	desc = "Enter or leave the runic combat stance. Required for stack abilities."
	overlay_state = "blade_path"
	recharge_time = 2 SECONDS

/obj/effect/proc_holder/spell/self/dead_knight/toggle_stance/cast(list/targets, mob/living/user)
	. = ..()
	if(!isliving(user) || user.incapacitated())
		return
	var/datum/component/combo_core/dead_knight/C = user.GetComponent(/datum/component/combo_core/dead_knight)
	if(!C)
		return
	C.ToggleStance()

// ============================================================
// 1) PLAGUE MARK — mark + explosion + plague spread
//    Costs: 2 Unholy + 1 Blood
// ============================================================

/obj/effect/proc_holder/spell/self/dead_knight/plague_mark
	name = "Plague Mark"
	desc = "Mark a nearby enemy with a runic plague sigil. After 5 seconds it detonates, infecting all nearby with plague. A priest can cleanse it before detonation. Costs 2 Unholy + 1 Blood."
	overlay_state = "cut_diagonal"
	recharge_time = 20 SECONDS

/obj/effect/proc_holder/spell/self/dead_knight/plague_mark/cast(list/targets, mob/living/user)
	. = ..()
	if(!isliving(user) || user.incapacitated())
		return

	var/datum/status_effect/buff/dk_stacks/stacks = user.has_status_effect(/datum/status_effect/buff/dk_stacks)
	if(!stacks || stacks.unholy < 2 || stacks.blood < 1)
		to_chat(user, span_warning("Not enough stacks! Need 2 Unholy + 1 Blood."))
		return

	var/mob/living/target = null
	for(var/mob/living/L in oview(2, user))
		if(L.stat == DEAD)
			continue
		if(L.faction_check_mob(user))
			continue
		target = L
		break

	if(!target)
		to_chat(user, span_warning("No valid target nearby."))
		return

	stacks.consume_unholy(2)
	stacks.consume_blood(1)

	target.apply_status_effect(/datum/status_effect/debuff/dk_plague_mark, user)
	user.visible_message(
		span_danger("[user] inscribes a dark rune upon [target]!"),
		span_danger("You mark [target] with the plague sigil.")
	)

// ============================================================
// 2) BLOOD WORMS — AoE lifesteal
//    Costs: 3 Blood
// ============================================================

/obj/effect/proc_holder/spell/self/dead_knight/blood_worms
	name = "Blood Worms"
	desc = "Summon blood worms on each nearby enemy, draining their life to restore yours. Costs 3 Blood."
	overlay_state = "cut_horizontal"
	recharge_time = 25 SECONDS

/obj/effect/proc_holder/spell/self/dead_knight/blood_worms/cast(list/targets, mob/living/user)
	. = ..()
	if(!isliving(user) || user.incapacitated())
		return

	var/datum/status_effect/buff/dk_stacks/stacks = user.has_status_effect(/datum/status_effect/buff/dk_stacks)
	if(!stacks || stacks.blood < 3)
		to_chat(user, span_warning("Not enough stacks! Need 3 Blood."))
		return

	var/total_heal = 0
	var/hit_count = 0

	for(var/mob/living/L in oview(3, user))
		if(L.stat == DEAD)
			continue
		if(L.faction_check_mob(user))
			continue
		var/drain = 20
		L.adjustBruteLoss(drain)
		to_chat(L, span_userdanger("Blood worms erupt from beneath you, tearing at your flesh!"))
		total_heal += drain * 0.6
		hit_count++

	if(hit_count <= 0)
		to_chat(user, span_warning("No enemies nearby to drain."))
		return

	stacks.consume_blood(3)
	user.adjustBruteLoss(-total_heal)
	to_chat(user, span_notice("The blood worms return, restoring [round(total_heal)] health from [hit_count] victims."))
	user.visible_message(span_danger("Crimson worms writhe around [user], draining the blood of nearby victims!"))

// ============================================================
// 3 & 9) SUMMON DEATH HORSE
//    Costs: 2 Unholy
// ============================================================

/obj/effect/proc_holder/spell/self/dead_knight/summon_death_horse
	name = "Summon Death Horse"
	desc = "Call forth a nightmarish steed from beyond the grave. Can be ridden. Costs 2 Unholy."
	overlay_state = "blade_path"
	recharge_time = 120 SECONDS

/obj/effect/proc_holder/spell/self/dead_knight/summon_death_horse/cast(list/targets, mob/living/user)
	. = ..()
	if(!isliving(user) || user.incapacitated())
		return

	var/datum/status_effect/buff/dk_stacks/stacks = user.has_status_effect(/datum/status_effect/buff/dk_stacks)
	if(!stacks || stacks.unholy < 2)
		to_chat(user, span_warning("Not enough stacks! Need 2 Unholy."))
		return

	stacks.consume_unholy(2)

	var/turf/T = get_step(user, user.dir)
	if(!T)
		T = get_turf(user)

	new /mob/living/simple_animal/hostile/retaliate/rogue/saiga/undead/death_horse(T, user)
	user.visible_message(
		span_danger("A nightmarish steed erupts from dark mist at [user]'s command!"),
		span_danger("You call forth your death horse.")
	)

// ============================================================
// 5) ICE IMMOVABILITY — tanking buff
//    Costs: 3 Ice
// ============================================================

/obj/effect/proc_holder/spell/self/dead_knight/ice_immovability
	name = "Ice Immovability"
	desc = "Encase yourself in runic ice. You cannot move but take greatly reduced damage. Costs 3 Ice."
	overlay_state = "cut_vertical"
	recharge_time = 30 SECONDS

/obj/effect/proc_holder/spell/self/dead_knight/ice_immovability/cast(list/targets, mob/living/user)
	. = ..()
	if(!isliving(user) || user.incapacitated())
		return

	var/datum/status_effect/buff/dk_stacks/stacks = user.has_status_effect(/datum/status_effect/buff/dk_stacks)
	if(!stacks || stacks.ice < 3)
		to_chat(user, span_warning("Not enough stacks! Need 3 Ice."))
		return

	stacks.consume_ice(3)
	user.apply_status_effect(/datum/status_effect/buff/dk_ice_immovability)

// ============================================================
// 6) ARMY OF DARKNESS — for each enemy, summon a skeleton
//    Costs: 3 Unholy + 2 Blood
// ============================================================

/obj/effect/proc_holder/spell/self/dead_knight/army_of_darkness
	name = "Army of Darkness"
	desc = "For each visible enemy nearby, summon a skeleton warrior that targets them. Costs 3 Unholy + 2 Blood."
	overlay_state = "blade_bind"
	recharge_time = 60 SECONDS

/obj/effect/proc_holder/spell/self/dead_knight/army_of_darkness/cast(list/targets, mob/living/user)
	. = ..()
	if(!isliving(user) || user.incapacitated())
		return

	var/datum/status_effect/buff/dk_stacks/stacks = user.has_status_effect(/datum/status_effect/buff/dk_stacks)
	if(!stacks || stacks.unholy < 3 || stacks.blood < 2)
		to_chat(user, span_warning("Not enough stacks! Need 3 Unholy + 2 Blood."))
		return

	var/list/enemies = list()
	for(var/mob/living/L in oview(5, user))
		if(L.stat == DEAD)
			continue
		if(L.faction_check_mob(user))
			continue
		enemies += L

	if(!length(enemies))
		to_chat(user, span_warning("No enemies in range."))
		return

	stacks.consume_unholy(3)
	stacks.consume_blood(2)

	user.visible_message(span_userdanger("[user] raises a gauntleted hand. The ground cracks open and skeletons claw their way out!"))

	var/list/skel_types = list(
		/mob/living/simple_animal/hostile/rogue/skeleton/axe,
		/mob/living/simple_animal/hostile/rogue/skeleton/guard,
		/mob/living/simple_animal/hostile/rogue/skeleton/spear,
		/mob/living/simple_animal/hostile/rogue/skeleton,
	)

	for(var/mob/living/enemy in enemies)
		var/turf/spawn_turf = get_step(user, get_dir(user, enemy))
		if(!spawn_turf)
			spawn_turf = get_turf(user)

		var/skel_type = pick(skel_types)
		var/mob/living/simple_animal/hostile/rogue/skeleton/S = new skel_type(spawn_turf, user, FALSE, TRUE)
		if(S.ai_controller)
			S.ai_controller.blackboard[BB_BASIC_MOB_CURRENT_TARGET] = enemy

	to_chat(user, span_danger("You raise [length(enemies)] skeleton warriors from the earth!"))

// ============================================================
// HELPER
// ============================================================

/proc/dk_check_stance(mob/living/user)
	if(!user)
		return FALSE
	if(!user.has_status_effect(/datum/status_effect/buff/dk_stance))
		to_chat(user, span_warning("You must be in Runic Stance to use this ability."))
		return FALSE
	var/obj/item/W = user.get_active_held_item()
	if(!istype(W, /obj/item/rogueweapon/sword/long/runic_blade))
		to_chat(user, span_warning("You must hold the runic blade."))
		return FALSE
	return TRUE

/proc/dk_get_stacks(mob/living/user)
	if(!user)
		return null
	return user.has_status_effect(/datum/status_effect/buff/dk_stacks)
