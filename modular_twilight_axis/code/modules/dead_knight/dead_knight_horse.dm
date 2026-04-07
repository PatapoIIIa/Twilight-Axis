// ============================================================
// Death Horse — Dead Knight's summoned mount
// Based on undead saiga template, themed as spectral horse.
// ============================================================

/mob/living/simple_animal/hostile/retaliate/rogue/saiga/undead/death_horse
	name = "death horse"
	desc = "A nightmarish steed wreathed in dark mist. Its hooves leave frost on the ground, and its hollow eyes burn with unholy light."
	icon = 'icons/roguetown/mob/monster/horse.dmi'
	icon_state = "horse"
	icon_living = "horse"
	icon_dead = "horse_dead"
	icon_downed = "horse_dead"

	health = 600
	maxHealth = 600
	leg_health = 200
	max_leg_health = 200
	head_health = 150
	max_head_health = 150

	melee_damage_lower = 40
	melee_damage_upper = 60

	move_to_delay = 6
	mob_biotypes = MOB_UNDEAD
	faction = list("undead")

	can_buckle = TRUE
	can_saddle = FALSE
	buckle_lying = FALSE
	max_buckled_mobs = 1

	aggressive = 1
	retreat_health = 0
	retreat_distance = 0
	minimum_distance = 0

	del_on_death = FALSE

	var/mob/living/bound_rider

/mob/living/simple_animal/hostile/retaliate/rogue/saiga/undead/death_horse/Initialize(mapload, mob/living/summoner)
	. = ..()
	if(summoner)
		bound_rider = summoner
		faction = list("undead", "[summoner.real_name]_faction")
		if(summoner.mind?.current)
			faction |= "[summoner.mind.current.real_name]_faction"
	setup_mount()
	add_filter("dk_horse_glow", 2, list("type" = "outline", "color" = "#4a0080", "size" = 1))

/mob/living/simple_animal/hostile/retaliate/rogue/saiga/undead/death_horse/Destroy()
	bound_rider = null
	return ..()

/mob/living/simple_animal/hostile/retaliate/rogue/saiga/undead/death_horse/death()
	unbuckle_all_mobs()
	can_buckle = FALSE
	visible_message(span_danger("[src] lets out a final whinny and dissolves into dark mist!"))
	. = ..()

/mob/living/simple_animal/hostile/retaliate/rogue/saiga/undead/death_horse/reanimation()
	return
