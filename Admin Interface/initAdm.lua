event.ignoreAll()
event.clear()

filesystem.initFileSystem("/dev")

scriptInfo = {
    network = component.proxy(component.findComponent(findClass("NetworkCard_C"))[1]),
    name = "Admin",
    fileSystemMonitor = true,
    port = 100,
    screen = component.proxy(component.findComponent("AdmScreen")[1]),
    screenWidth = 160,
    screenHeight = 50,
    auxPanel = "InvMgr_H1_ControlPanel1",
    emgPanel = "InvMgr_H1_EmgPanel1",
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
