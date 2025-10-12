-- should be shipped but doesn't need to be loaded explicitly
-- local steamApiHandle = core.openLibraryHandle("ucp/modules/steam-multiplayer/steam_api.dll")
if #arg > 0 then
    log(VERBOSE, string.format("writing steamapp_id.txt file"))
    local f, err = io.open("steam_appid.txt", 'w')
    if not f then error(err) end
    if arg[1] == "Stronghold_Crusader_Extreme.exe" then
        log(VERBOSE, string.format("writing steamapp_id.txt file for Extreme: 16700"))
        f:write("16700")
    else
        log(VERBOSE, string.format("writing steamapp_id.txt file for Crusader: 40970"))
        f:write("40970")
    end
    f:close()
end

local dplayxHandle = core.openLibraryHandle("ucp/modules/steam-multiplayer/RedirectPlay.dll")

return {
    enable = function(self, config)
        self.dplayxHandle = dplayxHandle
--        self.steamApiHandle = steamApiHandle


        local hookAddr, hookSize = core.AOBScan("E8 ? ? ? ? 85 C0 0F ? ? ? ? ? 8B 44 24 0C 8B 08"), 5
        core.writeCode(hookAddr, {0x90, 0x90, 0x90, 0x90, 0x90})
        core.writeCode(hookAddr, {core.AssemblyLambda([[
            call f
        ]], {
            f = dplayxHandle:getProcAddress("DirectPlayCreate"),
        })})
    end,

    disable = function(self, config)
    end,
}, {
    public = {
        dplayxHandle = dplayxHandle,
    }
}