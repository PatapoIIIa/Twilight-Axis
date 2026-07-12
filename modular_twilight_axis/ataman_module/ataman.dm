#define BB_ATAMAN_SPAWN_TURF "bb_ataman_spawn_turf"
#define BB_ATAMAN_OWNER "bb_ataman_owner"
#define BB_ATAMAN_TARGET "bb_ataman_target"
#define BB_ATAMAN_ROLE "bb_ataman_role"
#define BB_ATAMAN_SQUAD "bb_ataman_squad"
#define BB_ATAMAN_TACTICS_COOLDOWN "bb_ataman_tactics_cooldown"

#define ATAMAN_ROLE_GRABBER "grabber"
#define ATAMAN_ROLE_BINDER "binder"
#define ATAMAN_ROLE_ENFORCER "enforcer"

#define ATAMAN_LEASH_RANGE 10

#define ATAMAN_EXCIDIUM "The Excidium"
#define ATAMAN_BOUNTY_CATEGORY_MURDER "murder"
#define ATAMAN_BOUNTY_CATEGORY_THEFT "theft"

#define ATAMAN_MAX_ACTIVE_AMBUSHES 3
#define ATAMAN_TRAP_SETUP_TIME (7 SECONDS)
#define ATAMAN_TRAP_TOMB_EXCLUSION 30
#define ATAMAN_TRAP_MAX_CROWD 5
#define ATAMAN_TRAP_CROWD_RANGE 7

#define ATAMAN_TRADE_MIN_VALUE 250
#define ATAMAN_TRADE_PAYOUT_MULTIPLIER 0.6
#define ATAMAN_TREASURY_DAMAGE_MULTIPLIER 0.4
#define ATAMAN_TIER_BASE_BOUNTY 100

GLOBAL_VAR_INIT(ataman_ai_logging, TRUE)
GLOBAL_VAR_INIT(ataman_ai_log_file, null)

/proc/ataman_ai_log(mob/living/source, message)
	if(!GLOB.ataman_ai_logging)
		return
	if(!GLOB.ataman_ai_log_file)
		GLOB.ataman_ai_log_file = "[GLOB.log_directory]/ataman_ai.log"
	var/tag = "SQUAD"
	if(istype(source, /mob/living/carbon/human/npc/ataman_bandit))
		var/mob/living/carbon/human/npc/ataman_bandit/bandit = source
		tag = "[bandit.real_name]#[REF(bandit)] role=[bandit.ataman_role]"
	else if(source)
		tag = "[source.real_name]"
	WRITE_LOG(GLOB.ataman_ai_log_file, "\[[station_time_timestamp()]\] [tag]: [message]")

/mob/living/carbon/human
	var/list/ataman_active_ambushes
	var/ataman_loot_sold_total = 0
	var/ataman_loot_tier = 0
	var/list/recent_attackers = list()
	var/ataman_deathmark_bound = FALSE

/datum/bounty
	var/ataman_reason_category
	var/list/ataman_victim_names = list()

/proc/ataman_turf_has_trap(turf/target_turf)
	if(!target_turf)
		return FALSE
	if(locate(/obj/structure/trap) in target_turf)
		return TRUE
	if(locate(/obj/item/restraints/legcuffs/beartrap) in target_turf)
		return TRUE
	return FALSE

/proc/ataman_active_ambush_count(mob/living/carbon/human/owner)
	if(!owner)
		return 0
	LAZYINITLIST(owner.ataman_active_ambushes)
	for(var/datum/weakref/ambush_ref as anything in owner.ataman_active_ambushes.Copy())
		var/obj/structure/trap/ataman_ambush_stone/ambush = ambush_ref.resolve()
		if(QDELETED(ambush))
			owner.ataman_active_ambushes -= ambush_ref
	return length(owner.ataman_active_ambushes)

/proc/ataman_register_ambush(mob/living/carbon/human/owner, obj/structure/trap/ataman_ambush_stone/ambush)
	if(!owner || !ambush)
		return
	LAZYINITLIST(owner.ataman_active_ambushes)
	owner.ataman_active_ambushes += WEAKREF(ambush)

/proc/ataman_bandit_belongs_to(atom/movable/AM, mob/living/carbon/human/owner)
	if(!owner || !istype(AM, /mob/living/carbon/human/npc/ataman_bandit))
		return FALSE
	var/mob/living/carbon/human/npc/ataman_bandit/bandit = AM
	return bandit.ataman_owner_ref?.resolve() == owner

/proc/ataman_trap_spot_error(mob/living/user, turf/target_turf)
	var/area/spot_area = get_area(target_turf)
	if(istype(spot_area, /area/rogue/under))
		return "I cannot set this underground!"
	for(var/obj/structure/dungeon_entry/entry as anything in GLOB.dungeon_entries)
		var/turf/entry_turf = get_turf(entry)
		if(entry_turf && entry_turf.z == target_turf.z && get_dist(entry_turf, target_turf) <= ATAMAN_TRAP_TOMB_EXCLUSION)
			return "too close to the tomb!"
	var/crowd = 0
	for(var/mob/living/bystander in range(ATAMAN_TRAP_CROWD_RANGE, target_turf))
		if(bystander == user || bystander.stat == DEAD)
			continue
		crowd++
	if(crowd > ATAMAN_TRAP_MAX_CROWD)
		return "too many souls nearby!"
	return null

/proc/ataman_channel_undisturbed(mob/living/carbon/human/H, start_health)
	return !QDELETED(H) && H.health >= start_health && !H.pulledby

/proc/ataman_trap_channel(mob/living/carbon/human/H, turf/target_turf)
	var/datum/callback/checks = CALLBACK(GLOBAL_PROC, GLOBAL_PROC_REF(ataman_channel_undisturbed), H, H.health)
	return do_after(H, ATAMAN_TRAP_SETUP_TIME, target = target_turf, extra_checks = checks)

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

/proc/ataman_squad_size_for_tier(tier)
	switch(tier)
		if(3)
			return list(4, 7)
		if(4)
			return list(5, 7)
		if(5 to INFINITY)
			return list(5, 5)
	return list(3, 6)

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

/obj/item/gun/ballistic/revolver/grenadelauncher/crossbow/ataman_iron
	name = "iron crossbow"
	desc = "A sturdy crossbow whose lock and fittings are wrought from iron."
	smeltresult = /obj/item/ingot/iron

/datum/advclass/wretch/ataman
	name = "Атаман"
	tutorial = "Ты вёл горстку оборванцев-головорезов по глухим тропам и просёлкам, всегда мечтая о чём-то большем. Теперь ты пришёл в эти земли, чтобы установить собственные порядки - мечом, силком и петлёй, если придётся."
	allowed_sexes = list(MALE, FEMALE)
	outfit = /datum/outfit/job/roguetown/wretch/ataman
	cmode_music = 'sound/music/cmode/antag/combat_cutpurse.ogg'
	class_select_category = CLASS_CAT_WARRIOR
	category_tags = list(CTAG_WRETCH)
	traits_applied = list(TRAIT_MEDIUMARMOR, TRAIT_PERFECT_TRACKER, TRAIT_CICERONE, TRAIT_ALCHEMY_EXPERT, TRAIT_SMITHING_EXPERT, TRAIT_MEDICINE_EXPERT, TRAIT_KEENEARS)
	maximum_possible_slots = 1
	extra_context = "Ты ведёшь собственную небольшую банду дорогой славы. Грабь, то, что можно награбить, а неограбляемое делай ограбляемым"
	subclass_stats = list(
		STATKEY_INT = 4,
		STATKEY_PER = 3,
		STATKEY_CON = 2,
		STATKEY_WIL = 2,
	)
	subclass_skills = list(
		/datum/skill/combat/swords = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/combat/bows = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/combat/shields = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/combat/knives = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/climbing = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/athletics = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/craft/alchemy = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/medicine = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/misc/hunting = SKILL_LEVEL_APPRENTICE,
		/datum/skill/misc/tracking = SKILL_LEVEL_MASTER,
		/datum/skill/misc/sneaking = SKILL_LEVEL_JOURNEYMAN,
		/datum/skill/craft/engineering = SKILL_LEVEL_EXPERT,
		/datum/skill/misc/reading = SKILL_LEVEL_JOURNEYMAN,
	)

/datum/outfit/job/roguetown/wretch/ataman/pre_equip(mob/living/carbon/human/H)
	..()
	head = /obj/item/clothing/head/roguetown/roguehood/shalal/heavyhood
	neck = /obj/item/clothing/neck/roguetown/coif
	pants = /obj/item/clothing/under/roguetown/trou/leather
	armor = /obj/item/clothing/suit/roguetown/armor/leather
	shirt = /obj/item/clothing/suit/roguetown/shirt/undershirt/black
	cloak = /obj/item/clothing/cloak/thief_cloak
	backl = /obj/item/storage/backpack/rogue/satchel
	belt = /obj/item/storage/belt/rogue/leather/knifebelt/black/iron
	gloves = /obj/item/clothing/gloves/roguetown/leather
	shoes = /obj/item/clothing/shoes/roguetown/boots/leather/reinforced
	wrists = /obj/item/clothing/wrists/roguetown/bracers/leather
	backpack_contents = list(
		/obj/item/storage/belt/rogue/pouch/coins/poor = 1,
		/obj/item/flashlight/flare/torch/lantern/prelit = 1,
		/obj/item/rope/chain = 1,
		/obj/item/reagent_containers/glass/bottle/alchemical/healthpot = 1,
		)

	if(H.mind)
		var/weapon_sets = list("Меч и щит", "Копьё и щит", "Лук и кинжал", "Булава, щит и арбалет")
		var/weapon_choice = input(H, "Выбери вооружение своей банды.", "Снаряжение Атамана") as anything in weapon_sets
		switch(weapon_choice)
			if("Меч и щит")
				sword_shield_equip(H)
			if("Копьё и щит")
				spear_shield_equip(H)
			if("Лук и кинжал")
				bow_dagger_equip(H)
			if("Булава, щит и арбалет")
				mace_shield_crossbow_equip(H)

		grant_ataman_spells(H)

/datum/outfit/job/roguetown/wretch/ataman/proc/sword_shield_equip(mob/living/carbon/human/H)
	r_hand = /obj/item/rogueweapon/sword/iron
	backr = /obj/item/rogueweapon/shield/wood
	beltr = /obj/item/rogueweapon/scabbard/sword
	H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_EXPERT, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/combat/shields, SKILL_LEVEL_JOURNEYMAN, TRUE)

/datum/outfit/job/roguetown/wretch/ataman/proc/spear_shield_equip(mob/living/carbon/human/H)
	r_hand = /obj/item/rogueweapon/spear
	backr = /obj/item/rogueweapon/shield/wood
	H.adjust_skillrank_up_to(/datum/skill/combat/polearms, SKILL_LEVEL_EXPERT, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/combat/shields, SKILL_LEVEL_JOURNEYMAN, TRUE)

/datum/outfit/job/roguetown/wretch/ataman/proc/bow_dagger_equip(mob/living/carbon/human/H)
	r_hand = /obj/item/gun/ballistic/revolver/grenadelauncher/bow
	beltl = /obj/item/quiver/arrows
	beltr = /obj/item/rogueweapon/huntingknife/idagger
	H.adjust_skillrank_up_to(/datum/skill/combat/bows, SKILL_LEVEL_EXPERT, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/combat/knives, SKILL_LEVEL_EXPERT, TRUE)

/datum/outfit/job/roguetown/wretch/ataman/proc/mace_shield_crossbow_equip(mob/living/carbon/human/H)
	r_hand = /obj/item/rogueweapon/mace
	backr = /obj/item/rogueweapon/shield/wood
	backl = /obj/item/gun/ballistic/revolver/grenadelauncher/crossbow/ataman_iron
	beltl = /obj/item/quiver/bolt/standard
	H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_JOURNEYMAN, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/combat/shields, SKILL_LEVEL_JOURNEYMAN, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/combat/crossbows, SKILL_LEVEL_EXPERT, TRUE)

/datum/outfit/job/roguetown/wretch/ataman/proc/grant_ataman_spells(mob/living/carbon/human/H)
	H.mind.AddSpell(new /datum/action/cooldown/spell/ataman_ambush)
	H.mind.AddSpell(new /datum/action/cooldown/spell/ataman_trap)
	H.mind.AddSpell(new /datum/action/cooldown/spell/ataman_execute)
	H.mind.AddSpell(new /datum/action/cooldown/spell/ataman_exchange)

/datum/action/cooldown/spell/ataman_ambush
	name = "Set an Ambush"
	desc = "Spend seven undisturbed seconds placing a hidden ambush trigger. The first intruder to disturb it will be surrounded by my bandits. I can maintain no more than three ambushes at once."
	click_to_activate = TRUE
	self_cast_possible = FALSE
	primary_resource_type = SPELL_COST_STAMINA
	primary_resource_cost = SPELLCOST_MINOR_SUMMON
	invocation_type = INVOCATION_NONE
	charge_required = FALSE
	cooldown_time = 3 MINUTES
	cast_range = 1
	associated_skill = null
	associated_stat = null
	spell_requirements = SPELL_REQUIRES_HUMAN | SPELL_REQUIRES_SAME_Z

/datum/action/cooldown/spell/ataman_ambush/can_cast_spell(feedback = TRUE)
	. = ..()
	if(!.)
		return FALSE
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE
	if(ataman_active_ambush_count(H) >= ATAMAN_MAX_ACTIVE_AMBUSHES)
		if(feedback)
			H.balloon_alert(H, "three ambushes already set!")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/ataman_ambush/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	var/turf/target_turf = get_turf(cast_on)
	if(!target_turf || target_turf.density)
		return FALSE
	if(istype(target_turf, /turf/open/transparent/openspace))
		return FALSE
	if(ataman_turf_has_trap(target_turf))
		owner.balloon_alert(owner, "another trap is already here!")
		return FALSE
	var/area/rogue/place = get_area(target_turf)
	if(istype(place) && (place.town_area || place.keep_area))
		owner.balloon_alert(owner, "I cannot set an ambush here!")
		return FALSE
	var/spot_error = ataman_trap_spot_error(owner, target_turf)
	if(spot_error)
		owner.balloon_alert(owner, spot_error)
		return FALSE
	var/mob/living/carbon/human/H = owner
	if(!istype(H) || ataman_active_ambush_count(H) >= ATAMAN_MAX_ACTIVE_AMBUSHES)
		owner.balloon_alert(owner, "three ambushes already set!")
		return FALSE
	return TRUE

/datum/action/cooldown/spell/ataman_ambush/cast(atom/target)
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE
	var/turf/target_turf = get_turf(target)
	if(!target_turf || ataman_turf_has_trap(target_turf))
		H.balloon_alert(H, "another trap is already here!")
		return FALSE
	if(ataman_active_ambush_count(H) >= ATAMAN_MAX_ACTIVE_AMBUSHES)
		H.balloon_alert(H, "three ambushes already set!")
		return FALSE

	var/list/disguises = list(
		"Stone" = list("stone", "A piece of rough ground stone.", 'icons/roguetown/items/natural.dmi', "stone1"),
		"Clod of Earth" = list("clod", "A handful of earth.", 'icons/roguetown/items/natural.dmi', "clod1"),
		"Stick" = list("stick", "A tree branch perhaps.", 'icons/roguetown/items/natural.dmi', "stick1"),
	)
	var/choice = input(H, "What should the ambush look like?", "Set an Ambush") as null|anything in disguises
	if(!choice)
		return FALSE
	if(QDELETED(H) || H.z != target_turf.z || get_dist(H, target_turf) > cast_range || ataman_turf_has_trap(target_turf))
		if(!QDELETED(H))
			H.balloon_alert(H, "I can no longer set an ambush there!")
		return FALSE
	var/spot_error = ataman_trap_spot_error(H, target_turf)
	if(spot_error)
		H.balloon_alert(H, spot_error)
		return FALSE
	var/list/picked = disguises[choice]
	if(!ataman_trap_channel(H, target_turf))
		H.balloon_alert(H, "interrupted!")
		return FALSE
	if(QDELETED(H) || H.z != target_turf.z || get_dist(H, target_turf) > cast_range || ataman_turf_has_trap(target_turf) || ataman_trap_spot_error(H, target_turf))
		if(!QDELETED(H))
			H.balloon_alert(H, "I can no longer set an ambush there!")
		return FALSE
	. = ..()

	var/obj/structure/trap/ataman_ambush_stone/ambush = new(target_turf)
	ambush.disguise_as_prop(picked[1], picked[2], picked[3], picked[4])
	ambush.set_placer(H)
	to_chat(H, span_notice("I conceal [ambush] as [picked[1]]."))
	return TRUE

/datum/action/cooldown/spell/ataman_trap
	name = "Set a Snare"
	desc = "Spend seven undisturbed seconds burying a disguised trap. Anyone caught is mauled, left bleeding badly, and marked for my Finishing Blow until the mark fades."
	click_to_activate = TRUE
	self_cast_possible = FALSE
	primary_resource_type = SPELL_COST_STAMINA
	primary_resource_cost = SPELLCOST_MINOR_AOE
	invocation_type = INVOCATION_NONE
	charge_required = FALSE
	cooldown_time = 2 MINUTES
	cast_range = 1
	associated_skill = /datum/skill/craft/traps
	associated_stat = null
	spell_requirements = SPELL_REQUIRES_HUMAN | SPELL_REQUIRES_SAME_Z

/datum/action/cooldown/spell/ataman_trap/get_adjusted_cooldown()
	var/mob/living/carbon/human/H = owner
	if(istype(H) && H.ataman_loot_tier >= 5)
		return 15 MINUTES
	return ..()

/datum/action/cooldown/spell/ataman_trap/is_valid_target(atom/cast_on)
	. = ..()
	if(!.)
		return FALSE
	var/turf/target_turf = get_turf(cast_on)
	if(!target_turf || target_turf.density)
		return FALSE
	if(istype(target_turf, /turf/open/transparent/openspace))
		return FALSE
	if(ataman_turf_has_trap(target_turf))
		owner.balloon_alert(owner, "another trap is already here!")
		return FALSE
	var/area/rogue/place = get_area(target_turf)
	if(istype(place) && (place.town_area || place.keep_area))
		owner.balloon_alert(owner, "I cannot set a trap here!")
		return FALSE
	var/spot_error = ataman_trap_spot_error(owner, target_turf)
	if(spot_error)
		owner.balloon_alert(owner, spot_error)
		return FALSE
	return TRUE

/datum/action/cooldown/spell/ataman_trap/cast(atom/target)
	var/mob/living/carbon/human/H = owner
	if(!istype(H))
		return FALSE
	var/turf/target_turf = get_turf(target)
	if(!target_turf || ataman_turf_has_trap(target_turf))
		H.balloon_alert(H, "another trap is already here!")
		return FALSE

	var/list/flavors = list(
		"Mantrap" = /obj/structure/trap/ataman_snare/beartrap_type,
		"Buried charge" = /obj/structure/trap/ataman_snare/bomb_type,
		"Stake pit" = /obj/structure/trap/ataman_snare/stakes_type,
	)
	var/choice = input(H, "Which trap will I set?", "Set a Snare") as null|anything in flavors
	if(!choice)
		return FALSE
	if(QDELETED(H) || H.z != target_turf.z || get_dist(H, target_turf) > cast_range || ataman_turf_has_trap(target_turf))
		if(!QDELETED(H))
			H.balloon_alert(H, "I can no longer set a trap there!")
		return FALSE
	var/spot_error = ataman_trap_spot_error(H, target_turf)
	if(spot_error)
		H.balloon_alert(H, spot_error)
		return FALSE
	var/chosen_type = flavors[choice]
	if(!chosen_type)
		return FALSE
	if(!ataman_trap_channel(H, target_turf))
		H.balloon_alert(H, "interrupted!")
		return FALSE
	if(QDELETED(H) || H.z != target_turf.z || get_dist(H, target_turf) > cast_range || ataman_turf_has_trap(target_turf) || ataman_trap_spot_error(H, target_turf))
		if(!QDELETED(H))
			H.balloon_alert(H, "I can no longer set a trap there!")
		return FALSE
	. = ..()

	var/obj/structure/trap/ataman_snare/snare = new chosen_type(target_turf)
	snare.set_placer(H)
	to_chat(H, span_notice("I bury [snare] in the ground."))
	return TRUE

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
	duration = 30 SECONDS
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

	sack.forceMove(fence)
	budget2change(payout_value, H)
	ataman_process_honest_trade(H, appraised_value)
	to_chat(H, span_notice("I hand [sack] to [fence] and receive [payout_value] mammons."))
	return TRUE

/obj/structure/trap/ataman_ambush_stone
	name = "stone"
	desc = "A piece of rough ground stone."
	icon = 'icons/roguetown/items/natural.dmi'
	icon_state = "stone1"
	charges = 1
	time_between_triggers = 0
	checks_antimagic = FALSE
	var/datum/weakref/placed_by_ref
	var/list/bandit_types = list(/mob/living/carbon/human/npc/ataman_bandit)
	var/being_removed = FALSE

/obj/structure/trap/ataman_ambush_stone/Crossed(atom/movable/AM)
	var/mob/living/carbon/human/placer = placed_by_ref?.resolve()
	if(ataman_bandit_belongs_to(AM, placer))
		return
	return ..()

/obj/structure/trap/ataman_ambush_stone/proc/set_placer(mob/living/carbon/human/placer)
	if(!placer)
		return
	placed_by_ref = WEAKREF(placer)
	if(placer.mind)
		immune_minds += placer.mind
	ataman_register_ambush(placer, src)

/obj/structure/trap/ataman_ambush_stone/proc/disguise_as_prop(new_name, new_desc, new_icon, new_icon_state)
	name = new_name
	desc = new_desc
	icon = new_icon
	icon_state = new_icon_state

/obj/structure/trap/ataman_ambush_stone/flare()
	alpha = 200
	last_trigger = world.time
	charges--
	animate(src, alpha = 0, time = 2)
	QDEL_IN(src, 2)

/obj/structure/trap/ataman_ambush_stone/examine(mob/user)
	return

/obj/structure/trap/ataman_ambush_stone/attack_hand(mob/user)
	var/mob/living/carbon/human/placer = placed_by_ref?.resolve()
	if(user == placer)
		begin_owner_removal(placer)
		return TRUE
	return ..()

/obj/structure/trap/ataman_ambush_stone/attackby(obj/item/I, mob/user, params)
	var/mob/living/carbon/human/placer = placed_by_ref?.resolve()
	if(user == placer)
		begin_owner_removal(placer)
		return TRUE
	return ..()

/obj/structure/trap/ataman_ambush_stone/proc/begin_owner_removal(mob/living/carbon/human/placer)
	if(being_removed || QDELETED(src))
		return
	being_removed = TRUE
	placer.visible_message(
		span_notice("[placer] begins dismantling something hidden on the ground."),
		span_notice("I begin dismantling my ambush."),
	)
	if(do_after(placer, 5 SECONDS, target = src) && !QDELETED(src))
		to_chat(placer, span_notice("I dismantle my ambush."))
		qdel(src)
		return
	being_removed = FALSE

/obj/structure/trap/ataman_ambush_stone/trap_effect(mob/living/L)
	spring_ambush(L)

/obj/structure/trap/ataman_ambush_stone/proc/is_valid_ambush_spawn(turf/candidate, turf/spawn_center, list/used_turfs, exact_distance)
	if(!isopenturf(candidate) || candidate == spawn_center || candidate in used_turfs)
		return FALSE
	if(istype(candidate, /turf/open/transparent/openspace) || candidate.is_blocked_turf(exclude_mobs = TRUE))
		return FALSE
	if(exact_distance && get_dist(candidate, spawn_center) != exact_distance)
		return FALSE
	var/distance = get_dist(candidate, spawn_center)
	return distance >= 1 && distance <= 5

/obj/structure/trap/ataman_ambush_stone/proc/pick_ambush_spawn(turf/spawn_center, list/used_turfs)
	var/desired_distance = rand(1, 5)
	var/list/candidates = list()
	for(var/turf/candidate as anything in RANGE_TURFS(5, spawn_center))
		if(is_valid_ambush_spawn(candidate, spawn_center, used_turfs, desired_distance))
			candidates += candidate
	if(!length(candidates))
		for(var/turf/candidate as anything in RANGE_TURFS(5, spawn_center))
			if(is_valid_ambush_spawn(candidate, spawn_center, used_turfs, 0))
				candidates += candidate
	if(!length(candidates))
		return null
	return pick(candidates)

/obj/structure/trap/ataman_ambush_stone/proc/spring_ambush(mob/living/trigger)
	var/mob/living/carbon/human/placer = placed_by_ref?.resolve()
	var/turf/spawn_center = get_turf(src)
	if(!spawn_center || !isliving(trigger))
		return

	var/datum/ataman_squad/squad = new
	squad.target_ref = WEAKREF(trigger)
	squad.gear_tier = placer ? clamp(max(placer.ataman_loot_tier, 1), 1, 5) : 1

	var/list/squad_size_range = ataman_squad_size_for_tier(placer?.ataman_loot_tier || 0)
	var/list/used_spawn_turfs = list()
	var/amount = rand(squad_size_range[1], squad_size_range[2])
	var/grabber_count = amount >= 4 ? 2 : 1
	ataman_ai_log(placer, "AMBUSH: springing on [trigger] at [spawn_center] - size=[amount] (range [squad_size_range[1]]-[squad_size_range[2]]) gear_tier=[squad.gear_tier] grabbers=[grabber_count]")
	for(var/i in 1 to amount)
		var/turf/spawn_location = pick_ambush_spawn(spawn_center, used_spawn_turfs)
		if(!spawn_location)
			break
		used_spawn_turfs += spawn_location
		var/mob_type = pick(bandit_types)
		var/mob/living/carbon/human/npc/ataman_bandit/bandit = new mob_type(spawn_location)
		var/role = i <= grabber_count ? ATAMAN_ROLE_GRABBER : (i == grabber_count + 1 ? ATAMAN_ROLE_BINDER : ATAMAN_ROLE_ENFORCER)
		bandit.set_ataman(placer, spawn_center, trigger, role, squad)

	if(placer)
		to_chat(placer, span_notice("My ambush springs on [trigger]!"))

/obj/structure/trap/ataman_snare
	name = "clod"
	desc = "A handful of earth."
	icon = 'icons/roguetown/items/natural.dmi'
	icon_state = "clod1"
	charges = 1
	time_between_triggers = 0
	trap_damage = 35
	var/bleed_bonus = 30
	var/datum/weakref/placed_by_ref

/obj/structure/trap/ataman_snare/examine(mob/user)
	return

/obj/structure/trap/ataman_snare/Crossed(atom/movable/AM)
	var/mob/living/carbon/human/placer = placed_by_ref?.resolve()
	if(ataman_bandit_belongs_to(AM, placer))
		return
	return ..()

/obj/structure/trap/ataman_snare/proc/set_placer(mob/living/carbon/human/placer)
	if(!placer)
		return
	placed_by_ref = WEAKREF(placer)
	if(placer.mind)
		immune_minds += placer.mind

/obj/structure/trap/ataman_snare/trap_effect(mob/living/L)
	def_zone = pick(BODY_ZONE_L_LEG, BODY_ZONE_R_LEG)
	L.apply_damage(trap_damage, BRUTE, def_zone, L.run_armor_check(def_zone, "stab", armor_penetration = PEN_LIGHT, damage = trap_damage))
	L.simple_bleeding += bleed_bonus
	L.Paralyze(30)
	to_chat(L, span_danger("<B>[src] bites into me - I'm bleeding badly!</B>"))
	playsound(src, 'sound/items/beartrap.ogg', 100, TRUE)
	var/mob/living/carbon/human/placer = placed_by_ref?.resolve()
	L.AddComponent(/datum/component/ataman_marked, placer)

/obj/structure/trap/ataman_snare/beartrap_type
	name = "stick"
	desc = "A tree branch perhaps."
	icon = 'icons/roguetown/items/natural.dmi'
	icon_state = "stick1"

/obj/structure/trap/ataman_snare/beartrap_type/trap_effect(mob/living/L)
	..()
	L.visible_message(span_danger("A hidden trap snaps shut on [L]!"))

/obj/structure/trap/ataman_snare/bomb_type
	name = "stone"
	desc = "A piece of rough ground stone."
	icon = 'icons/roguetown/items/natural.dmi'
	icon_state = "stone1"

/obj/structure/trap/ataman_snare/bomb_type/trap_effect(mob/living/L)
	..()
	L.visible_message(span_danger("A buried charge rips into [L]!"))

/obj/structure/trap/ataman_snare/stakes_type
	name = "clod"
	desc = "A handful of earth."
	icon = 'icons/roguetown/items/natural.dmi'
	icon_state = "clod1"

/obj/structure/trap/ataman_snare/stakes_type/trap_effect(mob/living/L)
	..()
	L.visible_message(span_danger("[L] falls onto a bed of hidden stakes!"))

/datum/component/ataman_marked
	dupe_mode = COMPONENT_DUPE_UNIQUE

	var/datum/weakref/marked_by_ref
	var/mutable_appearance/marker_overlay
	var/expire_timer

/datum/component/ataman_marked/Initialize(mob/living/carbon/human/marker, duration = 90 SECONDS)
	if(!isliving(parent))
		return COMPONENT_INCOMPATIBLE
	if(marker)
		marked_by_ref = WEAKREF(marker)

	var/mob/living/L = parent
	marker_overlay = mutable_appearance('icons/mob/mob_effects.dmi', "eff_exposed", ABOVE_MOB_LAYER)
	marker_overlay.pixel_y = 32
	marker_overlay.plane = ABOVE_LIGHTING_PLANE
	marker_overlay.alpha = 255
	marker_overlay.appearance_flags = RESET_ALPHA | RESET_COLOR
	L.add_overlay(marker_overlay)

	expire_timer = addtimer(CALLBACK(src, PROC_REF(expire)), duration, TIMER_STOPPABLE)

/datum/component/ataman_marked/proc/expire()
	qdel(src)

/datum/component/ataman_marked/proc/get_marker()
	if(!marked_by_ref)
		return null
	return marked_by_ref.resolve()

/datum/component/ataman_marked/Destroy()
	var/mob/living/L = parent
	if(L && marker_overlay)
		L.cut_overlay(marker_overlay)
	marker_overlay = null
	if(expire_timer)
		deltimer(expire_timer)
		expire_timer = null
	return ..()

#define ATAMAN_DEATH_MARK_WINDOW 15
#define ATAMAN_DEATH_MARK_MAX_WITNESSES 6
#define ATAMAN_DEATH_MARK_BOUNTY 300

SUBSYSTEM_DEF(ataman_deathmark)
	name = "Ataman Death Mark"
	flags = SS_NO_FIRE

/datum/controller/subsystem/ataman_deathmark/Initialize()
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_CREATED, PROC_REF(on_mob_created))
	for(var/mob/living/carbon/human/H in GLOB.mob_list)
		register_human(H)
	return ..()

/datum/controller/subsystem/ataman_deathmark/proc/on_mob_created(datum/source, mob/new_mob)
	SIGNAL_HANDLER
	if(!ishuman(new_mob))
		return
	register_human(new_mob)

/datum/controller/subsystem/ataman_deathmark/proc/register_human(mob/living/carbon/human/H)
	if(!H || H.ataman_deathmark_bound)
		return
	H.ataman_deathmark_bound = TRUE
	RegisterSignal(H, COMSIG_MOB_APPLY_DAMGE, PROC_REF(on_damaged))
	RegisterSignal(H, COMSIG_LIVING_DEATH, PROC_REF(on_death))

/datum/controller/subsystem/ataman_deathmark/proc/on_damaged(mob/living/carbon/human/victim, damage, damagetype, def_zone)
	SIGNAL_HANDLER
	var/mob/living/attacker = victim.lastattacker_weakref?.resolve()
	if(!attacker || attacker == victim)
		return
	victim.recent_attackers += WEAKREF(attacker)
	var/excess = length(victim.recent_attackers) - ATAMAN_DEATH_MARK_WINDOW
	if(excess > 0)
		victim.recent_attackers.Cut(1, excess + 1)

/datum/controller/subsystem/ataman_deathmark/proc/on_death(mob/living/carbon/human/victim, gibbed)
	SIGNAL_HANDLER
	check_ataman_death_mark(victim)
	victim.recent_attackers = list()

/proc/ataman_resolve_source(mob/living/attacker)
	if(!istype(attacker))
		return null
	if(istype(attacker, /mob/living/carbon/human/npc/ataman_bandit))
		var/mob/living/carbon/human/npc/ataman_bandit/bandit = attacker
		return bandit.ataman_owner_ref?.resolve()
	return attacker

/proc/check_ataman_death_mark(mob/living/carbon/human/victim)
	if(!victim?.client || !length(victim.recent_attackers))
		return

	var/mob/living/carbon/human/culprit
	for(var/datum/weakref/ref as anything in victim.recent_attackers)
		var/mob/living/carbon/human/source = ataman_resolve_source(ref?.resolve())
		if(istype(source) && source.client && source.mind && source.advjob == "Атаман")
			culprit = source
			break

	if(!culprit?.client)
		return

	var/nearby_players = 0
	for(var/mob/living/witness in view(5, victim))
		if(!witness.client)
			continue
		nearby_players++
		if(nearby_players > ATAMAN_DEATH_MARK_MAX_WITNESSES)
			return

	var/list/d_list = culprit.get_mob_descriptors()
	var/descriptor_height = build_coalesce_description_nofluff(d_list, culprit, list(MOB_DESCRIPTOR_SLOT_HEIGHT), "%DESC1%")
	var/descriptor_body = build_coalesce_description_nofluff(d_list, culprit, list(MOB_DESCRIPTOR_SLOT_BODY), "%DESC1%")
	var/descriptor_voice = build_coalesce_description_nofluff(d_list, culprit, list(MOB_DESCRIPTOR_SLOT_VOICE), "%DESC1%")

	var/datum/bounty/bounty = ataman_find_bounty(culprit, ATAMAN_EXCIDIUM, ATAMAN_BOUNTY_CATEGORY_MURDER)
	if(bounty)
		bounty.ataman_victim_names += victim.real_name
		bounty.amount += ATAMAN_DEATH_MARK_BOUNTY
		bounty.reason = "Murder: [jointext(bounty.ataman_victim_names, ", ")]"
		bounty.banner = null
		compose_bounty(bounty)
	else
		bounty = ataman_create_bounty(culprit, ATAMAN_DEATH_MARK_BOUNTY, "Murder: [victim.real_name]", ATAMAN_EXCIDIUM, ATAMAN_BOUNTY_CATEGORY_MURDER, culprit.dna.species, culprit.gender, descriptor_height, descriptor_body, descriptor_voice)
		bounty.ataman_victim_names = list(victim.real_name)

	to_chat(culprit, span_danger("За мою голову назначена награда. Кто-то узнал о том, что я убил [victim.real_name]!"))

#undef ATAMAN_DEATH_MARK_WINDOW
#undef ATAMAN_DEATH_MARK_MAX_WITNESSES
#undef ATAMAN_DEATH_MARK_BOUNTY
