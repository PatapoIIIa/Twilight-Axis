/datum/controller/subsystem/bonds
	var/list/archetype_index
	var/list/dream_prototypes
	var/list/dream_buckets

/datum/bond_archetype
	abstract_type = /datum/bond_archetype
	var/flag = 0
	var/list/jobs

/datum/controller/subsystem/bonds/proc/build_archetype_index()
	archetype_index = list()
	for(var/datum/bond_archetype/arch_type as anything in typesof(/datum/bond_archetype))
		if(IS_ABSTRACT(arch_type))
			continue
		var/datum/bond_archetype/arch = new arch_type()
		if(!arch.flag || !length(arch.jobs))
			qdel(arch)
			continue
		for(var/job_type in arch.jobs)
			archetype_index[job_type] |= arch.flag
		qdel(arch)
	bondlog("archetype index built: [archetype_index.len] jobs", BONDLOG_INFO)

/datum/controller/subsystem/bonds/proc/archetypes_for_job(job_type)
	if(!job_type || !archetype_index)
		return 0
	var/current = job_type
	while(current)
		var/found = archetype_index[current]
		if(found)
			return found
		if(current == /datum/job)
			break
		current = type2parent(current)
	return 0

/datum/controller/subsystem/bonds/proc/archetypes_for(mob/living/carbon/human/person)
	return archetypes_for_job(job_type_of(person))

/datum/bond_event/dream
	abstract_type = /datum/bond_event/dream
	category = BOND_CATEGORY_DREAM
	timeout = 0
	scored_propagation = FALSE
	history_label = "Сон"
	var/valence = BOND_DREAM_POSITIVE
	var/scopes = BOND_DREAM_SCOPE_ANY
	var/dreamer_mask = 0
	var/other_mask = 0
	var/storyteller_type
	var/list/maps
	var/vampire_rule = BOND_DREAM_VAMPIRE_NONE
	var/rarity = 10

/datum/bond_event/dream/proc/build_echo(datum/social_bond/context)
	return build_story(context)

/datum/bond_event/dream/proc/fits(dreamer_arch, other_arch, scope)
	if(!(scopes & scope))
		return FALSE
	if(dreamer_mask && !(dreamer_arch & dreamer_mask))
		return FALSE
	if(other_mask && !(other_arch & other_mask))
		return FALSE
	return TRUE

/datum/bond_event/dream/proc/fits_round(map_type, teller_type)
	if(storyteller_type && storyteller_type != teller_type)
		return FALSE
	if(length(maps) && !(map_type in maps))
		return FALSE
	return TRUE

/datum/bond_event/dream/proc/fits_blood(mob/living/carbon/human/dreamer, mob/living/carbon/human/other)
	switch(vampire_rule)
		if(BOND_DREAM_VAMPIRE_OTHER)
			return bonds_is_vampire(other)
		if(BOND_DREAM_VAMPIRE_DREAMER)
			return bonds_is_vampire(dreamer)
	return TRUE

/proc/bonds_is_vampire(mob/living/carbon/human/person)
	return person?.mind?.has_antag_datum(/datum/antagonist/vampire) ? TRUE : FALSE

/datum/bond_event/dream/shield_wall
	valence = BOND_DREAM_POSITIVE
	scopes = BOND_DREAM_SCOPE_OWN
	dreamer_mask = BOND_ARCH_WARRIOR
	other_mask = BOND_ARCH_WARRIOR
	warmth_commit = 18
	weight_commit = 24
	history_label = "Сон о строе"

/datum/bond_event/dream/shield_wall/build_story(datum/social_bond/context)
	return "Мне снится строй: щиты сомкнуты, и слева стоит [context.display_name()]. Во сне я знаю, что этот край не подастся."

/datum/bond_event/dream/shield_wall/build_echo(datum/social_bond/context)
	return "Мы с [context.display_name()] держали один строй, и этот край не подался."

/datum/bond_event/dream/bound_my_wound
	valence = BOND_DREAM_POSITIVE
	other_mask = BOND_ARCH_HEALER
	warmth_commit = 18
	weight_commit = 22
	history_label = "Сон о лекаре"

/datum/bond_event/dream/bound_my_wound/build_story(datum/social_bond/context)
	return "Мне снятся руки в чужой крови - моей. [context.display_name()] затягивает повязку и говорит, что я ещё поживу, а я во сне верю."

/datum/bond_event/dream/bound_my_wound/build_echo(datum/social_bond/context)
	return "Я вытаскивал [context.display_name()] с того света, и, похоже, вытащил."

/datum/bond_event/dream/night_vigil
	valence = BOND_DREAM_POSITIVE
	scopes = BOND_DREAM_SCOPE_OWN
	dreamer_mask = BOND_ARCH_DEVOUT
	other_mask = BOND_ARCH_DEVOUT
	warmth_commit = 16
	weight_commit = 22
	history_label = "Сон о бдении"

/datum/bond_event/dream/night_vigil/build_story(datum/social_bond/context)
	return "Мне снится ночное бдение: свечи догорели, слова кончились, и мы с [context.display_name()] просто досидели до света вдвоём."

/datum/bond_event/dream/night_vigil/build_echo(datum/social_bond/context)
	return "То бдение мы с [context.display_name()] досидели до света, так и не найдя слов."

/datum/bond_event/dream/kept_confession
	valence = BOND_DREAM_POSITIVE
	other_mask = BOND_ARCH_DEVOUT
	warmth_commit = 20
	weight_commit = 24
	history_label = "Сон об исповеди"

/datum/bond_event/dream/kept_confession/build_story(datum/social_bond/context)
	return "Мне снится, что я говорю [context.display_name()] то, за что меня повесили бы. Во сне он молчит об этом и наяву молчал."

/datum/bond_event/dream/kept_confession/build_echo(datum/social_bond/context)
	return "[context.display_name()] доверил мне однажды то, за что его бы повесили. Я смолчал."

/datum/bond_event/dream/shared_bread
	valence = BOND_DREAM_POSITIVE
	other_mask = BOND_ARCH_CRAFTER | BOND_ARCH_SERVILE
	warmth_commit = 14
	weight_commit = 18
	history_label = "Сон о хлебе"

/datum/bond_event/dream/shared_bread/build_story(datum/social_bond/context)
	return "Мне снится голодная зима и [context.display_name()], который разломил последнюю краюху надвое, хотя мог не делить."

/datum/bond_event/dream/shared_bread/build_echo(datum/social_bond/context)
	return "Я разделил с [context.display_name()] последнюю краюху в ту зиму, хотя мог не делить."

/datum/bond_event/dream/forgave_debt
	valence = BOND_DREAM_POSITIVE
	other_mask = BOND_ARCH_MERCHANT | BOND_ARCH_NOBLE
	warmth_commit = 16
	weight_commit = 20
	history_label = "Сон о долге"

/datum/bond_event/dream/forgave_debt/build_story(datum/social_bond/context)
	return "Мне снится долговая запись и рука [context.display_name()], которая перечёркивает строку с моим именем. Просто так."

/datum/bond_event/dream/forgave_debt/build_echo(datum/social_bond/context)
	return "Я перечеркнул строку с именем [context.display_name()] и до сих пор не жалею."

/datum/bond_event/dream/stood_at_my_oath
	valence = BOND_DREAM_POSITIVE
	scopes = BOND_DREAM_SCOPE_OWN
	dreamer_mask = BOND_ARCH_WARRIOR | BOND_ARCH_SERVILE
	other_mask = BOND_ARCH_NOBLE
	warmth_commit = 15
	weight_commit = 22
	history_label = "Сон о клятве"

/datum/bond_event/dream/stood_at_my_oath/build_story(datum/social_bond/context)
	return "Мне снится, как я стою на одном колене, а [context.display_name()] принимает мою клятву и не отводит глаз. Во сне это ещё что-то значит."

/datum/bond_event/dream/stood_at_my_oath/build_echo(datum/social_bond/context)
	return "[context.display_name()] клялся мне, стоя на одном колене, и глаз не отвёл."

/datum/bond_event/dream/copied_by_candle
	valence = BOND_DREAM_POSITIVE
	dreamer_mask = BOND_ARCH_SCHOLAR
	other_mask = BOND_ARCH_SCHOLAR
	warmth_commit = 14
	weight_commit = 18
	history_label = "Сон о списке"

/datum/bond_event/dream/copied_by_candle/build_story(datum/social_bond/context)
	return "Мне снится свеча, догоревшая до пальцев, и [context.display_name()] напротив: мы переписывали одну книгу с двух концов и сошлись в середине."

/datum/bond_event/dream/copied_by_candle/build_echo(datum/social_bond/context)
	return "Мы с [context.display_name()] переписывали одну книгу с двух концов и сошлись в середине."

/datum/bond_event/dream/carried_me_home
	valence = BOND_DREAM_POSITIVE
	other_mask = BOND_ARCH_WARRIOR | BOND_ARCH_LAWMAN | BOND_ARCH_CRAFTER
	warmth_commit = 13
	weight_commit = 16
	history_label = "Сон о дороге домой"

/datum/bond_event/dream/carried_me_home/build_story(datum/social_bond/context)
	return "Мне снится грязь под щекой и то, как [context.display_name()] тащит меня волоком и ругается. Донёс ведь."

/datum/bond_event/dream/carried_me_home/build_echo(datum/social_bond/context)
	return "Я дотащил [context.display_name()] волоком и до сих пор помню, какой он был тяжёлый."

/datum/bond_event/dream/shared_the_road
	valence = BOND_DREAM_POSITIVE
	scopes = BOND_DREAM_SCOPE_FOREIGN
	other_mask = BOND_ARCH_WANDERER
	warmth_commit = 15
	weight_commit = 18
	history_label = "Сон о тракте"

/datum/bond_event/dream/shared_the_road/build_story(datum/social_bond/context)
	return "Мне снится тракт и чужой костёр, к которому меня пустил [context.display_name()], не спросив ни имени, ни веры."

/datum/bond_event/dream/shared_the_road/build_echo(datum/social_bond/context)
	return "Я пустил [context.display_name()] к своему костру, не спросив ни имени, ни веры."

/datum/bond_event/dream/left_me_in_the_line
	valence = BOND_DREAM_NEGATIVE
	dreamer_mask = BOND_ARCH_WARRIOR
	other_mask = BOND_ARCH_WARRIOR
	warmth_commit = -20
	weight_commit = 26
	history_label = "Сон о бегстве"

/datum/bond_event/dream/left_me_in_the_line/build_story(datum/social_bond/context)
	return "Мне снится, как строй редеет, и место [context.display_name()] справа от меня пусто. Во сне я оборачиваюсь и вижу его спину."

/datum/bond_event/dream/left_me_in_the_line/build_echo(datum/social_bond/context)
	return "Я ушёл из строя, где остался [context.display_name()]. Он выжил, и легче от этого не стало."

/datum/bond_event/dream/named_me_from_the_pulpit
	valence = BOND_DREAM_NEGATIVE
	other_mask = BOND_ARCH_DEVOUT | BOND_ARCH_LAWMAN
	warmth_commit = -18
	weight_commit = 24
	history_label = "Сон о доносе"

/datum/bond_event/dream/named_me_from_the_pulpit/build_story(datum/social_bond/context)
	return "Мне снится площадь и голос [context.display_name()], называющий моё имя вслух. Толпа поворачивается медленно, как во сне и положено."

/datum/bond_event/dream/named_me_from_the_pulpit/build_echo(datum/social_bond/context)
	return "Я назвал имя [context.display_name()] вслух, и толпа повернулась."

/datum/bond_event/dream/cut_my_purse
	valence = BOND_DREAM_NEGATIVE
	other_mask = BOND_ARCH_OUTLAW
	warmth_commit = -16
	weight_commit = 20
	history_label = "Сон о срезанном кошеле"

/datum/bond_event/dream/cut_my_purse/build_story(datum/social_bond/context)
	return "Мне снится тяжесть, которой нет на поясе, и [context.display_name()], уходящий в толпу не оглядываясь."

/datum/bond_event/dream/cut_my_purse/build_echo(datum/social_bond/context)
	return "Кошель [context.display_name()] был лёгкой добычей. Он, кажется, догадался чей."

/datum/bond_event/dream/swore_falsely
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -17
	weight_commit = 22
	history_label = "Сон о лжесвидетельстве"

/datum/bond_event/dream/swore_falsely/build_story(datum/social_bond/context)
	return "Мне снится суд, на котором [context.display_name()] говорит обо мне то, чего не было, и его слушают внимательнее, чем меня."

/datum/bond_event/dream/swore_falsely/build_echo(datum/social_bond/context)
	return "Я сказал о [context.display_name()] на суде то, чего не было, и меня слушали."

/datum/bond_event/dream/withheld_my_wage
	valence = BOND_DREAM_NEGATIVE
	scopes = BOND_DREAM_SCOPE_OWN
	dreamer_mask = BOND_ARCH_SERVILE | BOND_ARCH_CRAFTER
	other_mask = BOND_ARCH_NOBLE | BOND_ARCH_MERCHANT
	warmth_commit = -15
	weight_commit = 20
	history_label = "Сон о недоплате"

/datum/bond_event/dream/withheld_my_wage/build_story(datum/social_bond/context)
	return "Мне снится ладонь, в которую [context.display_name()] так и не досыпал обещанного, и как я всё равно поблагодарил."

/datum/bond_event/dream/withheld_my_wage/build_echo(datum/social_bond/context)
	return "Я недосыпал [context.display_name()] обещанного, а он ещё и поблагодарил."

/datum/bond_event/dream/bled_me_wrong
	valence = BOND_DREAM_NEGATIVE
	other_mask = BOND_ARCH_HEALER
	warmth_commit = -16
	weight_commit = 22
	history_label = "Сон о лечении"

/datum/bond_event/dream/bled_me_wrong/build_story(datum/social_bond/context)
	return "Мне снится, как [context.display_name()] уверенно режет не там, где болит, и просит потерпеть. Во сне я терплю."

/datum/bond_event/dream/bled_me_wrong/build_echo(datum/social_bond/context)
	return "Я резал [context.display_name()] не там, где болело, и просил потерпеть."

/datum/bond_event/dream/botched_the_rite
	valence = BOND_DREAM_NEGATIVE
	other_mask = BOND_ARCH_DEVOUT
	warmth_commit = -14
	weight_commit = 20
	history_label = "Сон об обряде"

/datum/bond_event/dream/botched_the_rite/build_story(datum/social_bond/context)
	return "Мне снятся похороны, на которых [context.display_name()] путает слова, и я всю ночь думаю, дошёл ли покойник куда следует."

/datum/bond_event/dream/botched_the_rite/build_echo(datum/social_bond/context)
	return "Я спутал слова над покойником, и [context.display_name()] это слышал."

/datum/bond_event/dream/flogged_me
	valence = BOND_DREAM_NEGATIVE
	scopes = BOND_DREAM_SCOPE_OWN
	dreamer_mask = BOND_ARCH_OUTLAW | BOND_ARCH_SERVILE | BOND_ARCH_CRAFTER
	other_mask = BOND_ARCH_LAWMAN
	warmth_commit = -19
	weight_commit = 24
	history_label = "Сон о столбе"

/datum/bond_event/dream/flogged_me/build_story(datum/social_bond/context)
	return "Мне снится столб, к которому меня привязали, и то, как [context.display_name()] считал удары вслух, ровным голосом."

/datum/bond_event/dream/flogged_me/build_echo(datum/social_bond/context)
	return "Я считал удары для [context.display_name()] вслух и ни разу не сбился."

/datum/bond_event/dream/usury
	valence = BOND_DREAM_NEGATIVE
	other_mask = BOND_ARCH_MERCHANT
	warmth_commit = -15
	weight_commit = 20
	history_label = "Сон о росте"

/datum/bond_event/dream/usury/build_story(datum/social_bond/context)
	return "Мне снится, как долг перед [context.display_name()] растёт сам собой, быстрее, чем я успеваю работать."

/datum/bond_event/dream/usury/build_echo(datum/social_bond/context)
	return "Долг [context.display_name()] растёт быстрее, чем он успевает работать. Это моя работа."

/datum/bond_event/dream/blood_price_unpaid
	valence = BOND_DREAM_NEGATIVE
	scopes = BOND_DREAM_SCOPE_FOREIGN
	other_mask = BOND_ARCH_WARRIOR | BOND_ARCH_NOBLE
	warmth_commit = -22
	weight_commit = 26
	history_label = "Сон о вире"

/datum/bond_event/dream/blood_price_unpaid/build_story(datum/social_bond/context)
	return "Мне снится мой мертвец и цена за него, которую [context.display_name()] не заплатил ни монетой, ни словом."

/datum/bond_event/dream/blood_price_unpaid/build_echo(datum/social_bond/context)
	return "За мертвеца [context.display_name()] я не заплатил ни монетой, ни словом."

/datum/controller/subsystem/bonds/proc/dream_bias(valence)
	var/datum/storyteller/teller = active_storyteller()
	if(!teller)
		return 1
	var/datum/bond_storyteller_lens/lens = storyteller_lenses[teller.type]
	if(!lens)
		return 1
	return (valence == BOND_DREAM_NEGATIVE) ? lens.dream_negative_bias : lens.dream_positive_bias

/datum/controller/subsystem/bonds/proc/dream_candidates(mob/living/carbon/human/dreamer, scope)
	RETURN_TYPE(/list)
	var/list/found = list()
	var/datum/bond_faction/own = faction_for(dreamer)
	for(var/mob/living/carbon/human/person in GLOB.player_list)
		if(person == dreamer || !person.mind || !person.ckey)
			continue
		if(person.stat == DEAD)
			continue
		if(istype(person, /mob/living/carbon/human/dummy))
			continue
		var/datum/bond_faction/theirs = faction_for(person)
		if(!theirs)
			continue
		if(scope == BOND_DREAM_SCOPE_OWN)
			if(!own || theirs != own)
				continue
		else if(own && theirs == own)
			continue
		found += person
	return found

/datum/controller/subsystem/bonds/proc/build_dream_index()
	dream_prototypes = list()
	dream_buckets = list("[BOND_DREAM_POSITIVE]" = list(), "[BOND_DREAM_NEGATIVE]" = list())
	for(var/event_type in event_prototypes)
		var/datum/bond_event/dream/prototype = event_prototypes[event_type]
		if(!istype(prototype))
			continue
		dream_prototypes += event_type
		var/list/bucket = dream_buckets["[prototype.valence]"]
		if(bucket)
			bucket += event_type
	bondlog("dream index built: [dream_prototypes.len] memories", BONDLOG_INFO)

/datum/controller/subsystem/bonds/proc/round_dream_pool(valence, scope)
	RETURN_TYPE(/list)
	var/list/bucket = dream_buckets?["[valence]"]
	if(!length(bucket))
		return list()
	var/map_type = current_map_type()
	var/teller_type = ruling_god_type()
	var/list/pool = list()
	for(var/event_type in bucket)
		var/datum/bond_event/dream/prototype = event_prototypes[event_type]
		if(!(prototype.scopes & scope))
			continue
		if(!prototype.fits_round(map_type, teller_type))
			continue
		pool += event_type
	return pool

/datum/controller/subsystem/bonds/proc/current_map_type()
	return SSmapping?.map_adjustment?.type

/datum/controller/subsystem/bonds/proc/dream_pool(valence, scope, dreamer_arch, other_arch, mob/living/carbon/human/dreamer, mob/living/carbon/human/other, list/round_pool)
	RETURN_TYPE(/list)
	if(isnull(round_pool))
		round_pool = round_dream_pool(valence, scope)
	var/list/pool = list()
	for(var/event_type in round_pool)
		var/datum/bond_event/dream/prototype = event_prototypes[event_type]
		if(!prototype.fits(dreamer_arch, other_arch, scope))
			continue
		if(prototype.vampire_rule != BOND_DREAM_VAMPIRE_NONE)
			if(!dreamer || !other)
				continue
			if(!prototype.fits_blood(dreamer, other))
				continue
		pool[event_type] = prototype.rarity
	return pool

/datum/controller/subsystem/bonds/proc/pick_dream(list/pool)
	var/total = 0
	for(var/event_type in pool)
		total += pool[event_type]
	if(total <= 0)
		return null
	var/roll = rand() * total
	var/cursor = 0
	for(var/event_type in pool)
		cursor += pool[event_type]
		if(roll <= cursor)
			return event_type
	return pool[pool.len]

/datum/controller/subsystem/bonds/proc/fire_dream(mob/living/carbon/human/dreamer, valence, scope)
	var/list/round_pool = round_dream_pool(valence, scope)
	if(!length(round_pool))
		return FALSE
	var/list/candidates = dream_candidates(dreamer, scope)
	if(!length(candidates))
		return FALSE
	var/dreamer_arch = archetypes_for(dreamer)
	for(var/mob/living/carbon/human/other as anything in shuffle(candidates))
		var/list/pool = dream_pool(valence, scope, dreamer_arch, archetypes_for(other), dreamer, other, round_pool)
		if(!length(pool))
			continue
		var/event_type = pick_dream(pool)
		if(!event_type)
			continue
		if(!record(dreamer.mind, other.mind, event_type, other, TRUE))
			continue
		notify_dream(dreamer, other)
		announce_echo(other, apply_echo(other.mind, dreamer.mind, event_type))
		bondlog("dream [dreamer.ckey] -> [other.ckey] [event_type]")
		return TRUE
	return FALSE

/datum/controller/subsystem/bonds/proc/notify_dream(mob/living/carbon/human/dreamer, mob/living/carbon/human/other)
	var/datum/social_bond/bond = get_bond(dreamer.mind, other.mind)
	if(!bond)
		return
	var/datum/bond_history/latest = LAZYLEN(bond.history) ? bond.history[bond.history.len] : null
	if(!latest)
		return
	to_chat(dreamer, span_notice("<b>Сон уводит меня назад.</b> [latest.story]"))

/datum/controller/subsystem/bonds/proc/apply_echo(subject, object, event_type)
	RETURN_TYPE(/datum/bond_history)
	var/datum/bond_event/dream/prototype = event_prototypes[event_type]
	if(!istype(prototype))
		return null
	var/datum/social_bond/bond = get_or_create_bond(subject, object)
	if(!bond || !bond.scored)
		return null
	var/warmth_delta = prototype.warmth_commit * BOND_DREAM_ECHO_SCALE
	var/weight_delta = prototype.weight_commit * BOND_DREAM_ECHO_SCALE
	bond.warmth_committed = clamp(bond.warmth_committed + warmth_delta, BOND_WARMTH_MIN, BOND_WARMTH_MAX)
	bond.weight_committed = clamp(bond.weight_committed + weight_delta, BOND_WEIGHT_MIN, BOND_WEIGHT_MAX)
	var/datum/bond_history/entry = new()
	entry.label = prototype.history_label
	entry.story = prototype.build_echo(bond)
	entry.created_at = world.time
	entry.warmth_delta = round(warmth_delta, 0.1)
	entry.weight_delta = round(weight_delta, 0.1)
	LAZYADD(bond.history, entry)
	bond.trim_history()
	bond.recalculate()
	return entry

/datum/controller/subsystem/bonds/proc/announce_echo(mob/living/carbon/human/other, datum/bond_history/entry)
	if(!other || !entry)
		return FALSE
	if(entry.warmth_delta >= 0)
		to_chat(other, span_notice("<i>Мне отчего-то думается, что обо мне сейчас вспомнили добром.</i> [entry.story]"))
	else
		to_chat(other, span_warning("<i>Мне отчего-то неспокойно, будто обо мне только что вспомнили.</i> [entry.story]"))
	return TRUE

/datum/controller/subsystem/bonds/proc/roll_dream(mob/living/carbon/human/dreamer)
	if(!ishuman(dreamer) || !dreamer.mind)
		return FALSE
	var/negative = dream_bias(BOND_DREAM_NEGATIVE)
	var/positive = dream_bias(BOND_DREAM_POSITIVE)
	var/list/chances = list(
		BOND_DREAM_CHANCE_OWN_NEGATIVE * negative,
		BOND_DREAM_CHANCE_FOREIGN_NEGATIVE * negative,
		BOND_DREAM_CHANCE_OWN_POSITIVE * positive,
		BOND_DREAM_CHANCE_FOREIGN_POSITIVE * positive,
	)
	var/total = chances[1] + chances[2] + chances[3] + chances[4]
	if(total <= 0 || !prob(total))
		return FALSE
	var/list/valences = list(BOND_DREAM_NEGATIVE, BOND_DREAM_NEGATIVE, BOND_DREAM_POSITIVE, BOND_DREAM_POSITIVE)
	var/list/bucket_scopes = list(BOND_DREAM_SCOPE_OWN, BOND_DREAM_SCOPE_FOREIGN, BOND_DREAM_SCOPE_OWN, BOND_DREAM_SCOPE_FOREIGN)
	var/roll = rand() * total
	var/cursor = 0
	var/chosen = length(chances)
	for(var/i in 1 to length(chances))
		cursor += chances[i]
		if(roll <= cursor)
			chosen = i
			break
	return fire_dream(dreamer, valences[chosen], bucket_scopes[chosen])

/datum/sleep_adv/advance_cycle()
	. = ..()
	if(!ishuman(mind?.current))
		return
	if(HAS_TRAIT(mind.current, TRAIT_CURSE_ABYSSOR))
		return
	SSbonds.roll_dream(mind.current)
