/datum/bond_event/dream/astrata
	abstract_type = /datum/bond_event/dream/astrata
	storyteller_type = /datum/storyteller/astrata

/datum/bond_event/dream/astrata/dawn_watch
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 16
	weight_commit = 20
	history_label = "Сон о рассвете"

/datum/bond_event/dream/astrata/dawn_watch/build_story(datum/social_bond/context)
	return "Мне снится стена перед рассветом и [context.display_name()] рядом. Он говорит, что солнце всегда возвращается, и во сне я ему верю."

/datum/bond_event/dream/astrata/dawn_watch/build_echo(datum/social_bond/context)
	return "Мы с [context.display_name()] достояли ту стражу до рассвета, и солнце всё-таки взошло."

/datum/bond_event/dream/astrata/just_verdict
	valence = BOND_DREAM_POSITIVE
	other_mask = BOND_ARCH_LAWMAN | BOND_ARCH_NOBLE
	warmth_commit = 17
	weight_commit = 22
	history_label = "Сон о правом суде"

/datum/bond_event/dream/astrata/just_verdict/build_story(datum/social_bond/context)
	return "Мне снится суд, где [context.display_name()] рассудил по закону, а не по знакомству, и это оказалось не в его выгоду."

/datum/bond_event/dream/astrata/just_verdict/build_echo(datum/social_bond/context)
	return "Я рассудил дело [context.display_name()] по закону, хотя выгоднее было иначе."

/datum/bond_event/dream/astrata/shared_prayer
	valence = BOND_DREAM_POSITIVE
	scopes = BOND_DREAM_SCOPE_OWN
	dreamer_mask = BOND_ARCH_DEVOUT
	other_mask = BOND_ARCH_DEVOUT
	warmth_commit = 15
	weight_commit = 20
	history_label = "Сон о молитве"

/datum/bond_event/dream/astrata/shared_prayer/build_story(datum/social_bond/context)
	return "Мне снится утренняя молитва в пустом храме и голос [context.display_name()], подхвативший её, когда мой сорвался."

/datum/bond_event/dream/astrata/shared_prayer/build_echo(datum/social_bond/context)
	return "Я дочитал утреннюю молитву за [context.display_name()], когда его голос сорвался."

/datum/bond_event/dream/astrata/bent_the_law
	valence = BOND_DREAM_NEGATIVE
	other_mask = BOND_ARCH_LAWMAN | BOND_ARCH_NOBLE
	warmth_commit = -17
	weight_commit = 22
	history_label = "Сон о кривом суде"

/datum/bond_event/dream/astrata/bent_the_law/build_story(datum/social_bond/context)
	return "Мне снится, как [context.display_name()] читает закон и на середине сворачивает туда, где ждёт нужный человек. Не я."

/datum/bond_event/dream/astrata/bent_the_law/build_echo(datum/social_bond/context)
	return "Я свернул закон в нужную сторону, и [context.display_name()] это заметил."

/datum/bond_event/dream/astrata/broke_formation
	valence = BOND_DREAM_NEGATIVE
	dreamer_mask = BOND_ARCH_WARRIOR
	other_mask = BOND_ARCH_WARRIOR
	warmth_commit = -18
	weight_commit = 24
	history_label = "Сон о сорванном строе"

/datum/bond_event/dream/astrata/broke_formation/build_story(datum/social_bond/context)
	return "Мне снится замысел, расписанный до последнего шага, и [context.display_name()], который решил, что знает лучше."

/datum/bond_event/dream/astrata/broke_formation/build_echo(datum/social_bond/context)
	return "Я сделал по-своему, и замысел рассыпался. [context.display_name()] не забыл."

/datum/bond_event/dream/noc
	abstract_type = /datum/bond_event/dream/noc
	storyteller_type = /datum/storyteller/noc

/datum/bond_event/dream/noc/shared_dream
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 18
	weight_commit = 24
	rarity = 6
	history_label = "Общий сон"

/datum/bond_event/dream/noc/shared_dream/build_story(datum/social_bond/context)
	return "Мне снится сон, который уже снился [context.display_name()]: та же комната, та же луна в окне. Проснувшись, я знаю это наверняка."

/datum/bond_event/dream/noc/shared_dream/build_echo(datum/social_bond/context)
	return "Мой сон этой ночью видел кто-то ещё. [context.display_name()], если верить ощущению."

/datum/bond_event/dream/noc/taught_letters
	valence = BOND_DREAM_POSITIVE
	other_mask = BOND_ARCH_SCHOLAR
	warmth_commit = 16
	weight_commit = 22
	history_label = "Сон о буквах"

/datum/bond_event/dream/noc/taught_letters/build_story(datum/social_bond/context)
	return "Мне снится, как [context.display_name()] ведёт моим пальцем по строке и не смеётся над тем, как медленно я читаю."

/datum/bond_event/dream/noc/taught_letters/build_echo(datum/social_bond/context)
	return "Я учил [context.display_name()] читать и ни разу не посмеялся над тем, как медленно у него выходило."

/datum/bond_event/dream/noc/lent_a_book
	valence = BOND_DREAM_POSITIVE
	dreamer_mask = BOND_ARCH_SCHOLAR
	other_mask = BOND_ARCH_SCHOLAR
	warmth_commit = 14
	weight_commit = 18
	history_label = "Сон о книге"

/datum/bond_event/dream/noc/lent_a_book/build_story(datum/social_bond/context)
	return "Мне снится книга, которую [context.display_name()] дал мне на одну ночь, зная, что за такие книги жгут."

/datum/bond_event/dream/noc/lent_a_book/build_echo(datum/social_bond/context)
	return "Я дал [context.display_name()] книгу на одну ночь, хотя за такие книги жгут."

/datum/bond_event/dream/noc/pried_into_me
	valence = BOND_DREAM_NEGATIVE
	other_mask = BOND_ARCH_SCHOLAR
	warmth_commit = -18
	weight_commit = 24
	rarity = 8
	history_label = "Сон о чужом взгляде"

/datum/bond_event/dream/noc/pried_into_me/build_story(datum/social_bond/context)
	return "Мне снится, что [context.display_name()] стоит у меня за глазами и смотрит оттуда наружу. Во сне я не могу его выгнать."

/datum/bond_event/dream/noc/pried_into_me/build_echo(datum/social_bond/context)
	return "Я заглянул туда, куда [context.display_name()] меня не звал."

/datum/bond_event/dream/noc/burned_my_notes
	valence = BOND_DREAM_NEGATIVE
	dreamer_mask = BOND_ARCH_SCHOLAR
	warmth_commit = -16
	weight_commit = 22
	history_label = "Сон о золе"

/datum/bond_event/dream/noc/burned_my_notes/build_story(datum/social_bond/context)
	return "Мне снится зола вместо трёх лет работы и лицо [context.display_name()], на котором нет ничего."

/datum/bond_event/dream/noc/burned_my_notes/build_echo(datum/social_bond/context)
	return "Три года работы [context.display_name()] сгорели, и я знаю, чья это была свеча."

/datum/bond_event/dream/necra
	abstract_type = /datum/bond_event/dream/necra
	storyteller_type = /datum/storyteller/necra

/datum/bond_event/dream/necra/closed_my_eyes
	valence = BOND_DREAM_POSITIVE
	other_mask = BOND_ARCH_DEVOUT
	warmth_commit = 18
	weight_commit = 24
	history_label = "Сон о последнем обряде"

/datum/bond_event/dream/necra/closed_my_eyes/build_story(datum/social_bond/context)
	return "Мне снится, что я лежу, а [context.display_name()] закрывает мне глаза и говорит нужные слова до конца, не торопясь."

/datum/bond_event/dream/necra/closed_my_eyes/build_echo(datum/social_bond/context)
	return "Я закрыл глаза [context.display_name()] и прочёл всё до конца, не торопясь."

/datum/bond_event/dream/necra/carried_the_bier
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 15
	weight_commit = 20
	history_label = "Сон о носилках"

/datum/bond_event/dream/necra/carried_the_bier/build_story(datum/social_bond/context)
	return "Мне снятся носилки, которые мы несли с [context.display_name()]: он спереди, я сзади, и мы ни разу не сбились с шага."

/datum/bond_event/dream/necra/carried_the_bier/build_echo(datum/social_bond/context)
	return "Мы несли те носилки с [context.display_name()] и ни разу не сбились с шага."

/datum/bond_event/dream/necra/grave_vigil
	valence = BOND_DREAM_POSITIVE
	scopes = BOND_DREAM_SCOPE_OWN
	warmth_commit = 14
	weight_commit = 18
	history_label = "Сон о поминках"

/datum/bond_event/dream/necra/grave_vigil/build_story(datum/social_bond/context)
	return "Мне снятся поминки, на которых остались только мы с [context.display_name()], когда все прочие разошлись."

/datum/bond_event/dream/necra/grave_vigil/build_echo(datum/social_bond/context)
	return "На тех поминках мы с [context.display_name()] остались последними."

/datum/bond_event/dream/necra/named_my_death
	valence = BOND_DREAM_NEGATIVE
	other_mask = BOND_ARCH_DEVOUT | BOND_ARCH_SCHOLAR
	warmth_commit = -19
	weight_commit = 26
	rarity = 8
	history_label = "Сон о предсказании"

/datum/bond_event/dream/necra/named_my_death/build_story(datum/social_bond/context)
	return "Мне снится, как [context.display_name()] смотрит на меня и называет год. Во сне я не переспрашиваю."

/datum/bond_event/dream/necra/named_my_death/build_echo(datum/social_bond/context)
	return "Я назвал [context.display_name()] год, и он не переспросил."

/datum/bond_event/dream/necra/left_unburied
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -20
	weight_commit = 26
	history_label = "Сон о непогребённом"

/datum/bond_event/dream/necra/left_unburied/build_story(datum/social_bond/context)
	return "Мне снится мой мертвец под открытым небом и [context.display_name()], который прошёл мимо и не остановился."

/datum/bond_event/dream/necra/left_unburied/build_echo(datum/social_bond/context)
	return "Я прошёл мимо мертвеца [context.display_name()] и не остановился."

/datum/bond_event/dream/abyssor
	abstract_type = /datum/bond_event/dream/abyssor
	storyteller_type = /datum/storyteller/abyssor

/datum/bond_event/dream/abyssor/same_storm
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 17
	weight_commit = 24
	history_label = "Сон о шторме"

/datum/bond_event/dream/abyssor/same_storm/build_story(datum/social_bond/context)
	return "Мне снится шторм, который мы с [context.display_name()] пересидели под одним куском парусины, вцепившись в одну снасть."

/datum/bond_event/dream/abyssor/same_storm/build_echo(datum/social_bond/context)
	return "Тот шторм мы с [context.display_name()] пересидели под одной парусиной."

/datum/bond_event/dream/abyssor/bailed_water
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 14
	weight_commit = 18
	history_label = "Сон о вычерпанной воде"

/datum/bond_event/dream/abyssor/bailed_water/build_story(datum/social_bond/context)
	return "Мне снится трюм по колено и [context.display_name()], который вычерпывал воду всю ночь и не стал меня будить."

/datum/bond_event/dream/abyssor/bailed_water/build_echo(datum/social_bond/context)
	return "Я вычерпывал воду всю ночь и не стал будить [context.display_name()]."

/datum/bond_event/dream/abyssor/cut_the_rope
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -21
	weight_commit = 26
	history_label = "Сон о перерезанном канате"

/datum/bond_event/dream/abyssor/cut_the_rope/build_story(datum/social_bond/context)
	return "Мне снится канат, который [context.display_name()] перерезал, чтобы шлюпка не перевернулась. Я был на другом конце."

/datum/bond_event/dream/abyssor/cut_the_rope/build_echo(datum/social_bond/context)
	return "Я перерезал тот канат, чтобы не перевернулись все. [context.display_name()] был на другом конце."

/datum/bond_event/dream/abyssor/sold_the_cargo
	valence = BOND_DREAM_NEGATIVE
	scopes = BOND_DREAM_SCOPE_FOREIGN
	other_mask = BOND_ARCH_MERCHANT
	warmth_commit = -16
	weight_commit = 22
	history_label = "Сон о проданном грузе"

/datum/bond_event/dream/abyssor/sold_the_cargo/build_story(datum/social_bond/context)
	return "Мне снится пристань, где [context.display_name()] продаёт то, что мы везли вместе, и цену называет свою."

/datum/bond_event/dream/abyssor/sold_the_cargo/build_echo(datum/social_bond/context)
	return "Я продал общий груз по своей цене. [context.display_name()] узнал об этом на пристани."

/datum/bond_event/dream/abyssor/same_nightmare
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -15
	weight_commit = 20
	rarity = 6
	history_label = "Общий кошмар"

/datum/bond_event/dream/abyssor/same_nightmare/build_story(datum/social_bond/context)
	return "Мне снится кошмар, в котором есть [context.display_name()], и наутро я понимаю, что он снился нам обоим."

/datum/bond_event/dream/abyssor/same_nightmare/build_echo(datum/social_bond/context)
	return "Этот кошмар видел не только я. [context.display_name()] тоже, судя по его лицу."

/datum/bond_event/dream/dendor
	abstract_type = /datum/bond_event/dream/dendor
	storyteller_type = /datum/storyteller/dendor

/datum/bond_event/dream/dendor/shared_the_kill
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 15
	weight_commit = 20
	history_label = "Сон об охоте"

/datum/bond_event/dream/dendor/shared_the_kill/build_story(datum/social_bond/context)
	return "Мне снится добыча, которую мы с [context.display_name()] делили у костра, и он взял себе худшую часть."

/datum/bond_event/dream/dendor/shared_the_kill/build_echo(datum/social_bond/context)
	return "Ту добычу мы делили с [context.display_name()], и худшую часть я взял себе."

/datum/bond_event/dream/dendor/beast_at_my_back
	valence = BOND_DREAM_POSITIVE
	other_mask = BOND_ARCH_WARRIOR | BOND_ARCH_WANDERER
	warmth_commit = 19
	weight_commit = 24
	history_label = "Сон о звере"

/datum/bond_event/dream/dendor/beast_at_my_back/build_story(datum/social_bond/context)
	return "Мне снится дыхание за спиной и [context.display_name()], который встал между мной и этим дыханием."

/datum/bond_event/dream/dendor/beast_at_my_back/build_echo(datum/social_bond/context)
	return "Я встал между [context.display_name()] и тем, что дышало ему в спину."

/datum/bond_event/dream/dendor/left_to_the_pack
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -21
	weight_commit = 26
	history_label = "Сон о стае"

/datum/bond_event/dream/dendor/left_to_the_pack/build_story(datum/social_bond/context)
	return "Мне снится вой со всех сторон и спина [context.display_name()], уходящая быстрее, чем я могу бежать."

/datum/bond_event/dream/dendor/left_to_the_pack/build_echo(datum/social_bond/context)
	return "Я бежал быстрее, чем [context.display_name()]. Стая досталась не нам поровну."

/datum/bond_event/dream/dendor/took_the_pelt
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -14
	weight_commit = 18
	history_label = "Сон о шкуре"

/datum/bond_event/dream/dendor/took_the_pelt/build_story(datum/social_bond/context)
	return "Мне снится шкура моего зверя на плечах [context.display_name()] и то, как он рассказывает, что взял его сам."

/datum/bond_event/dream/dendor/took_the_pelt/build_echo(datum/social_bond/context)
	return "Шкуру я забрал себе, а рассказывал так, будто зверь был мой. [context.display_name()] слышал."

/datum/bond_event/dream/dendor/went_strange
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -17
	weight_commit = 22
	rarity = 8
	history_label = "Сон о том, кто изменился"

/datum/bond_event/dream/dendor/went_strange/build_story(datum/social_bond/context)
	return "Мне снится [context.display_name()], который смотрит на меня не своими глазами и молчит слишком долго."

/datum/bond_event/dream/dendor/went_strange/build_echo(datum/social_bond/context)
	return "[context.display_name()] посмотрел на меня так, будто узнал обо мне то, чего я сам не знаю."

/datum/bond_event/dream/malum
	abstract_type = /datum/bond_event/dream/malum
	storyteller_type = /datum/storyteller/malum

/datum/bond_event/dream/malum/one_anvil
	valence = BOND_DREAM_POSITIVE
	dreamer_mask = BOND_ARCH_CRAFTER
	other_mask = BOND_ARCH_CRAFTER
	warmth_commit = 16
	weight_commit = 22
	history_label = "Сон об одной наковальне"

/datum/bond_event/dream/malum/one_anvil/build_story(datum/social_bond/context)
	return "Мне снится наковальня, у которой мы с [context.display_name()] стояли посменно, и молот не остывал двое суток."

/datum/bond_event/dream/malum/one_anvil/build_echo(datum/social_bond/context)
	return "Мы с [context.display_name()] держали одну наковальню двое суток, и молот не остывал."

/datum/bond_event/dream/malum/reforged_my_blade
	valence = BOND_DREAM_POSITIVE
	other_mask = BOND_ARCH_CRAFTER
	warmth_commit = 17
	weight_commit = 22
	history_label = "Сон о перекованном"

/datum/bond_event/dream/malum/reforged_my_blade/build_story(datum/social_bond/context)
	return "Мне снится клинок, который [context.display_name()] перековал мне заново и не взял ни монеты."

/datum/bond_event/dream/malum/reforged_my_blade/build_echo(datum/social_bond/context)
	return "Я перековал клинок [context.display_name()] заново и не взял с него ничего."

/datum/bond_event/dream/malum/stood_the_shift
	valence = BOND_DREAM_POSITIVE
	other_mask = BOND_ARCH_CRAFTER | BOND_ARCH_SERVILE
	warmth_commit = 13
	weight_commit = 16
	history_label = "Сон о чужой смене"

/datum/bond_event/dream/malum/stood_the_shift/build_story(datum/social_bond/context)
	return "Мне снится, как [context.display_name()] отстоял мою смену у печей, потому что я не держался на ногах."

/datum/bond_event/dream/malum/stood_the_shift/build_echo(datum/social_bond/context)
	return "Я отстоял смену за [context.display_name()], потому что он не держался на ногах."

/datum/bond_event/dream/malum/let_the_fire_die
	valence = BOND_DREAM_NEGATIVE
	scopes = BOND_DREAM_SCOPE_OWN
	dreamer_mask = BOND_ARCH_CRAFTER
	other_mask = BOND_ARCH_CRAFTER
	warmth_commit = -15
	weight_commit = 20
	history_label = "Сон о погасшей печи"

/datum/bond_event/dream/malum/let_the_fire_die/build_story(datum/social_bond/context)
	return "Мне снится остывшая печь и [context.display_name()], который должен был следить и не следил."

/datum/bond_event/dream/malum/let_the_fire_die/build_echo(datum/social_bond/context)
	return "Печь остыла на моей вахте, и разгребал это [context.display_name()]."

/datum/bond_event/dream/malum/stole_my_pattern
	valence = BOND_DREAM_NEGATIVE
	dreamer_mask = BOND_ARCH_CRAFTER
	other_mask = BOND_ARCH_CRAFTER | BOND_ARCH_MERCHANT
	warmth_commit = -18
	weight_commit = 24
	history_label = "Сон о краденом узоре"

/datum/bond_event/dream/malum/stole_my_pattern/build_story(datum/social_bond/context)
	return "Мне снится моя работа с чужим клеймом и [context.display_name()], который ставит это клеймо не первый год."

/datum/bond_event/dream/malum/stole_my_pattern/build_echo(datum/social_bond/context)
	return "Работа была [context.display_name()], а клеймо моё. Не первый год."

/datum/bond_event/dream/xylix
	abstract_type = /datum/bond_event/dream/xylix
	storyteller_type = /datum/storyteller/xylix

/datum/bond_event/dream/xylix/made_them_laugh
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 14
	weight_commit = 18
	history_label = "Сон о смехе"

/datum/bond_event/dream/xylix/made_them_laugh/build_story(datum/social_bond/context)
	return "Мне снится зал, который [context.display_name()] заставил хохотать в тот вечер, когда всем было не до смеха."

/datum/bond_event/dream/xylix/made_them_laugh/build_echo(datum/social_bond/context)
	return "В тот вечер я заставил хохотать целый зал. [context.display_name()] смеялся громче всех."

/datum/bond_event/dream/xylix/talked_us_out
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 19
	weight_commit = 24
	history_label = "Сон о вывернутом слове"

/datum/bond_event/dream/xylix/talked_us_out/build_story(datum/social_bond/context)
	return "Мне снится верёвка и [context.display_name()], который говорил так долго и складно, что верёвку убрали."

/datum/bond_event/dream/xylix/talked_us_out/build_echo(datum/social_bond/context)
	return "Я говорил, пока верёвку не убрали. [context.display_name()] стоял рядом и молчал, и правильно делал."

/datum/bond_event/dream/xylix/lucky_throw
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 12
	weight_commit = 16
	history_label = "Сон об удачном броске"

/datum/bond_event/dream/xylix/lucky_throw/build_story(datum/social_bond/context)
	return "Мне снятся кости, которые легли невозможно, и лицо [context.display_name()], поставившего на меня всё."

/datum/bond_event/dream/xylix/lucky_throw/build_echo(datum/social_bond/context)
	return "Я поставил на [context.display_name()] всё, и кости легли невозможно."

/datum/bond_event/dream/xylix/made_me_the_joke
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -16
	weight_commit = 20
	history_label = "Сон о чужой шутке"

/datum/bond_event/dream/xylix/made_me_the_joke/build_story(datum/social_bond/context)
	return "Мне снится смех, обращённый на меня, и [context.display_name()], который его начал и не остановил."

/datum/bond_event/dream/xylix/made_me_the_joke/build_echo(datum/social_bond/context)
	return "Смеялись над [context.display_name()], а начал я. Останавливать не стал."

/datum/bond_event/dream/xylix/swapped_the_dice
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -17
	weight_commit = 22
	history_label = "Сон о подменённых костях"

/datum/bond_event/dream/xylix/swapped_the_dice/build_story(datum/social_bond/context)
	return "Мне снятся кости, которые ложатся слишком ровно, и пальцы [context.display_name()], слишком быстрые для честной игры."

/datum/bond_event/dream/xylix/swapped_the_dice/build_echo(datum/social_bond/context)
	return "Кости я подменил. [context.display_name()], кажется, всё-таки заметил."

/datum/bond_event/dream/ravox
	abstract_type = /datum/bond_event/dream/ravox
	storyteller_type = /datum/storyteller/ravox

/datum/bond_event/dream/ravox/took_my_place
	valence = BOND_DREAM_POSITIVE
	other_mask = BOND_ARCH_WARRIOR
	warmth_commit = 20
	weight_commit = 26
	history_label = "Сон о подмене"

/datum/bond_event/dream/ravox/took_my_place/build_story(datum/social_bond/context)
	return "Мне снится место в первом ряду, которое должно было быть моим, и [context.display_name()], вставший туда вместо меня."

/datum/bond_event/dream/ravox/took_my_place/build_echo(datum/social_bond/context)
	return "Я встал в первый ряд вместо [context.display_name()]. Так было правильнее."

/datum/bond_event/dream/ravox/honest_duel
	valence = BOND_DREAM_POSITIVE
	dreamer_mask = BOND_ARCH_WARRIOR
	other_mask = BOND_ARCH_WARRIOR
	warmth_commit = 15
	weight_commit = 22
	history_label = "Сон о честном поединке"

/datum/bond_event/dream/ravox/honest_duel/build_story(datum/social_bond/context)
	return "Мне снится поединок с [context.display_name()], после которого мы подали друг другу руки и никто не счёл себя обиженным."

/datum/bond_event/dream/ravox/honest_duel/build_echo(datum/social_bond/context)
	return "После того поединка мы с [context.display_name()] подали друг другу руки."

/datum/bond_event/dream/ravox/yielded_and_lived
	valence = BOND_DREAM_POSITIVE
	other_mask = BOND_ARCH_WARRIOR
	warmth_commit = 14
	weight_commit = 18
	history_label = "Сон о пощаде"

/datum/bond_event/dream/ravox/yielded_and_lived/build_story(datum/social_bond/context)
	return "Мне снится, как я сдался, и [context.display_name()] опустил оружие, хотя мог не опускать."

/datum/bond_event/dream/ravox/yielded_and_lived/build_echo(datum/social_bond/context)
	return "[context.display_name()] сдался, и я опустил оружие, хотя мог не опускать."

/datum/bond_event/dream/ravox/struck_from_behind
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -22
	weight_commit = 28
	history_label = "Сон об ударе в спину"

/datum/bond_event/dream/ravox/struck_from_behind/build_story(datum/social_bond/context)
	return "Мне снится удар, которого не видно, и [context.display_name()], который единственный стоял за моей спиной."

/datum/bond_event/dream/ravox/struck_from_behind/build_echo(datum/social_bond/context)
	return "Я ударил [context.display_name()] со спины. Иначе бы не вышло."

/datum/bond_event/dream/ravox/boasted_my_deed
	valence = BOND_DREAM_NEGATIVE
	dreamer_mask = BOND_ARCH_WARRIOR
	warmth_commit = -16
	weight_commit = 22
	history_label = "Сон о присвоенной славе"

/datum/bond_event/dream/ravox/boasted_my_deed/build_story(datum/social_bond/context)
	return "Мне снится, как [context.display_name()] рассказывает о моём деле от первого лица, и его слушают охотнее."

/datum/bond_event/dream/ravox/boasted_my_deed/build_echo(datum/social_bond/context)
	return "Я рассказывал о деле [context.display_name()] от первого лица, и меня слушали охотнее."

/datum/bond_event/dream/pestra
	abstract_type = /datum/bond_event/dream/pestra
	storyteller_type = /datum/storyteller/pestra

/datum/bond_event/dream/pestra/sat_with_the_sick
	valence = BOND_DREAM_POSITIVE
	other_mask = BOND_ARCH_HEALER | BOND_ARCH_DEVOUT
	warmth_commit = 19
	weight_commit = 24
	history_label = "Сон о сиделке"

/datum/bond_event/dream/pestra/sat_with_the_sick/build_story(datum/social_bond/context)
	return "Мне снится жар и [context.display_name()], просидевший у моей постели всю ночь, зная, чем это может кончиться для него."

/datum/bond_event/dream/pestra/sat_with_the_sick/build_echo(datum/social_bond/context)
	return "Я просидел у постели [context.display_name()] всю ночь, понимая, чем это может кончиться."

/datum/bond_event/dream/pestra/took_the_fever
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 17
	weight_commit = 22
	history_label = "Сон о лихорадке"

/datum/bond_event/dream/pestra/took_the_fever/build_story(datum/social_bond/context)
	return "Мне снится, как [context.display_name()] меняет мне тряпки на лбу и врёт, что я выгляжу лучше."

/datum/bond_event/dream/pestra/took_the_fever/build_echo(datum/social_bond/context)
	return "Я врал [context.display_name()], что он выглядит лучше, и менял тряпки до утра."

/datum/bond_event/dream/pestra/gave_the_mercy
	valence = BOND_DREAM_POSITIVE
	other_mask = BOND_ARCH_HEALER | BOND_ARCH_WARRIOR
	warmth_commit = 16
	weight_commit = 24
	rarity = 8
	history_label = "Сон о милосердии"

/datum/bond_event/dream/pestra/gave_the_mercy/build_story(datum/social_bond/context)
	return "Мне снится тот, кого уже нельзя было спасти, и [context.display_name()], у которого хватило руки сделать это быстро."

/datum/bond_event/dream/pestra/gave_the_mercy/build_echo(datum/social_bond/context)
	return "Спасти было нельзя, и я сделал это быстро. [context.display_name()] видел."

/datum/bond_event/dream/pestra/barred_the_door
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -20
	weight_commit = 26
	history_label = "Сон о запертой двери"

/datum/bond_event/dream/pestra/barred_the_door/build_story(datum/social_bond/context)
	return "Мне снится дверь, которую [context.display_name()] запер изнутри, когда снаружи остались больные. Я был снаружи."

/datum/bond_event/dream/pestra/barred_the_door/build_echo(datum/social_bond/context)
	return "Я запер дверь. Снаружи остались больные, и [context.display_name()] среди них."

/datum/bond_event/dream/pestra/sold_the_cure
	valence = BOND_DREAM_NEGATIVE
	other_mask = BOND_ARCH_MERCHANT | BOND_ARCH_HEALER
	warmth_commit = -18
	weight_commit = 24
	history_label = "Сон о проданном лекарстве"

/datum/bond_event/dream/pestra/sold_the_cure/build_story(datum/social_bond/context)
	return "Мне снится склянка в руках [context.display_name()] и цена, которую он назвал, глядя на умирающего."

/datum/bond_event/dream/pestra/sold_the_cure/build_echo(datum/social_bond/context)
	return "Я назвал цену, глядя на умирающего. [context.display_name()] запомнил её лучше меня."

/datum/bond_event/dream/eora
	abstract_type = /datum/bond_event/dream/eora
	storyteller_type = /datum/storyteller/eora

/datum/bond_event/dream/eora/stopped_the_fight
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 17
	weight_commit = 22
	history_label = "Сон о разнятых руках"

/datum/bond_event/dream/eora/stopped_the_fight/build_story(datum/social_bond/context)
	return "Мне снится драка, которую [context.display_name()] разнял голыми руками, встав между двумя клинками."

/datum/bond_event/dream/eora/stopped_the_fight/build_echo(datum/social_bond/context)
	return "Ту драку я разнял голыми руками. [context.display_name()] был одним из двоих."

/datum/bond_event/dream/eora/stood_at_the_wedding
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 15
	weight_commit = 20
	history_label = "Сон о свадьбе"

/datum/bond_event/dream/eora/stood_at_the_wedding/build_story(datum/social_bond/context)
	return "Мне снится свадьба, на которой [context.display_name()] стоял рядом со мной, когда родня стоять отказалась."

/datum/bond_event/dream/eora/stood_at_the_wedding/build_echo(datum/social_bond/context)
	return "Я стоял рядом с [context.display_name()] на той свадьбе, когда его родня отказалась."

/datum/bond_event/dream/eora/took_in_my_kin
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 20
	weight_commit = 26
	history_label = "Сон о приюте"

/datum/bond_event/dream/eora/took_in_my_kin/build_story(datum/social_bond/context)
	return "Мне снится порог дома [context.display_name()] и мои родные, которых он впустил, не спросив, надолго ли."

/datum/bond_event/dream/eora/took_in_my_kin/build_echo(datum/social_bond/context)
	return "Я впустил родных [context.display_name()] и не стал спрашивать, надолго ли."

/datum/bond_event/dream/eora/turned_away_kin
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -19
	weight_commit = 24
	history_label = "Сон о закрытом пороге"

/datum/bond_event/dream/eora/turned_away_kin/build_story(datum/social_bond/context)
	return "Мне снится порог, на котором стояли мои, и [context.display_name()], который не открыл, хотя был дома."

/datum/bond_event/dream/eora/turned_away_kin/build_echo(datum/social_bond/context)
	return "Я не открыл, хотя был дома. На пороге стояли родные [context.display_name()]."

/datum/bond_event/dream/eora/broke_the_peace
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -17
	weight_commit = 22
	history_label = "Сон о нарушенном мире"

/datum/bond_event/dream/eora/broke_the_peace/build_story(datum/social_bond/context)
	return "Мне снится замирение, на которое мы оба дали слово, и [context.display_name()], нарушивший его первым."

/datum/bond_event/dream/eora/broke_the_peace/build_echo(datum/social_bond/context)
	return "Слово о замирении мы дали оба. Нарушил первым я, и [context.display_name()] это знает."

/datum/bond_event/dream/psydon
	abstract_type = /datum/bond_event/dream/psydon
	storyteller_type = /datum/storyteller/psydon

/datum/bond_event/dream/psydon/wept_together
	valence = BOND_DREAM_POSITIVE
	dreamer_mask = BOND_ARCH_DEVOUT
	other_mask = BOND_ARCH_DEVOUT
	warmth_commit = 17
	weight_commit = 22
	history_label = "Сон о плаче Всеотца"

/datum/bond_event/dream/psydon/wept_together/build_story(datum/social_bond/context)
	return "Мне снится, что мы с [context.display_name()] стоим на коленях и помним, из-за кого плакал Всеотец. Он не отводит взгляда."

/datum/bond_event/dream/psydon/wept_together/build_echo(datum/social_bond/context)
	return "Мы с [context.display_name()] стояли на коленях и помнили, из-за кого плакал Всеотец."

/datum/bond_event/dream/psydon/kept_the_old_rite
	valence = BOND_DREAM_POSITIVE
	scopes = BOND_DREAM_SCOPE_OWN
	other_mask = BOND_ARCH_DEVOUT
	warmth_commit = 16
	weight_commit = 22
	history_label = "Сон о старом обряде"

/datum/bond_event/dream/psydon/kept_the_old_rite/build_story(datum/social_bond/context)
	return "Мне снится обряд по старому чину, который [context.display_name()] провёл, зная, что за это спросят."

/datum/bond_event/dream/psydon/kept_the_old_rite/build_echo(datum/social_bond/context)
	return "Я провёл обряд по старому чину и знал, что спросят. [context.display_name()] был там."

/datum/bond_event/dream/psydon/shared_the_ashes
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 14
	weight_commit = 18
	history_label = "Сон о пепле"

/datum/bond_event/dream/psydon/shared_the_ashes/build_story(datum/social_bond/context)
	return "Мне снится пепел на лбу и рука [context.display_name()], которая его наносит, потому что моя дрожала."

/datum/bond_event/dream/psydon/shared_the_ashes/build_echo(datum/social_bond/context)
	return "Пепел я наносил [context.display_name()] сам, потому что его рука дрожала."

/datum/bond_event/dream/psydon/named_me_heretic
	valence = BOND_DREAM_NEGATIVE
	other_mask = BOND_ARCH_DEVOUT | BOND_ARCH_LAWMAN
	warmth_commit = -21
	weight_commit = 26
	history_label = "Сон об отступничестве"

/datum/bond_event/dream/psydon/named_me_heretic/build_story(datum/social_bond/context)
	return "Мне снится слово еретик, сказанное обо мне голосом [context.display_name()], и то, как быстро его подхватили."

/datum/bond_event/dream/psydon/named_me_heretic/build_echo(datum/social_bond/context)
	return "Я назвал [context.display_name()] еретиком, и это подхватили быстрее, чем я думал."

/datum/bond_event/dream/psydon/denied_the_father
	valence = BOND_DREAM_NEGATIVE
	dreamer_mask = BOND_ARCH_DEVOUT
	warmth_commit = -18
	weight_commit = 24
	history_label = "Сон об отречении"

/datum/bond_event/dream/psydon/denied_the_father/build_story(datum/social_bond/context)
	return "Мне снится, как [context.display_name()] отрекается от Всеотца при свидетелях, и одним из свидетелей был я."

/datum/bond_event/dream/psydon/denied_the_father/build_echo(datum/social_bond/context)
	return "Я отрёкся при свидетелях. Одним из них был [context.display_name()]."

/datum/bond_event/dream/zizo
	abstract_type = /datum/bond_event/dream/zizo
	storyteller_type = /datum/storyteller/zizo

/datum/bond_event/dream/zizo/hid_me_from_the_pyre
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 20
	weight_commit = 26
	rarity = 8
	history_label = "Сон о костре"

/datum/bond_event/dream/zizo/hid_me_from_the_pyre/build_story(datum/social_bond/context)
	return "Мне снится костёр, сложенный для меня, и [context.display_name()], который спрятал меня так, что не нашли."

/datum/bond_event/dream/zizo/hid_me_from_the_pyre/build_echo(datum/social_bond/context)
	return "Я спрятал [context.display_name()] так, что не нашли. Костёр сложили зря."

/datum/bond_event/dream/zizo/shared_the_secret
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 16
	weight_commit = 24
	rarity = 5
	history_label = "Сон о тайне"

/datum/bond_event/dream/zizo/shared_the_secret/build_story(datum/social_bond/context)
	return "Мне снится то, что [context.display_name()] сказал мне шёпотом и за что нас обоих сожгли бы вместе."

/datum/bond_event/dream/zizo/shared_the_secret/build_echo(datum/social_bond/context)
	return "То, что я сказал [context.display_name()] шёпотом, стоит нам обоим костра."

/datum/bond_event/dream/zizo/promised_salvation
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -16
	weight_commit = 22
	rarity = 8
	history_label = "Сон об обещанном спасении"

/datum/bond_event/dream/zizo/promised_salvation/build_story(datum/social_bond/context)
	return "Мне снится голос [context.display_name()], обещающий спасение так уверенно, что во сне я почти соглашаюсь."

/datum/bond_event/dream/zizo/promised_salvation/build_echo(datum/social_bond/context)
	return "Я обещал [context.display_name()] спасение, и он почти согласился."

/datum/bond_event/dream/zizo/marked_me
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -19
	weight_commit = 24
	rarity = 6
	history_label = "Сон о метке"

/datum/bond_event/dream/zizo/marked_me/build_story(datum/social_bond/context)
	return "Мне снится знак, оставленный на мне без спроса, и пальцы [context.display_name()], которые его выводили."

/datum/bond_event/dream/zizo/marked_me/build_echo(datum/social_bond/context)
	return "Знак на [context.display_name()] вывел я и спрашивать не стал."

/datum/bond_event/dream/zizo/gave_me_up
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -21
	weight_commit = 26
	rarity = 8
	history_label = "Сон о выданном"

/datum/bond_event/dream/zizo/gave_me_up/build_story(datum/social_bond/context)
	return "Мне снится дознание, на котором [context.display_name()] назвал моё имя первым и не запнулся."

/datum/bond_event/dream/zizo/gave_me_up/build_echo(datum/social_bond/context)
	return "На дознании я назвал имя [context.display_name()] первым и не запнулся."

/datum/bond_event/dream/baotha
	abstract_type = /datum/bond_event/dream/baotha
	storyteller_type = /datum/storyteller/baotha

/datum/bond_event/dream/baotha/shared_the_cup
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 14
	weight_commit = 18
	history_label = "Сон об общей чаше"

/datum/bond_event/dream/baotha/shared_the_cup/build_story(datum/social_bond/context)
	return "Мне снится чаша, которую мы с [context.display_name()] передавали друг другу, пока не рассвело."

/datum/bond_event/dream/baotha/shared_the_cup/build_echo(datum/social_bond/context)
	return "Ту чашу мы с [context.display_name()] передавали друг другу до рассвета."

/datum/bond_event/dream/baotha/covered_for_me
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 16
	weight_commit = 20
	history_label = "Сон о прикрытии"

/datum/bond_event/dream/baotha/covered_for_me/build_story(datum/social_bond/context)
	return "Мне снится, как [context.display_name()] соврал за меня, не моргнув, и никто не переспросил."

/datum/bond_event/dream/baotha/covered_for_me/build_echo(datum/social_bond/context)
	return "Я соврал за [context.display_name()] не моргнув, и переспрашивать не стали."

/datum/bond_event/dream/baotha/one_night
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 15
	weight_commit = 22
	rarity = 8
	history_label = "Сон об одной ночи"

/datum/bond_event/dream/baotha/one_night/build_story(datum/social_bond/context)
	return "Мне снится ночь с [context.display_name()], после которой мы оба сделали вид, что ничего не было."

/datum/bond_event/dream/baotha/one_night/build_echo(datum/social_bond/context)
	return "После той ночи мы с [context.display_name()] оба сделали вид, что ничего не было."

/datum/bond_event/dream/baotha/left_before_dawn
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -15
	weight_commit = 20
	history_label = "Сон об ушедшем"

/datum/bond_event/dream/baotha/left_before_dawn/build_story(datum/social_bond/context)
	return "Мне снится пустое место рядом и [context.display_name()], ушедший до рассвета, не сказав ни слова."

/datum/bond_event/dream/baotha/left_before_dawn/build_echo(datum/social_bond/context)
	return "Я ушёл до рассвета и ничего не сказал. [context.display_name()] проснулся один."

/datum/bond_event/dream/baotha/spent_my_coin
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -16
	weight_commit = 20
	history_label = "Сон о прогулянном"

/datum/bond_event/dream/baotha/spent_my_coin/build_story(datum/social_bond/context)
	return "Мне снится, как [context.display_name()] спускает мои деньги с чужими людьми и заказывает ещё."

/datum/bond_event/dream/baotha/spent_my_coin/build_echo(datum/social_bond/context)
	return "Деньги [context.display_name()] я спустил с чужими людьми и заказал ещё."

/datum/bond_event/dream/graggar
	abstract_type = /datum/bond_event/dream/graggar
	storyteller_type = /datum/storyteller/graggar

/datum/bond_event/dream/graggar/shared_the_spoils
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 14
	weight_commit = 20
	history_label = "Сон о добыче"

/datum/bond_event/dream/graggar/shared_the_spoils/build_story(datum/social_bond/context)
	return "Мне снится добыча, которую [context.display_name()] разделил поровну, хотя сильнее был он."

/datum/bond_event/dream/graggar/shared_the_spoils/build_echo(datum/social_bond/context)
	return "Добычу я разделил с [context.display_name()] поровну, хотя сильнее был я."

/datum/bond_event/dream/graggar/took_the_blame
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 18
	weight_commit = 24
	rarity = 6
	history_label = "Сон о чужой вине"

/datum/bond_event/dream/graggar/took_the_blame/build_story(datum/social_bond/context)
	return "Мне снится наказание, которое должно было достаться мне, и [context.display_name()], назвавший виновным себя."

/datum/bond_event/dream/graggar/took_the_blame/build_echo(datum/social_bond/context)
	return "Виновным я назвал себя, хотя это был [context.display_name()]."

/datum/bond_event/dream/graggar/made_me_kneel
	valence = BOND_DREAM_NEGATIVE
	other_mask = BOND_ARCH_NOBLE | BOND_ARCH_WARRIOR | BOND_ARCH_LAWMAN
	warmth_commit = -20
	weight_commit = 26
	history_label = "Сон о колене"

/datum/bond_event/dream/graggar/made_me_kneel/build_story(datum/social_bond/context)
	return "Мне снится, как [context.display_name()] ставит меня на колени при всех и держит там дольше, чем нужно."

/datum/bond_event/dream/graggar/made_me_kneel/build_echo(datum/social_bond/context)
	return "Я поставил [context.display_name()] на колени при всех и держал дольше, чем было нужно."

/datum/bond_event/dream/graggar/broke_my_hand
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -22
	weight_commit = 28
	rarity = 8
	history_label = "Сон о сломанной руке"

/datum/bond_event/dream/graggar/broke_my_hand/build_story(datum/social_bond/context)
	return "Мне снится хруст и лицо [context.display_name()], на котором нет ничего, кроме скуки."

/datum/bond_event/dream/graggar/broke_my_hand/build_echo(datum/social_bond/context)
	return "Руку [context.display_name()] я сломал, и мне было скучно."

/datum/bond_event/dream/graggar/named_me_weak
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -17
	weight_commit = 22
	history_label = "Сон о слабости"

/datum/bond_event/dream/graggar/named_me_weak/build_story(datum/social_bond/context)
	return "Мне снится слово слабый, сказанное обо мне голосом [context.display_name()] так, чтобы услышали все."

/datum/bond_event/dream/graggar/named_me_weak/build_echo(datum/social_bond/context)
	return "Я назвал [context.display_name()] слабым так, чтобы услышали все."

/datum/bond_event/dream/matthios
	abstract_type = /datum/bond_event/dream/matthios
	storyteller_type = /datum/storyteller/matthios

/datum/bond_event/dream/matthios/stood_the_rising
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 18
	weight_commit = 24
	history_label = "Сон о восстании"

/datum/bond_event/dream/matthios/stood_the_rising/build_story(datum/social_bond/context)
	return "Мне снится площадь, где мы с [context.display_name()] стояли плечом к плечу против тех, кто был выше нас обоих."

/datum/bond_event/dream/matthios/stood_the_rising/build_echo(datum/social_bond/context)
	return "На той площади мы с [context.display_name()] стояли плечом к плечу против тех, кто был выше."

/datum/bond_event/dream/matthios/shared_the_word
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 15
	weight_commit = 20
	history_label = "Сон о слове"

/datum/bond_event/dream/matthios/shared_the_word/build_story(datum/social_bond/context)
	return "Мне снится, как [context.display_name()] читает вслух то, что читать запрещено, и не понижает голоса."

/datum/bond_event/dream/matthios/shared_the_word/build_echo(datum/social_bond/context)
	return "Я читал вслух запрещённое и не понижал голоса. [context.display_name()] слушал."

/datum/bond_event/dream/matthios/took_the_lash
	valence = BOND_DREAM_POSITIVE
	warmth_commit = 19
	weight_commit = 24
	rarity = 8
	history_label = "Сон о плетях"

/datum/bond_event/dream/matthios/took_the_lash/build_story(datum/social_bond/context)
	return "Мне снятся плети, которые достались [context.display_name()] вместо меня, потому что он назвался первым."

/datum/bond_event/dream/matthios/took_the_lash/build_echo(datum/social_bond/context)
	return "Плети достались мне вместо [context.display_name()], потому что я назвался первым."

/datum/bond_event/dream/matthios/named_the_names
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -21
	weight_commit = 26
	history_label = "Сон о названных именах"

/datum/bond_event/dream/matthios/named_the_names/build_story(datum/social_bond/context)
	return "Мне снится, как [context.display_name()] перечисляет наш круг по именам, и моё идёт третьим."

/datum/bond_event/dream/matthios/named_the_names/build_echo(datum/social_bond/context)
	return "Я перечислил круг по именам. Имя [context.display_name()] шло третьим."

/datum/bond_event/dream/matthios/claimed_the_lead
	valence = BOND_DREAM_NEGATIVE
	warmth_commit = -16
	weight_commit = 22
	history_label = "Сон о первом среди равных"

/datum/bond_event/dream/matthios/claimed_the_lead/build_story(datum/social_bond/context)
	return "Мне снится, как [context.display_name()] объясняет, почему среди равных он всё-таки первый."

/datum/bond_event/dream/matthios/claimed_the_lead/build_echo(datum/social_bond/context)
	return "Я объяснил, почему среди равных первый всё-таки я. [context.display_name()] не согласился."
