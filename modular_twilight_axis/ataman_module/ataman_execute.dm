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
	desc = "Prepare my next expert melee strike or aimed/arc projectile against a target bearing my mark. The real attack keeps its current intent and completely bypasses armor."
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
	desc = "My next expert strike or aimed/arc shot against one of my marked targets completely bypasses armor."
	icon_state = "buff"

/datum/status_effect/buff/ataman_finishing_blow
	id = "ataman_finishing_blow"
	alert_type = /atom/movable/screen/alert/status_effect/buff/ataman_finishing_blow
	duration = 30 SECONDS
	tick_interval = -1
	status_type = STATUS_EFFECT_UNIQUE

	var/obj/item/pending_melee_weapon
	var/datum/weakref/pending_melee_target_ref
	var/datum/weakref/pending_mark_ref
	var/original_melee_d_type
	var/melee_committed = FALSE

	var/obj/item/gun/pending_gun
	var/datum/weakref/pending_ranged_target_ref
	var/ranged_committed = FALSE

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
	addtimer(CALLBACK(src, PROC_REF(clear_pending_melee_if_uncommitted), weapon), 0)

/datum/status_effect/buff/ataman_finishing_blow/proc/on_melee_success(obj/item/source, mob/living/target, mob/living/user)
	SIGNAL_HANDLER
	if(melee_committed || source != pending_melee_weapon || user != owner || pending_melee_target_ref?.resolve() != target)
		return
	var/datum/component/ataman_marked/mark = pending_mark_ref?.resolve()
	if(QDELETED(mark) || ataman_get_owned_mark(target, owner) != mark)
		clear_pending_melee()
		return

	melee_committed = TRUE
	UnregisterSignal(source, COMSIG_ITEM_ATTACK_SUCCESS)
	original_melee_d_type = source.d_type
	source.d_type = null
	addtimer(CALLBACK(src, PROC_REF(complete_melee_finisher), source, target), 0)

/datum/status_effect/buff/ataman_finishing_blow/proc/clear_pending_melee_if_uncommitted(obj/item/expected_weapon)
	if(melee_committed || expected_weapon != pending_melee_weapon)
		return
	clear_pending_melee()

/datum/status_effect/buff/ataman_finishing_blow/proc/clear_pending_melee()
	if(pending_melee_weapon && !QDELETED(pending_melee_weapon))
		UnregisterSignal(pending_melee_weapon, COMSIG_ITEM_ATTACK_SUCCESS)
		if(melee_committed && isnull(pending_melee_weapon.d_type))
			pending_melee_weapon.d_type = original_melee_d_type
	pending_melee_weapon = null
	pending_melee_target_ref = null
	pending_mark_ref = null
	original_melee_d_type = null
	melee_committed = FALSE

/datum/status_effect/buff/ataman_finishing_blow/proc/complete_melee_finisher(obj/item/weapon, mob/living/target)
	if(!QDELETED(weapon) && isnull(weapon.d_type))
		weapon.d_type = original_melee_d_type
	var/datum/component/ataman_marked/mark = pending_mark_ref?.resolve()
	if(!QDELETED(target) && !QDELETED(mark) && ataman_get_owned_mark(target, owner) == mark)
		qdel(mark)
	if(owner && !QDELETED(owner))
		owner.visible_message(
			span_danger("[owner]'s finishing blow tears through [target]'s armor!"),
			span_notice("My finishing blow tears through [target]'s armor!"),
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
	addtimer(CALLBACK(src, PROC_REF(clear_pending_ranged_if_uncommitted), pending_gun), 0)

/datum/status_effect/buff/ataman_finishing_blow/proc/on_projectile_created(obj/item/gun/source, obj/projectile/projectile, atom/original_target)
	SIGNAL_HANDLER
	var/mob/living/expected_target = pending_ranged_target_ref?.resolve()
	if(ranged_committed || source != pending_gun || projectile.firer != owner || original_target != expected_target)
		return
	var/datum/component/ataman_marked/mark = ataman_get_owned_mark(expected_target, owner)
	if(!mark)
		clear_pending_ranged()
		return

	ranged_committed = TRUE
	UnregisterSignal(source, COMSIG_PROJECTILE_BEFORE_FIRE)
	projectile.AddComponent(/datum/component/ataman_finishing_projectile, owner, expected_target, mark)
	addtimer(CALLBACK(src, PROC_REF(consume_ranged_preparation)), 0)

/datum/status_effect/buff/ataman_finishing_blow/proc/clear_pending_ranged_if_uncommitted(obj/item/gun/expected_gun)
	if(ranged_committed || expected_gun != pending_gun)
		return
	clear_pending_ranged()

/datum/status_effect/buff/ataman_finishing_blow/proc/clear_pending_ranged()
	if(pending_gun && !QDELETED(pending_gun))
		UnregisterSignal(pending_gun, COMSIG_PROJECTILE_BEFORE_FIRE)
	pending_gun = null
	pending_ranged_target_ref = null
	ranged_committed = FALSE

/datum/status_effect/buff/ataman_finishing_blow/proc/consume_ranged_preparation()
	if(owner && !QDELETED(owner))
		owner.remove_status_effect(/datum/status_effect/buff/ataman_finishing_blow)

/datum/component/ataman_finishing_projectile
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/datum/weakref/shooter_ref
	var/datum/weakref/target_ref
	var/datum/weakref/mark_ref
	var/original_flag
	var/original_armor_penetration
	var/bypass_applied = FALSE

/datum/component/ataman_finishing_projectile/Initialize(mob/living/carbon/human/shooter, mob/living/target, datum/component/ataman_marked/mark)
	if(!istype(parent, /obj/projectile) || !shooter || !target || !mark)
		return COMPONENT_INCOMPATIBLE
	shooter_ref = WEAKREF(shooter)
	target_ref = WEAKREF(target)
	mark_ref = WEAKREF(mark)
	RegisterSignal(target, COMSIG_ATOM_BULLET_ACT, PROC_REF(on_target_bullet_act))
	RegisterSignal(parent, COMSIG_PROJECTILE_SELF_ON_HIT, PROC_REF(on_projectile_hit))

/datum/component/ataman_finishing_projectile/proc/on_target_bullet_act(mob/living/source, obj/projectile/incoming, def_zone)
	SIGNAL_HANDLER
	if(bypass_applied || incoming != parent || source != target_ref?.resolve())
		return
	var/mob/living/carbon/human/shooter = shooter_ref?.resolve()
	var/datum/component/ataman_marked/mark = mark_ref?.resolve()
	if(!shooter || QDELETED(mark) || ataman_get_owned_mark(source, shooter) != mark)
		return

	bypass_applied = TRUE
	original_flag = incoming.flag
	original_armor_penetration = incoming.armor_penetration
	incoming.flag = null
	incoming.armor_penetration = 100
	addtimer(CALLBACK(src, PROC_REF(finish_projectile)), 0)

/datum/component/ataman_finishing_projectile/proc/on_projectile_hit(obj/projectile/source, mob/firer, atom/hit_target, angle)
	SIGNAL_HANDLER
	var/mob/living/expected_target = target_ref?.resolve()
	if(hit_target != expected_target || !bypass_applied)
		qdel(src)
		return
	var/mob/living/carbon/human/shooter = shooter_ref?.resolve()
	var/datum/component/ataman_marked/mark = mark_ref?.resolve()
	if(!QDELETED(mark) && shooter && ataman_get_owned_mark(expected_target, shooter) == mark)
		qdel(mark)
	if(shooter)
		shooter.visible_message(
			span_danger("[shooter]'s finishing shot tears through [expected_target]'s armor!"),
			span_notice("My finishing shot tears through [expected_target]'s armor!"),
		)

/datum/component/ataman_finishing_projectile/proc/finish_projectile()
	var/obj/projectile/projectile = parent
	if(!QDELETED(projectile) && bypass_applied)
		if(isnull(projectile.flag))
			projectile.flag = original_flag
		if(projectile.armor_penetration == 100)
			projectile.armor_penetration = original_armor_penetration
	bypass_applied = FALSE
	qdel(src)

/datum/component/ataman_finishing_projectile/Destroy()
	var/mob/living/target = target_ref?.resolve()
	if(target)
		UnregisterSignal(target, COMSIG_ATOM_BULLET_ACT)
	if(parent)
		UnregisterSignal(parent, COMSIG_PROJECTILE_SELF_ON_HIT)
	shooter_ref = null
	target_ref = null
	mark_ref = null
	return ..()
