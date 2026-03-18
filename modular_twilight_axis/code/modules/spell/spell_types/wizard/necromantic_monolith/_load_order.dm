// ---- Necromantic Monolith: load order ----
// This file controls the include order for all monolith subsystems.
// _defines MUST be first, _undefs MUST be last.

#include "_defines.dm"
#include "spell.dm"
#include "core.dm"
#include "spawning.dm"
#include "routing.dm"
#include "ai.dm"
#include "pathfinding.dm"
#include "dort_adapter.dm"
#include "_undefs.dm"
