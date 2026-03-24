// ---- SSdotr: load order ----
// _defines MUST be first.
// NOTE: _undefs.dm is NOT included here because DOTR_ defines are used
// by external adapters (e.g. dotr_adapter.dm in necromantic_monolith)
// that are loaded later in the .dme. The DOTR_ prefix prevents conflicts.

#include "_defines.dm"
#include "profile.dm"
#include "controller.dm"
#include "dotr.dm"
#include "virtual_combat.dm"
