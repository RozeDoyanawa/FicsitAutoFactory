--
-- Created by IntelliJ IDEA.
-- User: Roze
-- Date: 2020-08-22
-- Time: 09:53
-- To change this template use File | Settings | File Templates.
--

local dev = component.proxy(component.findComponent("Crafting Computer Network Adapter")[1])
scriptInfo.name = "Crafting T1"
scriptInfo.network = dev
scriptInfo.debugging = true

stationPrefix = "Crafter"

if dev then
    dev:open(100)
    event.listen(dev)
else
    print ("No such adapter")
end

stationOutputSlot = 2

screens.init("Crafting", 1, 1, math.floor(100 * 1.5), math.floor(45 * 1.5))

local panel = component.proxy(component.findComponent("Crafting Panel 1")[1])

local button = panel:getModule(0, 10)
registerEvent(button, button, function(self, evt)
    queue2("Iron Plate", 2)
end)
event.listen(button)

