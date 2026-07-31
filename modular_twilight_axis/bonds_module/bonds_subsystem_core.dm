SUBSYSTEM_DEF(bonds)
	name = "bonds"
	flags = SS_NO_FIRE
	lazy_load = FALSE

	var/list/nodes = list()
	var/list/actors_by_mind = list()
	var/list/actors_by_phantom = list()
	var/list/event_prototypes = list()
	var/list/stage_prototypes = list()
	var/list/round_prefs_by_ckey = list()
	var/list/round_ledger = list()
	var/list/faction_prototypes = list()
	var/list/faction_index = list()
	var/list/clan_index = list()
	var/list/origin_prototypes = list()
	var/list/origin_index = list()
	var/list/origin_lore = list()
	var/list/role_weights = list()
	var/list/map_lenses = list()
	var/list/influence_pools = list()
	var/list/faction_stances = list()
	var/list/house_stances = list()
	var/list/storyteller_lenses = list()
	var/storyteller_lens_applied = FALSE
	var/bonds_log_file
	var/bondlog_counter = 0
	var/bondlog_error_count = 0
	var/bondlog_warn_count = 0
#ifdef BONDS_DEBUG_LOGGING
	var/verbose_logging = TRUE
#else
	var/verbose_logging = FALSE
#endif

/datum/controller/subsystem/bonds/Initialize()
	build_event_prototypes()
	build_stage_prototypes()
	build_faction_index()
	build_clan_index()
	build_origin_index()
	build_origin_lore()
	build_role_weights()
	build_map_lenses()
	build_storyteller_lenses()
	build_faction_stances()
	RegisterSignal(SSdcs, COMSIG_GLOB_MOB_CREATED, PROC_REF(on_mob_created))
	schedule_seeding()
	bondlog("Initialize() DONE, events=[event_prototypes.len] stages=[stage_prototypes.len]", BONDLOG_INFO)
	return ..()

/datum/controller/subsystem/bonds/proc/bondlog(msg, level = BONDLOG_DEBUG)
	if(level == BONDLOG_DEBUG && !verbose_logging)
		return
	if(!bonds_log_file)
		if(GLOB.log_directory)
			bonds_log_file = "[GLOB.log_directory]/ss_bonds.log"
		else
			bonds_log_file = "data/logs/ss_bonds.log"
	bondlog_counter++
	if(level == BONDLOG_ERROR)
		bondlog_error_count++
	if(level == BONDLOG_WARN)
		bondlog_warn_count++
	WRITE_LOG(bonds_log_file, "\[[logtime]] [level] #[bondlog_counter] [msg]")

/datum/controller/subsystem/bonds/proc/build_event_prototypes()
	for(var/datum/bond_event/event_type as anything in typesof(/datum/bond_event))
		if(IS_ABSTRACT(event_type))
			continue
		event_prototypes[event_type] = new event_type()

/datum/controller/subsystem/bonds/proc/get_event_prototype(event_type)
	return event_prototypes[event_type]

/datum/controller/subsystem/bonds/proc/bondlog_state(tag = "SNAPSHOT")
	bondlog("=== [tag] ===", BONDLOG_INFO)
	var/total_bonds = 0
	for(var/datum/mind/owner as anything in nodes)
		var/datum/bond_node/node = nodes[owner]
		total_bonds += length(node.bonds)
	bondlog("[tag] nodes=[nodes.len] bonds=[total_bonds] errors=[bondlog_error_count] warns=[bondlog_warn_count]", BONDLOG_INFO)
	bondlog("=== /[tag] ===", BONDLOG_INFO)
