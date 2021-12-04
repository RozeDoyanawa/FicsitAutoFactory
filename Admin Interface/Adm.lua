
local periodicStuff = createLinkedList()

local btnResetAll, btnBusTest, btnBusTest2, btnReset2, btnReset3, btnReset4, btnTemp1;


function initNetwork()

end

local resetMutex = false;
local busTestMutex = false;
local busTest2Mutex = false;
local reset2Mutex = false;
local reset3Mutex = false;
local reset4Mutex = false;
local btnMutexTemp1 = false;

function initCommandPointLabel(panel, pointID, text, textColor, orientation, initModuleCallback, actionCallback, instance)
    if textColor ~= nil then
        panel:setForeground(pointID, textColor[1], textColor[2], textColor[3])
    end
    if orientation == nil then
        orientation = 1
    end
    if text ~= nil then
        panel:setText(pointID, text, orientation)
    end
    if actionCallback ~= nil or initModuleCallback ~= nil then
        local module = panel:getModule(pointID, 0)
        if instance == nil then
            instance = module
        end
        if module ~= nil then
            if initModuleCallback ~= nil then
                initModuleCallback(module)
            end
            if actionCallback ~= nil then
                registerEvent(module, instance, actionCallback)
                event.listen(module)
            end
            return module
        else
            rerror("Callback set for " .. panel.nick .. ":" .. pointID .. " but no module found")
        end
    end
    return nil
end

local managerPanels = {
    "Panel_CompData 1",
    "Panel_CompData 2"
}

local MANAGER_COLUMN_HEIGHT = 10

local managerPanelIndexReservations = {
    ["InvMgr_H2"] = {index = MANAGER_COLUMN_HEIGHT * 0 + 4},
    ["InvMgr_H1"] = {index = MANAGER_COLUMN_HEIGHT * 0 + 5},
    ["Admin"] = {index = MANAGER_COLUMN_HEIGHT * 0 + 9},
    --["ProdT2"] = {index = MANAGER_COLUMN_HEIGHT * 1 + 6},
    --["ProdT1"] = {index = MANAGER_COLUMN_HEIGHT * 1 + 7},
    --["ProdT3"] = {index = MANAGER_COLUMN_HEIGHT * 1 + 5},
    ["MfgMgr"] = {index = MANAGER_COLUMN_HEIGHT * 1 + 9},
    --["SmeltT2"] = {index = MANAGER_COLUMN_HEIGHT * 1 + 8},
    ["Fluids1"] = {index = MANAGER_COLUMN_HEIGHT * 1 + 4},
    ["LogMgr"] = {index = MANAGER_COLUMN_HEIGHT * 0 + 8},
    ["ProdMgr"] = {index = MANAGER_COLUMN_HEIGHT * 0 + 7},
    ["Water&OilSource"] = {index = MANAGER_COLUMN_HEIGHT * 1 + 2},
    ["BusMgr"] = {index = MANAGER_COLUMN_HEIGHT * 0 + 6},
}

function initComputerManagerPanels()
    for k,v in pairs(managerPanels) do
        local comp = component.proxy(component.findComponent(v)[1])
        managerPanels[k] = comp
        if comp == nil then
            rerror("No such panel: " .. k)
            error()
        end
        for i = 0,9 do
            local indStatus = comp:getModule(0, i)
            local btnReset = comp:getModule(3, i)
            local btnStop = comp:getModule(4, i)
            btnStop:setColor(0.5, 0, 0, 0)
            btnReset:setColor(0.5, 0.5, 0,0)
            indStatus:setColor(0,0,0,0)
        end
    end
    local arps = getARP()

    for k,v in pairs(managerPanelIndexReservations) do
        local r = arps[k]
        local panelIndex = math.floor(v.index / MANAGER_COLUMN_HEIGHT) + 1
        local moduleIndex = v.index % MANAGER_COLUMN_HEIGHT
        print("PanelIndex: ".. panelIndex .. ", ModuleIndex: " .. moduleIndex)
        local panel = managerPanels[panelIndex]
        v.indStatus = panel:getModule(0, moduleIndex)
        local btnReset = panel:getModule(3, moduleIndex)
        local btnStop = panel:getModule(4, moduleIndex)
        initModularButton(btnReset, function(self)
            local larp = getARP()
            local lr = larp[k]
            if lr ~= nil then
                scriptInfo.network:send(lr.address, getAdminPort(), "reset")
            end
        end, nil, true)
        initModularButton(btnStop, function(self)
            local larp = getARP()
            local lr = larp[k]
            if lr ~= nil then
                scriptInfo.network:send(lr.address, getAdminPort(), "stop")
            end
        end, nil, true)

    end
end


function initNetworkControlPanel()
    local panel = component.proxy(component.findComponent("NetworkControlPanel")[1])
    if panel ~= nil then
        btnNCP_btn1 = initCommandPointLabel(panel, 0, "Network\nReset", {1,1,1}, 1, function(self)
            self:setColor(0.4, 0, 0, 0.1)
        end, function(self)
            if resetMutex == false then
                resetMutex = true
                self:setColor(1, 0.5, 0.5, 1)
                scriptInfo.network:broadcast(getAdminPort(), "resetAll")
                wait(1000)
                self:setColor(0.4, 0, 0, 0.1)
                resetMutex = false
            end
        end)
        btnNCP_btn2 = initCommandPointLabel(panel, 1, "", {1,1,1}, 1)
        btnNCP_btn3 = initCommandPointLabel(panel, 2, "", {1,1,1}, 1)
        btnNCP_btn4 = initCommandPointLabel(panel, 3, "", {1,1,1}, 1)
        btnNCP_btn5 = initCommandPointLabel(panel, 4, "", {1,1,1}, 1)
        btnNCP_btn6 = initCommandPointLabel(panel, 5, "", {1,1,1}, 1)
    else
        rerror("No NetworkControlPanel")
    end
end
function printScreen()
    if scriptInfo.screen ~= nil then
        scriptInfo.gpu = computer.getGPUs()[1]
        local gpu = scriptInfo.gpu
        rsClear(gpu)
        local x = 0
        local y = 0
        rsSetColorA(gpu, scriptInfo.systemColors.Normal);
        gpu:setText(x, y, "Computers: "); y = y + 1
        x = x + 2
        local boxWidth = 36
        local boxHeight = 6
        local halfBox = boxWidth / 2.0
        local _x = x
        for key,v in pairs(getARP()) do
            local _y = y
            if v.address == key then
                rsSetColorA(gpu, scriptInfo.systemColors.Normal);
                rsprintSquareFrame(gpu, DOUBLE_LINE_BOX, x, y, boxWidth, boxHeight)
                y = y + 1
                rsSetColorA(gpu, scriptInfo.systemColors.Grey);
                gpu:setText(x + math.floor(halfBox - string.len(v.name) / 2.0), y, v.name)
                y = y + 1
                rsSetColorA(gpu, scriptInfo.systemColors.Normal);
                if v.resetting then
                    rsSetColorA(gpu, scriptInfo.systemColors.Yellow)
                    gpu:setText(x + math.floor(halfBox - 9.0 / 2.0), y, "Resetting");
                elseif v.online then
                    rsSetColorA(gpu, scriptInfo.systemColors.LightGreen)
                    gpu:setText(x + math.floor(halfBox - 6.0 / 2.0), y, "Online");
                    --if v.rtt >= 0 then
                    --    x = x + 1
                    --    rsSetColorA(gpu, scriptInfo.systemColors.Number)
                    --    gpu:setText(x, y, lpad(tostring(v.rtt), 2, " "));
                    --    x = x + 2
                    --    rsSetColorA(gpu, scriptInfo.systemColors.Normal)
                    --    gpu:setText(x, y, "ms");
                    --    x = x + 2
                    --end
                else
                    rsSetColorA(gpu, scriptInfo.systemColors.Yellow)
                    gpu:setText(x + math.floor(halfBox - 7.0 / 2.0), y, "Offline");
                end
                y = y + 1
                if v.errored then
                    rsSetColorA(gpu, scriptInfo.systemColors.LightRed)
                    gpu:setText(x + math.floor(halfBox - 5.0 / 2.0), y, "Error");
                end
                rsSetColorA(gpu, scriptInfo.systemColors.Number);
                gpu:setText(x + math.floor(halfBox - string.len(v.address) / 2.0), y, v.address)
                y = y + 1
                x = x + boxWidth + 1
            end

            y = _y
            if x + boxWidth >= scriptInfo.screenWidth then
                x = _x
                y = y + boxHeight
            end
        end

        gpu:flush()

    end
end


function printScreen2()
    scriptInfo.gpu = computer.getGPUs()[1]
    local gpu = scriptInfo.gpu
    rsclear()
    local x = 0
    local y = 0
    rsSetColorA(gpu, scriptInfo.systemColors.Normal);
    gpu:setText(x, y, "Computers: "); y = y + 1
    x = x + 2
    for _,v in pairs(getARP()) do
        local _x = x
        if v.address == _ then
            x = _x
            rsSetColorA(gpu, scriptInfo.systemColors.Grey);
            gpu:setText(x, y, v.name)
            x = x + 20
            rsSetColorA(gpu, scriptInfo.systemColors.Normal);
            gpu:setText(x, y, "[");
            x = x + 1
            if v.resetting then
                rsSetColorA(gpu, scriptInfo.systemColors.Yellow)
                gpu:setText(x, y, "Resetting");
                x = x + 9
            elseif v.online then
                rsSetColorA(gpu, scriptInfo.systemColors.LightGreen)
                gpu:setText(x, y, "Online");
                x = x + 6
                --if v.rtt >= 0 then
                --    x = x + 1
                --    rsSetColorA(gpu, scriptInfo.systemColors.Number)
                --    gpu:setText(x, y, lpad(tostring(v.rtt), 2, " "));
                --    x = x + 2
                --    rsSetColorA(gpu, scriptInfo.systemColors.Normal)
                --    gpu:setText(x, y, "ms");
                --    x = x + 2
                --end
            else
                rsSetColorA(gpu, scriptInfo.systemColors.Yellow)
                gpu:setText(x, y, "Offline");
                x = x + 7
            end
            if v.errored then
                rsSetColorA(gpu, scriptInfo.systemColors.Normal);
                gpu:setText(x, y, " +");
                x = x + 3
                rsSetColorA(gpu, scriptInfo.systemColors.LightRed)
                gpu:setText(x, y, "Error");
                x = x + 5
            end
            rsSetColorA(gpu, scriptInfo.systemColors.Normal);
            gpu:setText(x, y, "]");
            x = x + 1
            x = math.max(x, 45)
            rsSetColorA(gpu, scriptInfo.systemColors.Normal);
            gpu:setText(x, y, " > ");
            x = x + 3
            rsSetColorA(gpu, scriptInfo.systemColors.Number);
            gpu:setText(x, y, v.address)
            y = y + 1
            x = _x
        end
    end
    rsflush()
end

function initEmgPanel()
    if scriptInfo.emgPanel then
        print("Initializing emg panel: " .. scriptInfo.emgPanel)
        local panels = component.proxy(component.findComponent(scriptInfo.emgPanel))
        for _,k in pairs(panels) do
            local modules = k:getModules()
            local btnEmgStop = modules[1]

            --setCommandLabelText(k, 0, "", false)

            --k:setLabelIcon(0, "EmgStop", true)

            initModularButton(
                    btnEmgStop,
                    function(self, msg, params)
                        --self:setColor(1, 0.5, 0.5, 1)
                        scriptInfo.network:broadcast(getAdminPort(), "stopAll")
                        wait(1000)
                        --self:setColor(0.4, 0, 0, 0.1)
                        resetMutex = false
                    end,
                    rgba(0.4, 0.0, 0.0, 0.0)
            )
            event.listen(btnEmgStop)
        end
    end
end


function initPanel()
    local panel = component.proxy(component.findComponent("AdminInterfaceBoard")[1])
    btnResetAll = panel:getModule(0, 10, 0)
    btnResetAll:setColor(0.4, 0, 0, 0.1)

    registerEvent(btnResetAll, btnResetAll, function(self, msg, params)
        if resetMutex == false then
            resetMutex = true
            self:setColor(1, 0.5, 0.5, 1)
            scriptInfo.network:broadcast(getAdminPort(), "resetAll")
            wait(1000)
            self:setColor(0.4, 0, 0, 0.1)
            resetMutex = false
        end
    end)
    event.listen(btnResetAll)
    btnBusTest = panel:getModule(0, 7, 0)
    btnBusTest:setColor(0, 0.4, 0, 0.1)

    registerEvent(btnBusTest, btnBusTest, function(self, msg, params)
        if busTestMutex == false then
            busTestMutex = true
            local busses = {"A", "B", "C", "D", "E", "F"}
            local items = {"Iron Ore", "Copper Ore", "Caterium Ore", "Raw Quartz", "Iron Plate", "Iron Rod"}
            self:setColor(0.5, 1, 0.5, 1)
            for _,bus in pairs(busses) do
                rmessage("Requesting 4 " .. items[_] .. " from " .. bus)
                scriptInfo.network:send("294E82AC435A5A328CB94E86AA0551A4", 106, "order", "json", json.encode({
                    name = items[_],
                    count = "4",
                    taskID = 999,
                    bus = bus
                }))
            end
            wait(1000)
            self:setColor(0, 0.4, 0, 0.1)
            busTestMutex = false
        end
    end)
    event.listen(btnBusTest)
    btnBusTest2 = panel:getModule(2, 7, 0)
    btnBusTest2:setColor(0, 0.4, 0, 0.1)

    registerEvent(btnBusTest2, btnBusTest2, function(self, msg, params)
        if busTest2Mutex == false then
            busTest2Mutex = true
            self:setColor(0.5, 1, 0.5, 1)
            local item = "Screw"
            local bus = "D"
            rmessage("Requesting 4 " .. item .. " from " .. bus)
            scriptInfo.network:send("294E82AC435A5A328CB94E86AA0551A4", 106, "order", "json", json.encode({
                name = item,
                count = "4",
                taskID = 999,
                bus = bus
            }))
            wait(1000)
            self:setColor(0, 0.4, 0, 0.1)
            busTest2Mutex = false
        end
    end)
    event.listen(btnBusTest2)

    btnReset2 = panel:getModule(3, 10, 0)
    btnReset2:setColor(0.4, 0.4, 0, 0.1)

    registerEvent(btnReset2, btnReset2, function(self, msg, params)
        if reset2Mutex == false then
            reset2Mutex = true
            self:setColor(1, 1, 0.5, 1)
            rmessage("Resetting oil computer")
            scriptInfo.network:send("0FB7C81A4D8ACBDB97B3D3BAE8F8A507", 10, "reset")
            wait(1000)
            self:setColor(0.4, 0.4, 0, 0.1)
            reset2Mutex = false
        end
    end)
    event.listen(btnReset2)

    btnReset3 = panel:getModule(5, 10, 0)
    btnReset3:setColor(0.4, 0.4, 0, 0.1)

    registerEvent(btnReset3, btnReset3, function(self, msg, params)
        if reset3Mutex == false then
            reset3Mutex = true
            self:setColor(1, 1, 0.5, 1)
            rmessage("Resetting fluid maker computer")
            scriptInfo.network:send("A71309B34056CA4D4D77A891ADD09074", 10, "reset")
            wait(1000)
            self:setColor(0.4, 0.4, 0, 0.1)
            reset3Mutex = false
        end
    end)
    event.listen(btnReset3)

    btnReset4 = panel:getModule(10, 10, 0)
    btnReset4:setColor(0.7, 0.4, 0, 0.1)

    registerEvent(btnReset4, btnReset4, function(self, msg, params)
        if reset4Mutex == false then
            reset4Mutex = true
            self:setColor(1, 1, 0.5, 1)
            rmessage("Resetting inventory computers computer")
            scriptInfo.network:send("294E82AC435A5A328CB94E86AA0551A4", 10, "reset")
            scriptInfo.network:send("BAC723864AEA55E3D8179B826A9A0DF3", 10, "reset")
            wait(1000)
            self:setColor(0.4, 0.4, 0, 0.1)
            reset4Mutex = false
        end
    end)
    event.listen(btnReset4)
    btnTemp1 = panel:getModule(0, 0, 0)
    btnTemp1:setColor(0.4, 0.4, 1, 0.1)

    registerEvent(btnTemp1, btnTemp1, function(self, msg, params)
        if btnMutexTemp1 == false then
            btnMutexTemp1 = true
            self:setColor(0, 0, 1, 1)
            rmessage("Resetting inventory computers computer")
            scriptInfo.network:send("7C6D9E33408D0AE3409DD19229FC3CC0", 100, "dumpAll")
            wait(1000)
            self:setColor(0.4, 0.4, 1, 0.1)
            btnMutexTemp1 = false
        end
    end)
    event.listen(btnTemp1)
end

local indError

function updateStatus()
    local err = 0
    local ok = 0
    local warning = 0
    local brightness = 1
    local arp = getARP()
    for _,v in pairs(arp) do
        local _x = x
        if v.address == _ then
            if v.resetting then
                warning = warning + 1
            elseif v.online then
                ok = ok + 1
            else
                warning = warning + 1;
            end
            if v.errored then
                err = err + 1
            end
        end
    end
    if scriptInfo.stopping or err > 0 then
        indError:setColor(1, 0.1, 0.1, brightness)
    elseif scriptInfo.resetting or warning > 0 then
        indError:setColor(1, 1, 0.1, brightness)
    elseif ok > 0 then
        indError:setColor(0, 0.5, 0.0, brightness)
    else
        indError:setColor(1, 0.5, 0.0, brightness)
    end
    for k,v in pairs(managerPanelIndexReservations) do
        local r = arp[k]
        if r == nil then
            v.indStatus:setColor(0,0,0,0)
        elseif r.errored then
            v.indStatus:setColor(1,0,0,0.8)
        elseif r.resetting then
            v.indStatus:setColor(0.7,0.7,0,0.6)
        elseif r.online then
            v.indStatus:setColor(0,0.7,0,0.6)
        else
            v.indStatus:setColor(1,0.5,0,0.6)
        end
    end
end


function initAuxPanels()
    if scriptInfo.auxPanel then
        print("Initializing aux panel: " .. scriptInfo.auxPanel)
        local panels = component.proxy(component.findComponent(scriptInfo.auxPanel))
        for _,k in pairs(panels) do
            print(" * Panel found: " .. k.id)

            local modules = k:getModules()
            printArray(modules, 1)

            indError = k:getXModule(5)
            local btnResetAll = k:getXModule(0)
            local btnUnused1 = k:getXModule(1)
            local btnUnused2 = k:getXModule(2)
            local btnUnused3 = k:getXModule(3)
            local btnUnused4 = k:getXModule(4)

            --setCommandLabelText(k, 5, "Status", false)
            --setCommandLabelText(k, 2, "N/U", false)
            --setCommandLabelText(k, 1, "N/U", false)
            --setCommandLabelText(k, 0, "Reset All", false)

            indError:setColor(0.1, 0.1, 0.1, 0)
            btnUnused1:setColor(0,0,0,0)
            btnUnused2:setColor(0,0,0,0)
            btnUnused3:setColor(0,0,0,0)
            btnUnused4:setColor(0,0,0,0)
            initModularButton(
                    btnResetAll,
                    function(self, msg, params)
                        self:setColor(0, 0, 1, 0.01)
                        scriptInfo.network:broadcast(getAdminPort(), "resetAll")
                        wait(1000)
                        self:setColor(0, 0, 1, 0)
                    end,
                    rgba(0, 0, 1, 0)
            )
            event.listen(btnResetAll)

            periodicStuff:push({
                func = function()
                    updateStatus()
                end,
                ref = indError
            })
        end
    end
end

function initEmgStops()
    local panels = component.findComponent("EmgStop")
    for _,panelID in pairs(panels) do
        local panel = component.proxy(panelID)
        if panel then
            local emgButton = panel:getModule(0,0)
            if emgButton then
                registerEvent(emgButton, panel, function(self, params)
                    print(tostring(self))
                    print(self.nick .. " pressed")
                    local nick_ = explode(" ", self.nick)
                    printArray(nick_)
                    print("'" .. nick_[2] .. "'")
                    if nick_[2] == "ProdMgr" then
                        rwarning("Stopping Production Manager")
                        scriptInfo.network:send("B0FB35C4420EA149FC17A29793CF765B", getAdminPort(), "stop")
                    elseif nick_[2] == "BusMgr" then
                        rwarning("Stopping Bus Manager")
                        scriptInfo.network:send("B35461CC45566F0ED431BC9CA6DB10B9", getAdminPort(), "stop")
                    elseif nick_[2] == "InvMgr" then
                        rwarning("Stopping Inventory Manager")
                        scriptInfo.network:send("952B4E8C4EE276DBF4C2DF9C9057F888", getAdminPort(), "stop")
                        scriptInfo.network:send("F3E5BCC346FF7360CCFB49990E6286D0", getAdminPort(), "stop")
                    elseif nick_[2] == "CraftMgr" then
                        rwarning("Stopping Craft Managers")
                        scriptInfo.network:send("044449754E55E78F1F68C7BEEEE4F5BC", getAdminPort(), "stop")
                        scriptInfo.network:send("CB45FD7C49685AB8A406A88F0E612EDE", getAdminPort(), "stop")
                        scriptInfo.network:send("52ABCDD5473B394013185B952ACA3428", getAdminPort(), "stop")
                        scriptInfo.network:send("3297C0E4474C7FFFEB18E9A1F973223B", getAdminPort(), "stop")
                        scriptInfo.network:send("B94653BD4B1C60A74BF4229CF32C7F0F", getAdminPort(), "stop")
                        scriptInfo.network:send("AC08B114472DB6FFCDFB3CA257497D61", getAdminPort(), "stop")
                    elseif nick_[2] == "All" then
                        rwarning("Stopping All Computers")
                        scriptInfo.network:broadcast(getAdminPort(), "stopAll")
                    end
                end)
                event.listen(emgButton)
            else
                error("No Button for " .. panel.nick)
            end

        else
            error("No panel " .. panelID)
        end
    end
end

local pingEvery = 10000
local pingTimeout = 15000

local pingScheduler = {
    func = function(self)
        local time = computer.millis()
        if time - self.lastPing > pingEvery then
            scriptInfo.network:broadcast(10, "ping", tostring(computer.millis()))
            self.lastPing = time
            for _,v in pairs(getARP()) do
                if v.address == _ then
                    if time - v.lastPing > pingTimeout then
                        v.online = false
                    end
                end
            end
        end
    end,
    lastPing = computer.millis(),
    ref = nil
}
pingScheduler.ref = pingScheduler

periodicStuff:push(pingScheduler)




function main()
    initNetwork()

    initEmgPanel()

    initAuxPanels()

    initEmgStops()

    initComputerManagerPanels()

    updateStatus()
    --initPanel()
    --initNetworkControlPanel()

    rmessage("System Operational")

    schedulePeriodicTask(PeriodicTask.new( function()
        print("Update UI")
        printScreen()
        updateStatus()
    end, nil, 1000))

    commonMain(10, 0.5)

end