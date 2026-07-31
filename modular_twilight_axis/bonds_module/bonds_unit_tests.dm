#if defined(UNIT_TESTS) || defined(SPACEMAN_DMM)

#define BD_SOURCE replacetext(__FILE__, "\\", "/")
#define BD_ASSERT(assertion, reason) if(!(assertion)) { return Fail("Assertion failed: [reason || "no reason"]", BD_SOURCE, __LINE__) }
#define BD_ASSERT_EQUAL(a, b, reason) do { var/_lhs = ##a; var/_rhs = ##b; if(_lhs != _rhs) { return Fail("Expected [isnull(_lhs) ? "null" : _lhs] == [isnull(_rhs) ? "null" : _rhs]: [reason || "no reason"]", BD_SOURCE, __LINE__) } } while(FALSE)
#define BD_ASSERT_NOTNULL(a, reason) if(isnull(a)) { return Fail("Expected non-null: [reason || "no reason"]", BD_SOURCE, __LINE__) }
#define BD_ASSERT_NULL(a, reason) if(!isnull(a)) { return Fail("Expected null: [reason || "no reason"]", BD_SOURCE, __LINE__) }

/datum/unit_test/bonds
	abstract_type = /datum/unit_test/bonds
	var/static/bd_test_serial = 0
	var/list/bd_test_minds

/datum/unit_test/bonds/proc/bd_make_mind()
	bd_test_serial++
	var/datum/mind/created = new /datum/mind("BDTEST_[bd_test_serial]")
	created.name = "Test Subject [bd_test_serial]"
	LAZYADD(bd_test_minds, created)
	return created

/datum/unit_test/bonds/Destroy()
	for(var/datum/mind/tracked as anything in bd_test_minds)
		var/datum/bond_node/node = SSbonds.get_node(tracked)
		if(node)
			for(var/datum/social_bond/kin/link as anything in node.kin.Copy())
				SSbonds.remove_kin(tracked, link.other, link.kind)
		SSbonds.drop_actor(SSbonds.resolve_actor(tracked))
	bd_test_minds = null
	return ..()

/datum/unit_test/bonds/prototypes_built/Run()
	BD_ASSERT(SSbonds.event_prototypes.len > 0, "event prototypes must be built at init")
	BD_ASSERT(SSbonds.stage_prototypes.len > 0, "stage prototypes must be built at init")
	BD_ASSERT_NOTNULL(SSbonds.get_event_prototype(/datum/bond_event/struck_by), "struck_by prototype missing")

/datum/unit_test/bonds/stage_priority_order/Run()
	var/last_priority = null
	for(var/datum/bond_stage/stage as anything in SSbonds.stage_prototypes)
		if(!isnull(last_priority))
			BD_ASSERT(stage.priority <= last_priority, "stage prototypes must be sorted by descending priority")
		last_priority = stage.priority

/datum/unit_test/bonds/bond_creation_is_directed/Run()
	var/datum/mind/a = bd_make_mind()
	var/datum/mind/b = bd_make_mind()
	var/datum/social_bond/forward = SSbonds.get_or_create_bond(a, b)
	BD_ASSERT_NOTNULL(forward, "forward bond must be created")
	BD_ASSERT_NULL(SSbonds.get_bond(b, a), "creating one direction must not create the reverse")
	BD_ASSERT_NULL(SSbonds.get_or_create_bond(a, a), "self bonds must be refused")

/datum/unit_test/bonds/event_applies_transient_and_commit/Run()
	var/datum/mind/a = bd_make_mind()
	var/datum/mind/b = bd_make_mind()
	var/datum/social_bond/bond = SSbonds.get_or_create_bond(a, b)
	bond.attach_event(/datum/bond_event/struck_by)
	var/datum/bond_event/prototype = SSbonds.get_event_prototype(/datum/bond_event/struck_by)
	BD_ASSERT(bond.warmth < 0, "a hostile event must push warmth negative")
	BD_ASSERT(bond.weight > 0, "a hostile event must raise weight")
	BD_ASSERT_EQUAL(bond.warmth_committed, prototype.warmth_commit, "first commit must apply at full scale")
	BD_ASSERT(bond.tags & BOND_TAG_SHED_BLOOD, "struck_by must set the blood tag")
	BD_ASSERT_EQUAL(LAZYLEN(bond.history), 1, "an applied event must record one history entry")

/datum/unit_test/bonds/commit_cooldown_blocks_second_commit/Run()
	var/datum/mind/a = bd_make_mind()
	var/datum/mind/b = bd_make_mind()
	var/datum/social_bond/bond = SSbonds.get_or_create_bond(a, b)
	bond.attach_event(/datum/bond_event/struck_by)
	var/committed_after_first = bond.warmth_committed
	bond.attach_event(/datum/bond_event/struck_by)
	BD_ASSERT_EQUAL(bond.warmth_committed, committed_after_first, "a repeat inside the cooldown must not commit again")
	BD_ASSERT_EQUAL(LAZYLEN(bond.active_events), 1, "same-category repeats must refresh, not stack")

/datum/unit_test/bonds/commit_scale_falls_off/Run()
	var/datum/mind/a = bd_make_mind()
	var/datum/mind/b = bd_make_mind()
	var/datum/social_bond/bond = SSbonds.get_or_create_bond(a, b)
	BD_ASSERT_EQUAL(bond.commit_scale(BOND_CATEGORY_VIOLENCE), 1, "first commit must be unscaled")
	bond.attach_event(/datum/bond_event/struck_by)
	BD_ASSERT(bond.commit_scale(BOND_CATEGORY_VIOLENCE) < 1, "subsequent commits must be scaled down")

/datum/unit_test/bonds/transient_expiry_restores_axes/Run()
	var/datum/mind/a = bd_make_mind()
	var/datum/mind/b = bd_make_mind()
	var/datum/social_bond/bond = SSbonds.get_or_create_bond(a, b)
	bond.attach_event(/datum/bond_event/struck_by)
	var/warmth_with_transient = bond.warmth
	var/datum/bond_event/active = bond.active_events[BOND_CATEGORY_VIOLENCE]
	BD_ASSERT_NOTNULL(active, "event must be active before expiry")
	active.expire()
	BD_ASSERT(bond.warmth > warmth_with_transient, "expiring the transient part must relax warmth back toward the committed value")
	BD_ASSERT_EQUAL(bond.warmth, bond.warmth_committed, "after expiry only the committed residue remains")

/datum/unit_test/bonds/stage_resolves_from_axes/Run()
	var/datum/mind/a = bd_make_mind()
	var/datum/mind/b = bd_make_mind()
	var/datum/social_bond/bond = SSbonds.get_or_create_bond(a, b)
	BD_ASSERT_EQUAL(bond.stage_group(), BOND_GROUP_KNOWN, "a fresh bond must be a stranger")
	bond.warmth_committed = 80
	bond.weight_committed = 60
	bond.recalculate()
	BD_ASSERT_EQUAL(bond.stage_group(), BOND_GROUP_WARM, "high warmth and weight must resolve to a warm stage")
	bond.warmth_committed = -80
	bond.recalculate()
	BD_ASSERT_EQUAL(bond.stage_group(), BOND_GROUP_HOSTILE, "deep negative warmth at high weight must resolve to hostile")

/datum/unit_test/bonds/node_cap_evicts_weakest/Run()
	var/datum/mind/owner = bd_make_mind()
	var/datum/bond_node/node = SSbonds.get_or_create_node(owner)
	for(var/i in 1 to BOND_MAX_PER_MIND + 5)
		var/datum/mind/target = bd_make_mind()
		var/datum/social_bond/bond = SSbonds.get_or_create_bond(owner, target)
		bond.weight_committed = i
		bond.recalculate()
	BD_ASSERT(length(node.bonds) <= BOND_MAX_PER_MIND, "the node cap must bound outgoing bonds")

/datum/unit_test/bonds/tagged_bonds_survive_eviction/Run()
	var/datum/mind/owner = bd_make_mind()
	var/datum/mind/protected = bd_make_mind()
	var/datum/bond_node/node = SSbonds.get_or_create_node(owner)
	var/datum/social_bond/tagged = SSbonds.get_or_create_bond(owner, protected)
	tagged.tags |= BOND_TAG_KILLED_ME
	for(var/i in 1 to BOND_MAX_PER_MIND + 5)
		var/datum/mind/target = bd_make_mind()
		var/datum/social_bond/bond = SSbonds.get_or_create_bond(owner, target)
		bond.weight_committed = 50
		bond.recalculate()
	BD_ASSERT_NOTNULL(node.get_bond(protected), "a tagged bond must never be evicted by the cap")

/datum/unit_test/bonds/seed_flavors_are_pickable_only/Run()
	var/list/flavors = SSbonds.valid_seed_flavors()
	BD_ASSERT(length(flavors) > 0, "there must be at least one pickable seed flavor")
	var/datum/bond_event/seed/creditor = SSbonds.get_event_prototype(/datum/bond_event/seed/creditor)
	BD_ASSERT(!creditor.pickable, "the creditor side is applied as an opposite, never picked directly")

/datum/unit_test/bonds/asymmetric_seed_has_opposite/Run()
	var/datum/bond_event/seed/debtor = SSbonds.get_event_prototype(/datum/bond_event/seed/debtor)
	BD_ASSERT_EQUAL(debtor.opposite_type, /datum/bond_event/seed/creditor, "debtor must map to creditor on the other side")
	var/datum/bond_event/seed/served = SSbonds.get_event_prototype(/datum/bond_event/seed/served_together)
	BD_ASSERT_NULL(served.opposite_type, "symmetric seeds must not define an opposite")

/datum/unit_test/bonds/record_requires_visible_identity/Run()
	var/datum/mind/a = bd_make_mind()
	var/datum/mind/b = bd_make_mind()
	BD_ASSERT_NULL(SSbonds.record(a, b, /datum/bond_event/struck_by, null), "a concealed or absent body must not form a bond")
	BD_ASSERT_NOTNULL(SSbonds.record(a, b, /datum/bond_event/struck_by, null, TRUE), "forced records bypass the identity gate for seeding")

/datum/unit_test/bonds/kin_link_is_reciprocal/Run()
	var/datum/mind/child = bd_make_mind()
	var/datum/mind/parent = bd_make_mind()
	SSbonds.add_kin(child, parent, BOND_KIN_PARENT, FALSE, null)
	BD_ASSERT_NOTNULL(SSbonds.find_kin(child, parent, BOND_KIN_PARENT), "forward parent link missing")
	BD_ASSERT_NOTNULL(SSbonds.find_kin(parent, child, BOND_KIN_CHILD), "reciprocal child link must be written automatically")
	BD_ASSERT_EQUAL(bonds_kin_reciprocal(BOND_KIN_SPOUSE), BOND_KIN_SPOUSE, "spouse-like kinds mirror themselves")

/datum/unit_test/bonds/kin_removal_clears_both_sides/Run()
	var/datum/mind/child = bd_make_mind()
	var/datum/mind/parent = bd_make_mind()
	SSbonds.add_kin(child, parent, BOND_KIN_PARENT, FALSE, null)
	SSbonds.remove_kin(child, parent, BOND_KIN_PARENT)
	BD_ASSERT_NULL(SSbonds.find_kin(child, parent, BOND_KIN_PARENT), "forward link must be gone")
	BD_ASSERT_NULL(SSbonds.find_kin(parent, child, BOND_KIN_CHILD), "reciprocal link must be gone")

/datum/unit_test/bonds/kin_is_unscored_and_unevictable/Run()
	var/datum/mind/child = bd_make_mind()
	var/datum/mind/parent = bd_make_mind()
	var/datum/social_bond/kin/link = SSbonds.add_kin(child, parent, BOND_KIN_PARENT, FALSE, null)
	BD_ASSERT(!link.scored, "kinship carries no sentiment")
	BD_ASSERT(!link.evictable, "kinship must never be dropped by the node cap")
	BD_ASSERT_NULL(link.attach_event(/datum/bond_event/struck_by), "an unscored link must refuse sentiment events")
	BD_ASSERT_EQUAL(link.warmth, 0, "kin axes stay untouched")

/datum/unit_test/bonds/kin_and_sentiment_coexist/Run()
	var/datum/mind/a = bd_make_mind()
	var/datum/mind/b = bd_make_mind()
	SSbonds.add_kin(a, b, BOND_KIN_SWORN_SIBLING, FALSE, null)
	var/datum/social_bond/feeling = SSbonds.get_or_create_bond(a, b)
	feeling.attach_event(/datum/bond_event/struck_by)
	BD_ASSERT_NOTNULL(SSbonds.find_kin(a, b, BOND_KIN_SWORN_SIBLING), "kinship survives alongside sentiment")
	BD_ASSERT(feeling.warmth < 0, "you can hate a brother")

/datum/unit_test/bonds/kin_adoption_mirrors/Run()
	var/datum/mind/child = bd_make_mind()
	var/datum/mind/parent = bd_make_mind()
	SSbonds.add_kin(child, parent, BOND_KIN_PARENT, FALSE, null)
	SSbonds.set_kin_adopted(child, parent, BOND_KIN_PARENT, TRUE)
	var/datum/social_bond/kin/forward = SSbonds.find_kin(child, parent, BOND_KIN_PARENT)
	var/datum/social_bond/kin/backward = SSbonds.find_kin(parent, child, BOND_KIN_CHILD)
	BD_ASSERT(forward.adopted, "adoption must be set on the forward link")
	BD_ASSERT(backward.adopted, "adoption must mirror to the reciprocal link")

/datum/unit_test/bonds/kin_cycle_is_detected/Run()
	var/datum/mind/grandparent = bd_make_mind()
	var/datum/mind/parent = bd_make_mind()
	var/datum/mind/child = bd_make_mind()
	SSbonds.add_kin(parent, grandparent, BOND_KIN_PARENT, FALSE, null)
	SSbonds.add_kin(child, parent, BOND_KIN_PARENT, FALSE, null)
	BD_ASSERT(SSbonds.kin_would_cycle(grandparent, child), "making a descendant into an ancestor must be refused")
	BD_ASSERT(!SSbonds.kin_would_cycle(child, grandparent), "an ordinary ancestor link is fine")

/datum/unit_test/bonds/actor_identity_is_stable/Run()
	var/datum/mind/subject = bd_make_mind()
	var/datum/bond_actor/first = SSbonds.resolve_actor(subject)
	BD_ASSERT_NOTNULL(first, "a mind must resolve to an actor")
	BD_ASSERT_EQUAL(SSbonds.resolve_actor(subject), first, "resolving the same mind twice must give the same actor")
	BD_ASSERT_EQUAL(SSbonds.resolve_actor(first), first, "an actor resolves to itself")
	BD_ASSERT_NULL(SSbonds.resolve_actor(null), "nothing resolves to nothing")

/datum/unit_test/bonds/phantom_gets_graph_identity/Run()
	var/datum/family_member/phantom = new /datum/family_member(null, null)
	phantom.phantom = TRUE
	var/datum/bond_actor/actor = SSbonds.resolve_actor(phantom)
	BD_ASSERT_NOTNULL(actor, "a bodiless phantom relative must still get an actor")
	BD_ASSERT(actor.is_phantom(), "phantom actors must be marked as such")
	BD_ASSERT_EQUAL(actor.family_member_of(), phantom, "the actor must resolve back to its member")

	var/datum/mind/child = bd_make_mind()
	SSbonds.add_kin(child, phantom, BOND_KIN_PARENT, FALSE, null)
	BD_ASSERT_NOTNULL(SSbonds.find_kin(child, phantom, BOND_KIN_PARENT), "a phantom must be usable as a parent")
	BD_ASSERT_NOTNULL(SSbonds.find_kin(phantom, child, BOND_KIN_CHILD), "the reciprocal must land on the phantom too")

	SSbonds.remove_kin(child, phantom, BOND_KIN_PARENT)
	SSbonds.drop_actor(actor)
	qdel(phantom)

/datum/unit_test/bonds/clan_index_resolves/Run()
	BD_ASSERT(SSbonds.clan_index.len > 0, "clan index must be built at init")
	var/datum/bond_faction/clan/nosferatu = SSbonds.clan_index[/datum/clan/nosferatu]
	BD_ASSERT_NOTNULL(nosferatu, "nosferatu must map to a clan faction")
	BD_ASSERT_EQUAL(nosferatu.id, BOND_CLAN_NOSFERATU, "clan faction id drifted")
	BD_ASSERT_EQUAL(length(nosferatu.titles()), 0, "clans must contribute no job titles")

/datum/unit_test/bonds/clan_pairs_share_the_stance_matrix/Run()
	var/forward = SSbonds.stance_warmth(BOND_CLAN_ABYSS, BOND_CLAN_CRIMSON)
	var/backward = SSbonds.stance_warmth(BOND_CLAN_CRIMSON, BOND_CLAN_ABYSS)
	BD_ASSERT_EQUAL(forward, backward, "clan stances must be order independent like faction ones")
	BD_ASSERT_NOTNULL(SSbonds.get_stance(BOND_CLAN_ABYSS, BOND_CLAN_CRIMSON), "declared clan baselines must be present")

/datum/unit_test/bonds/arena_is_a_sanctioned_ground/Run()
	BD_ASSERT(SSbonds.zone_lenses.len > 0, "zone lenses must be built")
	var/datum/bond_zone_lens/arena = SSbonds.zone_lenses[1]
	BD_ASSERT_EQUAL(arena.type, /datum/bond_zone_lens/arena, "the arena must sort first by priority")
	BD_ASSERT_EQUAL(arena.weight, 0, "duelling ground must not move faction politics")

/datum/unit_test/bonds/masochist_takes_no_offence/Run()
	BD_ASSERT(SSbonds.dispositions.len > 0, "dispositions must be built")
	var/datum/bond_disposition/masochist = locate(/datum/bond_disposition/masochist) in SSbonds.dispositions
	BD_ASSERT_NOTNULL(masochist, "the masochist disposition must load")
	BD_ASSERT_EQUAL(masochist.category_scales[BOND_CATEGORY_VIOLENCE], 0, "being struck must not build a masochist a grudge")
	BD_ASSERT_NULL(masochist.category_scales[BOND_CATEGORY_KINDNESS], "kindness is untouched by that flaw")

/datum/unit_test/bonds/unscaled_event_never_lands/Run()
	var/datum/mind/a = bd_make_mind()
	var/datum/mind/b = bd_make_mind()
	var/datum/social_bond/bond = SSbonds.get_or_create_bond(a, b)
	BD_ASSERT_NULL(bond.attach_event(/datum/bond_event/struck_by, 0), "a zeroed disposition must drop the event entirely")
	BD_ASSERT_EQUAL(bond.warmth, 0, "and leave the bond untouched")

/datum/unit_test/bonds/ancestry_walk_is_directional/Run()
	var/datum/mind/grandparent = bd_make_mind()
	var/datum/mind/parent = bd_make_mind()
	var/datum/mind/child = bd_make_mind()
	SSbonds.add_kin(parent, grandparent, BOND_KIN_PARENT, FALSE, null)
	SSbonds.add_kin(child, parent, BOND_KIN_PARENT, FALSE, null)

	BD_ASSERT(SSbonds.kin_reaches(child, grandparent, BOND_KIN_PARENT), "walking up must reach a grandparent")
	BD_ASSERT(SSbonds.kin_reaches(grandparent, child, BOND_KIN_CHILD), "walking down must reach a grandchild")
	BD_ASSERT(!SSbonds.kin_reaches(child, grandparent, BOND_KIN_CHILD), "the walk must respect direction")
	BD_ASSERT(!SSbonds.kin_reaches(child, child, BOND_KIN_PARENT), "nobody is their own ancestor")

/datum/unit_test/bonds/influence_pool_depletes_then_mutes/Run()
	var/datum/mind/subject = bd_make_mind()
	var/datum/bond_actor/actor = SSbonds.resolve_actor(subject)
	for(var/i in 1 to BOND_INFLUENCE_POOL)
		BD_ASSERT(SSbonds.spend_influence(actor), "the pool must allow its first [BOND_INFLUENCE_POOL] acts")
	BD_ASSERT(!SSbonds.spend_influence(actor), "an exhausted pool must stop counting")
	BD_ASSERT(SSbonds.influence_muted(actor), "exhausting the pool mutes the actor")
	SSbonds.influence_pools -= actor

/datum/unit_test/bonds/role_weight_scales_by_office/Run()
	BD_ASSERT_EQUAL(SSbonds.role_weights["Bishop"], 2.5, "high office weight drifted")
	BD_ASSERT_EQUAL(SSbonds.role_weights["Knight"], 1.8, "notable weight drifted")
	BD_ASSERT_NULL(SSbonds.role_weights["Towner"], "ordinary jobs carry no declared weight")

/datum/unit_test/bonds/map_lens_is_inert_at_zero/Run()
	BD_ASSERT(SSbonds.map_lenses.len > 0, "map lenses must be built")
	BD_ASSERT_EQUAL(SSbonds.map_weight(), 1, "a zero-weight lens must fall back to neutral")

/datum/unit_test/bonds/origin_lore_is_symmetric/Run()
	BD_ASSERT_EQUAL(bonds_origin_key("zybantu", "grenzelhoft"), bonds_origin_key("grenzelhoft", "zybantu"), "origin keys must not depend on order")
	var/datum/origin_lore/lore = SSbonds.origin_lore[bonds_origin_key("zybantu", "grenzelhoft")]
	BD_ASSERT_NOTNULL(lore, "the declared Zybantu/Grenzelhoft grudge must load")
	BD_ASSERT(lore.bias < 0, "that pair starts sour")
	BD_ASSERT(lore.weight_scale > 1, "and incidents between them land harder")

/datum/unit_test/bonds/faction_index_has_no_collisions/Run()
	var/list/seen = list()
	for(var/faction_id in SSbonds.faction_prototypes)
		var/datum/bond_faction/faction = SSbonds.faction_prototypes[faction_id]
		for(var/title in faction.titles())
			BD_ASSERT(!seen[title], "title [title] belongs to two factions: [seen[title]] and [faction_id]")
			seen[title] = faction_id

/datum/unit_test/bonds/venue_titles_resolve_to_class_factions/Run()
	BD_ASSERT_EQUAL(SSbonds.faction_for_title("Bathmaster")?.id, BOND_FACTION_BURGHER, "venue owners belong to the burghers")
	BD_ASSERT_EQUAL(SSbonds.faction_for_title("Innkeeper")?.id, BOND_FACTION_BURGHER, "venue owners belong to the burghers")
	BD_ASSERT_EQUAL(SSbonds.faction_for_title("Bathhouse Attendant")?.id, BOND_FACTION_PEASANT, "venue staff are commoners")
	BD_ASSERT_EQUAL(SSbonds.faction_for_title("Tapster")?.id, BOND_FACTION_PEASANT, "venue staff are commoners")
	BD_ASSERT_EQUAL(SSbonds.faction_for_title("Cook")?.id, BOND_FACTION_PEASANT, "venue staff are commoners")

/datum/unit_test/bonds/stance_key_is_symmetric/Run()
	BD_ASSERT_EQUAL(bonds_stance_key(BOND_FACTION_CHURCH, BOND_FACTION_NOBLE), bonds_stance_key(BOND_FACTION_NOBLE, BOND_FACTION_CHURCH), "stance keys must not depend on argument order")
	BD_ASSERT_NULL(bonds_stance_key(BOND_FACTION_NOBLE, null), "an incomplete pair has no key")

/datum/unit_test/bonds/baselines_loaded_and_symmetric/Run()
	BD_ASSERT(SSbonds.faction_stances.len > 0, "declared baselines must populate the stance matrix")
	var/forward = SSbonds.stance_warmth(BOND_FACTION_CHURCH, BOND_FACTION_INQUISITION)
	var/backward = SSbonds.stance_warmth(BOND_FACTION_INQUISITION, BOND_FACTION_CHURCH)
	BD_ASSERT_EQUAL(forward, backward, "stance lookup must be order independent")
	BD_ASSERT(forward < 0, "church and inquisition start tense")
	BD_ASSERT_EQUAL(SSbonds.stance_warmth(BOND_FACTION_NOBLE, BOND_FACTION_NOBLE), BOND_STANCE_SAME_FACTION_WARMTH, "same faction resolves without a stored pair")

/datum/unit_test/bonds/stance_nudge_clamps/Run()
	SSbonds.nudge_stance(BOND_FACTION_WANDERER, BOND_FACTION_VANGUARD, 500, 500, "unit test")
	var/datum/faction_stance/stance = SSbonds.get_stance(BOND_FACTION_WANDERER, BOND_FACTION_VANGUARD)
	BD_ASSERT_NOTNULL(stance, "nudging must create the pair on demand")
	BD_ASSERT_EQUAL(stance.warmth, BOND_WARMTH_MAX, "stance warmth must clamp")
	BD_ASSERT_EQUAL(stance.weight, BOND_WEIGHT_MAX, "stance weight must clamp")
	BD_ASSERT_EQUAL(LAZYLEN(stance.history), 1, "a reasoned nudge records history")
	SSbonds.faction_stances -= bonds_stance_key(BOND_FACTION_WANDERER, BOND_FACTION_VANGUARD)
	qdel(stance)

#undef BD_SOURCE
#undef BD_ASSERT
#undef BD_ASSERT_EQUAL
#undef BD_ASSERT_NOTNULL
#undef BD_ASSERT_NULL

#endif
