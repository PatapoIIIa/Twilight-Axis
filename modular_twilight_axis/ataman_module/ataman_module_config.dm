// === ATAMAN MODULE ===
// Include hub for the Ataman wretch subclass. Include this file from the DME compile section;
// it pulls in every sibling file via relative #include, so only this one line needs to be
// registered in roguetown.dme.
// #include "modular_twilight_axis\ataman_module\ataman_module_config.dm"
//
// --- FILE MAP ---
// ataman.dm                          - /datum/advclass/wretch/ataman + outfit/loadout
// ataman_ambush.dm                   - "Устроить засаду" spell
// ataman_trap.dm                     - "Поставить силок" spell
// ataman_execute.dm                  - "Добивающий удар" spell (consumes ataman_marked)
// ataman_exchange.dm                 - "Честный обмен" spell + looted-only appraisal
// ataman_ambush_stone.dm             - disguised ambush trigger structure
// ataman_snare.dm                    - invisible bleed trap structure
// ataman_marked_component.dm         - /datum/component/ataman_marked, overhead marker
// ataman_bandit.dm                   - /mob/living/carbon/human/npc/ataman_bandit
// ataman_bandit_controller.dm        - /datum/ai_controller/human_npc/ataman_bandit
// ataman_bandit_defines.dm           - BB_ATAMAN_* blackboard keys, ATAMAN_LEASH_RANGE
// ataman_leash_subtree.dm            - leash-to-spawn-point planning subtree
// ataman_disarm_restrain_subtree.dm  - disarm-then-restrain planning subtree
// ataman_disarm_behavior.dm          - disarm behavior
// ataman_restrain_behavior.dm        - restrain behavior
// ataman_deathmark_subsystem.dm      - Death Mark: signal-based hit tracking, bounty stacking
// ataman_treasury.dm                 - shared bounty-stacking helpers, loot tiers, Честный обмен treasury drain
//
// Notes:
// - No core/upstream files are touched by this module. Hit tracking hooks COMSIG_MOB_APPLY_DAMGE
//   and COMSIG_LIVING_DEATH via SSdcs's COMSIG_GLOB_MOB_CREATED, not direct edits.
// - Subclass registration lives in modular_twilight_axis\code\modules\jobs\job_types\roguetown\adventurer\wretch.dm
//   (job_subclasses += list(...) in /datum/job/roguetown/wretch/New()), not in core wretch.dm.
// - When adding a new file, update this FILE MAP and the #include order below.

#include "ataman_bandit_defines.dm"
#include "ataman_treasury.dm"
#include "ataman.dm"
#include "ataman_ambush.dm"
#include "ataman_trap.dm"
#include "ataman_execute.dm"
#include "ataman_exchange.dm"
#include "ataman_ambush_stone.dm"
#include "ataman_snare.dm"
#include "ataman_marked_component.dm"
#include "ataman_bandit.dm"
#include "ataman_bandit_controller.dm"
#include "ataman_leash_subtree.dm"
#include "ataman_disarm_restrain_subtree.dm"
#include "ataman_disarm_behavior.dm"
#include "ataman_restrain_behavior.dm"
#include "ataman_deathmark_subsystem.dm"
