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
filesystem.doFile("/BusProcessing.lua")
filesystem.doFile("/CraftingT3.lua")
filesystem.doFile("/CraftingCommon.lua")