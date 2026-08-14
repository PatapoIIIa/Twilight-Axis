/proc/bonds_split_words(text)
	RETURN_TYPE(/list)
	var/list/out = list()
	for(var/token in splittext(replacetext(text, "\t", " "), " "))
		var/clean = trim(token)
		if(length(clean))
			out += clean
	return out

/proc/bonds_parse_stance_cell(cell)
	RETURN_TYPE(/list)
	if(cell == "-")
		return null
	var/split = findtext(cell, "/")
	if(!split)
		return null
	var/warmth = text2num(copytext(cell, 1, split))
	var/weight = text2num(copytext(cell, split + 1))
	if(isnull(warmth) || isnull(weight))
		return null
	return list(warmth, weight)

/datum/controller/subsystem/bonds/proc/load_stance_file(name)
	RETURN_TYPE(/list)
	var/path = "[BOND_STANCE_DIRECTORY]/[name]"
	if(!fexists(path))
		bondlog("stance config [path] is missing; every pair it would declare stays at flat zero", BONDLOG_WARN)
		return null

	var/list/axis = list()
	var/list/rows_by_label = list()
	var/line_number = 0
	for(var/line in world.file2list(path))
		line_number++
		var/trimmed = trim(line)
		if(!length(trimmed) || findtextEx(trimmed, "#") == 1)
			continue
		var/split = findtext(trimmed, ":")
		if(!split)
			bondlog("[name]:[line_number] has no colon; expected 'faction: cells'", BONDLOG_WARN)
			continue
		var/label = lowertext(trim(copytext(trimmed, 1, split)))
		var/payload = copytext(trimmed, split + 1)
		if(label == "axis")
			axis = bonds_split_words(payload)
			continue
		if(!length(label))
			bondlog("[name]:[line_number] has no faction before the colon", BONDLOG_WARN)
			continue
		if(!isnull(rows_by_label[label]))
			bondlog("[name]:[line_number] declares [label] a second time; the later row would silently win", BONDLOG_WARN)
			continue
		rows_by_label[label] = bonds_split_words(payload)

	if(!length(axis))
		bondlog("[name] never declares an axis, so none of its rows can be placed", BONDLOG_WARN)
		return null

	var/count = length(axis)
	var/list/warmth_rows = list()
	var/list/weight_rows = list()
	for(var/i in 1 to count)
		var/label = axis[i]
		var/expected = count - i
		var/list/cells = rows_by_label[label]
		if(isnull(cells))
			if(expected)
				bondlog("[name] names [label] on the axis but never gives it a row", BONDLOG_WARN)
			cells = list()
		else if(length(cells) != expected)
			bondlog("[name] row [label] holds [length(cells)] cells, expected [expected]", BONDLOG_WARN)
		var/list/warmth_row = list()
		var/list/weight_row = list()
		for(var/column in 1 to expected)
			var/list/pair = (column <= length(cells)) ? bonds_parse_stance_cell(cells[column]) : null
			if(isnull(pair))
				if(column <= length(cells) && cells[column] != "-")
					bondlog("[name] row [label] column [column] reads \"[cells[column]]\", expected warmth/weight", BONDLOG_WARN)
				warmth_row += null
				weight_row += null
				continue
			warmth_row += pair[1]
			weight_row += pair[2]
		warmth_rows += list(warmth_row)
		weight_rows += list(weight_row)

	return list(axis, warmth_rows, weight_rows)

/datum/controller/subsystem/bonds/proc/stance_blocks()
	RETURN_TYPE(/list)
	if(stance_blocks_cache)
		return stance_blocks_cache
	var/list/blocks = list()
	for(var/name in list("faction_stances.txt", "clan_stances.txt"))
		var/list/block = load_stance_file(name)
		if(block)
			blocks += list(block)
	stance_blocks_cache = blocks
	return blocks
