event.ignoreAll()
event.clear()

filesystem.initFileSystem("/dev")

scriptInfo = {
    network = component.proxy("80DD4D334BFB1145601565BD280818DF"),
    name = "CU4",
    comment = "Foundry",
    fileSystemMonitor = true,
    makerOutputIndex = 2,
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
