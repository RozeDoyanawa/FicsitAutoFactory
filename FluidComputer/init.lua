---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Roze.
--- DateTime: 2020-09-08 23:20
---

event.ignoreAll()
event.clear()

filesystem.initFileSystem("/dev")

drive = ""
for _,f in pairs(filesystem.childs("/dev")) do
    if not (f == "serial") then
        drive = f
        break
    end
end
filesystem.mount("/dev/" .. drive, "/")

filesystem.doFile("/Common.lua")
filesystem.doFile("/Screen.lua")

local dev = component.proxy(component.findComponent("Fluid Computer Network Adapter")[1])
scriptInfo.name = "Fluids"
scriptInfo.network = dev

stationPrefix = "FluidStation"
stationOutputSlot = 1

if dev then
    dev:open(100)
    event.listen(dev)
else
    print ("No such adapter")
end

screens.init("Fluids", 1, 1, 115, 45)

local panel = component.proxy(component.findComponent("Fluids Panel 1")[1])
local panel2 = component.proxy(component.findComponent("Fluids Panel 2")[1])

local button = panel:getModule(0, 10)
registerEvent(button, button, function(self, evt)
    globalStation:order("Plastic", 3)
end)
event.listen(button)

button = panel2:getModule(0, 10)
registerEvent(button, button, function(self, evt)
    globalStation:order("Plastic", 1)
end)
event.listen(button)

filesystem.doFile("/BusProcessing.lua")
filesystem.doFile("/FluidCrafting.lua")