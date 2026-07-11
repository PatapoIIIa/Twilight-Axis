/proc/ataman_appraise_looted(atom/movable/container)
	var/total = 0
	for(var/obj/item/I in container.contents)
		if(length(I.contents))
			total += ataman_appraise_looted(I)
		if(I.looted)
			total += I.get_real_price()
	return total

/datum/action/cooldown/spell/ataman_exchange
	name = "Honest Exchange"
	desc = "Trade a bag of stolen goods to a nearby fence. I receive 60% of their appraised value, while the duchy treasury loses 40%. Only goods that once belonged to someone else count."
	click_to_activate = TRUE
	self_cast_possible = FALSE
	primary_resource_type = SPELL_COST_STAMINA
	primary_resource_cost = SPELLCOST_CANTRIP
	invocation_type = INVOCATION_NONE
	charge_required = FALSE
	cooldown_time = 10 SECONDS
	cast_range = 1
	associated_skill = null
	associated_stat = null
	spell_requirements = SPELL_REQUIRES_HUMAN | SPELL_REQUIRES_SAME_Z

/datum/action/cooldown/spell/ataman_exchange/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	if(!istype(cast_on, /obj/item/storage))
		owner.balloon_alert(owner, "that is not a bag of goods!")
		return FALSE
	if(!locate(/obj/structure/roguemachine/blackmarket) in range(2, owner))
		owner.balloon_alert(owner, "there is no fence nearby!")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/ataman_exchange/cast(atom/target)
	. = ..()
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE
	var/obj/item/storage/sack = target
	if(!istype(sack))
		return FALSE
	var/obj/structure/roguemachine/blackmarket/fence = locate(/obj/structure/roguemachine/blackmarket) in range(2, H)
	if(!fence)
		return FALSE

	var/appraised_value = round(ataman_appraise_looted(sack))
	if(appraised_value < ATAMAN_TRADE_MIN_VALUE)
		to_chat(H, span_warning("There are not enough stolen goods in [sack] for a real exchange."))
		return FALSE
	var/payout_value = round(appraised_value * ATAMAN_TRADE_PAYOUT_MULTIPLIER)
	var/treasury_damage = round(appraised_value * ATAMAN_TREASURY_DAMAGE_MULTIPLIER)

	sack.forceMove(fence)
	budget2change(payout_value, H)
	ataman_process_honest_trade(H, appraised_value, treasury_damage)
	to_chat(H, span_notice("I hand [sack] to [fence] and receive [payout_value] mammons."))
	return TRUE
