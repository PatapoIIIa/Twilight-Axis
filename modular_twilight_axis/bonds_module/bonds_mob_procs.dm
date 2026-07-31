/mob/living/carbon/human/proc/bonds_open_panel()
	var/datum/bonds_panel/panel = new(src)
	panel.ui_interact(src)
	return TRUE

/mob/living/carbon/human/verb/my_bonds()
	set name = "My Bonds"
	set category = "IC"

	if(!mind)
		to_chat(src, span_warning("Вам некого вспоминать."))
		return
	bonds_open_panel()

/mob/living/carbon/human/verb/bonds_settings()
	set name = "Bond Settings"
	set category = "Preferences"

	if(!client?.prefs)
		return
	var/datum/bonds_prefs_panel/panel = new(src)
	panel.ui_interact(src)
