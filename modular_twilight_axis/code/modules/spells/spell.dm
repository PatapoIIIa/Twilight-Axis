/obj/effect/proc_holder/spell/perform(list/targets, recharge = TRUE, mob/user = usr)
	if(!ignore_los)
		if(length(targets))
			var/radius
			if(range > 0)
				radius = range
			else
				radius = 1
			if(get_dist(targets[1], user) > radius)
				to_chat(user, span_warning("It's too far!"))
				revert_cast()
				return
			var/atom/A = targets[1]
			var/turf/source_turf = get_turf(user)
			if(A.z > user.z)
				source_turf = get_step_multiz(source_turf, UP)
			if(A.z < user.z)
				source_turf = get_step_multiz(source_turf, DOWN)

	before_cast(targets, user = user)
	if(user && user.ckey)
		user.log_message(span_danger("cast the spell [name]."), LOG_ATTACK)
	if(user.mob_timers[MT_INVISIBILITY] > world.time)
		user.mob_timers[MT_INVISIBILITY] = world.time
		user.update_sneak_invis(reset = TRUE)
	if(isliving(user))
		var/mob/living/L = user
		if(L.rogue_sneaking)
			L.mob_timers[MT_FOUNDSNEAK] = world.time
			L.update_sneak_invis(reset = TRUE)
	if(cast(targets, user = user))
		SEND_SIGNAL(user, COMSIG_MOB_LEGACY_SPELL_CAST, src, targets)
		if(!ranged_ability_user && releasedrain > 0 && isliving(user))
			var/mob/living/L = user
			var/fatigue = calculate_fatigue_drain(L)
			if(fatigue > 0)
				L.stamina_add(fatigue)
		invocation(user)
		start_recharge()
		if(sound)
			playMagSound()
		after_cast(targets, user = user)
		if(isliving(user))
			var/mob/living/L = user
			if(releasedrain > 0)
				L.stamina_add(calculate_fatigue_drain(L))
			if(L.has_status_effect(/datum/status_effect/buff/clash))
				var/mob/living/carbon/human/H = user
				H.bad_guard(span_warning("I can't focus while casting spells!"), cheesy = TRUE)
		if(action)
			action.build_all_button_icons()
		return TRUE
	return FALSE
