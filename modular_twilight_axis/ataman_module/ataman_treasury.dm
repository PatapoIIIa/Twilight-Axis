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

/// Min/max ambush squad size for a given notoriety tier.
/proc/ataman_squad_size_for_tier(tier)
	switch(tier)
		if(3)
			return list(4, 7)
		if(4)
			return list(5, 7)
		if(5 to INFINITY)
			return list(5, 5)
	return list(3, 6)

/// Equips an ambush bandit's armor to match the Ataman's current notoriety tier:
/// leather at 1, heavy leather + iron at 2, iron at 3-4, steel at 5+.
/proc/ataman_apply_bandit_gear(mob/living/carbon/human/npc/ataman_bandit/bandit, tier)
	switch(tier)
		if(2)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/suit/roguetown/armor/leather/heavy, SLOT_ARMOR, TRUE)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/gloves/roguetown/plate/iron, SLOT_GLOVES, TRUE)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/shoes/roguetown/boots/armor/iron, SLOT_SHOES, TRUE)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/wrists/roguetown/bracers/iron, SLOT_WRISTS, TRUE)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/neck/roguetown/chaincoif/iron, SLOT_NECK, TRUE)
		if(3, 4)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/suit/roguetown/armor/plate/iron, SLOT_ARMOR, TRUE)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/gloves/roguetown/plate/iron, SLOT_GLOVES, TRUE)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/shoes/roguetown/boots/armor/iron, SLOT_SHOES, TRUE)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/wrists/roguetown/bracers/iron, SLOT_WRISTS, TRUE)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/neck/roguetown/chaincoif/iron, SLOT_NECK, TRUE)
		if(5 to INFINITY)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/suit/roguetown/armor/plate, SLOT_ARMOR, TRUE)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/gloves/roguetown/plate, SLOT_GLOVES, TRUE)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/shoes/roguetown/boots/armor, SLOT_SHOES, TRUE)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/wrists/roguetown/bracers, SLOT_WRISTS, TRUE)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/neck/roguetown/chaincoif, SLOT_NECK, TRUE)
		else
			bandit.equip_to_slot_or_del(new /obj/item/clothing/suit/roguetown/armor/leather, SLOT_ARMOR, TRUE)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/gloves/roguetown/leather, SLOT_GLOVES, TRUE)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/shoes/roguetown/boots/leather/reinforced, SLOT_SHOES, TRUE)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/wrists/roguetown/bracers/leather, SLOT_WRISTS, TRUE)
			bandit.equip_to_slot_or_del(new /obj/item/clothing/neck/roguetown/leather, SLOT_NECK, TRUE)

/// Completes an Honest Exchange: treasury loss and theft bounty use 40% of the
/// appraisal (+10% per notoriety tier already reached), while tier progress
/// records the full value of the goods sold.
/proc/ataman_process_honest_trade(mob/living/carbon/human/H, appraised_value)
	var/damage_multiplier = ATAMAN_TREASURY_DAMAGE_MULTIPLIER * (1 + (0.1 * H.ataman_loot_tier))
	var/treasury_damage = round(appraised_value * damage_multiplier)
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
