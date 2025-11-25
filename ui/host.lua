local function createHostMenu(menuID, modalMenuID)
  log(VERBOSE, string.format("createHostMenu(%s, %s)", menuID, modalMenuID))
  local menuItems = {

  }
  local menu = api.ui.Menu:createMenu({
    menuID = menuID,
    menuItemsCount = 10,
    -- menuItems = ffi.new(string.format("MenuItem[%s]", #menuItems), menuItems)
  })

  ---@type ModalMenu
  local ModalMenu = api.ui.ModalMenu
  local modalMenu = ModalMenu:createModalMenu({
    modalMenuID = modalMenuID,
    width = 600,
    height = 408,
    x = -1,
    y = -1,
    borderStyle = 512,
    backgroundColor = 0,
    menuModalRenderFunction = function(x, y, width, height)

      local status, err = pcall(function()
        -- game.Rendering.drawBlendedBlackBox(game.Rendering.pencilRenderCore, x+6, y+6, x + 600 - 6, y + 408-6, 0x14)
        game.Rendering.renderTextToScreenConst(game.Rendering.textManager, "Create Lobby", x + 20, y + 25, 0, 0xCCFAFF, 0xF, false, 0)
        
        -- game.Rendering.renderTextToScreenConst(textManager, "Save & Close", x + width - 150, y + height - 45 + 5 + 3, 0, 0xB8EEFB, 0x13, 0, 0)

        -- local feeTxt = string.format("Market fee:   %d", 0) .. " %"
        -- if SETTINGS.logic.marketFee.enabled == true then
        --   feeTxt = string.format("Market fee:   %d", SETTINGS.logic.marketFee.value) .. " %"
        -- end
        
        -- game.Rendering.renderTextToScreenConst(textManager, feeTxt, x + 30 + 5, y + height - 45 + 5 + 3, 0, 0xB8EEFB, 0x13, 0, 0)



      end)
      if status == false then log(ERROR, err) end
      
    end,
    menu = menu,
  })

  return {
    modalMenuID = modalMenu.modalMenuID,
    menuID = menu.menuID,
  }
end

return {
  createHostMenu = createHostMenu,
}