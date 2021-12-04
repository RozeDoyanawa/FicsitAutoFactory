event.ignoreAll()
event.clear()

filesystem.initFileSystem("/dev")

scriptInfo = {
    network = component.proxy("F3E5BCC346FF7360CCFB49990E6286D0"),
    name = "InvMgr_H2",
    fileSystemMonitor = false,
    hallName = "H2",
    topupPrefix = "TopUp2",
    port = 106,
    auxPanel = "InvMgr_H2_ControlPanel1",
    emgPanel = "InvMgr_H2_EmgPanel1",
}


drive = ""
for _,f in pairs(filesystem.childs("/dev")) do
    if not (f == "serial") then
        drive = f
        print(drive)
        break
    end
end
filesystem.mount("/dev/" .. drive, "/")

filesystem.doFile("/InvMgrCommon.lua")

---@type InventoryPanelData
inventoryPanelData = {
    resources = {
        --InventoryPanelResource.new(""                                  ,  1),
        --InventoryPanelResource.new(""                                  ,  2),
        --InventoryPanelResource.new(""                                  ,  3),
        InventoryPanelResource.new("Bauxite"                           ,  4),
        InventoryPanelResource.new("Uranium"                           ,  5),
        InventoryPanelResource.new("Sulfur"                            ,  6),
        --InventoryPanelResource.new(""                                  ,  7),
        --InventoryPanelResource.new(""                                  ,  8),
        --InventoryPanelResource.new(""                                  ,  9),
        InventoryPanelResource.new("Beacon"                            , 10),
        --InventoryPanelResource.new("Nobelisk"                          , 11),
        InventoryPanelResource.new("Gunpowder"                         , 12),
        InventoryPanelResource.new("Packaged Fuel"                     , 13),
        InventoryPanelResource.new("Packaged Heavy Oil Residue"        , 14),
        InventoryPanelResource.new("Packaged Liquid Biofuel"           , 15),
        InventoryPanelResource.new("Packaged Alumina Solution"         , 16),
        InventoryPanelResource.new("Aluminum Scrap"                    , 17),
        InventoryPanelResource.new("Aluminum Ingot"                    , 18),
        InventoryPanelResource.new("Supercomputer"                    , 19),
        InventoryPanelResource.new("Computer"                          , 20),
        InventoryPanelResource.new("High-Speed Connector"              , 21),
        InventoryPanelResource.new("AI Limiter"                        , 22),
        InventoryPanelResource.new("Circuit Board"                     , 23),
        InventoryPanelResource.new("Crystal Oscillator"                , 24),
        InventoryPanelResource.new("Radio Control Unit"                , 25),
        --InventoryPanelResource.new(""                                  , 26),
        --InventoryPanelResource.new(""                                  , 27),
        --InventoryPanelResource.new(""                                  , 28),
        --InventoryPanelResource.new(""                                  , 29),
        --InventoryPanelResource.new(""                                  , 30),
        --InventoryPanelResource.new(""                                  , 31),
        --InventoryPanelResource.new(""                                  , 32),
        --InventoryPanelResource.new(""                                  , 33),
        InventoryPanelResource.new("Silica"                            , 34),
        InventoryPanelResource.new("Alclad Aluminum Sheet"             , 35),
        InventoryPanelResource.new("Aluminum Casing"                  , 36),
    }
}



filesystem.doFile("/Common.lua")

commonInit()

