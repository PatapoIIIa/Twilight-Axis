// ============================================================
// Runic Blade — Dead Knight's summoned weapon
// Signal-based recall (only one can exist at a time)
// ============================================================

/obj/item/rogueweapon/sword/long/runic_blade
	name = "runic blade"
	desc = "A cruel, frost-rimed longsword etched with pulsing blood-red runes. Unholy sigils crawl along the fuller, whispering of forgotten oaths and broken kingdoms. It materialises at its master's will — and crumbles to nothing without it."
	force = 30
	force_wielded = 42
	possible_item_intents = list(/datum/intent/sword/cut, /datum/intent/sword/thrust, /datum/intent/sword/strike)
	gripped_intents = list(/datum/intent/sword/cut, /datum/intent/sword/thrust, /datum/intent/sword/strike, /datum/intent/sword/chop)
	icon_state = "vlord"
	item_state = "vlord"
	wbalance = WBALANCE_NORMAL
	max_blade_int = 500
	max_integrity = 9999
	sellprice = 0
	static_price = TRUE
	equip_delay_self = 0
	unequip_delay_self = 0
	blade_dulling = DULLING_SHAFT_CONJURED

	var/mob/living/bound_owner

/obj/item/rogueweapon/sword/long/runic_blade/Initialize(mapload, mob/living/summoner)
	. = ..()
	bound_owner = summoner
	SEND_GLOBAL_SIGNAL(COMSIG_NEW_RUNIC_BLADE_SPAWNED, src)
	RegisterSignal(SSdcs, COMSIG_NEW_RUNIC_BLADE_SPAWNED, PROC_REF(on_recall))
	add_filter(DK_BLADE_FILTER_GLOW, 2, list("type" = "outline", "color" = DK_BLADE_GLOW_COLOR, "size" = DK_BLADE_GLOW_SIZE))

/obj/item/rogueweapon/sword/long/runic_blade/Destroy()
	bound_owner = null
	remove_filter(DK_BLADE_FILTER_GLOW)
	return ..()

/obj/item/rogueweapon/sword/long/runic_blade/proc/on_recall(obj/new_sword)
	SIGNAL_HANDLER
	if(new_sword == src)
		return
	visible_message(span_warning("\The [src] dissolves into dark mist, the runes fading to silence."))
	qdel(src)

/obj/item/rogueweapon/sword/long/runic_blade/proc/is_held_by_owner()
	if(!bound_owner)
		return FALSE
	return (loc == bound_owner)
