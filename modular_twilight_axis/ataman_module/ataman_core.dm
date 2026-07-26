#define BB_ATAMAN_FLEE_TURF "bb_ataman_flee_turf"
#define BB_ATAMAN_SPAWN_TURF "bb_ataman_spawn_turf"
#define BB_ATAMAN_OWNER "bb_ataman_owner"
#define BB_ATAMAN_TARGET "bb_ataman_target"
#define BB_ATAMAN_ROLE "bb_ataman_role"
#define BB_ATAMAN_SQUAD "bb_ataman_squad"
#define BB_ATAMAN_TACTICS_COOLDOWN "bb_ataman_tactics_cooldown"
#define BB_ATAMAN_INTERCEPT_TURF "bb_ataman_intercept_turf"

#define ATAMAN_ROLE_GRABBER "grabber"
#define ATAMAN_ROLE_BINDER "binder"
#define ATAMAN_ROLE_ENFORCER "enforcer"

#define ATAMAN_LEASH_RANGE 10

#define ATAMAN_EXCIDIUM "The Excidium"
#define ATAMAN_BOUNTY_CATEGORY_MURDER "murder"
#define ATAMAN_BOUNTY_CATEGORY_THEFT "theft"

#define ATAMAN_MAX_ACTIVE_AMBUSHES 3
#define ATAMAN_MAX_ACTIVE_TRAPS 3
#define ATAMAN_TRAP_SETUP_TIME (7 SECONDS)
#define ATAMAN_TRAP_TOMB_EXCLUSION 15
#define ATAMAN_TRAP_MAX_CROWD 5
#define ATAMAN_TRAP_CROWD_RANGE 7
#define ATAMAN_TRAP_PLAYER_EXCLUSION_RANGE 8
#define ATAMAN_TRAP_MIN_SPACING 8

#define ATAMAN_TRADE_MIN_ITEM_VALUE 25
#define ATAMAN_TRADE_MIN_VALUE 200
#define ATAMAN_TRADE_PAYOUT_MULTIPLIER 0.55
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
	var/list/ataman_active_traps
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

/proc/ataman_active_trap_count(mob/living/carbon/human/owner)
	if(!owner)
		return 0
	LAZYINITLIST(owner.ataman_active_traps)
	for(var/datum/weakref/trap_ref as anything in owner.ataman_active_traps.Copy())
		var/obj/structure/trap/ataman_snare/trap = trap_ref.resolve()
		if(QDELETED(trap))
			owner.ataman_active_traps -= trap_ref
	return length(owner.ataman_active_traps)

/proc/ataman_register_trap(mob/living/carbon/human/owner, obj/structure/trap/ataman_snare/trap)
	if(!owner || !trap)
		return
	LAZYINITLIST(owner.ataman_active_traps)
	owner.ataman_active_traps += WEAKREF(trap)

/proc/ataman_too_close_to_own(mob/living/carbon/human/owner, turf/target_turf, list/existing_refs, min_distance)
	if(!owner || !length(existing_refs))
		return FALSE
	for(var/datum/weakref/existing_ref as anything in existing_refs)
		var/obj/structure/trap/existing = existing_ref.resolve()
		if(QDELETED(existing))
			continue
		var/turf/existing_turf = get_turf(existing)
		if(existing_turf && existing_turf.z == target_turf.z && get_dist(existing_turf, target_turf) < min_distance)
			return TRUE
	return FALSE

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
	for(var/mob/living/bystander in range(ATAMAN_TRAP_PLAYER_EXCLUSION_RANGE, target_turf))
		if(bystander == user || !bystander.client)
			continue
		return "someone would see me do this!"
	var/crowd = 0
	for(var/mob/living/bystander in range(ATAMAN_TRAP_CROWD_RANGE, target_turf))
		if(bystander == user || bystander.stat == DEAD || ataman_bandit_belongs_to(bystander, user))
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
