#define ATAMAN_TRADE_MIN_VALUE 250
#define ATAMAN_TRADE_PAYOUT_MULTIPLIER 0.6
#define ATAMAN_TREASURY_DAMAGE_MULTIPLIER 0.4
#define ATAMAN_TIER_BASE_BOUNTY 100

/datum/bounty
	var/ataman_reason_category
	var/list/ataman_victim_names = list()

/mob/living/carbon/human
	var/ataman_loot_sold_total = 0
	var/ataman_loot_tier = 0

/proc/ataman_find_bounty(mob/living/carbon/human/culprit, employer, category)
	for(var/datum/bounty/existing in GLOB.head_bounties)
		if(existing.target == culprit.real_name && existing.employer == employer && existing.ataman_reason_category == category)
			return existing
	return null

/proc/ataman_create_bounty(mob/living/carbon/human/culprit, amount, reason, employer, category, race, gender, descriptor_height, descriptor_body, descriptor_voice)
	add_bounty(culprit.real_name, race, gender, descriptor_height, descriptor_body, descriptor_voice, amount, FALSE, reason, employer)
	var/datum/bounty/created = GLOB.head_bounties[length(GLOB.head_bounties)]
	created.ataman_reason_category = category
	return created

/proc/ataman_get_loot_tier(total)
	if(total >= 5000)
		return 5
	if(total >= 4000)
		return 4
	if(total >= 2500)
		return 3
	if(total >= 1500)
		return 2
	if(total >= 500)
		return 1
	return 0

/// Completes an Honest Exchange: treasury loss and theft bounty use 40% of the
/// appraisal, while tier progress records the full value of the goods sold.
/proc/ataman_process_honest_trade(mob/living/carbon/human/H, appraised_value, treasury_damage)
	SStreasury.burn(SStreasury.discretionary_fund, treasury_damage, "Honest Exchange")
	send_ooc_note("[treasury_damage] coins have been stolen from the duchy treasury!", job = list("Grand Duke", "Steward", "Clerk", "Sultan", "Vizier"))

	var/list/d_list = H.get_mob_descriptors()
	var/descriptor_height = build_coalesce_description_nofluff(d_list, H, list(MOB_DESCRIPTOR_SLOT_HEIGHT), "%DESC1%")
	var/descriptor_body = build_coalesce_description_nofluff(d_list, H, list(MOB_DESCRIPTOR_SLOT_BODY), "%DESC1%")
	var/descriptor_voice = build_coalesce_description_nofluff(d_list, H, list(MOB_DESCRIPTOR_SLOT_VOICE), "%DESC1%")

	var/datum/bounty/bounty = ataman_find_bounty(H, ATAMAN_EXCIDIUM, ATAMAN_BOUNTY_CATEGORY_THEFT)
	if(bounty)
		bounty.amount += treasury_damage
	else
		bounty = ataman_create_bounty(H, treasury_damage, "", ATAMAN_EXCIDIUM, ATAMAN_BOUNTY_CATEGORY_THEFT, H.dna.species, H.gender, descriptor_height, descriptor_body, descriptor_voice)
	bounty.reason = "Theft from the [SSmapping.config.map_name] treasury - [bounty.amount] coins"

	H.ataman_loot_sold_total += appraised_value
	var/new_tier = ataman_get_loot_tier(H.ataman_loot_sold_total)
	if(new_tier > H.ataman_loot_tier)
		H.ataman_loot_tier = new_tier
		var/tier_bonus = new_tier * ATAMAN_TIER_BASE_BOUNTY
		bounty.amount += tier_bonus
		to_chat(H, span_danger("My notoriety reaches tier [new_tier] - the Excidium adds [tier_bonus] coins to the price on my head."))

	bounty.banner = null
	compose_bounty(bounty)
