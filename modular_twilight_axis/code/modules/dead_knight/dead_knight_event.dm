// ============================================================
// Dead Knight — solo event spawner
// ============================================================

/datum/round_event_control/antagonist/solo/dead_knight
	name = "Dead Knight"
	tags = list(
		TAG_COMBAT,
		TAG_HAUNTED,
		TAG_VILLIAN,
	)
	roundstart = TRUE
	antag_flag = ROLE_DEAD_KNIGHT
	shared_occurence_type = SHARED_HIGH_THREAT

	denominator = 80

	base_antags = 1
	maximum_antags = 1

	weight = 2
	max_occurrences = 1

	earliest_start = 0 SECONDS

	typepath = /datum/round_event/antagonist/solo/dead_knight
	antag_datum = /datum/antagonist/lich/dead_knight

	restricted_roles = DEFAULT_ANTAG_BLACKLISTED_ROLES

/datum/round_event_control/antagonist/solo/dead_knight/preRunEvent()
	if(is_storyteller_villain_blocked())
		return EVENT_CANT_RUN
	return ..()

/datum/round_event/antagonist/solo/dead_knight
