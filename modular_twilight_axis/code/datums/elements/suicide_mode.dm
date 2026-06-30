#define SUICIDE_MODE_TRAIT "suicide_mode"
#define SUICIDE_MODE_TARGET_HEALTH -50

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
	var/confirmation = alert(src, "Your next deliberate self-harming action will cause critical injuries. Continue?", "Enable Suicide Mode", "Yes", "No")
	if(ckey != old_key || confirmation != "Yes" || !canSuicide())
		return

	AddElement(/datum/element/suicide_mode)
	to_chat(src, span_userdanger("Suicide mode is armed. My next deliberate self-harming action will cause critical injuries."))

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
	if(source.is_jumping && old_turf && new_turf && new_turf.z < old_turf.z)
		commit_suicide(source, "jumping from a height")
		return

	if(forced && islava(new_turf))
		commit_suicide(source, "entering lava through a portal")

/datum/element/suicide_mode/proc/on_item_attack(mob/living/carbon/human/source, obj/item/weapon, mob/living/attacker)
	SIGNAL_HANDLER

	if(attacker != source)
		return
	commit_suicide(source, "attacking themselves with [weapon]")

/datum/element/suicide_mode/proc/on_projectile_hit(mob/living/carbon/human/source, obj/projectile/projectile, def_zone)
	SIGNAL_HANDLER

	if(projectile.firer != source)
		return
	commit_suicide(source, "shooting themselves with [projectile]")

/datum/element/suicide_mode/proc/on_modern_spell_cast(mob/living/carbon/human/source, datum/action/cooldown/spell/spell, atom/cast_on)
	SIGNAL_HANDLER

	if(cast_on != source)
		return
	commit_suicide(source, "casting [spell] on themselves")

/datum/element/suicide_mode/proc/on_legacy_spell_cast(mob/living/carbon/human/source, obj/effect/proc_holder/spell/spell, list/targets)
	SIGNAL_HANDLER

	if(!islist(targets) || !(source in targets))
		return
	commit_suicide(source, "casting [spell] on themselves")

/datum/element/suicide_mode/proc/commit_suicide(mob/living/carbon/human/source, method)
	if(!HAS_TRAIT(source, SUICIDE_MODE_TRAIT))
		return

	source.RemoveElement(/datum/element/suicide_mode)
	source.set_suicide(TRUE)
	source.log_message("triggered suicide mode by [method]", LOG_ATTACK)
	source.suicide_log()
	source.visible_message(
		span_suicide("[source] deliberately follows through with a suicidal act!"),
		span_userdanger("I deliberately follow through. There is no turning back now.")
	)
	addtimer(CALLBACK(src, PROC_REF(force_critical_condition), WEAKREF(source)), world.tick_lag)

/datum/element/suicide_mode/proc/force_critical_condition(datum/weakref/source_ref)
	var/mob/living/carbon/human/source = source_ref.resolve()
	if(!source || QDELETED(source) || source.stat == DEAD)
		return

	var/target_oxy_loss = source.maxHealth - SUICIDE_MODE_TARGET_HEALTH
	if(source.getOxyLoss() < target_oxy_loss)
		source.setOxyLoss(target_oxy_loss)

#undef SUICIDE_MODE_TARGET_HEALTH
#undef SUICIDE_MODE_TRAIT
