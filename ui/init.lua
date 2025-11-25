
-- ---@type Module_UI
-- local ui = modules.ui
-- local access = ui:access()

local function initialize()
    -- log(VERBOSE, string.format("initialize()"))
    -- local menuID = access.manager.getAvailableMenuID(28019)
    -- local modalMenuID = access.manager.getAvailableModalMenuID(28019 + 1)

    -- ui:getState():executeFile("ucp/modules/steam-multiplayer/ui/manager.lua")
    -- ui:getState():invoke("ucp/modules/steam-multiplayer/ui/host/createHostMenu", menuID, modalMenuID)

    -- log(VERBOSE, string.format("invoked init: %s, %s", menuID, modalMenuID))

    -- return {
    --     menuID = menuID,
    --     modalMenuID = modalMenuID,
    -- }
end


return {
    initialize = initialize,
}