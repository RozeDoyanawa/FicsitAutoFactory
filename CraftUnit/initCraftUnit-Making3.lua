event.ignoreAll()
event.clear()

filesystem.initFileSystem("/dev")

scriptInfo = {
    network = component.proxy("85162A4141BE7416E054D8B872EB4DCC"),
    name = "CU3",
    comment = "Assembler",
    fileSystemMonitor = true,
    makerOutputIndex = 3,
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
