/obj/structure/trap/ataman_snare
	name = "hidden snare"
	desc = "A concealed set of jaws, ready to bite down on the unwary."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "beartrap"
	alpha = 0
	mouse_opacity = MOUSE_OPACITY_TRANSPARENT
	charges = 1
	time_between_triggers = 0
	trap_damage = 35
	var/bleed_bonus = 30
	var/datum/weakref/placed_by_ref

// Ataman traps are found by mob/living/look_around(); examining them never reveals them.
/obj/structure/trap/ataman_snare/examine(mob/user)
	return

/obj/structure/trap/ataman_snare/proc/set_placer(mob/living/carbon/human/placer)
	if(!placer)
		return
	placed_by_ref = WEAKREF(placer)
	if(placer.mind)
		immune_minds += placer.mind
	AddComponent(/datum/component/ataman_trap_owner_view, placer)

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
	name = "mantrap"
	desc = "A crude iron mantrap."
	icon = 'icons/roguetown/items/misc.dmi'
	icon_state = "beartrap"

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
