/// Reads the shared squad state and reacts to whatever the target is doing right
/// now: bolting gets an immediate feint from whoever's able, an ordinary spell
/// gets met with a guard stance, and otherwise the squad's staged feint economy
/// gets first refusal before the generic melee subtree is allowed to swing.
/datum/ai_planning_subtree/ataman_squad_tactics/SelectBehaviors(datum/ai_controller/controller, delta_time)
	. = ..()
	var/mob/living/carbon/human/pawn = controller.pawn
	if(!istype(pawn))
		return
	var/datum/ataman_squad/squad = controller.blackboard[BB_ATAMAN_SQUAD]
	if(!squad)
		return
	var/mob/living/target = controller.blackboard[BB_ATAMAN_TARGET]
	if(!istype(target) || target.stat == DEAD || ataman_target_is_secured(target) || !pawn.Adjacent(target))
		return

	if(squad.target_channeling_escape_spell())
		if(squad.consider_feint(pawn, target, emergency = TRUE))
			squad.register_feint()
			controller.ai_interact(target, TRUE, TRUE, list(RIGHT_CLICK = TRUE))
		return SUBTREE_RETURN_FINISH_PLANNING

	if(squad.target_channeling_spell())
		if(!pawn.has_status_effect(/datum/status_effect/buff/clash) && squad.claim_guard())
			pawn.try_guard()
		return SUBTREE_RETURN_FINISH_PLANNING

	if(squad.consider_feint(pawn, target))
		squad.register_feint()
		controller.ai_interact(target, TRUE, TRUE, list(RIGHT_CLICK = TRUE))
		return SUBTREE_RETURN_FINISH_PLANNING

	return
