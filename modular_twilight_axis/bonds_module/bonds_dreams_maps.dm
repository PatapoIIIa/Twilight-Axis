/datum/bond_event/dream/azuria
	abstract_type = /datum/bond_event/dream/azuria
	maps = list(/datum/map_adjustment/template/dunworld)

/datum/bond_event/dream/azuria/over_the_pass
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 17
	weight_commit = 23
	history_label = "Сон о перевале"

/datum/bond_event/dream/azuria/over_the_pass/build_story(datum/social_bond/context)
	return "Мне снится перевал у подножия Безголовой Горы, снег выше колена и [context.display_name()], который шёл первым и протаптывал за двоих."

/datum/bond_event/dream/azuria/over_the_pass/build_echo(datum/social_bond/context)
	return "Тот перевал я протаптывал за двоих, и [context.display_name()] шёл по моему следу."

/datum/bond_event/dream/azuria/pulled_from_the_shaft
	valence = BOND_DREAM_POSITIVE
	other_mask = BOND_ARCH_CRAFTER | BOND_ARCH_WARRIOR
	warmth_commit = 19
	weight_commit = 25
	history_label = "Сон о завале"

/datum/bond_event/dream/azuria/pulled_from_the_shaft/build_story(datum/social_bond/context)
	return "Мне снится штольня Дафтсмарча, осевшая кровля и руки [context.display_name()], которые разгребали породу, когда все остальные уже считали меня покойником."

/datum/bond_event/dream/azuria/pulled_from_the_shaft/build_echo(datum/social_bond/context)
	return "Я разгребал ту породу, когда [context.display_name()] уже записали в покойники."

/datum/bond_event/dream/azuria/watch_on_the_marches
	valence = BOND_DREAM_POSITIVE
	scopes = BOND_DREAM_SCOPE_OWN
	warmth_commit = 15
	weight_commit = 20
	history_label = "Сон о дозоре"

/datum/bond_event/dream/azuria/watch_on_the_marches/build_story(datum/social_bond/context)
	return "Мне снится ночь в Лазурном Анклаве, когда за стеной выли волколаки, а [context.display_name()] всю смену говорил со мной ни о чём, чтобы я не слушал."

/datum/bond_event/dream/azuria/watch_on_the_marches/build_echo(datum/social_bond/context)
	return "Я всю ту смену говорил с [context.display_name()] ни о чём, чтобы он не слушал, что творится за стеной."

/datum/bond_event/dream/azuria/bog_share
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 14
	weight_commit = 18
	history_label = "Сон о болотном шёлке"

/datum/bond_event/dream/azuria/bog_share/build_story(datum/social_bond/context)
	return "Мне снятся топи у Блэкхолта и [context.display_name()], который отдал мне свою долю мотылькового шёлка, потому что у меня зимовать было не на что."

/datum/bond_event/dream/azuria/bog_share/build_echo(datum/social_bond/context)
	return "Свою долю блэкхолтского шёлка я отдал [context.display_name()], потому что ему было не на что зимовать."

/datum/bond_event/dream/azuria/left_in_the_dark
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -21
	weight_commit = 27
	history_label = "Сон о тьме под горой"

/datum/bond_event/dream/azuria/left_in_the_dark/build_story(datum/social_bond/context)
	return "Мне снятся ходы под Безголовой Горой, погасший фонарь и шаги [context.display_name()], которые удаляются ровно и не сбиваются."

/datum/bond_event/dream/azuria/left_in_the_dark/build_echo(datum/social_bond/context)
	return "Я вышел из-под горы один. Фонарь [context.display_name()] погас раньше, и я не вернулся."

/datum/bond_event/dream/azuria/sold_to_the_deep
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -24
	weight_commit = 30
	rarity = 4
	history_label = "Сон о проданном под гору"

/datum/bond_event/dream/azuria/sold_to_the_deep/build_story(datum/social_bond/context)
	return "Мне снится, как [context.display_name()] говорит с теми, кто пришёл снизу, и показывает на меня. Во сне я не слышу цены."

/datum/bond_event/dream/azuria/sold_to_the_deep/build_echo(datum/social_bond/context)
	return "Тем, кто пришёл снизу, я показал на [context.display_name()]. Цену я до сих пор помню."

/datum/bond_event/dream/rockhill
	abstract_type = /datum/bond_event/dream/rockhill
	maps = list(/datum/map_adjustment/template/rockhill)

/datum/bond_event/dream/rockhill/held_the_bridge
	valence = BOND_DREAM_POSITIVE
	dreamer_mask = BOND_ARCH_WARRIOR
	other_mask = BOND_ARCH_WARRIOR
	warmth_commit = 19
	weight_commit = 26
	history_label = "Сон о мосте"

/datum/bond_event/dream/rockhill/held_the_bridge/build_story(datum/social_bond/context)
	return "Мне снится мост через пролив и [context.display_name()] рядом. Скала и Камень, Дисциплина и Смерть - в ту ночь это были не просто слова."

/datum/bond_event/dream/rockhill/held_the_bridge/build_echo(datum/social_bond/context)
	return "Тот мост мы держали с [context.display_name()], и слова о Скале и Камне в ту ночь чего-то стоили."

/datum/bond_event/dream/rockhill/astratas_garden
	valence = BOND_DREAM_POSITIVE
	scopes = BOND_DREAM_SCOPE_OWN
	warmth_commit = 16
	weight_commit = 22
	history_label = "Сон об Астратовом Саде"

/datum/bond_event/dream/rockhill/astratas_garden/build_story(datum/social_bond/context)
	return "Мне снится Астратов Сад на рассвете и [context.display_name()], который остался у околицы, когда из города за нами так никто и не пришёл."

/datum/bond_event/dream/rockhill/astratas_garden/build_echo(datum/social_bond/context)
	return "Я остался у околицы Астратова Сада вместе с [context.display_name()]. Из города за нами так и не пришли."

/datum/bond_event/dream/rockhill/saved_from_the_fangs
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 21
	weight_commit = 28
	rarity = 7
	history_label = "Сон о клыках"

/datum/bond_event/dream/rockhill/saved_from_the_fangs/build_story(datum/social_bond/context)
	return "Мне снится холод у горла и [context.display_name()], который оторвал от меня то, что уже пило, и не бросил меня после."

/datum/bond_event/dream/rockhill/saved_from_the_fangs/build_echo(datum/social_bond/context)
	return "Я оторвал от горла [context.display_name()] то, что уже пило, и не бросил его после."

/datum/bond_event/dream/rockhill/shared_blood
	valence = BOND_DREAM_POSITIVE
	vampire_rule = BOND_DREAM_VAMPIRE_DREAMER
	warmth_commit = 24
	weight_commit = 32
	rarity = 2
	history_label = "Сон о разделённой крови"

/datum/bond_event/dream/rockhill/shared_blood/build_story(datum/social_bond/context)
	return "Мне снится голод, от которого темнеет в глазах, и [context.display_name()], который молча закатал рукав и подставил запястье сам. Такого не забывают и не прощают себе."

/datum/bond_event/dream/rockhill/shared_blood/build_echo(datum/social_bond/context)
	return "Я закатал рукав и подставил запястье [context.display_name()] сам. Я до сих пор не знаю, зачем."

/datum/bond_event/dream/rockhill/named_to_the_otavans
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -22
	weight_commit = 28
	history_label = "Сон об отаванцах"

/datum/bond_event/dream/rockhill/named_to_the_otavans/build_story(datum/social_bond/context)
	return "Мне снится сходня отаванского судна и [context.display_name()], который поднимается по ней сам, чтобы назвать им моё имя."

/datum/bond_event/dream/rockhill/named_to_the_otavans/build_echo(datum/social_bond/context)
	return "На отаванское судно я поднялся сам и назвал им имя [context.display_name()]."

/datum/bond_event/dream/rockhill/swamp_gold
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -19
	weight_commit = 25
	history_label = "Сон о болотной казне"

/datum/bond_event/dream/rockhill/swamp_gold/build_story(datum/social_bond/context)
	return "Мне снятся болота за мостом, куда мы пошли втроём за казной старого короля, и [context.display_name()], который вернулся вдвоём меньше и с полным мешком."

/datum/bond_event/dream/rockhill/swamp_gold/build_echo(datum/social_bond/context)
	return "С болот за мостом я вернулся один и с полным мешком. [context.display_name()] считал ушедших."

/datum/bond_event/dream/ranesh
	abstract_type = /datum/bond_event/dream/ranesh
	maps = list(/datum/map_adjustment/template/deserttown)

/datum/bond_event/dream/ranesh/shared_water
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 19
	weight_commit = 25
	history_label = "Сон о воде"

/datum/bond_event/dream/ranesh/shared_water/build_story(datum/social_bond/context)
	return "Мне снятся пески между колодцами и [context.display_name()], который отдал мне последний бурдюк, зная, что до следующего оазиса два перехода."

/datum/bond_event/dream/ranesh/shared_water/build_echo(datum/social_bond/context)
	return "Последний бурдюк я отдал [context.display_name()], хотя до оазиса было два перехода."

/datum/bond_event/dream/ranesh/arena_spared
	valence = BOND_DREAM_POSITIVE
	dreamer_mask = BOND_ARCH_WARRIOR | BOND_ARCH_SERVILE
	other_mask = BOND_ARCH_WARRIOR
	warmth_commit = 18
	weight_commit = 26
	history_label = "Сон об арене"

/datum/bond_event/dream/ranesh/arena_spared/build_story(datum/social_bond/context)
	return "Мне снится песок арены, забитый кровью, и [context.display_name()], который стоял надо мной и опустил оружие, когда трибуны требовали обратного."

/datum/bond_event/dream/ranesh/arena_spared/build_echo(datum/social_bond/context)
	return "Я стоял над [context.display_name()] и опустил оружие, хотя трибуны требовали другого."

/datum/bond_event/dream/ranesh/guest_right
	valence = BOND_DREAM_POSITIVE
	scopes = BOND_DREAM_SCOPE_FOREIGN
	warmth_commit = 15
	weight_commit = 19
	history_label = "Сон о гостеприимстве"

/datum/bond_event/dream/ranesh/guest_right/build_story(datum/social_bond/context)
	return "Мне снится скудный ужин под чужим шатром: [context.display_name()] разделил со мной ровно то, что имел, и не спросил, чей я и откуда."

/datum/bond_event/dream/ranesh/guest_right/build_echo(datum/social_bond/context)
	return "Я разделил с [context.display_name()] ровно то, что имел, и не стал спрашивать, чей он и откуда."

/datum/bond_event/dream/ranesh/bought_my_papers
	valence = BOND_DREAM_POSITIVE
	dreamer_mask = BOND_ARCH_SERVILE
	other_mask = BOND_ARCH_MERCHANT | BOND_ARCH_NOBLE
	warmth_commit = 22
	weight_commit = 28
	rarity = 7
	history_label = "Сон о выкупе"

/datum/bond_event/dream/ranesh/bought_my_papers/build_story(datum/social_bond/context)
	return "Мне снится помост, счёт чужого товара и [context.display_name()], который выкупил меня и в тот же день отпустил, не потребовав отработать."

/datum/bond_event/dream/ranesh/bought_my_papers/build_echo(datum/social_bond/context)
	return "Я выкупил [context.display_name()] с помоста и отпустил в тот же день, не потребовав отработки."

/datum/bond_event/dream/ranesh/sold_me_on
	valence = BOND_DREAM_NEGATIVE
	other_mask = BOND_ARCH_MERCHANT | BOND_ARCH_NOBLE | BOND_ARCH_LAWMAN
	warmth_commit = -23
	weight_commit = 29
	history_label = "Сон о помосте"

/datum/bond_event/dream/ranesh/sold_me_on/build_story(datum/social_bond/context)
	return "Мне снится помост, на который меня вывели, и [context.display_name()] внизу: он торговался обо мне спокойно, как о мере ячменя."

/datum/bond_event/dream/ranesh/sold_me_on/build_echo(datum/social_bond/context)
	return "Я торговался о [context.display_name()] спокойно, как о мере ячменя, и сбил цену."

/datum/bond_event/dream/ranesh/dreamwalker
	valence = BOND_DREAM_NEGATIVE
	other_mask = BOND_ARCH_SCHOLAR
	warmth_commit = -18
	weight_commit = 24
	rarity = 5
	history_label = "Сон о сноходце"

/datum/bond_event/dream/ranesh/dreamwalker/build_story(datum/social_bond/context)
	return "Мне снится мой собственный сон, в котором стоит [context.display_name()] и ходит по нему как по чужой комнате, ничего не трогая и всё запоминая."

/datum/bond_event/dream/ranesh/dreamwalker/build_echo(datum/social_bond/context)
	return "По снам [context.display_name()] я прошёл как по чужой комнате: ничего не тронул и всё запомнил."
