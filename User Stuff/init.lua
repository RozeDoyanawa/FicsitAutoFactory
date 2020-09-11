---
--- Generated by EmmyLua(https://github.com/EmmyLua)
--- Created by Roze.
--- DateTime: 2020-09-08 23:19
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


registerEvent("FileSystemUpdate", nil, function(pullRequest)
    if pullRequest[4] and pullRequest[4] == "/Common.lua" then
        rdebug("Computer reset by filesystem")
        print("Meow")
        computer.skip()
        computer.reset()
    end
end)

filesystem.doFile("/Screen.lua")
filesystem.doFile("/padding.lua")
filesystem.doFile("/UserStuff.lua")
