/proc/ataman_appraise_looted(atom/movable/container)
	var/total = 0
	for(var/obj/item/I in container.contents)
		if(length(I.contents))
			total += ataman_appraise_looted(I)
		if(I.looted)
			total += I.get_real_price()
	return total

/datum/action/cooldown/spell/ataman_exchange
	name = "Честный обмен"
	desc = "Стоя рядом с нелегальным скупщиком, обменять мешок с чужим добром на 90% его стоимости монетами - без лишних вопросов. Считается только то, что когда-то принадлежало другим."
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
		owner.balloon_alert(owner, "Это не мешок с добром!")
		return FALSE
	if(!locate(/obj/structure/roguemachine/blackmarket) in range(2, owner))
		owner.balloon_alert(owner, "Поблизости нет скупщика!")
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

	var/value = round(ataman_appraise_looted(sack) * 0.9)
	if(value < ATAMAN_TRADE_MIN_VALUE)
		to_chat(H, span_warning("В [sack] недостаточно чужого добра для настоящей сделки."))
		return FALSE

	sack.forceMove(fence)
	budget2change(value, H)
	ataman_process_honest_trade(H, value)
	to_chat(H, span_notice("Я передаю [sack] [fence] и получаю [value] маммон."))
	return TRUE
