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
	neck = /obj/item/clothing/neck/roguetown/chaincoif
	pants = /obj/item/clothing/under/roguetown/heavy_leather_pants
	armor = /obj/item/clothing/suit/roguetown/armor/leather
	shirt = /obj/item/clothing/suit/roguetown/shirt/undershirt/black
	cloak = /obj/item/clothing/cloak/thief_cloak
	backl = /obj/item/storage/backpack/rogue/satchel
	belt = /obj/item/storage/belt/rogue/leather/knifebelt/black/steel
	gloves = /obj/item/clothing/gloves/roguetown/plate
	shoes = /obj/item/clothing/shoes/roguetown/boots/armor/iron
	wrists = /obj/item/clothing/wrists/roguetown/bracers/jackchain
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
	backr = /obj/item/rogueweapon/shield/iron
	beltr = /obj/item/rogueweapon/scabbard/sword
	H.adjust_skillrank_up_to(/datum/skill/combat/swords, SKILL_LEVEL_EXPERT, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/combat/shields, SKILL_LEVEL_JOURNEYMAN, TRUE)

/datum/outfit/job/roguetown/wretch/ataman/proc/spear_shield_equip(mob/living/carbon/human/H)
	r_hand = /obj/item/rogueweapon/spear
	backr = /obj/item/rogueweapon/shield/iron
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
	backr = /obj/item/rogueweapon/shield/iron
	backl = /obj/item/gun/ballistic/revolver/grenadelauncher/crossbow
	beltl = /obj/item/quiver/bolt/standard
	H.adjust_skillrank_up_to(/datum/skill/combat/maces, SKILL_LEVEL_JOURNEYMAN, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/combat/shields, SKILL_LEVEL_JOURNEYMAN, TRUE)
	H.adjust_skillrank_up_to(/datum/skill/combat/crossbows, SKILL_LEVEL_EXPERT, TRUE)

/datum/outfit/job/roguetown/wretch/ataman/proc/grant_ataman_spells(mob/living/carbon/human/H)
	H.mind.AddSpell(new /datum/action/cooldown/spell/ataman_ambush)
	H.mind.AddSpell(new /datum/action/cooldown/spell/ataman_trap)
	H.mind.AddSpell(new /datum/action/cooldown/spell/ataman_execute)
	H.mind.AddSpell(new /datum/action/cooldown/spell/ataman_exchange)
