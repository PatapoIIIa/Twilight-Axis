// === BONDS MODULE ===
// Directed social-bond graph for Twilight-Axis. Include this file from the DME compile section;
// pair it with bonds_module_deinclude.dm to clean up macros after the section.
// #include "modular_twilight_axis\bonds_module\bonds_module_config.dm"
//
// --- FILE MAP ---
// bonds_identity.dm         - identity visibility gate and snapshot building
// bonds_history.dm          - /datum/bond_history: one recorded moment on a bond
// bonds_stage.dm            - /datum/bond_stage: label bands plus priority resolution
// bonds_stages_defs.dm      - the stage table itself
// bonds_bond.dm             - /datum/social_bond: axes, tags, active events, history
// bonds_kin.dm              - /datum/social_bond/kin: structural kinship links plus the kin API
// bonds_node.dm             - /datum/bond_node: one mind's outgoing bonds plus eviction
// bonds_event.dm            - /datum/bond_event: transient contribution plus permanent commit
// bonds_events_hostile.dm   - hostile event definitions
// bonds_events_friendly.dm  - friendly event definitions
// bonds_events_seed.dm      - roundstart backstory seeds, symmetric and asymmetric
// bonds_faction.dm          - /datum/bond_faction plus the title->faction index
// bonds_factions_defs.dm    - the faction table (data, one entry per GLOB.*_positions list)
// bonds_faction_baselines.dm- declared starting stances between faction pairs
// bonds_faction_stance.dm   - live faction-to-faction stance matrix plus nudge API
// bonds_storyteller.dm      - storyteller lens over faction stances (all weights 1.0 for now)
// bonds_storyteller_lenses.dm - one lens per storyteller, tuning table
// bonds_origins.dm          - /datum/bond_origin: where a character is from, cached on the actor
// bonds_origin_lore.dm      - inherited opinion between origins, mixed into faction impact
// bonds_role_weight.dm      - how loudly a job's actions echo between factions
// bonds_weights.dm          - declared template shares and the normalised blend
// bonds_map_lens.dm         - per-map lens over faction impact (all weights 0 for now)
// bonds_map_roster.dm       - which factions exist on which map
// bonds_zone_lens.dm        - per-area lens: where it happened (weights 1, arena 0)
// bonds_duel.dm             - sanctioned violence: duellist rings or duelling ground
// bonds_disposition.dm      - recipient's flaws scale what an act does to their side
// bonds_influence.dm        - per-character influence pool and mute, so brawls do not rewrite politics
// bonds_impact.dm           - the ordered impact pipeline: role, map, storyteller, lore, influence
// bonds_house_stance.dm     - house-to-house standing, accumulated from member incidents
// bonds_hierarchy.dm        - rank table per faction plus member lookup
// bonds_roster_panel.dm     - /datum/bonds_roster_panel: your faction by rank plus closest ally
// bonds_faction_map.dm      - whole inter-faction graph, not a view from one character
// bonds_faction_panel.dm    - /datum/bonds_faction_panel: faction map, house and clan standing
// bonds_admin_panel.dm      - admin view/edit of live faction and house standings
// bonds_tree_panel.dm       - /datum/bonds_tree_panel: radial bond tree with two-sided progress
// bonds_prefs.dm            - /datum/preferences vars plus savefile load/save/sanitize
// bonds_round_prefs.dm      - per-ckey round-locked snapshot of the seeding prefs
// bonds_round_ledger.dm     - per-ckey ledger: granted seeds and already-paired ckeys
// bonds_seeding.dm          - phase gate, weighted pairing, seed application
// bonds_family_bridge.dm    - read-through adapter: kinship from SSfamilytree as a bond group
// bonds_panel.dm            - /datum/bonds_panel tgui backend plus panel data building
// bonds_prefs_panel.dm      - /datum/bonds_prefs_panel tgui backend for seeding prefs
// bonds_subsystem_core.dm   - SUBSYSTEM_DEF(bonds): init, logging, prototypes, teardown
// bonds_graph_api.dm        - SSbonds graph facade: nodes, bonds, record()
// bonds_listener.dm         - centralized signal hookup, resolves actor/target pairs
// bonds_mob_procs.dm        - player verbs
// bonds_unit_tests.dm       - CI unit tests for the bond chains; runs under UNIT_TESTS
//
// --- MODEL ---
// A bond is DIRECTED: it is holder's view of other. The reverse bond is a separate datum,
// so one-sided relationships are representable without special cases.
//
// Each bond carries two axes:
//   warmth  (-100..100) - cold to warm
//   weight  (0..100)    - how much this person registers at all
// A high-weight/low-warmth bond is an enemy; a low-weight bond is nobody, whatever the warmth.
//
// Every axis value is the sum of a PERMANENT part and the TRANSIENT parts of currently active
// events. Events expire on their own timers (no global decay sweep), but each event commits a
// small permanent residue when it lands, rate-limited per category by BOND_COMMIT_COOLDOWN.
// One slight fades; repeated slights accumulate.
//
// Notes:
// - Bonds are keyed by /datum/bond_actor: a player actor wraps their mind (so bonds survive
//   body replacement), a phantom actor wraps a bodiless family_member.
// - Any new #define here MUST be mirrored by a matching #undef in bonds_module_deinclude.dm.
// - When adding a file, update this FILE MAP and the #include order below.

//#define BONDS_DEBUG_LOGGING //UNDEFINE IT FOR THE LOCAL TESTING

#define BOND_WARMTH_MIN -100
#define BOND_WARMTH_MAX 100
#define BOND_WEIGHT_MIN 0
#define BOND_WEIGHT_MAX 100

// Cap on outgoing bonds per mind. Beyond this the weakest untagged bond is evicted, so a
// crowded round cannot grow the graph quadratically.
#define BOND_MAX_PER_MIND 40
// Minimum gap between two permanent commits of the same category on one bond.
#define BOND_COMMIT_COOLDOWN (90 SECONDS)
// Hard cap on stored history entries per bond. This is a reminder of what happened lately,
// not a round-long journal: unpinned entries drop first, then the oldest pinned ones.
#define BOND_MAX_HISTORY 5
// Bonds below this weight are noise and stay hidden from the player.
#define BOND_VISIBLE_WEIGHT 10

// Each further commit of the same category on the same bond is scaled by
// 1 / (1 + count * BOND_COMMIT_FALLOFF), so grinding one interaction saturates.
#define BOND_COMMIT_FALLOFF 0.55
// A death counts as murder by the last aggressor only inside this window.
#define BOND_KILL_ATTRIBUTION_WINDOW (2 MINUTES)

#define BOND_TAG_NONE 0
#define BOND_TAG_SHED_BLOOD (1<<0)
#define BOND_TAG_KILLED_ME (1<<1)
#define BOND_TAG_KILLED_THEM (1<<2)
#define BOND_TAG_COMFORTED (1<<3)
#define BOND_TAG_SERVED_TOGETHER (1<<4)
#define BOND_TAG_OWES_DEBT (1<<5)

// Roundstart seeding. A seed is an ordinary event applied at t=0, so backstory and
// in-round development share one code path.
#define BOND_MAX_SEEDS 3
#define BOND_SEED_DELAY (90 SECONDS)
#define BOND_SEED_RETRY (45 SECONDS)

#define BOND_CATEGORY_VIOLENCE "violence"
#define BOND_CATEGORY_KINDNESS "kindness"
#define BOND_CATEGORY_DEATH "death"
#define BOND_CATEGORY_SEED "seed"

// Faction ids. The taxonomy is roguetown-local and lives in bonds_factions_defs.dm as data;
// each faction points at one GLOB.*_positions list. Bathhouse and tavern are deliberately NOT
// factions - they are venues, and treating them as factions was the sole source of title
// collisions (Bathmaster, Innkeeper, Bathhouse Attendant, Cook, Tapster).
#define BOND_FACTION_NOBLE "noble"
#define BOND_FACTION_COURT "court"
#define BOND_FACTION_RETINUE "retinue"
#define BOND_FACTION_GARRISON "garrison"
#define BOND_FACTION_CITYWATCH "citywatch"
#define BOND_FACTION_VANGUARD "vanguard"
#define BOND_FACTION_CHURCH "church"
#define BOND_FACTION_INQUISITION "inquisition"
#define BOND_FACTION_BURGHER "burgher"
#define BOND_FACTION_ATC "atc"
#define BOND_FACTION_PEASANT "peasant"
#define BOND_FACTION_SIDEFOLK "sidefolk"
#define BOND_FACTION_WANDERER "wanderer"
#define BOND_FACTION_OUTLAW "outlaw"

// Vampire clans: a second faction axis, indexed by clan type instead of job title, sharing
// the same stance matrix. A vampire belongs to one of each.
#define BOND_CLAN_CAITIFF "clan_caitiff"
#define BOND_CLAN_ABYSS "clan_abyss"
#define BOND_CLAN_CRIMSON "clan_crimson"
#define BOND_CLAN_EORAN "clan_eoran"
#define BOND_CLAN_NOSFERATU "clan_nosferatu"
#define BOND_CLAN_THRONLEER "clan_thronleer"

// Implicit warmth between two members of the same faction; never stored as a pair.
#define BOND_STANCE_SAME_FACTION_WARMTH 35
// Absolute stance warmth above which two factions are considered entangled enough that
// their members plausibly share a past - allies AND rivals both qualify.
#define BOND_STANCE_AFFINITY_THRESHOLD 25
// Below this weight an unremarkable faction pair is left off the map to keep it readable.
#define BOND_MAP_MIN_WEIGHT 5
// Template shares for the impact blend. They MUST sum to 1: at rest every modifier is 1.0 and
// the blend returns 1.0, so a neutral incident is unchanged. Multiplying them instead would
// let a knight striking a bishop in a public square stack to a tenfold swing.
#define BOND_SHARE_ROLE "role"
#define BOND_SHARE_LORE "lore"
#define BOND_SHARE_STORYTELLER "storyteller"
#define BOND_SHARE_ZONE "zone"
#define BOND_SHARE_MAP "map"
// Cap on how far one pair's permanent warmth may travel inside one window, so a bad first
// minute cannot land two characters at maximum hatred before they have said a word.
#define BOND_MAX_SWING 25
#define BOND_SWING_WINDOW (10 MINUTES)
// Fraction of a personal event's permanent commit that bleeds into the two houses involved.
// House feuds are meant to be the accumulated residue of many incidents, never one fight.
#define BOND_HOUSE_PROPAGATION 0.25
// Influence pool: how many faction-moving acts one character is worth before the wider world
// stops counting them, how long that mute lasts, and how often the pool refills.
#define BOND_INFLUENCE_POOL 3
#define BOND_INFLUENCE_BAN (3 MINUTES)
#define BOND_INFLUENCE_REFILL (5 MINUTES)

// Kinship link kinds. A kin link is directed and always written as a reciprocal pair:
// A holding PARENT to B implies B holds CHILD to A. Spouse-like kinds mirror themselves.
// Kin links are /datum/social_bond/kin - structurally a bond, but unscored and unevictable,
// because kinship is a path fact, not a sentiment.
#define BOND_KIN_PARENT "parent"
#define BOND_KIN_CHILD "child"
#define BOND_KIN_SPOUSE "spouse"
#define BOND_KIN_FORMER_SPOUSE "former_spouse"
#define BOND_KIN_SWORN_SIBLING "sworn_sibling"
// Not a kinship in itself: remembers the term two people kept using for each other after the
// relative who linked them left. Each direction carries its own label.
#define BOND_KIN_PRESERVED "preserved"

#define BOND_GROUP_FAMILY "family"
#define BOND_GROUP_KNOWN "known"
#define BOND_GROUP_WARM "warm"
#define BOND_GROUP_COLD "cold"
#define BOND_GROUP_HOSTILE "hostile"

#define BONDLOG_DEBUG "DEBUG"
#define BONDLOG_INFO "INFO"
#define BONDLOG_WARN "WARN"
#define BONDLOG_ERROR "ERROR"

#include "bonds_actor.dm"
#include "bonds_identity.dm"
#include "bonds_history.dm"
#include "bonds_stage.dm"
#include "bonds_stages_defs.dm"
#include "bonds_bond.dm"
#include "bonds_kin.dm"
#include "bonds_node.dm"
#include "bonds_event.dm"
#include "bonds_events_hostile.dm"
#include "bonds_events_friendly.dm"
#include "bonds_events_seed.dm"
#include "bonds_subsystem_core.dm"
#include "bonds_graph_api.dm"
#include "bonds_faction.dm"
#include "bonds_factions_defs.dm"
#include "bonds_clans.dm"
#include "bonds_faction_baselines.dm"
#include "bonds_clan_baselines.dm"
#include "bonds_faction_stance.dm"
#include "bonds_origins.dm"
#include "bonds_origin_lore.dm"
#include "bonds_role_weight.dm"
#include "bonds_weights.dm"
#include "bonds_map_lens.dm"
#include "bonds_map_roster.dm"
#include "bonds_zone_lens.dm"
#include "bonds_duel.dm"
#include "bonds_disposition.dm"
#include "bonds_influence.dm"
#include "bonds_impact.dm"
#include "bonds_house_stance.dm"
#include "bonds_storyteller.dm"
#include "bonds_storyteller_lenses.dm"
#include "bonds_prefs.dm"
#include "bonds_round_prefs.dm"
#include "bonds_round_ledger.dm"
#include "bonds_seeding.dm"
#include "bonds_family_bridge.dm"
#include "bonds_panel.dm"
#include "bonds_faction_map.dm"
#include "bonds_hierarchy.dm"
#include "bonds_roster_panel.dm"
#include "bonds_faction_panel.dm"
#include "bonds_admin_panel.dm"
#include "bonds_tree_panel.dm"
#include "bonds_prefs_panel.dm"
#include "bonds_listener.dm"
#include "bonds_mob_procs.dm"
#include "bonds_unit_tests.dm"
