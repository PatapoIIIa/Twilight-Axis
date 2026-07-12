// Dedicated, always-on trace log for the ambush bandit AI - every role assignment,
// subtree branch, queued behavior and squad-tactic decision gets a line here so a
// single test round is enough to see exactly what each bandit was thinking and when.
// Toggle with GLOB.ataman_ai_logging (VV it to FALSE to quiet it down mid-round).
// Read the file back with SendUserFile/an editor - it lives at data/logs/<round>/ataman_ai.log.
GLOBAL_VAR_INIT(ataman_ai_logging, TRUE)
GLOBAL_VAR_INIT(ataman_ai_log_file, null)

/proc/ataman_ai_log(mob/living/source, message)
	if(!GLOB.ataman_ai_logging)
		return
	if(!GLOB.ataman_ai_log_file)
		GLOB.ataman_ai_log_file = "[GLOB.log_directory]/ataman_ai.log"
	var/tag = "SQUAD"
	if(istype(source, /mob/living/carbon/human/npc/ataman_bandit))
		var/mob/living/carbon/human/npc/ataman_bandit/bandit = source
		tag = "[bandit.real_name]#[REF(bandit)] role=[bandit.ataman_role]"
	else if(source)
		tag = "[source.real_name]"
	WRITE_LOG(GLOB.ataman_ai_log_file, "\[[station_time_timestamp()]\] [tag]: [message]")
