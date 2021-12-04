event.ignoreAll()
event.clear()

filesystem.initFileSystem("/dev")

scriptInfo = {
    network = component.proxy("952B4E8C4EE276DBF4C2DF9C9057F888"),
    name = "InvMgr_H1",
    fileSystemMonitor = false,
    hallName = "H1",
    topupPrefix = "TopUp",
    port = 106,
    auxPanel = "InvMgr_H1_ControlPanel1",
    emgPanel = "InvMgr_H1_EmgPanel1",
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
        InventoryPanelResource.new("Screw"                          ,  1),
        InventoryPanelResource.new("Wire"                           ,  2),
        InventoryPanelResource.new("Quickwire"                      ,  3),
        InventoryPanelResource.new("Iron Ore"                       ,  4),
        InventoryPanelResource.new("Copper Ore"                     ,  5),
        InventoryPanelResource.new("Caterium Ore"                   ,  6),
        InventoryPanelResource.new("Coal"                           ,  7),
        InventoryPanelResource.new("Packaged Oil"                   ,  8),
        InventoryPanelResource.new("Packaged Water"                 ,  9),
        InventoryPanelResource.new("Empty Canister"                 , 10),
        InventoryPanelResource.new("Plastic"                        , 11),
        InventoryPanelResource.new("Rubber"                         , 12),
        InventoryPanelResource.new("Iron Ingot"                     , 13),
        InventoryPanelResource.new("Copper Ingot"                   , 14),
        InventoryPanelResource.new("Caterium Ingot"                 , 15),
        InventoryPanelResource.new("Steel Ingot"                    , 16),
        InventoryPanelResource.new("Raw Quartz"                     , 17),
        InventoryPanelResource.new("Quartz Crystal"                 , 18),
        InventoryPanelResource.new("Limestone"                      , 19),
        InventoryPanelResource.new("Concrete"                       , 20),
        InventoryPanelResource.new("Copper Sheet"                   , 21),
        InventoryPanelResource.new("Iron Plate"                     , 22),
        InventoryPanelResource.new("Iron Rod"                       , 23),
        InventoryPanelResource.new("Steel Pipe"                     , 24),
        InventoryPanelResource.new("Steel Beam"                     , 25),
        InventoryPanelResource.new("Reinforced Iron Plate"          , 26),
        InventoryPanelResource.new("Encased Industrial Beam"        , 27),
        InventoryPanelResource.new("Modular Frame"                  , 28),
        InventoryPanelResource.new("Heavy Modular Frame"            , 29),
        InventoryPanelResource.new("Rotor"                          , 30),
        InventoryPanelResource.new("Stator"                         , 31),
        InventoryPanelResource.new("Motor"                          , 32),
        InventoryPanelResource.new("Petroleum Coke"                 , 33),
        InventoryPanelResource.new("Polymer Resin"                  , 34),
        --InventoryPanelResource.new("Silica                        , 35),
        InventoryPanelResource.new("Cable"                          , 36),
    }
    --H2 = {
    --}
}


--main = function () end
filesystem.doFile("/Common.lua")

commonInit()

