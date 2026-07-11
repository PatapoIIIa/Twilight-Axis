// === ATAMAN MODULE ===
// Include hub for the Ataman wretch subclass. Only this hub is registered in the DME;
// every implementation file remains inside modular_twilight_axis/ataman_module.
//
// FILE MAP
// ataman_bandit_defines.dm            - blackboard keys, squad roles and bounty constants
// ataman_trap_common.dm               - overlap/limit helpers and owner-only trap rendering
// ataman_treasury.dm                  - bounty stacking, trade tiers and treasury loss
// ataman.dm                           - class, iron loadout and spell grants
// ataman_ambush.dm                    - Set an Ambush action
// ataman_trap.dm                      - Set a Snare action
// ataman_execute.dm                   - Finishing Blow and one-shot armor bypass
// ataman_exchange.dm                  - Honest Exchange and looted-only appraisal
// ataman_ambush_stone.dm              - hidden ambush trigger and randomized spawning
// ataman_snare.dm                     - hidden damaging snares
// ataman_marked_component.dm          - owned mark and overhead indicator
// ataman_bandit.dm                    - summoned ambush NPC
// ataman_bandit_controller.dm         - fixed-target, role-aware NPC controller
// ataman_squad.dm                     - shared squad coordination datum (feints, guard, mouth claim)
// ataman_squad_tactics.dm             - escape/cast reaction and staged feint economy
// ataman_leash_subtree.dm             - pursuit leash
// ataman_disarm_restrain_subtree.dm   - capture role coordinator
// ataman_disarm_behavior.dm           - disarm, grab and shove behaviors
// ataman_restrain_behavior.dm         - single binder behavior
// ataman_deathmark_subsystem.dm       - player-only murder bounty tracking

#include "ataman_bandit_defines.dm"
#include "ataman_trap_common.dm"
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
#include "ataman_squad.dm"
#include "ataman_squad_tactics.dm"
#include "ataman_leash_subtree.dm"
#include "ataman_disarm_restrain_subtree.dm"
#include "ataman_disarm_behavior.dm"
#include "ataman_restrain_behavior.dm"
#include "ataman_deathmark_subsystem.dm"
