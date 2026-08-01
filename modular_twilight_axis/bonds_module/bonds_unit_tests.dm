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

/datum/unit_test/bonds/a_full_node_still_accepts_newcomers/Run()
	var/datum/mind/owner = bd_make_mind()
	for(var/i in 1 to BOND_MAX_PER_MIND + 2)
		var/datum/mind/filler = bd_make_mind()
		var/datum/social_bond/bond = SSbonds.get_or_create_bond(owner, filler)
		BD_ASSERT_NOTNULL(bond, "creating a bond must return it")
		bond.weight_committed = 50
		bond.recalculate()

	var/datum/mind/newcomer = bd_make_mind()
	var/datum/social_bond/fresh = SSbonds.get_or_create_bond(owner, newcomer)
	BD_ASSERT_NOTNULL(SSbonds.get_bond(owner, newcomer), "a full node must still make room for someone new")
	BD_ASSERT_EQUAL(fresh, SSbonds.get_bond(owner, newcomer), "and must not hand back a bond it already dropped")

/datum/unit_test/bonds/tagged_bonds_survive_eviction/Run()
	var/datum/mind/owner = bd_make_mind()
	var/datum/mind/protected = bd_make_mind()
	var/datum/social_bond/tagged = SSbonds.get_or_create_bond(owner, protected)
	tagged.tags |= BOND_TAG_KILLED_ME
	for(var/i in 1 to BOND_MAX_PER_MIND + 5)
		var/datum/mind/target = bd_make_mind()
		var/datum/social_bond/bond = SSbonds.get_or_create_bond(owner, target)
		bond.weight_committed = 50
		bond.recalculate()
	BD_ASSERT_NOTNULL(SSbonds.get_bond(owner, protected), "a tagged bond must never be evicted by the cap")
	var/datum/bond_node/node = SSbonds.get_node(owner)
	BD_ASSERT(length(node.bonds) <= BOND_MAX_PER_MIND, "the cap must still hold while protecting it")

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

/datum/unit_test/bonds/dropping_an_actor_leaves_nothing_behind/Run()
	var/datum/mind/a = bd_make_mind()
	var/datum/mind/b = bd_make_mind()
	SSbonds.add_kin(a, b, BOND_KIN_PARENT, FALSE, null)
	var/datum/social_bond/feeling = SSbonds.get_or_create_bond(b, a)
	feeling.attach_event(/datum/bond_event/struck_by)
	var/datum/bond_actor/actor_a = SSbonds.resolve_actor(a)
	SSbonds.spend_influence(actor_a)
	BD_ASSERT_NOTNULL(SSbonds.influence_pools[actor_a], "the pool entry must exist before the drop")

	SSbonds.drop_actor(actor_a)

	BD_ASSERT_NULL(SSbonds.influence_pools[actor_a], "a dropped actor must not stay a key in the influence pool")
	BD_ASSERT_NULL(SSbonds.find_kin(b, actor_a, BOND_KIN_CHILD), "the reciprocal kin link must go with it")
	BD_ASSERT_NULL(SSbonds.get_bond(b, actor_a), "and so must anyone's sentiment toward it")

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
	BD_ASSERT_EQUAL(SSbonds.role_weights[/datum/job/roguetown/priest], 2.5, "high office weight drifted")
	BD_ASSERT(SSbonds.role_weights[/datum/job/roguetown/hand] > SSbonds.role_weights[/datum/job/roguetown/marshal], "the Hand outranks the Marshal: they command every noble")
	BD_ASSERT(SSbonds.role_weights[/datum/job/roguetown/lord] > SSbonds.role_weights[/datum/job/roguetown/hand], "the ruler still has absolute priority")
	BD_ASSERT_EQUAL(SSbonds.role_weights[/datum/job/roguetown/knight], 1.8, "notable weight drifted")
	BD_ASSERT_NULL(SSbonds.role_weights[/datum/job/roguetown/villager], "ordinary jobs carry no declared weight")

/datum/unit_test/bonds/map_lens_is_inert_at_zero/Run()
	BD_ASSERT(SSbonds.map_lenses.len > 0, "map lenses must be built")
	BD_ASSERT_EQUAL(SSbonds.map_weight(), 1, "a zero-weight lens must fall back to neutral")

/datum/unit_test/bonds/origins_never_enter_the_live_matrix/Run()
	for(var/key in SSbonds.faction_stances)
		var/datum/faction_stance/stance = SSbonds.faction_stances[key]
		BD_ASSERT_NULL(SSbonds.origin_prototypes[stance.faction_a], "country standing is static lore and must never become a live stance")
		BD_ASSERT_NULL(SSbonds.origin_prototypes[stance.faction_b], "country standing is static lore and must never become a live stance")
	BD_ASSERT(SSbonds.origin_lore.len > 0, "origin lore itself must still be loaded as a read-only modifier table")

/datum/unit_test/bonds/origin_lore_is_symmetric/Run()
	BD_ASSERT_EQUAL(bonds_origin_key("zybantu", "grenzelhoft"), bonds_origin_key("grenzelhoft", "zybantu"), "origin keys must not depend on order")
	var/datum/origin_lore/lore = SSbonds.origin_lore[bonds_origin_key("zybantu", "grenzelhoft")]
	BD_ASSERT_NOTNULL(lore, "the declared Zybantu/Grenzelhoft grudge must load")
	BD_ASSERT(lore.bias < 0, "the losers of the Twilight War and its victors start sour")
	BD_ASSERT(lore.weight_scale > 1, "and incidents between them land harder")

	var/datum/origin_lore/friendly = SSbonds.origin_lore[bonds_origin_key("azuria", "grenzelhoft")]
	BD_ASSERT_NOTNULL(friendly, "Azuria and Grenzelhoft have a declared position too")
	BD_ASSERT(friendly.bias > 0, "wartime neutrality and dynastic kinship make them friendly, not hostile")
	BD_ASSERT(friendly.weight_scale < 1, "so their incidents matter less, not more")

/datum/unit_test/bonds/seeding_goes_idle_when_nobody_waits/Run()
	BD_ASSERT(!SSbonds.anyone_still_wants_seeds(), "no synthetic ckey declares seeds, so nothing should be pending")
	SSbonds.stop_seeding("unit test")
	BD_ASSERT(SSbonds.seeding_idle, "with nothing pending the loop must park itself")
	BD_ASSERT(SSbonds.wake_seeding(), "a newcomer must be able to wake it")
	BD_ASSERT(!SSbonds.seeding_idle, "and waking clears the idle flag")
	BD_ASSERT(!SSbonds.wake_seeding(), "waking an already-running loop must be a no-op")
	SSbonds.stop_seeding("unit test cleanup")

/datum/unit_test/bonds/weight_shares_sum_to_one/Run()
	var/total = 0
	for(var/share_id in SSbonds.weight_shares)
		var/datum/bond_weight_share/entry = SSbonds.weight_shares[share_id]
		total += entry.share
	BD_ASSERT(total > 0.999 && total < 1.001, "template shares must sum to exactly 1, got [total]")

/datum/unit_test/bonds/blend_is_neutral_at_rest/Run()
	var/neutral = SSbonds.blend_weights(list(
		BOND_SHARE_ROLE = 1,
		BOND_SHARE_LORE = 1,
		BOND_SHARE_STORYTELLER = 1,
		BOND_SHARE_ZONE = 1,
		BOND_SHARE_MAP = 1,
	))
	BD_ASSERT(neutral > 0.999 && neutral < 1.001, "an all-neutral incident must blend to 1, got [neutral]")
	var/partial = SSbonds.blend_weights(list(BOND_SHARE_ROLE = 1))
	BD_ASSERT(partial > 0.999 && partial < 1.001, "an unmentioned template must default to neutral, got [partial]")

/datum/unit_test/bonds/blend_bounds_a_stacked_incident/Run()
	var/stacked = SSbonds.blend_weights(list(
		BOND_SHARE_ROLE = 4.5,
		BOND_SHARE_LORE = 1.8,
		BOND_SHARE_STORYTELLER = 1.8,
		BOND_SHARE_ZONE = 1,
		BOND_SHARE_MAP = 1,
	))
	BD_ASSERT(stacked < 3, "the blend must bound a stacked incident well below the 14x a raw product would give, got [stacked]")
	BD_ASSERT(stacked > 1, "but it must still amplify it")

/datum/unit_test/bonds/faction_presence_follows_the_map_blacklist/Run()
	var/list/present = SSbonds.present_faction_ids()
	BD_ASSERT(length(present) > 0, "some factions must exist on any map")
	var/list/blacklist = SSbonds.map_blacklist()
	for(var/faction_id in present)
		var/datum/bond_faction/faction = SSbonds.get_faction(faction_id)
		var/any_live = FALSE
		var/any_job = FALSE
		for(var/job_type in SSbonds.faction_index)
			if(SSbonds.faction_index[job_type] != faction)
				continue
			any_job = TRUE
			if(!(job_type in blacklist))
				any_live = TRUE
				break
		BD_ASSERT(any_live || !any_job, "[faction_id] is listed as present but every one of its jobs is blacklisted on this map")

/datum/unit_test/bonds/hierarchy_has_one_leader_per_faction/Run()
	BD_ASSERT(SSbonds.hierarchy_by_faction.len > 0, "hierarchy must be built at init")
	for(var/faction_id in SSbonds.hierarchy_by_faction)
		var/list/ranks = SSbonds.hierarchy_by_faction[faction_id]
		var/datum/bond_rank/first = ranks[1]
		BD_ASSERT_EQUAL(first.level, 1, "[faction_id] must start at level 1 after sorting")
		var/last_level = 0
		for(var/datum/bond_rank/rank as anything in ranks)
			BD_ASSERT(rank.level >= last_level, "[faction_id] ranks must be sorted by level")
			last_level = rank.level

/datum/unit_test/bonds/rank_titles_do_not_collide/Run()
	var/list/seen = list()
	for(var/faction_id in SSbonds.hierarchy_by_faction)
		for(var/datum/bond_rank/rank as anything in SSbonds.hierarchy_by_faction[faction_id])
			for(var/title in rank.titles)
				BD_ASSERT(!seen[title], "title [title] is claimed by two ranks: [seen[title]] and [rank.label]")
				seen[title] = rank.label

/datum/unit_test/bonds/inquisitor_leads_the_mission/Run()
	var/datum/bond_rank/rank = SSbonds.rank_for_title("Inquisitor")
	BD_ASSERT_NOTNULL(rank, "the Inquisitor must have a rank")
	BD_ASSERT_EQUAL(rank.level, 1, "everyone in the Otavan mission answers to the Inquisitor without exception")
	var/datum/bond_rank/deputy = SSbonds.rank_for_title("Absolver")
	BD_ASSERT_EQUAL(deputy.level, 2, "the Absolver stands in when the Inquisitor falls")

/datum/unit_test/bonds/faction_index_has_no_collisions/Run()
	var/list/seen = list()
	for(var/faction_id in SSbonds.faction_prototypes)
		var/datum/bond_faction/faction = SSbonds.faction_prototypes[faction_id]
		for(var/title in faction.titles())
			BD_ASSERT(!seen[title], "title [title] belongs to two factions: [seen[title]] and [faction_id]")
			seen[title] = faction_id

/datum/unit_test/bonds/venue_titles_resolve_to_class_factions/Run()
	BD_ASSERT_EQUAL(SSbonds.faction_for_job(/datum/job/roguetown/bathmaster)?.id, BOND_FACTION_BURGHER, "venue owners belong to the burghers")
	BD_ASSERT_EQUAL(SSbonds.faction_for_job(/datum/job/roguetown/innkeeper)?.id, BOND_FACTION_BURGHER, "venue owners belong to the burghers")
	BD_ASSERT_EQUAL(SSbonds.faction_for_job(/datum/job/roguetown/servant)?.id, BOND_FACTION_PEASANT, "venue staff are commoners")

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

/datum/unit_test/bonds/violence_outlives_its_transient/Run()
	var/datum/mind/victim = bd_make_mind()
	var/datum/mind/aggressor = bd_make_mind()
	var/datum/social_bond/bond = SSbonds.get_or_create_bond(victim, aggressor)
	BD_ASSERT_NOTNULL(bond, "the pair must be able to hold a bond")

	bond.attach_event(/datum/bond_event/struck_by)
	var/hot_warmth = bond.warmth
	BD_ASSERT(hot_warmth < 0, "being struck must read as hostile while it is fresh")

	for(var/category in bond.active_events.Copy())
		var/datum/bond_event/live = bond.active_events[category]
		live.expire()

	BD_ASSERT_EQUAL(length(bond.active_events), 0, "every transient must be gone")
	BD_ASSERT(bond.warmth < 0, "the grudge must survive its transient, not snap back to neutral")
	BD_ASSERT(bond.weight >= BOND_VISIBLE_WEIGHT, "an assault must leave the attacker visible in the panel afterwards, or the bond reads as a reset")

#undef BD_SOURCE
#undef BD_ASSERT
#undef BD_ASSERT_EQUAL
#undef BD_ASSERT_NOTNULL
#undef BD_ASSERT_NULL

#endif
