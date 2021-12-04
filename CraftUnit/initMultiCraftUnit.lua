event.ignoreAll()
event.clear()

filesystem.initFileSystem("/dev")

scriptInfo = {
    network = component.proxy("044449754E55E78F1F68C7BEEEE4F5BC"),
    name = "MfgMgr",
    units = {{
                 name = "SmeltT1",
                 output = 1,
                 comment = "Smelters",
                 factories = {}
             },{
                 name = "SmeltT2",
                 output = 2,
                 comment = "Foundries",
                 factories = {}
             },{
                 name = "ProdT1",
                 output = 2,
                 comment = "Constructors",
                 factories = {}
             },{
                 name = "ProdT2",
                 output = 3,
                 comment = "Assemblers",
                 factories = {}
             },{
                 name = "ProdT3",
                 output = 2,
                 comment = "Manufacturers",
                 factories = {}
    }},
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
