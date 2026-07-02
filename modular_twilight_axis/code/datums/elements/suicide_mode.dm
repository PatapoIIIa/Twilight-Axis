#define SUICIDE_MODE_TRAIT "suicide_mode"
#define SUICIDE_MODE_DUST_SOURCE "suicide_mode_elemental_death"

#define SUICIDE_MAGIC_GENERIC 0
#define SUICIDE_MAGIC_FIRE 1
#define SUICIDE_MAGIC_ICE 2
#define SUICIDE_MAGIC_LIGHTNING 3

#define SUICIDE_UNARMED_STRANGLE 1
#define SUICIDE_UNARMED_NECK_SNAP 2
#define SUICIDE_UNARMED_EYES 3
#define SUICIDE_UNARMED_TONGUE 4
#define SUICIDE_UNARMED_SKULL 5

#define SUICIDE_INTERVENTION_RANGE 7

/datum/status_effect/freon/suicide
	duration = 10 MINUTES
	can_melt = FALSE

/atom/movable/screen/alert/status_effect/debuff/suicide_intervention
	name = "Моя жизнь кому-то очень важна, я не могу легко уйти прямо сейчас"
	desc = "Моя жизнь кому-то очень важна, я не могу легко уйти прямо сейчас"
	icon = 'icons/mob/screen_alert_combat.dmi'
	icon_state = "clash"

/datum/status_effect/debuff/suicide_intervention
	id = "suicide_intervention"
	duration = 10 MINUTES
	status_type = STATUS_EFFECT_UNIQUE
	alert_type = /atom/movable/screen/alert/status_effect/debuff/suicide_intervention

/datum/status_effect/debuff/suicide_intervention/on_apply()
	. = ..()
	to_chat(owner, span_warning("Моя жизнь кому-то очень важна, я не могу легко уйти прямо сейчас"))
	return TRUE

/mob/living/carbon/human/canSuicide()
	if(has_status_effect(/datum/status_effect/debuff/suicide_intervention))
		to_chat(src, span_warning("Моя жизнь кому-то очень важна, я не могу легко уйти прямо сейчас"))
		return FALSE
	return ..()

/mob/living/carbon/human/proc/apply_suicide_intervention_if_needed()
	if(!mind)
		return FALSE
	for(var/mob/living/nearby in view(SUICIDE_INTERVENTION_RANGE, src))
		if(nearby == src || nearby.stat == DEAD || !nearby.cmode)
			continue
		if(!isnum(mind.attackedme[nearby.real_name]))
			continue
		apply_status_effect(/datum/status_effect/debuff/suicide_intervention)
		return TRUE
	return FALSE

/proc/twilight_try_suicide_prop_use(obj/item/prop, mob/user)
	if(!ishuman(user) || !HAS_TRAIT(user, SUICIDE_MODE_TRAIT))
		return FALSE
	return SEND_SIGNAL(user, COMSIG_MOB_SUICIDE_PROP_USED, prop)

/obj/item/rope/attack_self(mob/user)
	if(twilight_try_suicide_prop_use(src, user))
		return
	return ..()

/obj/item/clothing/neck/cloak/attack_self(mob/user)
	if(twilight_try_suicide_prop_use(src, user))
		return
	return ..()

/obj/item/storage/belt/attack_self(mob/user)
	if(twilight_try_suicide_prop_use(src, user))
		return
	return ..()

/mob/living/carbon/human/verb/toggle_suicide_mode()
	set name = "Подготовить последний акт"
	set category = "IC"
	set desc = "Подготовить или отменить последний осознанный акт саморазрушения."

	if(HAS_TRAIT(src, SUICIDE_MODE_TRAIT))
		RemoveElement(/datum/element/suicide_mode, src)
		to_chat(src, span_notice("Я отступаю от края. Последний акт отменён."))
		return

	if(!canSuicide())
		return

	if(apply_suicide_intervention_if_needed())
		return

	var/old_key = ckey
	var/confirmation = alert(src, "Мой следующий осознанный акт саморазрушения станет последним и катастрофическим. Продолжить?", "Последний акт", "Да", "Нет")
	if(ckey != old_key || confirmation != "Да" || !canSuicide())
		return
	if(apply_suicide_intervention_if_needed())
		return

	AddElement(/datum/element/suicide_mode, src)
	to_chat(src, span_userdanger("Выбор сделан. Моё следующее осознанное действие против себя станет последним."))

/datum/element/suicide_mode
	element_flags = ELEMENT_BESPOKE | ELEMENT_DETACH
	argument_hash_start_idx = 2
	var/datum/suicide_trauma/trauma_handler
	var/list/self_cast_spells
	var/list/tracked_items
	var/list/tracked_buckles
	var/turf/last_turf

/datum/element/suicide_mode/Attach(datum/target, datum/identity)
	. = ..()
	if(target != identity || !ishuman(target))
		return ELEMENT_INCOMPATIBLE
	if(!trauma_handler)
		trauma_handler = new

	var/mob/living/carbon/human/human_target = target
	ADD_TRAIT(human_target, SUICIDE_MODE_TRAIT, type)
	RegisterSignal(human_target, COMSIG_MOVABLE_TURF_ENTERED, PROC_REF(on_turf_entered))
	RegisterSignal(human_target, COMSIG_MOVABLE_Z_CHANGED, PROC_REF(on_z_changed))
	RegisterSignal(human_target, COMSIG_ITEM_ATTACKED_SUCCESS, PROC_REF(on_item_attack))
	RegisterSignal(human_target, COMSIG_ATOM_BULLET_ACT, PROC_REF(on_projectile_hit))
	RegisterSignal(human_target, COMSIG_MOB_AFTER_SPELL_CAST, PROC_REF(on_modern_spell_cast))
	RegisterSignal(human_target, COMSIG_MOB_LEGACY_SPELL_CAST, PROC_REF(on_legacy_spell_cast))
	RegisterSignal(human_target, COMSIG_MOB_ATTACKED_BY_HAND, PROC_REF(on_unarmed_attack))
	RegisterSignal(human_target, COMSIG_LIVING_IGNITED, PROC_REF(on_ignited))
	RegisterSignal(human_target, COMSIG_MOB_EQUIPPED_ITEM, PROC_REF(on_item_equipped))
	RegisterSignal(human_target, COMSIG_MOB_SUICIDE_PROP_USED, PROC_REF(on_suicide_prop_used))
	last_turf = get_turf(human_target)
	track_inventory_items(human_target)
	track_buckle_sources(last_turf)
	enable_spell_self_cast(human_target)
	addtimer(CALLBACK(src, PROC_REF(check_current_buckle), WEAKREF(human_target)), world.tick_lag)

/datum/element/suicide_mode/Detach(mob/living/carbon/human/source, ...)
	REMOVE_TRAIT(source, SUICIDE_MODE_TRAIT, type)
	UnregisterSignal(source, list(
		COMSIG_MOVABLE_TURF_ENTERED,
		COMSIG_MOVABLE_Z_CHANGED,
		COMSIG_ITEM_ATTACKED_SUCCESS,
		COMSIG_ATOM_BULLET_ACT,
		COMSIG_MOB_AFTER_SPELL_CAST,
		COMSIG_MOB_LEGACY_SPELL_CAST,
		COMSIG_MOB_ATTACKED_BY_HAND,
		COMSIG_LIVING_IGNITED,
		COMSIG_MOB_EQUIPPED_ITEM,
		COMSIG_MOB_SUICIDE_PROP_USED,
	))
	untrack_inventory_items()
	untrack_buckle_sources()
	last_turf = null
	disable_spell_self_cast(source)
	return ..()

/datum/element/suicide_mode/proc/enable_spell_self_cast(mob/living/carbon/human/source)
	self_cast_spells = list()
	for(var/datum/action/cooldown/spell/spell in source.actions)
		if(!spell.click_to_activate || spell.self_cast_possible)
			continue
		spell.self_cast_possible = TRUE
		self_cast_spells += WEAKREF(spell)

/datum/element/suicide_mode/proc/disable_spell_self_cast(mob/living/carbon/human/source)
	for(var/datum/weakref/spell_ref as anything in self_cast_spells)
		var/datum/action/cooldown/spell/spell = spell_ref.resolve()
		if(spell)
			spell.self_cast_possible = FALSE
	self_cast_spells = null

/datum/element/suicide_mode/proc/on_turf_entered(mob/living/carbon/human/source, turf/new_turf)
	SIGNAL_HANDLER

	var/turf/old_turf = last_turf
	last_turf = new_turf
	track_buckle_sources(new_turf)
	var/entered_deep_water = is_suicide_deep_water(new_turf) && !is_suicide_deep_water(old_turf)

	if(istype(new_turf, /turf/open/lava/acid))
		commit_mode(source, "погружение в кислоту", CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_acid_death), WEAKREF(source)))
		return

	if(islava(new_turf))
		commit_mode(source, "погружение в лаву", CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_lava_death), WEAKREF(source)))
		return

	if(entered_deep_water)
		commit_mode(source, "падение в воду", CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_water_death), WEAKREF(source)))
		return

	for(var/obj/item/restraints/legcuffs/beartrap/trap in new_turf)
		if(!trap.armed)
			continue
		var/zone = pick(BODY_ZONE_PRECISE_L_FOOT, BODY_ZONE_PRECISE_R_FOOT)
		commit_mode(source, "шаг в капкан", CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_mantrap_trauma), WEAKREF(source), zone))
		return

/datum/element/suicide_mode/proc/on_z_changed(mob/living/carbon/human/source, old_z, new_z)
	SIGNAL_HANDLER

	if(!source.is_jumping || new_z >= old_z)
		return
	addtimer(CALLBACK(src, PROC_REF(resolve_fall), WEAKREF(source)), world.tick_lag)

/datum/element/suicide_mode/proc/resolve_fall(datum/weakref/source_ref)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || !HAS_TRAIT(source, SUICIDE_MODE_TRAIT))
		return

	var/turf/landing = get_turf(source)
	if(istype(landing, /turf/open/lava/acid))
		commit_mode(source, "погружение в кислоту", CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_acid_death), WEAKREF(source)))
		return
	if(islava(landing))
		commit_mode(source, "погружение в лаву", CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_lava_death), WEAKREF(source)))
		return
	if(istype(landing, /turf/open/water))
		commit_mode(source, "падение в воду", CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_water_death), WEAKREF(source)))
		return
	commit_mode(source, "прыжок с высоты", CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_fall_trauma), WEAKREF(source)))

/datum/element/suicide_mode/proc/on_item_attack(mob/living/carbon/human/source, obj/item/weapon, mob/living/attacker)
	SIGNAL_HANDLER

	if(attacker != source)
		return

	var/zone = source.zone_selected || BODY_ZONE_CHEST
	var/bclass = source.used_intent?.blade_class || BCLASS_BLUNT
	var/weapon_name = weapon?.name || "оружие"
	if(weapon && weapon.get_temperature() >= FIRE_MINIMUM_TEMPERATURE_TO_EXIST)
		bclass = BCLASS_BURN
	commit_mode(
		source,
		"атака себя предметом [weapon_name]",
		CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_targeted_trauma), WEAKREF(source), zone, bclass, weapon_name),
	)

/datum/element/suicide_mode/proc/on_projectile_hit(mob/living/carbon/human/source, obj/projectile/projectile, def_zone)
	SIGNAL_HANDLER

	if(projectile.firer != source)
		return

	var/projectile_name = projectile.name
	if(istype(projectile, /obj/projectile/magic))
		var/magic_kind = trauma_handler.get_magic_kind(projectile)
		var/starting_fire_stacks = source.fire_stacks
		commit_mode(
			source,
			"попадание собственной магией [projectile_name]",
			CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_magic_trauma), WEAKREF(source), magic_kind, projectile_name, starting_fire_stacks),
		)
		return

	var/zone = def_zone || source.zone_selected || BODY_ZONE_CHEST
	var/bclass = projectile.woundclass || ((projectile.damage_type == BURN) ? BCLASS_BURN : BCLASS_PIERCE)
	commit_mode(
		source,
		"выстрел в себя из [projectile_name]",
		CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_targeted_trauma), WEAKREF(source), zone, bclass, projectile_name),
	)

/datum/element/suicide_mode/proc/on_modern_spell_cast(mob/living/carbon/human/source, datum/action/cooldown/spell/spell, atom/cast_on)
	SIGNAL_HANDLER

	if(cast_on != source || !is_harmful_modern_spell(spell))
		return

	var/magic_kind = trauma_handler.get_magic_kind(spell)
	var/starting_fire_stacks = source.fire_stacks
	commit_mode(
		source,
		"применение [spell] на себя",
		CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_magic_trauma), WEAKREF(source), magic_kind, spell.name, starting_fire_stacks),
	)

/datum/element/suicide_mode/proc/is_harmful_modern_spell(datum/action/cooldown/spell/spell)
	if(istype(spell, /datum/action/cooldown/spell/projectile))
		var/datum/action/cooldown/spell/projectile/projectile_spell = spell
		if(projectile_spell.projectile_type && initial(projectile_spell.projectile_type.damage) > 0)
			return TRUE
	if(spell.displayed_damage > 0)
		return TRUE
	return FALSE

/datum/element/suicide_mode/proc/on_legacy_spell_cast(mob/living/carbon/human/source, obj/effect/proc_holder/spell/spell, list/targets)
	SIGNAL_HANDLER

	if(!islist(targets) || !(source in targets) || !is_harmful_legacy_spell(spell))
		return

	var/magic_kind = trauma_handler.get_magic_kind(spell)
	var/starting_fire_stacks = source.fire_stacks
	commit_mode(
		source,
		"применение [spell] на себя",
		CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_magic_trauma), WEAKREF(source), magic_kind, spell.name, starting_fire_stacks),
	)

/datum/element/suicide_mode/proc/is_harmful_legacy_spell(obj/effect/proc_holder/spell/spell)
	return istype(spell, /obj/effect/proc_holder/spell/invoked/projectile) \
		|| istype(spell, /obj/effect/proc_holder/spell/targeted/projectile) \
		|| istype(spell, /obj/effect/proc_holder/spell/aimed)

/datum/element/suicide_mode/proc/on_unarmed_attack(mob/living/carbon/human/source, mob/living/carbon/human/attacker, mob/living/carbon/human/target)
	SIGNAL_HANDLER

	if(attacker != source || target != source || source.used_intent.type == INTENT_HELP)
		return

	var/unarmed_kind = SUICIDE_UNARMED_SKULL
	var/zone = source.zone_selected
	if(zone == BODY_ZONE_PRECISE_NECK)
		unarmed_kind = source.used_intent.type == INTENT_GRAB ? SUICIDE_UNARMED_STRANGLE : SUICIDE_UNARMED_NECK_SNAP
	else if(zone == BODY_ZONE_PRECISE_L_EYE || zone == BODY_ZONE_PRECISE_R_EYE)
		unarmed_kind = SUICIDE_UNARMED_EYES
	else if(zone == BODY_ZONE_PRECISE_MOUTH)
		unarmed_kind = SUICIDE_UNARMED_TONGUE

	commit_mode(
		source,
		"обращение голых рук против себя",
		CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_unarmed_trauma), WEAKREF(source), unarmed_kind),
	)

/datum/element/suicide_mode/proc/on_ignited(mob/living/carbon/human/source)
	SIGNAL_HANDLER

	var/on_pyre = istype(source.buckled, /obj/machinery/light/rogue/campfire/pyre)
	var/obj/item/held_item = source.get_active_held_item()
	if(!on_pyre && (!held_item || held_item.get_temperature() < FIRE_MINIMUM_TEMPERATURE_TO_EXIST))
		return
	commit_mode(
		source,
		on_pyre ? "восхождение на горящий погребальный костёр" : "самосожжение",
		CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_immolation_trauma), WEAKREF(source), on_pyre, "пламя"),
	)

/datum/element/suicide_mode/proc/on_item_equipped(mob/living/carbon/human/source, obj/item/item, slot)
	SIGNAL_HANDLER

	track_item(item)

/datum/element/suicide_mode/proc/track_inventory_items(mob/living/carbon/human/source)
	tracked_items = list()
	for(var/obj/item/item in source.contents)
		track_item(item)

/datum/element/suicide_mode/proc/track_item(obj/item/item)
	if(!istype(item, /obj/item/reagent_containers) && !istype(item, /obj/item/bomb))
		return
	if(item in tracked_items)
		return

	tracked_items += item
	if(istype(item, /obj/item/reagent_containers))
		RegisterSignal(item, COMSIG_ITEM_PRE_ATTACK, PROC_REF(on_reagent_container_used))
	if(istype(item, /obj/item/bomb))
		RegisterSignal(item, COMSIG_ITEM_AFTERATTACK, PROC_REF(on_bomb_afterattack))
		RegisterSignal(item, COMSIG_PARENT_ATTACKBY, PROC_REF(on_bomb_attacked))

/datum/element/suicide_mode/proc/untrack_inventory_items()
	for(var/obj/item/item as anything in tracked_items)
		if(QDELETED(item))
			continue
		UnregisterSignal(item, list(COMSIG_ITEM_PRE_ATTACK, COMSIG_ITEM_AFTERATTACK, COMSIG_PARENT_ATTACKBY))
	tracked_items = null

/datum/element/suicide_mode/proc/on_reagent_container_used(obj/item/reagent_containers/container, atom/target, mob/living/user, params)
	SIGNAL_HANDLER

	if(target != user || !ishuman(user) || !HAS_TRAIT(user, SUICIDE_MODE_TRAIT))
		return
	var/mob/living/carbon/human/source = user
	var/poison_name = get_dominant_harmful_reagent_name(container.reagents)
	if(!poison_name)
		return

	var/delay = 1 SECONDS
	if(istype(container, /obj/item/reagent_containers/pill))
		var/obj/item/reagent_containers/pill/pill = container
		delay = max(delay, pill.self_delay + world.tick_lag)
	var/previous_volume = get_harmful_reagent_volume(source)
	addtimer(CALLBACK(src, PROC_REF(verify_poison_use), WEAKREF(source), previous_volume, poison_name), delay)

/datum/element/suicide_mode/proc/verify_poison_use(datum/weakref/source_ref, previous_volume, poison_name)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || !HAS_TRAIT(source, SUICIDE_MODE_TRAIT))
		return
	if(get_harmful_reagent_volume(source) <= previous_volume + 0.01)
		return
	commit_mode(
		source,
		"принятие яда [poison_name]",
		CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_poison_trauma), WEAKREF(source), poison_name),
	)

/datum/element/suicide_mode/proc/on_bomb_afterattack(obj/item/bomb/bomb, atom/target, mob/user, proximity_flag, click_parameters)
	SIGNAL_HANDLER

	queue_bomb_check(bomb, user)

/datum/element/suicide_mode/proc/on_bomb_attacked(obj/item/bomb/bomb, obj/item/ignition_source, mob/user, params)
	SIGNAL_HANDLER

	queue_bomb_check(bomb, user)

/datum/element/suicide_mode/proc/queue_bomb_check(obj/item/bomb/bomb, mob/user)
	if(!ishuman(user) || !HAS_TRAIT(user, SUICIDE_MODE_TRAIT))
		return
	addtimer(CALLBACK(src, PROC_REF(verify_bomb_use), WEAKREF(bomb), WEAKREF(user)), world.tick_lag)

/datum/element/suicide_mode/proc/verify_bomb_use(datum/weakref/bomb_ref, datum/weakref/source_ref)
	var/obj/item/bomb/bomb = bomb_ref.resolve()
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!bomb || !source || !HAS_TRAIT(source, SUICIDE_MODE_TRAIT))
		return
	if(!bomb.lit || !(bomb in source.contents))
		return
	commit_mode(
		source,
		"удерживание зажжённой алхимической бомбы",
		CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_bomb_trauma), WEAKREF(source), WEAKREF(bomb)),
	)

/datum/element/suicide_mode/proc/track_buckle_sources(turf/current_turf)
	untrack_buckle_sources()
	tracked_buckles = list()
	if(!current_turf)
		return
	for(var/atom/movable/buckle_source in current_turf)
		if(!istype(buckle_source, /obj/machinery/light/rogue/campfire/pyre) && !istype(buckle_source, /obj/structure/meathook))
			continue
		tracked_buckles += buckle_source
		RegisterSignal(buckle_source, COMSIG_MOVABLE_BUCKLE, PROC_REF(on_buckled))

/datum/element/suicide_mode/proc/untrack_buckle_sources()
	for(var/atom/movable/buckle_source as anything in tracked_buckles)
		if(!QDELETED(buckle_source))
			UnregisterSignal(buckle_source, COMSIG_MOVABLE_BUCKLE)
	tracked_buckles = null

/datum/element/suicide_mode/proc/on_buckled(atom/movable/buckle_source, mob/living/buckled_mob, force)
	SIGNAL_HANDLER

	if(!ishuman(buckled_mob) || !HAS_TRAIT(buckled_mob, SUICIDE_MODE_TRAIT))
		return
	resolve_buckle(buckled_mob, buckle_source)

/datum/element/suicide_mode/proc/check_current_buckle(datum/weakref/source_ref)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || !HAS_TRAIT(source, SUICIDE_MODE_TRAIT) || !source.buckled)
		return
	resolve_buckle(source, source.buckled)

/datum/element/suicide_mode/proc/resolve_buckle(mob/living/carbon/human/source, atom/movable/buckle_source)
	if(istype(buckle_source, /obj/machinery/light/rogue/campfire/pyre))
		var/obj/machinery/light/rogue/campfire/pyre/pyre = buckle_source
		if(!pyre.on)
			return FALSE
		return commit_mode(
			source,
			"восхождение на горящий погребальный костёр",
			CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_immolation_trauma), WEAKREF(source), TRUE, pyre.name),
		)
	if(istype(buckle_source, /obj/structure/meathook))
		return commit_mode(source, "жертва мясницкому крюку", CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_meathook_trauma), WEAKREF(source)))
	return FALSE

/datum/element/suicide_mode/proc/on_suicide_prop_used(mob/living/carbon/human/source, obj/item/prop)
	SIGNAL_HANDLER

	if(!istype(prop, /obj/item/rope) && !istype(prop, /obj/item/clothing/neck/cloak) && !istype(prop, /obj/item/storage/belt))
		return FALSE
	return commit_mode(
		source,
		"изготовление петли из [prop]",
		CALLBACK(trauma_handler, TYPE_PROC_REF(/datum/suicide_trauma, apply_hanging_trauma), WEAKREF(source), prop.name),
	)

/datum/element/suicide_mode/proc/is_suicide_deep_water(turf/target)
	return istype(target, /turf/open/water/ocean/deep) || istype(target, /turf/open/water/swamp/deep)

/datum/element/suicide_mode/proc/get_harmful_reagent_volume(mob/living/carbon/human/source)
	var/total_volume = 0
	for(var/datum/reagent/reagent as anything in source.reagents?.reagent_list)
		if(reagent.harmful)
			total_volume += reagent.volume
	return total_volume

/datum/element/suicide_mode/proc/get_dominant_harmful_reagent_name(datum/reagents/reagents)
	var/datum/reagent/dominant_reagent
	for(var/datum/reagent/reagent as anything in reagents?.reagent_list)
		if(!reagent.harmful)
			continue
		if(!dominant_reagent || reagent.volume > dominant_reagent.volume)
			dominant_reagent = reagent
	return dominant_reagent?.name

/datum/element/suicide_mode/proc/commit_mode(mob/living/carbon/human/source, method, datum/callback/consequence)
	if(!HAS_TRAIT(source, SUICIDE_MODE_TRAIT) || !consequence)
		return FALSE

	source.RemoveElement(/datum/element/suicide_mode, source)
	addtimer(CALLBACK(src, PROC_REF(execute_consequence), WEAKREF(source), method, consequence), world.tick_lag)
	return TRUE

/datum/element/suicide_mode/proc/execute_consequence(datum/weakref/source_ref, method, datum/callback/consequence)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source) || !consequence)
		return
	source.set_suicide(TRUE)
	source.log_message("запустил режим самоубийства: [method]", LOG_ATTACK)
	source.suicide_log()
	consequence.Invoke()

/datum/suicide_trauma/proc/is_show_death(mob/living/carbon/human/source)
	return HAS_TRAIT(source, TRAIT_CRITICAL_WEAKNESS) || HAS_TRAIT(source, TRAIT_DNR)

/datum/suicide_trauma/proc/announce_trauma(mob/living/carbon/human/source, normal_message, show_message, self_message)
	var/show_death = is_show_death(source)
	var/public_message = show_death ? show_message : normal_message
	if(show_death)
		if(HAS_TRAIT(source, TRAIT_CRITICAL_WEAKNESS))
			public_message += " Катастрофически хрупкое тело превращает эту травму в чудовищное зрелище!"
		if(HAS_TRAIT(source, TRAIT_DNR))
			public_message += " Люкс гаснет в тот же миг, не оставляя пути обратно к жизни!"
	source.visible_message(
		span_bigbold(span_crit(public_message)),
		span_bigbold(span_userdanger(self_message))
	)

/datum/suicide_trauma/proc/create_bloodbath(mob/living/carbon/human/source, spectacular = FALSE)
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

/datum/suicide_trauma/proc/ruin_organ(mob/living/carbon/human/source, organ_slot)
	var/obj/item/organ/organ = source.getorganslot(organ_slot)
	if(!organ)
		return
	organ.applyOrganDamage(organ.maxHealth)
	organ.organ_flags |= ORGAN_FAILING
	if(organ_slot == ORGAN_SLOT_HEART)
		source.set_heartattack(TRUE)

/datum/suicide_trauma/proc/ruin_internal_organs(mob/living/carbon/human/source, include_brain = FALSE)
	for(var/obj/item/organ/organ as anything in source.internal_organs)
		if(!include_brain && organ.slot == ORGAN_SLOT_BRAIN)
			continue
		organ.applyOrganDamage(organ.maxHealth)
		organ.organ_flags |= ORGAN_FAILING
	source.set_heartattack(TRUE)

/datum/suicide_trauma/proc/damage_every_bodypart(mob/living/carbon/human/source, brute_damage, burn_damage)
	for(var/obj/item/bodypart/bodypart as anything in source.bodyparts)
		bodypart.receive_damage(brute_damage, burn_damage, 0, 0, FALSE)
	source.updatehealth()
	source.update_damage_overlays()

/datum/suicide_trauma/proc/fracture_every_bodypart(mob/living/carbon/human/source)
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

/datum/suicide_trauma/proc/apply_hanging_trauma(datum/weakref/source_ref, prop_name)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	var/show_death = is_show_death(source)
	announce_trauma(
		source,
		"[source] свивает из [prop_name] петлю, затягивает её и отдаёт ей вес своего тела!",
		"[source] бросается в петлю из [prop_name]; узел затягивается резко, словно приговор палача!",
		"Я отдаю свой вес узлу. Мир сужается до верёвки и тьмы."
	)
	playsound(source, 'sound/foley/noosed.ogg', 120, FALSE)
	var/obj/item/bodypart/head = source.get_bodypart(BODY_ZONE_HEAD)
	head?.add_wound(/datum/wound/fracture/neck/shatter)
	source.setOxyLoss(max(source.getOxyLoss(), source.maxHealth + 50))
	source.Paralyze(2 MINUTES)
	if(show_death)
		create_bloodbath(source, TRUE)
		if(head && !head.dismember(BRUTE, BCLASS_CHOP, source, BODY_ZONE_PRECISE_NECK, 999, vorpal = TRUE, skip_checks = TRUE))
			source.death()

/datum/suicide_trauma/proc/apply_unarmed_trauma(datum/weakref/source_ref, unarmed_kind)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	var/show_death = is_show_death(source)
	var/obj/item/bodypart/head = source.get_bodypart(BODY_ZONE_HEAD)
	switch(unarmed_kind)
		if(SUICIDE_UNARMED_STRANGLE)
			announce_trauma(
				source,
				"[source] смыкает обе руки на собственном горле и лишает тело следующего вдоха!",
				"Пальцы [source] впиваются в собственное горло, пока дыхание, голос и люкс не угасают вместе!",
				"Я не ослабляю хватку, вопреки каждому порыву вдохнуть."
			)
			source.setOxyLoss(max(source.getOxyLoss(), source.maxHealth + 50))
			source.Paralyze(2 MINUTES)
			if(show_death && source.stat != DEAD)
				source.death()
			return

		if(SUICIDE_UNARMED_NECK_SNAP)
			announce_trauma(
				source,
				"[source] хватается за собственную голову и выворачивает её, пока шея не сдаётся с сухим хрустом!",
				"[source] сворачивает себе шею с уверенностью палача; позвоночник лопается под кожей!",
				"Я поворачиваю дальше боли и сопротивления, пока моя шея не ломается."
			)
			head?.add_wound(/datum/wound/fracture/neck/shatter)
			ruin_organ(source, ORGAN_SLOT_BRAIN)

		if(SUICIDE_UNARMED_EYES)
			announce_trauma(
				source,
				"[source] вдавливает большие пальцы в собственные глаза и дальше, сквозь истерзанные глазницы!",
				"[source] разрывает оба глаза в кровавом, осознанном порыве и дробит кость за ними!",
				"Я давлю дальше зрения, в темноту за ним."
			)
			head?.add_wound(/datum/wound/fracture/head/eyes)
			head?.add_wound(/datum/wound/fracture/head/brain/shatter)
			ruin_organ(source, ORGAN_SLOT_EYES)
			ruin_organ(source, ORGAN_SLOT_BRAIN)

		if(SUICIDE_UNARMED_TONGUE)
			announce_trauma(
				source,
				"[source] перекусывает собственный язык и топит последние слова в крови!",
				"[source] отрывает язык зубами; алая кровь заполняет рот и лёгкие!",
				"Я сжимаю зубы, пока речь не обрывается и кровь не занимает место дыхания."
			)
			head?.add_wound(/datum/wound/fracture/mouth)
			ruin_organ(source, ORGAN_SLOT_TONGUE)
			source.setOxyLoss(max(source.getOxyLoss(), source.maxHealth + 50))

		else
			announce_trauma(
				source,
				"[source] бьётся собственным черепом о землю, пока кости не поддаются!",
				"[source] превращает собственную голову в месиво, достойное плахи палача!",
				"Я бьюсь снова и снова, пока за моими глазами ничего не остаётся."
			)
			head?.add_wound(/datum/wound/fracture/head/shatter)
			ruin_organ(source, ORGAN_SLOT_BRAIN)

	create_bloodbath(source, show_death)
	source.Unconscious(2 MINUTES)
	if(show_death)
		if(unarmed_kind == SUICIDE_UNARMED_SKULL || unarmed_kind == SUICIDE_UNARMED_EYES)
			source.gib()
		else if(source.stat != DEAD)
			source.death()

/datum/suicide_trauma/proc/apply_immolation_trauma(datum/weakref/source_ref, on_pyre = FALSE, fire_source = "пламя")
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	if(on_pyre)
		announce_trauma(
			source,
			"[source] принимает погребальный костёр; пламя восходит по телу золотым саваном, оставляя лишь пепел!",
			"[source] становится живым святым костра, венчанным огнём, а затем рассыпается священным прахом!",
			"Я отдаю плоть, имя и люкс ожидающему меня костру."
		)
	else
		announce_trauma(
			source,
			"[source] обращает [fire_source] на себя и стоит неподвижно, пока одежда превращается в погребальный костёр!",
			"[source] венчает себя пламенем [fire_source] и пылает, словно мученик из древней легенды!",
			"Я не бегу от пламени. Я позволяю ему положить мне конец."
	)
	playsound(source, 'sound/health/burning.ogg', 120, FALSE)
	source.emote("firescream", TRUE)
	damage_every_bodypart(source, 0, 200)
	source.adjust_fire_stacks(25)
	source.ignite_mob()
	ADD_TRAIT(source, TRAIT_DUSTABLE, SUICIDE_MODE_DUST_SOURCE)
	source.dust(just_ash = TRUE, drop_items = TRUE, force = TRUE)

/datum/suicide_trauma/proc/apply_mantrap_trauma(datum/weakref/source_ref, zone)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	var/show_death = is_show_death(source)
	var/obj/item/bodypart/target_part = source.get_bodypart(zone)
	var/limb_name = target_part?.name || "нога"
	announce_trauma(
		source,
		"[source] ставит [limb_name] в капкан и позволяет железным челюстям сомкнуться сквозь плоть и кость!",
		"[source] с силой наступает в капкан; его челюсти отрывают [limb_name] в фонтане крови!",
		"Я слышу, как срывается пружина. Железо смыкается, и нога перестаёт быть моей."
	)
	playsound(source, 'sound/items/beartrap.ogg', 130, FALSE)
	target_part?.add_wound(/datum/wound/fracture)
	target_part?.add_wound(/datum/wound/artery)
	target_part?.receive_damage(200, 0)
	if(target_part && !target_part.dismember(BRUTE, BCLASS_CHOP, source, target_part.body_zone, 999, skip_checks = TRUE))
		target_part.drop_limb()
	create_bloodbath(source, show_death)
	if(show_death && source.stat != DEAD)
		source.death()

/datum/suicide_trauma/proc/apply_meathook_trauma(datum/weakref/source_ref)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	var/show_death = is_show_death(source)
	announce_trauma(
		source,
		"[source] отдаёт свой вес мясницкому крюку; железо пробивает рёбра и вскрывает живот!",
		"[source] насаживается глубже на крюк, пока тот не выходит из груди под дождём крови и внутренностей!",
		"Я отдаю свой вес крюку и чувствую, как он проходит сквозь всё внутри."
	)
	playsound(source, 'sound/foley/butcher.ogg', 120, FALSE)
	var/obj/item/bodypart/chest = source.get_bodypart(BODY_ZONE_CHEST)
	chest?.add_wound(/datum/wound/artery/chest)
	chest?.add_wound(/datum/wound/slash/disembowel)
	ruin_internal_organs(source)
	create_bloodbath(source, show_death)
	source.Unconscious(2 MINUTES)
	if(show_death)
		var/obj/structure/meathook/hook = source.buckled
		hook?.unbuckle_mob(source, TRUE)
		source.gib()

/datum/suicide_trauma/proc/apply_bomb_trauma(datum/weakref/source_ref, datum/weakref/bomb_ref)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	var/show_death = is_show_death(source)
	announce_trauma(
		source,
		"[source] прижимает шипящую алхимическую бомбу к груди и ждёт, когда стекло распустится осколками!",
		"[source] обнимает зажжённую бомбу, словно возлюбленную; огонь, стекло и кровь расцветают в единый страшный миг!",
		"Я держу горящий фитиль у груди и жду последнего вздоха бутыли."
	)
	var/obj/item/bomb/bomb = bomb_ref.resolve()
	bomb?.explode(TRUE)
	if(QDELETED(source))
		return
	damage_every_bodypart(source, 250, 150)
	fracture_every_bodypart(source)
	ruin_internal_organs(source, include_brain = TRUE)
	create_bloodbath(source, show_death)
	if(show_death)
		source.gib()

/datum/suicide_trauma/proc/apply_poison_trauma(datum/weakref/source_ref, poison_name)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	var/show_death = is_show_death(source)
	announce_trauma(
		source,
		"[source] осушает [poison_name], не дрогнув; лицо бледнеет, пока отрава поражает каждый орган!",
		"[source] принимает [poison_name] как последнее причастие; вены чернеют, а с губ льются кровь и желчь!",
		"Я глотаю горькую отраву и чувствую, как её корни смыкаются вокруг сердца."
	)
	playsound(source, 'sound/magic/heartbeat.ogg', 100, FALSE)
	source.emote("paincrit", TRUE)
	source.add_nausea(30)
	source.vomit(blood = TRUE)
	source.setToxLoss(max(source.getToxLoss(), source.maxHealth + 50))
	ruin_internal_organs(source)
	source.Unconscious(2 MINUTES)
	if(show_death && source.stat != DEAD)
		source.death()

/datum/suicide_trauma/proc/apply_fall_trauma(datum/weakref/source_ref)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	var/show_death = is_show_death(source)
	announce_trauma(
		source,
		"[source] ударяется о землю с тошнотворным хрустом; череп, позвоночник, рёбра и конечности ломаются разом!",
		"[source] падает на землю, словно брошенная туша, и распадается во взрыве костей, органов и крови!",
		"Я ударяюсь о землю. Всё внутри меня ломается разом."
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

/datum/suicide_trauma/proc/apply_lava_death(datum/weakref/source_ref)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	announce_trauma(
		source,
		"[source] погружается в лаву и вспыхивает ревущим столбом огня, оставляя после себя лишь пепел!",
		"[source] касается лавы и взрывается подобно погребальному костру; белый силуэт вспыхивает и осыпается прахом!",
		"Лава поглощает меня целиком. Плоть, кости и мысли сгорают вместе."
	)
	playsound(source, 'sound/misc/lava_death.ogg', 140, FALSE)
	ADD_TRAIT(source, TRAIT_DUSTABLE, SUICIDE_MODE_DUST_SOURCE)
	source.dust(just_ash = TRUE, drop_items = TRUE, force = TRUE)

/datum/suicide_trauma/proc/apply_acid_death(datum/weakref/source_ref)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	announce_trauma(
		source,
		"[source] с яростным шипением растворяется в кислоте, пока не остаётся лишь дымящийся прах!",
		"[source] опадает пенящимся силуэтом, пока кислота за считанные мгновения пожирает плоть, органы и кости!",
		"Кислота разъедает всё моё тело разом. Я растворяюсь без остатка."
	)
	playsound(source, 'sound/misc/hiss.ogg', 120, FALSE)
	ADD_TRAIT(source, TRAIT_DUSTABLE, SUICIDE_MODE_DUST_SOURCE)
	source.dust(just_ash = TRUE, drop_items = TRUE, force = TRUE)

/datum/suicide_trauma/proc/apply_water_death(datum/weakref/source_ref)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	var/show_death = is_show_death(source)
	if(prob(50))
		announce_trauma(
			source,
			"[source] исчезает под водой; поток пузырей отмечает миг, когда лёгкие наполняются водой!",
			"[source] в судорогах скрывается под поверхностью, а последний выдох взрывается над водой короной пены!",
			"Вода заполняет мои лёгкие. Поверхность навсегда ускользает."
		)
		source.Knockdown(2 MINUTES)
		source.setOxyLoss(max(source.getOxyLoss(), source.maxHealth + 50))
		if(show_death && source.stat != DEAD)
			source.death()
		return

	announce_trauma(
		source,
		"[source] врезается в воду, словно в камень; удар сокрушает всё тело хором влажных хрустов!",
		"[source] ударяется о воду с такой силой, что поверхность окрашивается кровью, а тело складывается от удара!",
		"Я ударяюсь о воду всем телом. Каждая кость отвечает одновременно."
	)
	playsound(source, pick('sound/foley/water_land1.ogg', 'sound/foley/water_land2.ogg', 'sound/foley/water_land3.ogg'), 130, FALSE)
	damage_every_bodypart(source, 180, 0)
	fracture_every_bodypart(source)
	ruin_internal_organs(source, include_brain = TRUE)
	create_bloodbath(source, show_death)
	source.Unconscious(2 MINUTES)
	if(show_death)
		source.gib()

/datum/suicide_trauma/proc/apply_targeted_trauma(datum/weakref/source_ref, zone, bclass, weapon_name)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	var/show_death = is_show_death(source)
	var/obj/item/bodypart/target_part = source.get_bodypart(zone)
	var/body_zone = check_zone(zone)
	var/is_sharp = (bclass in GLOB.artery_bclasses)

	if(bclass == BCLASS_BURN)
		apply_immolation_trauma(source_ref, FALSE, weapon_name)
		return

	if(body_zone in list(BODY_ZONE_L_ARM, BODY_ZONE_R_ARM, BODY_ZONE_L_LEG, BODY_ZONE_R_LEG))
		var/limb_name = target_part?.name || "конечность"
		if(is_sharp)
			announce_trauma(
				source,
				"[source] вонзает [weapon_name] в собственную конечность ([limb_name]) и отсекает её фонтаном крови!",
				"[weapon_name] полностью отрывает конечность [source] ([limb_name]), и та улетает сквозь алую завесу!",
				"Я довожу удар до конца. Моя конечность ([limb_name]) остаётся у меня в руках."
			)
			if(target_part && !target_part.dismember(BRUTE, bclass, source, target_part.body_zone, 999, skip_checks = TRUE))
				target_part.drop_limb()
		else
			announce_trauma(
				source,
				"[source] бьёт собственную конечность ([limb_name]) предметом [weapon_name], пока кость не дробится, а артерия не лопается!",
				"[source] превращает конечность ([limb_name]) в кровавый шарнир из раздробленных костей под ударами [weapon_name]!",
				"Я бью, пока моя конечность ([limb_name]) не превращается в сломанную кость и текущую кровь."
			)
			target_part?.add_wound(/datum/wound/fracture)
			target_part?.add_wound(/datum/wound/artery)
			target_part?.receive_damage(200, 0)
		create_bloodbath(source, show_death)
		if(show_death && source.stat != DEAD)
			source.death()
		return

	var/obj/item/bodypart/head = source.get_bodypart(BODY_ZONE_HEAD)
	var/obj/item/bodypart/chest = source.get_bodypart(BODY_ZONE_CHEST)

	if(zone == BODY_ZONE_PRECISE_NECK)
		announce_trauma(
			source,
			is_sharp ? "[source] вскрывает себе горло предметом [weapon_name]; сонная артерия расходится алой завесой!" : "[source] вдавливает [weapon_name] в собственную шею, пока позвоночник не ломается!",
			is_sharp ? "[source] перерезает собственное горло так глубоко, что кровь окрашивает всё вокруг!" : "Шея [source] складывается с пушечным треском, а сломанный позвоночник проступает под кожей!",
			is_sharp ? "Я вскрываю себе горло и чувствую, как сердцебиение уходит через рану." : "Я провожу удар сквозь шею. Мой позвоночник ломается."
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
			"[source] вспарывает собственный живот предметом [weapon_name], роняя истерзанные органы себе в руки!",
			"[source] разрывает себя от паха до рёбер; органы и кровь вываливаются наружу горячей лавиной!",
			"Я вскрываю собственный живот. Всё внутри меня вываливается наружу."
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
			is_sharp ? "[source] вгоняет [weapon_name] в собственную грудь и пронзает сердце насквозь!" : "[source] проламывает себе грудь предметом [weapon_name], превращая сердце и лёгкие под сломанными рёбрами в месиво!",
			is_sharp ? "[source] пронзает собственное сердце; с каждым угасающим ударом кровь извергается изо рта и раны!" : "Грудная клетка [source] проваливается внутрь под [weapon_name], выбрасывая кровь и кости с последним ударом сердца!",
			is_sharp ? "Я чувствую, как [weapon_name] входит в моё сердце. Его последний удар стекает по моим рукам." : "Я сокрушаю собственную грудь, пока сердце не останавливается под обломками."
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
		is_sharp ? "[source] вонзает [weapon_name] сквозь собственный череп, вскрывая мозг!" : "[source] дробит собственный череп предметом [weapon_name] в брызгах крови и костей!",
		is_sharp ? "[source] с такой силой пронзает собственную голову, что череп и мозг раскрываются вокруг [weapon_name]!" : "Голова [source] проваливается под [weapon_name] и разлетается с громовым треском!",
		is_sharp ? "Я проталкиваю [weapon_name] сквозь свой череп, в темноту под ним." : "Я чувствую, как мой череп складывается вокруг удара."
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

/datum/suicide_trauma/proc/get_magic_kind(datum/magic_source)
	if(istype(magic_source, /datum/action/cooldown/spell))
		var/datum/action/cooldown/spell/modern_spell = magic_source
		switch(modern_spell.attunement_school)
			if(ASPECT_NAME_PYROMANCY)
				return SUICIDE_MAGIC_FIRE
			if(ASPECT_NAME_CRYOMANCY)
				return SUICIDE_MAGIC_ICE
			if(ASPECT_NAME_FULGURMANCY)
				return SUICIDE_MAGIC_LIGHTNING

	var/magic_source_name
	if(magic_source)
		magic_source_name = magic_source.vars["name"]
	var/search_text = lowertext("[magic_source?.type] [magic_source_name]")
	if(findtext(search_text, "frost") || findtext(search_text, "ice") || findtext(search_text, "snow") || findtext(search_text, "cryo") || findtext(search_text, "cold") || findtext(search_text, "freeze") || findtext(search_text, "icicle"))
		return SUICIDE_MAGIC_ICE
	if(findtext(search_text, "lightning") || findtext(search_text, "thunder") || findtext(search_text, "fulgur") || findtext(search_text, "storm") || findtext(search_text, "electric"))
		return SUICIDE_MAGIC_LIGHTNING
	if(findtext(search_text, "fire") || findtext(search_text, "flame") || findtext(search_text, "burn") || findtext(search_text, "infernal") || findtext(search_text, "solar") || findtext(search_text, "astrata"))
		return SUICIDE_MAGIC_FIRE
	return SUICIDE_MAGIC_GENERIC

/datum/suicide_trauma/proc/apply_magic_trauma(datum/weakref/source_ref, magic_kind, spell_name, starting_fire_stacks)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source))
		return

	var/show_death = is_show_death(source)
	switch(magic_kind)
		if(SUICIDE_MAGIC_FIRE)
			announce_trauma(
				source,
				"[source] обращает [spell_name] внутрь себя; каждая часть тела вспыхивает ненасытным пламенем!",
				"[source] становится сердцем огненной бури; плоть обращается в раскалённый пепел под действием [spell_name]!",
				"Я открываю себя для [spell_name]. Огонь заполняет каждую вену и полость."
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
				"[source] мгновенно замерзает изнутри и превращается в изломанную человеческую сосульку!",
				"[source] с оглушительным треском кристаллизуется; кровь, органы и кости становятся сверкающей статуей из расколотого льда!",
				"Холод смыкается вокруг каждой клетки. Я становлюсь единым осколком льда."
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
				"[source] проводит [spell_name] сквозь собственное тело и вспыхивает ослепительным силуэтом из пепла!",
				"[source] становится живой молнией; мир вспыхивает белым, а тело взрывается дымящимся прахом!",
				"Молния заменяет мою кровь. На один белый миг я становлюсь самим громом."
			)
			playsound(source, 'sound/magic/lightning.ogg', 140, FALSE)
			ADD_TRAIT(source, TRAIT_DUSTABLE, SUICIDE_MODE_DUST_SOURCE)
			source.dust(just_ash = TRUE, drop_items = TRUE, force = TRUE)
			return

	announce_trauma(
		source,
		"[source] обращает [spell_name] внутрь себя; чистая магия взрывается сразу в каждой конечности и каждом органе!",
		"[source] становится центром арканной катастрофы и разрывается, пока [spell_name] мечет тело и люкс во все стороны!",
		"Я выпускаю [spell_name] внутри себя. Всё моё тело распадается одновременно."
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

#undef SUICIDE_UNARMED_SKULL
#undef SUICIDE_UNARMED_TONGUE
#undef SUICIDE_UNARMED_EYES
#undef SUICIDE_UNARMED_NECK_SNAP
#undef SUICIDE_UNARMED_STRANGLE

#undef SUICIDE_INTERVENTION_RANGE

#undef SUICIDE_MODE_DUST_SOURCE
#undef SUICIDE_MODE_TRAIT
