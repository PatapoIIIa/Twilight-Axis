GLOBAL_LIST_INIT(familytree_probe_confirm_types, list(
	"family",
	"house",
	"sibling_house",
	"spouse",
	"targeted_spouse",
	"dynasty",
	"relative",
))

/datum/familytree_probe
	var/guards_checked = 0
	var/types_rendered = 0
	var/blocks_checked = 0

/datum/familytree_probe/proc/session_count()
	var/found = 0
	for(var/datum/family_confirm_session/session in world)
		if(!QDELETED(session))
			found++
	return found

/datum/familytree_probe/proc/run_mutual_guard_probe(mob/living/carbon/human/first, mob/living/carbon/human/second)
	if(!first || !second)
		return fault("the guard probe needs two people")

	first.familytree_confirmation_pending = FALSE
	second.familytree_confirmation_pending = FALSE

	first.familytree_opted_out = TRUE
	SSfamilytree.request_mutual_confirmation(first, second, null, "family")
	guards_checked++
	if(first.familytree_confirmation_pending || second.familytree_confirmation_pending)
		fault("an offer to someone who opted out left a pending flag behind")
	first.familytree_opted_out = FALSE
	first.familytree_confirmation_pending = FALSE
	second.familytree_confirmation_pending = FALSE

	first.familytree_confirmation_pending = TRUE
	SSfamilytree.request_mutual_confirmation(first, second, null, "family")
	guards_checked++
	if(second.familytree_confirmation_pending)
		fault("an offer was opened against someone already holding a confirmation")
	first.familytree_confirmation_pending = FALSE
	second.familytree_confirmation_pending = FALSE

	SSfamilytree.request_mutual_confirmation(first, second, null, "family")
	guards_checked++
	if(first.familytree_confirmation_pending || second.familytree_confirmation_pending)
		fault("an offer to people without clients left them marked pending, so the queue would skip them forever")

	SSfamilytree.request_mutual_confirmation(first, null, null, "family")
	SSfamilytree.request_mutual_confirmation(null, second, null, "family")
	SSfamilytree.request_mutual_confirmation(first, first, null, "family")
	guards_checked += 3

	first.familytree_confirmation_pending = FALSE
	second.familytree_confirmation_pending = FALSE
	return !length(violations)

/datum/familytree_probe/proc/run_timeout_block_probe(mob/living/carbon/human/first, mob/living/carbon/human/second)
	if(!first?.ckey || !second?.ckey)
		return fault("the block probe needs two people with ckeys")

	first.familytree_timeout_blocks = null
	second.familytree_timeout_blocks = null

	if(SSfamilytree.familytree_pair_blocked(first, second))
		return fault("a fresh pair is already blocked")

	SSfamilytree.familytree_record_timeout_block(first, second)
	blocks_checked++
	if(!SSfamilytree.familytree_pair_blocked(first, second))
		fault("an unanswered offer must hold the pair back, or the queue re-offers it at once")
	if(!SSfamilytree.familytree_pair_blocked(second, first))
		fault("the hold-back must read the same from either side")

	for(var/i in 1 to FAMILYTREE_TIMEOUT_BLOCK_ITERATIONS)
		if(!SSfamilytree.familytree_pair_blocked(first, second))
			fault("the hold-back expired after [i - 1] of [FAMILYTREE_TIMEOUT_BLOCK_ITERATIONS] iterations")
			break
		SSfamilytree.familytree_tick_timeout_blocks(first)
		SSfamilytree.familytree_tick_timeout_blocks(second)
		blocks_checked++

	if(SSfamilytree.familytree_pair_blocked(first, second))
		fault("the hold-back outlived its [FAMILYTREE_TIMEOUT_BLOCK_ITERATIONS] iterations, so the pair never meets again")

	first.familytree_timeout_blocks = null
	second.familytree_timeout_blocks = null
	return !length(violations)

/datum/familytree_probe/proc/run_confirm_text_probe(mob/living/carbon/human/first, mob/living/carbon/human/second)
	if(!first || !second)
		return fault("the text probe needs two people")

	var/list/types = GLOB.familytree_probe_confirm_types.Copy()
	types += "a_type_no_one_has_written_yet"

	for(var/confirm_type in types)
		for(var/mutual in list(TRUE, FALSE))
			var/text = SSfamilytree.familytree_confirmation_found_text(confirm_type, first, second, mutual, null)
			types_rendered++
			if(!length(text))
				fault("confirmation type \"[confirm_type]\" renders no text[mutual ? " on the mutual path" : ""], so the prompt would open blank")
		var/body = SSfamilytree.familytree_confirmation_prompt_body("проба", first, second)
		if(!length(body))
			fault("confirmation type \"[confirm_type]\" renders an empty prompt body")
	return !length(violations)

/datum/familytree_probe/proc/run_mutual_sweep(mob/living/carbon/human/first, mob/living/carbon/human/second)
	run_mutual_guard_probe(first, second)
	run_timeout_block_probe(first, second)
	run_confirm_text_probe(first, second)
	return !length(violations)

/datum/familytree_probe/proc/mutual_report()
	var/list/out = list()
	out += "guards:  [guards_checked] refusal paths walked"
	out += "blocks:  [blocks_checked] hold-back steps"
	out += "texts:   [types_rendered] confirmation strings rendered"
	if(length(violations))
		out += "FAULTS ([length(violations)]):"
		for(var/line in violations)
			out += "  - [line]"
	else
		out += "no faults"
	return out.Join("\n")
