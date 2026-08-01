GLOBAL_LIST_EMPTY(bonds_debug_population)
GLOBAL_LIST_EMPTY(bonds_debug_rows)

/datum/controller/subsystem/bonds/proc/register_debug_verbs()
	GLOB.admin_verbs_debug |= list(
		/client/proc/bonds_debug_load,
		/client/proc/bonds_debug_timeskip,
		/client/proc/bonds_debug_degrade,
		/client/proc/bonds_debug_purge,
	)

/datum/bonds_bench
	var/label = ""
	var/phase = ""
	var/started = 0
	var/tick_peak = 0
	var/list/rows = list()

/datum/bonds_bench/New(bench_label = "bench")
	label = bench_label
	SSbonds.bondlog("=== BENCH [label] BEGIN ===", BONDLOG_INFO)

/datum/bonds_bench/proc/open(name)
	phase = name
	tick_peak = TICK_USAGE
	started = world.timeofday

/datum/bonds_bench/proc/sample()
	var/now = TICK_USAGE
	if(now > tick_peak)
		tick_peak = now

/datum/bonds_bench/proc/close(ops = 0)
	var/elapsed = world.timeofday - started
	if(elapsed < 0)
		elapsed += 864000
	var/ms = elapsed * 100
	var/per_op = ops > 0 ? (ms * 1000 / ops) : 0
	var/list/state = SSbonds.debug_graph_state()
	var/line = "[label] | [phase] | ops=[ops] ms=[ms] us/op=[round(per_op, 0.1)] peak_tick=[round(tick_peak, 0.1)]% | nodes=[state["nodes"]] bonds=[state["bonds"]] kin=[state["kin"]] history=[state["history"]] active=[state["active"]] stances=[state["stances"]] pools=[state["pools"]]"
	rows += line
	GLOB.bonds_debug_rows += line
	SSbonds.bondlog(line, BONDLOG_INFO)
	return line

/datum/controller/subsystem/bonds/proc/debug_graph_state()
	RETURN_TYPE(/list)
	var/bonds_total = 0
	var/kin_total = 0
	var/history_total = 0
	var/active_total = 0
	for(var/datum/bond_actor/owner as anything in nodes)
		var/datum/bond_node/node = nodes[owner]
		if(!node)
			continue
		bonds_total += length(node.bonds)
		kin_total += length(node.kin)
		for(var/datum/bond_actor/target as anything in node.bonds)
			var/datum/social_bond/bond = node.bonds[target]
			history_total += LAZYLEN(bond.history)
			active_total += LAZYLEN(bond.active_events)
	return list(
		"nodes" = length(nodes),
		"bonds" = bonds_total,
		"kin" = kin_total,
		"history" = history_total,
		"active" = active_total,
		"stances" = length(faction_stances),
		"pools" = length(influence_pools),
	)

/datum/controller/subsystem/bonds/proc/debug_job_pool()
	RETURN_TYPE(/list)
	var/list/pool = list()
	for(var/job_type in faction_index)
		pool += job_type
	return pool

/datum/controller/subsystem/bonds/proc/debug_spawn_population(count, turf/spot)
	RETURN_TYPE(/list)
	var/list/pool = list()
	var/list/job_types = debug_job_pool()
	if(!length(job_types) || !spot)
		return pool
	for(var/i in 1 to count)
		var/mob/living/carbon/human/body = new(spot)
		body.real_name = "Bench [i]"
		body.name = body.real_name
		body.ckey = "BENCH[i]"
		if(!body.mind)
			body.mind = new /datum/mind(body.ckey)
		body.mind.current = body
		body.mind.name = body.real_name
		var/job_type = job_types[((i - 1) % length(job_types)) + 1]
		var/datum/job/role = SSjob.GetJobType(job_type)
		if(role)
			body.mind.assigned_role = role.title
			body.job = role.title
		register_human(body)
		var/datum/bonds_round_prefs/prefs = new()
		prefs.ckey = body.ckey
		prefs.seed_count = BOND_MAX_SEEDS
		prefs.seed_flavors = valid_seed_flavors().Copy()
		round_prefs_by_ckey[body.ckey] = prefs
		pool += body
	return pool

/datum/controller/subsystem/bonds/proc/debug_purge_population()
	for(var/mob/living/carbon/human/body as anything in GLOB.bonds_debug_population)
		if(QDELETED(body))
			continue
		if(body.mind)
			drop_actor(resolve_actor(body.mind))
			round_prefs_by_ckey -= body.ckey
			round_ledger -= body.ckey
		qdel(body)
	GLOB.bonds_debug_population = list()

/datum/controller/subsystem/bonds/proc/debug_storm(list/pool, count, list/event_types)
	var/fired = 0
	for(var/i in 1 to count)
		var/mob/living/carbon/human/subject = pick(pool)
		var/mob/living/carbon/human/object = pick(pool)
		if(subject == object || QDELETED(subject) || QDELETED(object))
			continue
		var/event_type = pick(event_types)
		record(subject.mind, object.mind, event_type, object, TRUE)
		social_impact(subject.mind, object.mind, event_type)
		fired++
	return fired

/datum/controller/subsystem/bonds/proc/debug_timeskip(deciseconds)
	var/expired = 0
	for(var/datum/bond_actor/owner as anything in nodes)
		var/datum/bond_node/node = nodes[owner]
		if(!node)
			continue
		for(var/datum/bond_actor/target as anything in node.bonds)
			var/datum/social_bond/bond = node.bonds[target]
			bond.swing_reset -= deciseconds
			bond.updated_at -= deciseconds
			if(bond.commit_times)
				for(var/category in bond.commit_times)
					bond.commit_times[category] -= deciseconds
			for(var/datum/bond_history/entry as anything in bond.history)
				entry.created_at -= deciseconds
			if(LAZYLEN(bond.active_events))
				for(var/category in bond.active_events.Copy())
					var/datum/bond_event/live = bond.active_events[category]
					if(!live || live.timeout <= 0)
						continue
					if(live.timeout > deciseconds)
						continue
					if(live.timer_id)
						deltimer(live.timer_id)
						live.timer_id = null
					live.expire()
					expired++
			bond.recalculate()
	for(var/datum/bond_actor/actor as anything in influence_pools)
		var/list/state = influence_pools[actor]
		if(!islist(state))
			continue
		state["refill"] -= deciseconds
		state["banned_until"] = max(0, state["banned_until"] - deciseconds)
	return expired

/datum/controller/subsystem/bonds/proc/debug_seeding_pass(list/pool)
	var/paired = 0
	for(var/mob/living/carbon/human/seeker as anything in pool)
		if(remaining_seeds(seeker.ckey) <= 0)
			continue
		var/list/candidates = seed_candidates(seeker, pool)
		if(!length(candidates))
			continue
		if(apply_seed(seeker, pick(candidates)))
			paired++
	return paired

/datum/controller/subsystem/bonds/proc/debug_panel_pass(list/pool, samples)
	var/built = 0
	for(var/i in 1 to samples)
		var/mob/living/carbon/human/viewer = pool[((i - 1) % length(pool)) + 1]
		build_panel_groups(viewer)
		build_bonds_tree(viewer)
		build_faction_map(viewer)
		built++
	return built

/datum/controller/subsystem/bonds/proc/debug_dream_pass(list/pool)
	var/rolled = 0
	for(var/mob/living/carbon/human/dreamer as anything in pool)
		if(QDELETED(dreamer))
			continue
		roll_dream(dreamer)
		rolled++
	return rolled

/datum/controller/subsystem/bonds/proc/debug_forced_dream_pass(list/pool)
	var/fired = 0
	for(var/mob/living/carbon/human/dreamer as anything in pool)
		if(QDELETED(dreamer))
			continue
		if(fire_dream(dreamer, BOND_DREAM_POSITIVE, BOND_DREAM_SCOPE_FOREIGN))
			fired++
	return fired

/datum/controller/subsystem/bonds/proc/debug_event_pool()
	RETURN_TYPE(/list)
	return list(
		/datum/bond_event/struck_by,
		/datum/bond_event/struck_them,
		/datum/bond_event/beaten_by,
		/datum/bond_event/embraced_by,
		/datum/bond_event/embraced_them,
	)

/client/proc/bonds_debug_load()
	set name = "Bonds Bench: Load"
	set category = "Debug"

	if(!check_rights(R_DEBUG))
		return
	var/turf/spot = get_turf(mob)
	if(!spot)
		to_chat(src, span_warning("Нужна точка отсчёта: встаньте на турф."))
		return
	var/players = input(src, "Сколько синтетических игроков?", "Bonds Bench", 120) as num|null
	if(!players)
		return
	var/events = input(src, "Сколько событий прогнать?", "Bonds Bench", 600) as num|null
	if(isnull(events))
		return
	players = clamp(players, 2, 400)
	events = clamp(events, 0, 20000)

	if(length(GLOB.bonds_debug_population))
		SSbonds.debug_purge_population()

	to_chat(src, span_notice("Бенчмарк запущен. Сервер будет подвисать: замеры идут без CHECK_TICK внутри фаз."))
	var/datum/bonds_bench/bench = new("load[players]")

	bench.open("spawn+register")
	GLOB.bonds_debug_population = SSbonds.debug_spawn_population(players, spot)
	bench.close(players)
	var/list/pool = GLOB.bonds_debug_population
	if(!length(pool))
		to_chat(src, span_warning("Не удалось создать популяцию."))
		return
	CHECK_TICK

	bench.open("seeding")
	var/paired = SSbonds.debug_seeding_pass(pool)
	bench.close(length(pool))
	to_chat(src, span_notice("Сидинг связал пар: [paired]"))
	CHECK_TICK

	bench.open("events")
	var/fired = SSbonds.debug_storm(pool, events, SSbonds.debug_event_pool())
	bench.close(fired)
	CHECK_TICK

	bench.open("dreams")
	var/rolled = SSbonds.debug_dream_pass(pool)
	bench.close(rolled)
	CHECK_TICK

	bench.open("dreams-forced")
	SSbonds.debug_forced_dream_pass(pool)
	bench.close(length(pool))
	CHECK_TICK

	bench.open("panels")
	var/built = SSbonds.debug_panel_pass(pool, min(length(pool), 60))
	bench.close(built)

	for(var/line in bench.rows)
		to_chat(src, span_smallnotice(line))
	to_chat(src, span_notice("Готово. Полный отчёт в data/logs/ss_bonds.log"))

/client/proc/bonds_debug_timeskip()
	set name = "Bonds Bench: Time Skip"
	set category = "Debug"

	if(!check_rights(R_DEBUG))
		return
	var/minutes = input(src, "На сколько минут промотать?", "Bonds Bench", 15) as num|null
	if(!minutes)
		return
	minutes = clamp(minutes, 1, 600)
	var/datum/bonds_bench/bench = new("skip[minutes]m")
	bench.open("timeskip")
	var/expired = SSbonds.debug_timeskip(minutes MINUTES)
	bench.close(1)
	to_chat(src, span_notice("Промотано [minutes] мин, истекло транзиентов: [expired]"))
	to_chat(src, span_smallnotice(bench.rows[bench.rows.len]))

/client/proc/bonds_debug_degrade()
	set name = "Bonds Bench: Degradation"
	set category = "Debug"

	if(!check_rights(R_DEBUG))
		return
	var/list/pool = GLOB.bonds_debug_population
	if(!length(pool))
		to_chat(src, span_warning("Сначала запустите Bonds Bench: Load."))
		return
	var/waves = input(src, "Сколько волн (одна волна = отрезок раунда)?", "Bonds Bench", 8) as num|null
	if(!waves)
		return
	var/events = input(src, "Событий на волну?", "Bonds Bench", 400) as num|null
	if(isnull(events))
		return
	var/minutes = input(src, "Минут на волну?", "Bonds Bench", 15) as num|null
	if(!minutes)
		return
	waves = clamp(waves, 1, 60)
	events = clamp(events, 0, 20000)
	minutes = clamp(minutes, 1, 120)

	var/datum/bonds_bench/bench = new("degrade[waves]x[minutes]m")
	var/list/event_types = SSbonds.debug_event_pool()
	for(var/wave in 1 to waves)
		bench.open("w[wave]-events")
		var/fired = SSbonds.debug_storm(pool, events, event_types)
		bench.close(fired)
		CHECK_TICK

		bench.open("w[wave]-dreams")
		var/rolled = SSbonds.debug_dream_pass(pool)
		bench.close(rolled)
		CHECK_TICK

		bench.open("w[wave]-panels")
		var/built = SSbonds.debug_panel_pass(pool, min(length(pool), 30))
		bench.close(built)
		CHECK_TICK

		bench.open("w[wave]-timeskip")
		SSbonds.debug_timeskip(minutes MINUTES)
		bench.close(1)
		CHECK_TICK

	for(var/line in bench.rows)
		to_chat(src, span_smallnotice(line))
	to_chat(src, span_notice("Деградация за [waves * minutes] симулированных минут отработана."))

/client/proc/bonds_debug_purge()
	set name = "Bonds Bench: Purge"
	set category = "Debug"

	if(!check_rights(R_DEBUG))
		return
	var/count = length(GLOB.bonds_debug_population)
	SSbonds.debug_purge_population()
	GLOB.bonds_debug_rows = list()
	to_chat(src, span_notice("Снесено синтетических тел: [count]"))
