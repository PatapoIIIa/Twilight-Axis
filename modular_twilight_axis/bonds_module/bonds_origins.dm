// Where a character is from. Origins are a third identity axis alongside job faction and
// vampire clan: they never change during a round, they are shared by people who have nothing
// else in common, and they carry inherited opinion about each other (see bonds_origin_lore.dm).
//
// The value lives in prefs (virtue_origin), which can vanish with the client, so it is read
// once and cached on the actor.

/datum/bond_origin
	abstract_type = /datum/bond_origin
	var/id = ""
	var/name = ""
	var/virtue_type

/datum/bond_origin/azuria
	id = "azuria"
	name = "Азурия"
	virtue_type = /datum/virtue/origin/azuria
/datum/bond_origin/grenzelhoft
	id = "grenzelhoft"
	name = "Гренцельхофт"
	virtue_type = /datum/virtue/origin/grenzelhoft
/datum/bond_origin/zybantian
	id = "zybantu"
	name = "Зибанту"
	virtue_type = /datum/virtue/origin/zybantian
/datum/bond_origin/valorian
	id = "valoria"
	name = "Валория"
	virtue_type = /datum/virtue/origin/valorian
/datum/bond_origin/otava
	id = "otava"
	name = "Отава"
	virtue_type = /datum/virtue/origin/otava
/datum/bond_origin/naledi
	id = "naledi"
	name = "Наледи"
	virtue_type = /datum/virtue/origin/naledi
/datum/bond_origin/heartfelt
	id = "heartfelt"
	name = "Хартфельт"
	virtue_type = /datum/virtue/origin/heartfelt
/datum/bond_origin/etrusca
	id = "etrusca"
	name = "Этруска"
	virtue_type = /datum/virtue/origin/etrusca
/datum/bond_origin/gronn
	id = "gronn"
	name = "Гронн"
	virtue_type = /datum/virtue/origin/gronn
/datum/bond_origin/hammerhold
	id = "hammerhold"
	name = "Хаммерхольд"
	virtue_type = /datum/virtue/origin/hammerhold
/datum/bond_origin/kazengun
	id = "kazengun"
	name = "Казенгун"
	virtue_type = /datum/virtue/origin/kazengun
/datum/bond_origin/lingyue
	id = "lingyue"
	name = "Линъюэ"
	virtue_type = /datum/virtue/origin/lingyue
/datum/bond_origin/avar
	id = "avar"
	name = "Авар"
	virtue_type = /datum/virtue/origin/avar
/datum/bond_origin/gyedzenese
	id = "gyedzen"
	name = "Гьедзен"
	virtue_type = /datum/virtue/origin/gyedzenese
/datum/bond_origin/raneshen
	id = "raneshen"
	name = "Ранешен"
	virtue_type = /datum/virtue/origin/raneshen
/datum/bond_origin/enigma
	id = "enigma"
	name = "Энигма"
	virtue_type = /datum/virtue/origin/enigma
/datum/bond_origin/unknown
	id = "unknown"
	name = "Неизвестно откуда"
	virtue_type = /datum/virtue/origin/unknown

/datum/controller/subsystem/bonds/proc/build_origin_index()
	origin_prototypes = list()
	origin_index = list()
	for(var/datum/bond_origin/origin_type as anything in typesof(/datum/bond_origin))
		if(IS_ABSTRACT(origin_type))
			continue
		var/datum/bond_origin/origin = new origin_type()
		origin_prototypes[origin.id] = origin
		if(origin.virtue_type)
			origin_index[origin.virtue_type] = origin
	bondlog("origin index built: [origin_prototypes.len] origins", BONDLOG_INFO)

/datum/controller/subsystem/bonds/proc/origin_for(participant)
	var/datum/bond_actor/actor = resolve_actor(participant)
	if(!actor)
		return null
	if(actor.cached_origin_id)
		return origin_prototypes[actor.cached_origin_id]
	var/mob/living/carbon/human/body = actor.current_body()
	var/datum/virtue/virtue = body?.client?.prefs?.virtue_origin
	if(!virtue)
		return null
	var/datum/bond_origin/origin = origin_index[virtue.type]
	if(!origin)
		return null
	actor.cached_origin_id = origin.id
	return origin

/datum/controller/subsystem/bonds/proc/origin_id_for(participant)
	var/datum/bond_origin/origin = origin_for(participant)
	return origin?.id
