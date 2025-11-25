local types = require("ucp/modules/steam-multiplayer/types/init")
local typesHelpers = require("ucp/modules/steam-multiplayer/types/helpers")
local client = {}

---@type table<integer, SteamMultiplayer_LobbyListEntry>
client.enumerationExtraInformation = ffi.new("SteamMultiplayer_LobbyListEntry[50]", {})

---@type integer
local guidOffset = ffi.offsetof("DPSESSIONDESC2", "guidInstance")

---@param lpThisSD table<integer, DPSESSIONDESC2>
function client.onAddSession(lpThisSD, lpdwTimeOut, dwFlags, lpContext)

  for i=0, 49 do
    if typesHelpers.testGUIDEquality(client.enumerationExtraInformation[i].pGUID[0], lpThisSD[0].guidInstance) then
      client.enumerationExtraInformation[i].hasPassword = lpThisSD[0].lpszPassword ~= 0
      return true
    end
  end

  for i=0, 49 do
    if client.enumerationExtraInformation[i].pGUID == 0 then
      client.enumerationExtraInformation[i].pGUID = ffi.cast("GUID *", guidOffset + tonumber(ffi.cast("unsigned long", lpThisSD)))
      client.enumerationExtraInformation[i].hasPassword = lpThisSD[0].lpszPassword ~= 0
      return true
    end
  end

  return false
end

---@type CDATA
client.cbOnAddSession = ffi.cast("bool (__stdcall *)(DPSESSIONDESC2 *lpThisSD,LPDWORD lpdwTimeOut,DWORD dwFlags,LPVOID lpContext)", client.onAddSession)
---@type integer
client.pOnAddSession = tonumber(ffi.cast("unsigned long", client.cbOnAddSession))

return client