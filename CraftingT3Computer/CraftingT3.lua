--
-- Created by IntelliJ IDEA.
-- User: Roze
-- Date: 2020-08-22
-- Time: 09:53
-- To change this template use File | Settings | File Templates.
--

local dev = component.proxy(component.findComponent("CraftingT3 Computer Network Adapter")[1])
scriptInfo.name = "Crafting T3"
scriptInfo.network = dev

stationPrefix = "CrafterT3"

if dev then
    dev:open(100)
    event.listen(dev)
else
    print ("No such adapter")
end

stationOutputSlot = 2

screens.init("CraftingT3", 1, 1, math.floor(115 * 1), math.floor(45 * 1))
--screens.init("CraftingT3", 1, 1, 115, 45)

local panel = component.proxy(component.findComponent("CraftingT3 Panel 1")[1])

local button = panel:getModule(0, 10)
registerEvent(button, button, function(self, evt)
    queue2("Iron Plate", 2)
end)
event.listen(button)