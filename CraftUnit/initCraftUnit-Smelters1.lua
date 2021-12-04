event.ignoreAll()
event.clear()

filesystem.initFileSystem("/dev")

scriptInfo = {
    network = component.proxy("044449754E55E78F1F68C7BEEEE4F5BC"),
    name = "SmeltT1",
    comment = "Smelters",
    fileSystemMonitor = true,
    makerOutputIndex = 1,
    port = 105
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

--main = function () end

json = filesystem.doFile("/json.lua")
filesystem.doFile("/Common.lua")

commonInit()
