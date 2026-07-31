/datum/bond_stage/stranger
	label = "Незнакомец"
	desc = "Лицо, которое ничего вам не говорит."
	category = BOND_GROUP_KNOWN
	accent = "#7a7a7a"
	priority = 0
	weight_max = 14

/datum/bond_stage/acquaintance
	label = "Знакомый"
	desc = "Вы пересекались, не более того."
	category = BOND_GROUP_KNOWN
	accent = "#9aa0a6"
	priority = 10
	weight_min = 15
	warmth_min = -14
	warmth_max = 14

/datum/bond_stage/warm
	label = "Приятель"
	desc = "С этим человеком легко."
	category = BOND_GROUP_WARM
	accent = "#7fb069"
	priority = 20
	weight_min = 15
	warmth_min = 15
	warmth_max = 39

/datum/bond_stage/friend
	label = "Друг"
	desc = "Вы держитесь друг за друга."
	category = BOND_GROUP_WARM
	accent = "#4c9f70"
	priority = 30
	weight_min = 30
	warmth_min = 40
	warmth_max = 74

/datum/bond_stage/close_friend
	label = "Близкий друг"
	desc = "Мало кому вы доверяете так же."
	category = BOND_GROUP_WARM
	accent = "#2f8f5b"
	priority = 40
	weight_min = 50
	warmth_min = 75

/datum/bond_stage/cold
	label = "Холодок"
	desc = "Что-то между вами не так."
	category = BOND_GROUP_COLD
	accent = "#a08a6a"
	priority = 20
	weight_min = 15
	warmth_min = -39
	warmth_max = -15

/datum/bond_stage/rival
	label = "Соперник"
	desc = "Вы меряетесь с ним при каждом удобном случае."
	category = BOND_GROUP_COLD
	accent = "#c08a3e"
	priority = 30
	weight_min = 50
	warmth_min = -60
	warmth_max = -15

/datum/bond_stage/enemy
	label = "Враг"
	desc = "Вы не желаете ему добра."
	category = BOND_GROUP_HOSTILE
	accent = "#b4553f"
	priority = 40
	weight_min = 40
	warmth_max = -40

/datum/bond_stage/nemesis
	label = "Кровный враг"
	desc = "Между вами пролилась кровь, и это не забывается."
	category = BOND_GROUP_HOSTILE
	accent = "#8c2f2f"
	priority = 60
	weight_min = 70
	warmth_max = -75
	required_tags = BOND_TAG_SHED_BLOOD
