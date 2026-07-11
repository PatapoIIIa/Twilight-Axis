/mob/living/carbon/human/npc/ataman_bandit
	name = "bandit"
	real_name = "bandit"
	ai_controller = /datum/ai_controller/human_npc/ataman_bandit
	faction = list(FACTION_BANDITS)
	ambushable = FALSE

	var/datum/weakref/ataman_owner_ref
	var/datum/weakref/ataman_target_ref
	var/turf/ataman_spawn_turf
	var/ataman_role = ATAMAN_ROLE_ENFORCER
	var/datum/ataman_squad/ataman_squad

/mob/living/carbon/human/npc/ataman_bandit/Initialize(mapload)
	. = ..()
	set_species(pick(NPC_RACES_TYPES))
	gender = pick(MALE, FEMALE)
	dna.species.random_character(src)
	addtimer(CALLBACK(src, PROC_REF(finish_bandit_setup)), 1 SECONDS)

/mob/living/carbon/human/npc/ataman_bandit/proc/finish_bandit_setup()
	ADD_TRAIT(src, TRAIT_NOMOOD, TRAIT_GENERIC)
	ADD_TRAIT(src, TRAIT_NOHUNGER, TRAIT_GENERIC)
	ADD_TRAIT(src, TRAIT_NPC_EXAMINE, TRAIT_GENERIC)
	equipOutfit(new /datum/outfit/job/roguetown/human/species/human/northern/highwayman)
	dna.species.handle_body(src)
	random_voice_NPC()
	random_hair_NPC()
	random_eye_color_NPC()
	correct_features_NPC()
	if(gender == FEMALE)
		real_name = pick(world.file2list("strings/names/first_female.txt"))
	else
		real_name = pick(world.file2list("strings/names/first_male.txt"))
	name = real_name

/mob/living/carbon/human/npc/ataman_bandit/proc/set_ataman(mob/living/carbon/human/owner, turf/spawn_turf, mob/living/target, role = ATAMAN_ROLE_ENFORCER, datum/ataman_squad/squad)
	ataman_spawn_turf = spawn_turf || get_turf(src)
	ataman_role = role
	ataman_squad = squad
	if(target)
		ataman_target_ref = WEAKREF(target)
	if(ai_controller)
		ai_controller.set_blackboard_key(BB_ATAMAN_SPAWN_TURF, ataman_spawn_turf)
		ai_controller.set_blackboard_key(BB_ATAMAN_OWNER, owner)
		ai_controller.set_blackboard_key(BB_ATAMAN_TARGET, target)
		ai_controller.set_blackboard_key(BB_ATAMAN_ROLE, ataman_role)
		ai_controller.set_blackboard_key(BB_ATAMAN_SQUAD, squad)
		ai_controller.set_blackboard_key(BB_BASIC_MOB_CURRENT_TARGET, target)
		ai_controller.set_blackboard_key(BB_HIGHEST_THREAT_MOB, target)
	if(!owner)
		return
	ataman_owner_ref = WEAKREF(owner)
	summoner = owner.real_name
	faction += "[owner.real_name]_ataman_gang"
	apply_mob_lifespan(src, owner, 5 MINUTES)
