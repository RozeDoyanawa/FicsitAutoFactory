event.ignoreAll()
event.clear()

filesystem.initFileSystem("/dev")

scriptInfo = {
    network = component.proxy("3825B51947382D003E6ADB8FA817DB0F"),
    name = "LogMgr",
    screen = component.proxy(component.findComponent("LoggingScreen")[1]),
    screenWidth = 150,
    screenHeight = 44,
    fileSystemMonitor = false,
    port = 101,
    preventResetAll = true,
    preventStopAll = true,
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

