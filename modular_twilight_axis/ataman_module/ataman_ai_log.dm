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
