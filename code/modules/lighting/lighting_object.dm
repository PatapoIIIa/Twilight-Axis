//TA EDIT START
/datum/lighting_object
	var/needs_update = FALSE
	var/turf/myturf
	var/lamp_lit = FALSE
	var/mutable_appearance/light_underlay
	var/mutable_appearance/lamp_underlay
	var/light_state
	var/light_color
	var/lamp_state
	var/lamp_color

/datum/lighting_object/New(turf/source)
	myturf = source
	if(myturf.lighting_object)
		qdel(myturf.lighting_object, force = TRUE)
	myturf.lighting_object = src
	myturf.luminosity = 0

	needs_update = TRUE
	SSlighting.objects_queue += src

/datum/lighting_object/Destroy(force)
	if (force)
		SSlighting.objects_queue -= src
		if (isturf(myturf))
			set_light_parts(null, null, null, null)
			myturf.lighting_object = null
			myturf.luminosity = 1
		myturf = null

		return ..()

	else
		return QDEL_HINT_LETMELIVE

/datum/lighting_object/proc/update()
	if (!isturf(myturf) || myturf.lighting_object != src)
		qdel(src, TRUE)
		return
//TA EDIT END

	// To the future coder who sees this and thinks
	// "Why didn't he just use a loop?"
	// Well my man, it's because the loop performed like shit.
	// And there's no way to improve it because
	// without a loop you can make the list all at once which is the fastest you're gonna get.
	// Oh it's also shorter line wise.
	// Including with these comments.

	// See LIGHTING_CORNER_DIAGONAL in lighting_corner.dm for why these values are what they are.
	var/static/datum/lighting_corner/dummy/dummy_lighting_corner = new

	var/list/corners = myturf.corners
	var/datum/lighting_corner/cr = dummy_lighting_corner
	var/datum/lighting_corner/cg = dummy_lighting_corner
	var/datum/lighting_corner/cb = dummy_lighting_corner
	var/datum/lighting_corner/ca = dummy_lighting_corner
	if (corners) //done this way for speed
		cr = corners[3] || dummy_lighting_corner
		cg = corners[2] || dummy_lighting_corner
		cb = corners[4] || dummy_lighting_corner
		ca = corners[1] || dummy_lighting_corner

	var/max = max(cr.cache_mx, cg.cache_mx, cb.cache_mx, ca.cache_mx)

	#if LIGHTING_SOFT_THRESHOLD != 0
	var/set_luminosity = max > LIGHTING_SOFT_THRESHOLD
	#else
	// Because of floating points™?, it won't even be a flat 0.
	// This number is mostly arbitrary.
	var/set_luminosity = max > 1e-6
	#endif

	//TA EDIT START
	var/mask = tent_mask()
	var/tent_color
	if(mask && ca.cache_r + ca.cache_g + ca.cache_b > LIGHTING_TENT_THRESHOLD)
		tent_color = rgb(ca.cache_r * 255, ca.cache_g * 255, ca.cache_b * 255)
	var/tent_state = tent_color ? "tent[mask]" : null
	var/new_light_state
	var/new_light_color
	if(myturf.opaque_atom_count > 0)
		var/flat_r = (cr.cache_r + cg.cache_r + cb.cache_r + ca.cache_r) / 4
		var/flat_g = (cr.cache_g + cg.cache_g + cb.cache_g + ca.cache_g) / 4
		var/flat_b = (cr.cache_b + cg.cache_b + cb.cache_b + ca.cache_b) / 4
		if(flat_r + flat_g + flat_b > LIGHTING_TENT_THRESHOLD)
			new_light_state = "flat"
			new_light_color = rgb(flat_r * 255, flat_g * 255, flat_b * 255)
		set_light_parts(new_light_state, new_light_color, tent_state, tent_color)
	else
		set_light_parts(tent_state, tent_color, null, null)
	lamp_lit = set_luminosity
	myturf.luminosity = set_luminosity

/datum/lighting_object/proc/light_part(state, part_color)
	var/mutable_appearance/part = mutable_appearance(LIGHTING_TENT_ICON, state, LIGHTING_LAYER, LIGHTING_PLANE)
	part.appearance_flags = RESET_COLOR | RESET_ALPHA | RESET_TRANSFORM
	part.blend_mode = BLEND_ADD
	part.invisibility = INVISIBILITY_LIGHTING
	part.color = part_color
	return part

/datum/lighting_object/proc/set_light_parts(new_light_state, new_light_color, new_lamp_state, new_lamp_color)
	if(new_light_state == light_state && new_light_color == light_color && new_lamp_state == lamp_state && new_lamp_color == lamp_color)
		return
	remove_underlays()
	light_state = new_light_state
	light_color = new_light_color
	lamp_state = new_lamp_state
	lamp_color = new_lamp_color
	light_underlay = light_state ? light_part(light_state, light_color) : null
	lamp_underlay = lamp_state ? light_part(lamp_state, lamp_color) : null
	add_underlays()

/datum/lighting_object/proc/remove_underlays()
	if(light_underlay)
		myturf.underlays -= light_underlay
	if(lamp_underlay)
		myturf.underlays -= lamp_underlay

/datum/lighting_object/proc/add_underlays()
	if(light_underlay)
		myturf.underlays += light_underlay
	if(lamp_underlay)
		myturf.underlays += lamp_underlay

/datum/lighting_object/proc/reapply()
	remove_underlays()
	add_underlays()
	myturf.luminosity = lamp_lit

/datum/lighting_object/proc/underlay_count()
	. = 0
	if(light_underlay)
		.++
	if(lamp_underlay)
		.++

/datum/lighting_object/proc/tent_mask()
	. = 0
	if(myturf.opaque_atom_count <= 0)
		. |= TENT_COVERS_SELF
	var/turf/neighbor = get_step(myturf, EAST)
	if(neighbor && neighbor.opaque_atom_count <= 0)
		. |= TENT_COVERS_EAST
	neighbor = get_step(myturf, NORTH)
	if(neighbor && neighbor.opaque_atom_count <= 0)
		. |= TENT_COVERS_NORTH
	neighbor = get_step(myturf, NORTHEAST)
	if(neighbor && neighbor.opaque_atom_count <= 0)
		. |= TENT_COVERS_NORTHEAST
//TA EDIT END
