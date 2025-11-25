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
    if arg == "+connect_lobby" then
      return arg[index + 1]
    end
  end
end

local ui = require("ui")

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



    ui.initialize()
  end,

  disable = function(self, config)
  end,
}, {
  public = {
    dplayxHandle = dplayxHandle,
  }
}