// ============================================================
// Dead Knight — Spells & Abilities
// ============================================================

// --- Shared feedback helpers ---

/obj/effect/temp_visual/dead_knight_fx
	name = "runic flare"
	icon = 'icons/effects/effects.dmi'
	icon_state = "curseblob"
	layer = ABOVE_MOB_LAYER
	plane = ABOVE_LIGHTING_PLANE
	randomdir = FALSE
	duration = 0.6 SECONDS
	fade_time = 0.2 SECONDS
	alpha = 220

/obj/effect/temp_visual/dead_knight_fx/Initialize(mapload, set_color, set_icon_state, set_dir, set_duration, set_pixel_y)
	if(set_icon_state)
		icon_state = set_icon_state
	if(isnum(set_duration))
		duration = set_duration
	if(isnum(set_pixel_y))
		pixel_y = set_pixel_y
	if(set_color)
		add_atom_colour(set_color, FIXED_COLOUR_PRIORITY)
	. = ..()
	if(set_dir)
		setDir(set_dir)

/proc/dk_show_message(mob/living/user, list/public_lines, list/private_lines)
	if(!user || !length(public_lines))
		return

	var/public_line = pick(public_lines)
	if(length(private_lines))
		user.visible_message(public_line, pick(private_lines))
	else
		user.visible_message(public_line)

/proc/dk_show_overhead(mob/living/target, icon_state, color, duration = 0.8 SECONDS, y_offset = 20, x_offset = 0)
	if(!target || !icon_state)
		return

	var/atom/visual = target.play_overhead_indicator_flick('modular_twilight_axis/icons/roguetown/misc/roninspells.dmi', icon_state, duration, ABOVE_MOB_LAYER + 0.3, null, y_offset, x_offset)
	if(visual && color)
		visual.add_atom_colour(color, FIXED_COLOUR_PRIORITY)

/proc/dk_spawn_fx(atom/target, icon_state = "curseblob", color = "#7b2cff", dir_override = null, duration = 0.6 SECONDS, pixel_y = null)
	var/turf/T = get_turf(target)
	if(!T)
		return
	new /obj/effect/temp_visual/dead_knight_fx(T, color, icon_state, dir_override, duration, pixel_y)

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
	dk_show_message(
		user,
		list(
			span_danger("[user] draws a wet crimson rune through the air."),
			span_danger("[user]'s blade drinks at the scent of blood."),
			span_danger("Blood-red runes crawl along [user]'s blade.")
		),
		list(
			span_danger("Blood answers the blade."),
			span_danger("The rune drinks. Blood gathers."),
			span_danger("You carve the first blood rune.")
		)
	)
	dk_show_overhead(user, "cut_horizontal", "#b5122b")
	dk_spawn_fx(user, "curseblob", "#b5122b", user.dir, 0.5 SECONDS)
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
	dk_show_message(
		user,
		list(
			span_notice("A pale frost-rune flashes over [user]'s guard."),
			span_notice("[user]'s blade exhales a knife-cold mist."),
			span_notice("Rime gathers along [user]'s runic edge.")
		),
		list(
			span_notice("Ice locks into the rune."),
			span_notice("The cold steadies your hand."),
			span_notice("You carve the frost rune.")
		)
	)
	dk_show_overhead(user, "cut_vertical", "#66d9ff")
	dk_spawn_fx(user, "shieldsparkles", "#66d9ff", user.dir, 0.5 SECONDS)
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
	dk_show_message(
		user,
		list(
			span_boldwarning("[user] stains the air with an unholy sigil."),
			span_boldwarning("A profane whisper coils around [user]'s blade."),
			span_boldwarning("[user]'s runes flare with grave-light.")
		),
		list(
			span_boldwarning("Unholy power answers."),
			span_boldwarning("The dead rune wakes."),
			span_boldwarning("You carve the profane rune.")
		)
	)
	dk_show_overhead(user, "cut_diagonal", "#8f3cff")
	dk_spawn_fx(user, "curse", "#8f3cff", user.dir, 0.5 SECONDS)
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

	if(target.has_status_effect(/datum/status_effect/debuff/dk_plague_mark))
		to_chat(user, span_warning("[target] already bears your plague mark."))
		return

	stacks.consume_unholy(2)
	stacks.consume_blood(1)

	target.apply_status_effect(/datum/status_effect/debuff/dk_plague_mark, user)
	dk_show_message(
		user,
		list(
			span_danger("[user] brands [target] with a sickly plague sigil!"),
			span_danger("[user] draws a rotten rune over [target]'s head!"),
			span_danger("A carrion-green mark blooms above [target] at [user]'s command!")
		),
		list(
			span_danger("You mark [target] with the plague sigil."),
			span_danger("The plague rune takes hold on [target]."),
			span_danger("Your sigil sinks into [target]'s flesh.")
		)
	)
	dk_show_overhead(target, "cut_diagonal", "#4fbf4f", 1.2 SECONDS, 22)
	dk_spawn_fx(target, "curseblob", "#4fbf4f", null, 0.8 SECONDS, 10)

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
		dk_show_overhead(L, "cut_horizontal", "#b5122b", 0.7 SECONDS, 18)
		dk_spawn_fx(L, "curseblob", "#b5122b", null, 0.6 SECONDS)
		total_heal += drain * 0.6
		hit_count++

	if(hit_count <= 0)
		to_chat(user, span_warning("No enemies nearby to drain."))
		return

	stacks.consume_blood(3)
	user.adjustBruteLoss(-total_heal)
	to_chat(user, span_notice("The blood worms return, restoring [round(total_heal)] health from [hit_count] victims."))
	dk_show_message(
		user,
		list(
			span_danger("Crimson worms writhe around [user], draining nearby victims!"),
			span_danger("The ground under [user] splits and blood-worms surge outward!"),
			span_danger("[user]'s rune calls a hungry tide of blood-worms!")
		),
		list(
			span_notice("The worms return full and warm."),
			span_notice("Stolen blood seals your wounds."),
			span_notice("The blood rune feeds you.")
		)
	)
	dk_show_overhead(user, "cut_horizontal", "#b5122b", 0.8 SECONDS, 22)

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
	dk_show_message(
		user,
		list(
			span_danger("A nightmarish steed erupts from dark mist at [user]'s command!"),
			span_danger("Hooves hammer from the grave as [user] calls a death horse!"),
			span_danger("Black mist tears open and a death horse answers [user]!")
		),
		list(
			span_danger("You call forth your death horse."),
			span_danger("Your steed claws its way back to you."),
			span_danger("The grave yields your mount.")
		)
	)
	dk_show_overhead(user, "blade_path", "#7b2cff", 1 SECONDS, 22)
	dk_spawn_fx(T, "curseblob", "#4a0080", null, 1 SECONDS)

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
	dk_show_message(
		user,
		list(
			span_notice("Runic ice locks around [user] like a tomb."),
			span_notice("A frostbound bulwark closes over [user]."),
			span_notice("[user] roots in place as ice-runes harden over them.")
		),
		list(
			span_notice("The ice accepts your oath. You will not be moved."),
			span_notice("You seal yourself in runic ice."),
			span_notice("Cold iron stillness takes you.")
		)
	)
	dk_show_overhead(user, "cut_vertical", "#66d9ff", 1 SECONDS, 22)
	dk_spawn_fx(user, "shieldsparkles", "#66d9ff", null, 0.9 SECONDS, 8)

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

	dk_show_message(
		user,
		list(
			span_userdanger("[user] raises a gauntleted hand. The ground cracks open and skeletons claw their way out!"),
			span_userdanger("[user] calls the old dead to war, and the earth answers!"),
			span_userdanger("Grave-runes blaze around [user] as skeletons claw upward!")
		),
		list(
			span_danger("Rise. March. Kill."),
			span_danger("The dead remember your command."),
			span_danger("You drag soldiers from the dark.")
		)
	)
	dk_show_overhead(user, "blade_bind", "#8f3cff", 1.2 SECONDS, 24)

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
		dk_spawn_fx(spawn_turf, "curseblob", "#7b2cff", null, 0.8 SECONDS)
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
