event.ignoreAll()
event.clear()

filesystem.initFileSystem("/dev")

scriptInfo = {
    network = component.proxy("B0FB35C4420EA149FC17A29793CF765B"),
    name = "ProdMgr",
    fileSystemMonitor = true,
    port = 100,
    debugging = true,
    screen = component.proxy(component.findComponent("ProdMgr_Screen")[1]),
    screenWidth = 360,
    screenHeight = 56,
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

