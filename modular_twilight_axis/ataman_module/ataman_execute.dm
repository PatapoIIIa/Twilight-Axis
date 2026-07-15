/proc/ataman_weapon_skill(obj/item/weapon)
	if(istype(weapon, /obj/item/gun/ballistic/revolver/grenadelauncher/bow))
		return /datum/skill/combat/bows
	return weapon?.associated_skill

/proc/ataman_get_owned_mark(mob/living/target, mob/living/carbon/human/marker)
	if(!target || !marker)
		return null
	var/datum/component/ataman_marked/mark = target.GetComponent(/datum/component/ataman_marked)
	if(mark?.get_marker() != marker)
		return null
	return mark

/proc/ataman_can_finish_with(mob/living/carbon/human/user, obj/item/weapon, feedback = FALSE)
	var/weapon_skill = ataman_weapon_skill(weapon)
	if(weapon_skill && user.get_skill_level(weapon_skill) >= SKILL_LEVEL_EXPERT)
		return TRUE
	if(feedback)
		user.balloon_alert(user, "I lack mastery with this weapon!")
	return FALSE

/datum/action/cooldown/spell/ataman_execute
	name = "Finishing Blow"
	desc = "Prepare my next expert melee strike or aimed/arc projectile against a target bearing my mark. A clean hit consumes the mark and lands with all my weight behind it, though armor protects as it always does."
	click_to_activate = FALSE
	self_cast_possible = TRUE
	primary_resource_type = SPELL_COST_STAMINA
	primary_resource_cost = SPELLCOST_CANTRIP
	invocation_type = INVOCATION_NONE
	charge_required = FALSE
	cooldown_time = 4 SECONDS
	associated_skill = null
	associated_stat = null
	spell_requirements = SPELL_REQUIRES_HUMAN | SPELL_REQUIRES_SAME_Z

/datum/action/cooldown/spell/ataman_execute/can_cast_spell(feedback = TRUE)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE
	if(H.has_status_effect(/datum/status_effect/buff/ataman_finishing_blow))
		if(feedback)
			H.balloon_alert(H, "a finishing blow is already prepared!")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/ataman_execute/cast(atom/cast_on)
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(!istype(H) || H.has_status_effect(/datum/status_effect/buff/ataman_finishing_blow))
		return FALSE
	H.apply_status_effect(/datum/status_effect/buff/ataman_finishing_blow)
	to_chat(H, span_notice("Я приготовился нанести сокрушительный удар!"))
	return TRUE

/atom/movable/screen/alert/status_effect/buff/ataman_finishing_blow
	name = "Finishing Blow"
	desc = "My next expert strike or aimed/arc shot against one of my marked targets will finish the hunt."
	icon_state = "buff"

/datum/status_effect/buff/ataman_finishing_blow
	id = "ataman_finishing_blow"
	alert_type = /atom/movable/screen/alert/status_effect/buff/ataman_finishing_blow
	duration = 10 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE

	var/obj/item/pending_melee_weapon
	var/datum/weakref/pending_melee_target_ref
	var/datum/weakref/pending_mark_ref

	var/obj/item/gun/pending_gun
	var/datum/weakref/pending_ranged_target_ref

/datum/status_effect/buff/ataman_finishing_blow/on_apply()
	. = ..()
	RegisterSignal(owner, COMSIG_MOB_ITEM_ATTACK_POST_SWINGDELAY, PROC_REF(on_melee_swing))
	RegisterSignal(owner, COMSIG_MOB_ITEM_AFTERATTACK, PROC_REF(on_ranged_attack))

/datum/status_effect/buff/ataman_finishing_blow/on_remove()
	UnregisterSignal(owner, list(COMSIG_MOB_ITEM_ATTACK_POST_SWINGDELAY, COMSIG_MOB_ITEM_AFTERATTACK))
	clear_pending_melee()
	clear_pending_ranged()
	. = ..()

/datum/status_effect/buff/ataman_finishing_blow/proc/on_melee_swing(mob/living/source, mob/living/target, mob/living/user, obj/item/weapon)
	SIGNAL_HANDLER
	if(user != owner || !isliving(target) || !weapon || user.used_intent?.tranged)
		return
	var/mob/living/carbon/human/H = owner
	var/datum/component/ataman_marked/mark = ataman_get_owned_mark(target, H)
	if(!mark || !ataman_can_finish_with(H, weapon, TRUE))
		return
	clear_pending_melee()
	pending_melee_weapon = weapon
	pending_melee_target_ref = WEAKREF(target)
	pending_mark_ref = WEAKREF(mark)
	RegisterSignal(weapon, COMSIG_ITEM_ATTACK_SUCCESS, PROC_REF(on_melee_success))

/datum/status_effect/buff/ataman_finishing_blow/proc/on_melee_success(obj/item/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	if(source != pending_melee_weapon || user != owner || pending_melee_target_ref?.resolve() != target)
		return
	var/datum/component/ataman_marked/mark = pending_mark_ref?.resolve()
	if(QDELETED(mark) || ataman_get_owned_mark(target, owner) != mark)
		clear_pending_melee()
		return
	addtimer(CALLBACK(src, PROC_REF(complete_finisher), target, mark), 0)

/datum/status_effect/buff/ataman_finishing_blow/proc/clear_pending_melee()
	if(pending_melee_weapon && !QDELETED(pending_melee_weapon))
		UnregisterSignal(pending_melee_weapon, COMSIG_ITEM_ATTACK_SUCCESS)
	pending_melee_weapon = null
	pending_melee_target_ref = null
	pending_mark_ref = null

/datum/status_effect/buff/ataman_finishing_blow/proc/complete_finisher(mob/living/target, datum/component/ataman_marked/mark)
	if(!QDELETED(target) && !QDELETED(mark) && ataman_get_owned_mark(target, owner) == mark)
		qdel(mark)
	if(owner && !QDELETED(owner))
		owner.visible_message(
			span_danger("[owner]'s finishing blow crashes into [target]!"),
			span_notice("My finishing blow crashes into [target]!"),
		)
		owner.remove_status_effect(/datum/status_effect/buff/ataman_finishing_blow)

/datum/status_effect/buff/ataman_finishing_blow/proc/on_ranged_attack(mob/living/source, atom/target, obj/item/item, proximity, params)
	SIGNAL_HANDLER
	if(source != owner || !istype(item, /obj/item/gun) || !isliving(target))
		return
	if(!istype(source.used_intent, /datum/intent/shoot) && !istype(source.used_intent, /datum/intent/arc))
		return
	var/mob/living/carbon/human/H = owner
	var/mob/living/living_target = target
	var/datum/component/ataman_marked/mark = ataman_get_owned_mark(living_target, H)
	if(!mark || !ataman_can_finish_with(H, item, TRUE))
		return
	clear_pending_ranged()
	pending_gun = item
	pending_ranged_target_ref = WEAKREF(living_target)
	RegisterSignal(pending_gun, COMSIG_PROJECTILE_BEFORE_FIRE, PROC_REF(on_projectile_created))

/datum/status_effect/buff/ataman_finishing_blow/proc/on_projectile_created(obj/item/gun/source, obj/projectile/projectile, atom/original_target)
	SIGNAL_HANDLER
	var/mob/living/expected_target = pending_ranged_target_ref?.resolve()
	if(source != pending_gun || projectile.firer != owner || original_target != expected_target)
		return
	var/datum/component/ataman_marked/mark = ataman_get_owned_mark(expected_target, owner)
	if(!mark)
		clear_pending_ranged()
		return
	UnregisterSignal(source, COMSIG_PROJECTILE_BEFORE_FIRE)
	projectile.AddComponent(/datum/component/ataman_finishing_projectile, owner, expected_target, mark)
	addtimer(CALLBACK(src, PROC_REF(consume_ranged_preparation)), 0)

/datum/status_effect/buff/ataman_finishing_blow/proc/clear_pending_ranged()
	if(pending_gun && !QDELETED(pending_gun))
		UnregisterSignal(pending_gun, COMSIG_PROJECTILE_BEFORE_FIRE)
	pending_gun = null
	pending_ranged_target_ref = null

/datum/status_effect/buff/ataman_finishing_blow/proc/consume_ranged_preparation()
	if(owner && !QDELETED(owner))
		owner.remove_status_effect(/datum/status_effect/buff/ataman_finishing_blow)

/datum/component/ataman_finishing_projectile
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/datum/weakref/shooter_ref
	var/datum/weakref/target_ref
	var/datum/weakref/mark_ref

/datum/component/ataman_finishing_projectile/Initialize(mob/living/carbon/human/shooter, mob/living/target, datum/component/ataman_marked/mark)
	if(!istype(parent, /obj/projectile) || !shooter || !target || !mark)
		return COMPONENT_INCOMPATIBLE
	shooter_ref = WEAKREF(shooter)
	target_ref = WEAKREF(target)
	mark_ref = WEAKREF(mark)
	RegisterSignal(parent, COMSIG_PROJECTILE_SELF_ON_HIT, PROC_REF(on_projectile_hit))

/datum/component/ataman_finishing_projectile/proc/on_projectile_hit(obj/projectile/source, mob/firer, atom/hit_target, angle)
	SIGNAL_HANDLER
	var/mob/living/expected_target = target_ref?.resolve()
	if(hit_target != expected_target)
		qdel(src)
		return
	var/mob/living/carbon/human/shooter = shooter_ref?.resolve()
	var/datum/component/ataman_marked/mark = mark_ref?.resolve()
	if(!QDELETED(mark) && shooter && ataman_get_owned_mark(expected_target, shooter) == mark)
		qdel(mark)
	if(shooter)
		shooter.visible_message(
			span_danger("[shooter]'s finishing shot slams into [expected_target]!"),
			span_notice("My finishing shot slams into [expected_target]!"),
		)
	qdel(src)

/datum/component/ataman_finishing_projectile/Destroy()
	if(parent)
		UnregisterSignal(parent, COMSIG_PROJECTILE_SELF_ON_HIT)
	shooter_ref = null
	target_ref = null
	mark_ref = null
	return ..()
