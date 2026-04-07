// ============================================================
// Dead Knight — major antagonist, melee subclass of the Lich
// Inherits phylactery/resurrection system; replaces magic with
// runic blade combo (Blood / Ice / Unholy stacks).
// ============================================================

/datum/antagonist/lich/dead_knight
	name = "Dead Knight"
	roundend_category = "Dead Knight"
	antagpanel_category = "Dead Knight"
	job_rank = ROLE_DEAD_KNIGHT
	confess_lines = list(
		"THE RUNES WILL NEVER FADE!",
		"MY BLADE DRINKS DEEP!",
		"DEATH IS MERELY THE BEGINNING!",
	)

/datum/antagonist/lich/dead_knight/greet()
	to_chat(owner.current, span_userdanger("An undying knight rises from the grave. Let the runes sing, and let the living tremble."))
	owner.announce_objectives()
	owner.current.playsound_local(get_turf(owner.current), 'sound/villain/lichintro.ogg', 80, FALSE, pressure_affected = FALSE)

/datum/antagonist/lich/dead_knight/equip_lich()
	owner.unknow_all_people()
	for(var/datum/mind/MF in get_minds())
		owner.become_unknown_to(MF)

	var/mob/living/carbon/human/L = owner.current
	L.cmode_music = 'modular_twilight_axis/sound/music/combat_lich.ogg'
	L.faction = list("undead")

	for(var/datum/charflaw/cf in L.charflaws)
		L.charflaws.Remove(cf)
		QDEL_NULL(cf)

	L.mob_biotypes |= MOB_UNDEAD
	replace_eyes(L)

	for(var/obj/item/bodypart/B in L.bodyparts)
		B.skeletonize(FALSE)

	for(var/obj/item/I in L)
		L.dropItemToGround(I, TRUE)
		qdel(I)

	equip_and_traits()
	L.equipOutfit(/datum/outfit/job/roguetown/dead_knight)
	L.set_patron(/datum/patron/inhumen/zizo)
	L.regenerate_icons()
	owner.current.forceMove(pick(GLOB.vlord_starts))

/datum/antagonist/lich/dead_knight/equip_and_traits()
	var/mob/living/carbon/human/body = owner.current
	var/list/equipment_slots = list(
		SLOT_HEAD,
		SLOT_PANTS,
		SLOT_SHOES,
		SLOT_NECK,
		SLOT_ARMOR,
		SLOT_SHIRT,
		SLOT_WRISTS,
		SLOT_GLOVES,
		SLOT_BELT,
		SLOT_BELT_L,
		SLOT_BACK_L,
	)

	var/list/equipment_items = list(
		/obj/item/clothing/head/roguetown/helmet/heavy/knight,
		/obj/item/clothing/under/roguetown/platelegs,
		/obj/item/clothing/shoes/roguetown/boots,
		/obj/item/clothing/neck/roguetown/chaincoif,
		/obj/item/clothing/suit/roguetown/armor/plate/blacksteel,
		/obj/item/clothing/suit/roguetown/armor/gambeson/light,
		/obj/item/clothing/wrists/roguetown/bracers,
		/obj/item/clothing/gloves/roguetown/plate/blacksteel,
		/obj/item/storage/belt/rogue/leather/black,
		/obj/item/rogueweapon/huntingknife/idagger/steel,
		/obj/item/storage/backpack/rogue/satchel,
	)
	for(var/i = 1, i <= equipment_slots.len, i++)
		var/slot = equipment_slots[i]
		var/item_type = equipment_items[i]
		body.equip_to_slot_or_del(new item_type, slot, TRUE)

	for(var/trait in traits_lich)
		ADD_TRAIT(body, trait, "[type]")

// --- Dead Knight outfit (skills, spells, combo) ---

/datum/outfit/job/roguetown/dead_knight/pre_equip(mob/living/carbon/human/H)
	..()

	H.adjust_skillrank(/datum/skill/combat/swords, 6, TRUE)
	H.adjust_skillrank(/datum/skill/combat/wrestling, 4, TRUE)
	H.adjust_skillrank(/datum/skill/combat/unarmed, 3, TRUE)
	H.adjust_skillrank(/datum/skill/combat/knives, 3, TRUE)
	H.adjust_skillrank(/datum/skill/combat/shields, 2, TRUE)
	H.adjust_skillrank(/datum/skill/misc/athletics, 4, TRUE)
	H.adjust_skillrank(/datum/skill/misc/climbing, 2, TRUE)
	H.adjust_skillrank(/datum/skill/misc/riding, 5, TRUE)
	H.adjust_skillrank(/datum/skill/misc/reading, 2, TRUE)
	H.adjust_skillrank(/datum/skill/misc/medicine, 1, TRUE)
	H.adjust_skillrank(/datum/skill/craft/crafting, 1, TRUE)

	H.change_stat(STATKEY_STR, 5)
	H.change_stat(STATKEY_CON, 5)
	H.change_stat(STATKEY_SPD, 3)
	H.change_stat(STATKEY_PER, 3)
	H.change_stat(STATKEY_INT, 2)

	H.grant_language(/datum/language/undead)

	if(H.mind)
		H.AddComponent(/datum/component/combo_core/dead_knight, DK_COMBO_WINDOW, DK_MAX_HISTORY)

		H.mind.AddSpell(new /obj/effect/proc_holder/spell/self/dead_knight/summon_blade)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/self/dead_knight/toggle_stance)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/self/dead_knight/blood_strike)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/self/dead_knight/ice_strike)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/self/dead_knight/unholy_strike)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/self/dead_knight/plague_mark)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/self/dead_knight/blood_worms)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/self/dead_knight/ice_immovability)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/self/dead_knight/army_of_darkness)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/self/dead_knight/summon_death_horse)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/invoked/minion_order)
		H.mind.AddSpell(new /obj/effect/proc_holder/spell/self/lich_announce)

	H.ambushable = FALSE
	H.dna.species.soundpack_m = new /datum/voicepack/other/lich()

	addtimer(CALLBACK(H, TYPE_PROC_REF(/mob/living/carbon/human, choose_name_popup), "DEAD KNIGHT"), 5 SECONDS)

/datum/outfit/job/roguetown/dead_knight/post_equip(mob/living/carbon/human/H)
	..()
	var/datum/antagonist/lich/dead_knight/dkman = H.mind.has_antag_datum(/datum/antagonist/lich/dead_knight)
	if(!dkman)
		dkman = H.mind.has_antag_datum(/datum/antagonist/lich)
	if(dkman)
		var/obj/item/phylactery/new_phylactery = new(H.loc)
		dkman.phylacteries += new_phylactery
		new_phylactery.possessor = dkman
		H.equip_to_slot_or_del(new_phylactery, SLOT_IN_BACKPACK, TRUE)
