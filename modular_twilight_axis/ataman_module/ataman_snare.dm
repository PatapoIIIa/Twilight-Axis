/obj/structure/trap/ataman_snare
	name = "hidden snare"
	desc = ""
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "beartrap"
	alpha = 0
	charges = 1
	time_between_triggers = 0
	trap_damage = 35
	var/bleed_bonus = 30
	var/datum/weakref/placed_by_ref

/obj/structure/trap/ataman_snare/examine(mob/user)
	if(!isliving(user) || !armed)
		return
	var/mob/living/luser = user
	if(user.mind && (user.mind in immune_minds))
		return
	if(luser.STAPER > 16 && prob(50))
		to_chat(user, span_notice("I spot [src]!"))
		flare()

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
	name = "hidden snare"
	desc = "A concealed set of jaws, ready to bite down on the unwary."

/obj/structure/trap/ataman_snare/beartrap_type/trap_effect(mob/living/L)
	..()
	L.visible_message(span_danger("A hidden trap snaps shut on [L]!"))

/obj/structure/trap/ataman_snare/bomb_type
	name = "hidden charge"
	desc = "A concealed charge, rigged to maim rather than kill."
	icon_state = "trap-fire"

/obj/structure/trap/ataman_snare/bomb_type/trap_effect(mob/living/L)
	..()
	L.visible_message(span_danger("A buried charge rips into [L]!"))

/obj/structure/trap/ataman_snare/stakes_type
	name = "hidden stakes"
	desc = "A pit of sharpened stakes, hidden beneath a false floor."
	icon_state = "trap-earth"

/obj/structure/trap/ataman_snare/stakes_type/trap_effect(mob/living/L)
	..()
	L.visible_message(span_danger("[L] falls onto a bed of hidden stakes!"))
