-- only global thing allowed
if modules == nil then
  modules = registerObject({})
end
if modules['steam-multiplayer'] == nil then
  modules['steam-multiplayer'] = {}
end

local types = require("ucp/modules/steam-multiplayer/types/init")

---@type table
namespace = modules['steam-multiplayer']

namespace.host = require("ucp/modules/steam-multiplayer/ui/host")

_G["ucp/modules/steam-multiplayer/ui/host/createHostMenu"] = namespace.host.createHostMenu


namespace.client = require("ucp/modules/steam-multiplayer/ui/client")