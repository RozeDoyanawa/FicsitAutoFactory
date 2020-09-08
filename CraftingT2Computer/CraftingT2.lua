--
-- Created by IntelliJ IDEA.
-- User: Roze
-- Date: 2020-08-22
-- Time: 09:53
-- To change this template use File | Settings | File Templates.
--

local dev = component.proxy(component.findComponent("CraftingT2 Computer Network Adapter")[1])
scriptInfo.name = "Crafting T2"
scriptInfo.network = dev

stationPrefix = "CrafterT2"

if dev then
    dev:open(100)
    event.listen(dev)
else
    print ("No such adapter")
end

stationOutputSlot = 3

screens.init("CraftingT2", 1, 1, 100, 45)

local panel = component.proxy(component.findComponent("CraftingT2 Panel 1")[1])

local button = panel:getModule(0, 10)
registerEvent(button, button, function(self, evt)
    queue2("Iron Plate", 2)
end)
event.listen(button)