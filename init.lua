-- should be shipped but doesn't need to be loaded explicitly
-- local steamApiHandle = core.openLibraryHandle("ucp/modules/steam-multiplayer/steam_api.dll")
local function setSteamAppIdFile()

  local APP_ID_CRUSADER = 40970
  local APP_ID_CRUSADER_EXTREME = 16700

  if #arg > 0 then
    log(VERBOSE, string.format("writing steamapp_id.txt file"))
    local haystack = (arg[1] or ''):lower()
    local needle1 = ("Stronghold Crusader.exe"):lower()
    local needle2 = ("Stronghold_Crusader_Extreme.exe"):lower()
    local s1, e1 = haystack:find(needle1)
    local s2, e2 = haystack:find(needle2)

    local appid = nil
    if s2 ~= nil and e2 ~= nil and e2 == haystack:len() then
      appid = APP_ID_CRUSADER_EXTREME
    elseif s1 ~= nil and e1 ~= nil and e1 == haystack:len() then
      appid = APP_ID_CRUSADER
    else
      if data.version.isExtreme() then
        appid = APP_ID_CRUSADER_EXTREME
      else
        appid = APP_ID_CRUSADER
      end
    end

    if appid ~= nil then
      local f, err = io.open("steam_appid.txt", 'w')
      if not f then error(err) end
      log(VERBOSE, string.format("writing steamapp_id.txt file for game variant: %s", appid))
      f:write(string.format("%i", appid))
      f:close()
    else
      log(VERBOSE, string.format("leaving steamapp_id.txt untouched: could not identify game variant"))
    end
  end
end


local dplayxHandle = core.openLibraryHandle("ucp/modules/steam-multiplayer/RedirectPlay.dll")

local function installDPLAYXHook()
  local hookAddr, hookSize = core.AOBScan("E8 ? ? ? ? 85 C0 0F ? ? ? ? ? 8B 44 24 0C 8B 08"), 5
  core.writeCode(hookAddr, {0x90, 0x90, 0x90, 0x90, 0x90})
  core.writeCode(hookAddr, {core.AssemblyLambda([[
    call f
  ]], {
    f = dplayxHandle:getProcAddress("DirectPlayCreate"),
  })})
end

local function detectSteamLobbyConnectArguments()
  -- arg is a global specifying the raw arguments of the process
  for index, a in ipairs(arg) do
    if a == "+connect_lobby" then
      return tonumber(arg[index + 1]) -- lobby id: e.g. 109775243988447845 (middle part of steam://joinlobby/16700/109775243988447845/more numbers)
    end
  end
  return nil
end

local function lobbyIDToGUIDBytes(lobbyID)
  local bytes = {}
  local data1 = (lobbyID >> 32) & 0xFFFFFFFF
  local data2 = (lobbyID >> 16) & 0xFFFF
  local data3 = lobbyID & 0xFFFF
  local data4 = table.pack(string.byte("STEAMID", 1, -1))
  table.insert(data4, 0) -- append 0 byte
  data4.n = nil

  for _, v in ipairs(core.itob(data1)) do
    table.insert(bytes, v)
  end
  for _, v in ipairs(core.stob(data2)) do
    table.insert(bytes, v)
  end
  for _, v in ipairs(core.stob(data3)) do
    table.insert(bytes, v)
  end
  for i=1,8 do
    table.insert(bytes, data4[i])
  end

  if #bytes ~= 16 then
    error(string.format("invalid bytes: %s", json:encode(bytes)))
  end

  return bytes
end

local function allocateDataLocations()
  return {
    pGUID = core.allocate(16, true),
    pForceSteamworks = core.allocate(4, true),
  }
end

local locations

local pSwitchToMenu = core.AOBScan("55 8B 6C 24 08 83 FD 17")
local _, pGameCore = utils.AOBExtract("B9 I(? ? ? ?) C7 87 84 02 00 00 15 00 00 00")
local _switchToMenu = core.exposeCode(pSwitchToMenu, 3, 1)

local _, pMultiplayerInitStep = utils.AOBExtract("39 ? I(? ? ? ?) 56 89 ? ? ? ? ?")
local _, pNextModalDialog = utils.AOBExtract("C7 ? I(? ? ? ?) ? ? ? ? 89 ? ? ? ? ? 89 ? ? ? ? ? C7 ? ? ? ? ? ? ? ? ? 89 ? ? ? ? ? 89 ? ? ? ? ? 89 ? ? ? ? ? 89 ? ? ? ? ? 89 ? ? ? ? ? 89 ? ? ? ? ? 6A 13")
local WAITING_FOR_HOST = 21
local _, pIsHost = utils.AOBExtract("A3 I(? ? ? ?) 0F ? ? ? ? ? 8B CF")
local pIsEqualGUID = core.AOBScan("8B 44 24 08 8B 4C 24 04 56 57 BE 10 00 00 00")
local pPostLobbyNameCompare, sizePostLobbyNameCompare = core.AOBScan("83 C4 08 85 C0 0F ? ? ? ? ? 8B ? ? ? ? ? ? 8B 08"), 5

local _, pSessionGUIDs = utils.AOBExtract("8B ? ? I(? ? ? ?) 8B 08 89 ? ? ? ? ? ")

local function insertPostLobbyNameCompareHook()
  core.insertCode(pPostLobbyNameCompare, sizePostLobbyNameCompare, {
    core.allocateAssembly([[
      push eax                            ; store eax
      mov eax, dword [pForceSteamworks]   ; fetch if there is steam guid value
      cmp eax, 1                          ; test against true
      jne original                        ; if not true, do the original code (not in steamworks mode)
    modification:
      mov eax, dword [edi * 4 + pSessionGUIDs]  ; get pointer to GUID received from remote
      push eax            ; second arg
      mov eax, pGUID      ; pointer to command line GUID
      push eax            ; first arg
      call isEqualGUID    ; guid compare
      add esp, 0x8        ; fix up stack
      cmp eax, 1          ; check if guids are equal
      jne original_fail   ; if not, do original code but force its comparison to fail
      xor eax, eax        ; if true, make the compare succeed
      test eax, eax       ; set the compare
      jmp cleanup         ; jump to the end
    original_fail:
      mov eax, 1          ; make the compare fail
      test eax, eax       ; this is never 0
      jmp cleanup
    original:
      pop eax             ; restore eax
      test eax, eax       ;  original code required for the jump
      jmp finish
    cleanup:
      pop eax             ; restore eax
    finish:
  ]], {
    pForceSteamworks = locations.pForceSteamworks,
    pGUID = locations.pGUID,
    isEqualGUID = pIsEqualGUID,
    pSessionGUIDs = pSessionGUIDs,
  })}, nil, 'before')
end

local pSteamworksGUID = core.allocate(16, true)
core.writeBytes(pSteamworksGUID, { 0xFB, 0x59, 0xEF, 0xF7, 0x02, 0xFA, 0xCE, 0x45, 0xBC, 0x36, 0x7B, 0xF1, 0xD0, 0xF6, 0xBC, 0xE5, })

local pGetGUIDForSelectedProvider, sizeGetGUIDForSelectedProvider = core.AOBScan("83 B9 8C 02 00 00 00"), 7
local function insertGetGUIDForSelectedProviderHook()
  core.insertCode(pGetGUIDForSelectedProvider, sizeGetGUIDForSelectedProvider, {
    core.AssemblyLambda([[
      mov eax, dword [esp + 4] ; first parameter contains guid pointer (destination)
      push ecx
      mov ecx, dword [pSteamworksGUID]
      mov dword [eax], ecx
      mov ecx, dword [pSteamworksGUID + 0x4]
      mov dword [eax + 0x4], ecx
      mov ecx, dword [pSteamworksGUID + 0x8]
      mov dword [eax + 0x8], ecx
      mov ecx, dword [pSteamworksGUID + 0xC]
      mov dword [eax + 0xC], ecx
      pop ecx
    ]], {
      pSteamworksGUID = pSteamworksGUID,
    })
  },nil, "after")
end

local pDisconnectDPlayHook, sizeDisconnectDPlayHook = core.AOBScan("89 AE 8C 02 00 00"), 6
local function insertDisconnectDPlayHook()
  core.insertCode(pDisconnectDPlayHook, sizeDisconnectDPlayHook, {
    core.AssemblyLambda([[
        mov dword [pForceSteamworks], ebp ; set to false or 0 if multiplayer is over
      ]], {
      pForceSteamworks = locations.pForceSteamworks,
    })
  }, nil, "after")
end

local pHandleCommandLineArgumentsEvent, sizeHandleCommandLineArgumentsEvent = core.AOBScan("8B 8C 24 14 04 00 00"), 7


return {
  enable = function(self, config)

    if config.steam_appid.write == true then
      setSteamAppIdFile()
    else
      log(VERBOSE, string.format("leaving steam_appid.txt untouched"))
    end

    self.dplayxHandle = dplayxHandle
--    self.steamApiHandle = steamApiHandle
    installDPLAYXHook()

    locations = allocateDataLocations()

    core.detourCode(function(registers)
      log(VERBOSE, string.format("handling command line arguments"))
      local lobbyID = detectSteamLobbyConnectArguments()
      if lobbyID ~= nil then
        local guidBytes = lobbyIDToGUIDBytes(lobbyID)
        core.writeBytes(locations.pGUID, guidBytes)
        core.writeInteger(locations.pForceSteamworks, 1) -- force is to true
        log(VERBOSE, string.format("wrote lobby id to memory: %s", lobbyID))

        core.writeInteger(pIsHost, 0)
        core.writeInteger(pNextModalDialog, WAITING_FOR_HOST)
        _switchToMenu(pGameCore, 19, 0) -- MP_CONNECTION
        core.writeInteger(pMultiplayerInitStep, 0)
      else
        log(VERBOSE, string.format("no +connect_lobby argument found"))
      end
    end, pHandleCommandLineArgumentsEvent, sizeHandleCommandLineArgumentsEvent)
    

    insertPostLobbyNameCompareHook()
    insertGetGUIDForSelectedProviderHook()
    insertDisconnectDPlayHook()
  end,

  disable = function(self, config)
  end,
}, {
  public = {
    dplayxHandle = dplayxHandle,
  }
}