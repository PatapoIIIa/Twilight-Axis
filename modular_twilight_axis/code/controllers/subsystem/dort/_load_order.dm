// ---- SSdort: load order ----
// _defines MUST be first.
// NOTE: _undefs.dm is NOT included here because DORT_ defines are used
// by external adapters (e.g. dort_adapter.dm in necromantic_monolith)
// that are loaded later in the .dme. The DORT_ prefix prevents conflicts.

#include "_defines.dm"
#include "profile.dm"
#include "controller.dm"
#include "dort.dm"
#include "virtual_combat.dm"
