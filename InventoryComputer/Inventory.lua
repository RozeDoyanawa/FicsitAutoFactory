--
-- Created by IntelliJ IDEA.
-- User: Roze
-- Date: 2020-08-22
-- Time: 09:53
-- To change this template use File | Settings | File Templates.
--

local dev = component.proxy(component.findComponent("Inventory Computer Network Adapter")[1])
scriptInfo.name = "Inventory"
scriptInfo.network = dev
scriptInfo.debugging = true
if dev then
    dev:open(100)
    event.listen(dev)
else
    print ("No such adapter")
end

screens.init("Inventory", 1, 1, 100, 45)

local panel = component.proxy(component.findComponent("Inventory Panel 1")[1])

local autoCraft = false

local busses = {
    A = {
        name = "A",
        request = function(self, item, count)
            rmessage("Send for " .. tostring(count) .. " " .. item .. " from A")
            scriptInfo.network:send(itemManagerAddress, 100, "order", item, count, self.name)
        end
    },
    --B = {
    --    name = "B",
    --    request = function(self, item, count)
    --        rmessage("Send for " .. tostring(count) .. " " .. item .. " from B")
    --        scriptInfo.network:send(itemManagerAddress, 100, "order", item, count, self.name)
    --    end
    --},
}

local userPuller = getBus("Puller_B_User")
if not userPuller then
    rerror("User Puller is null!")
end

local addressToSystems = {
    ["667B553E4C69859C89B0B4A4F3D9D3A7"] = craftSystems.Crafting,
    ["2ACBF2BB40D9E7FB393FD5972D1A2A48"] = craftSystems.Smelting,
    ["00A40EEE4356018B3366B8BD380C73F2"] = craftSystems.CraftingT2,
    ["5A16F0B541A433104F846B8FDA2A4650"] = craftSystems.CraftingT3,
    ["DFEBAB504E31B927CDEB7E9432F64B96"] = craftSystems.Fluids,
}

local defaultProcess = nil --craftSystems.Crafting


local processes = {
}

local defaultUserMaintain = "stacks"
local defaultSystemMaintain = "stacks"
local stacksToMaintain = 10
local systemStacksToMaintain = 5

local items = {
    ["Iron Ingot"] = {
        system = craftSystems.Smelting,
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        craftDependencies = false,
    },
    ["Copper Ingot"] = {
        system = craftSystems.Smelting,
        userMaintain = defaultUserMaintain,
        craftDependencies = false,
        maintain = defaultSystemMaintain
    },
    ["Caterium Ingot"] = {
        system = craftSystems.Smelting,
        userMaintain = defaultUserMaintain,
        craftDependencies = false,
    },
    ["Steel Ingot"] = {
        system = craftSystems.Smelting,
        craftDependencies = false,
        userMaintain = defaultUserMaintain,
        maintain = defaultSystemMaintain,
        treshold = 50
    },
    ["Limestone"] = {
        --noReserve = true,
        userMaintain = defaultUserMaintain,
        noCrafting = true,
    },
    ["Raw Quartz"] = {
        --noReserve = true,
        userMaintain = defaultUserMaintain,
        noCrafting = true,
    },
    ["Screw"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 1000,
        maxOrder = 400
    },
    ["Iron Plate"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 50,
        maxOrder = 50
    },
    ["Steel Beam"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 10,
        maxOrder = 10
    },
    ["Steel Pipe"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 10,
        maxOrder = 10
    },
    ["Reinforced Iron Plate"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 10,
        maxOrder = 10
    },
    ["Modular Frame"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 10,
        maxOrder = 10
    },
    ["Encased Industrial Beam"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 50,
        maxOrder = 25
    },
    ["Wire"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 1000,
        maxOrder = 200
    },
    ["Quickwire"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 1000,
        maxOrder = 200
    },
    ["Cable"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 30,
        maxOrder = 50
    },
    ["Concrete"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 66,
        maxOrder = 33,
    },
    ["Silica"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 100,
        maxOrder = 100,
    },
    ["Rotor"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 100,
        maxOrder = 100,
        recipeName = "Alternate: Steel Rotor"
    },
    ["Stator"] = {
        userMaintain = defaultUserMaintain,
        maintain = defaultSystemMaintain,
        treshold = 50,
        maxOrder = 15,
    },
    ["Motor"] = {
        maintain = defaultSystemMaintain,
        treshold = 30,
        userMaintain = defaultUserMaintain,
        maxOrder = 15,
    },
    ["Encased Industrial Beam"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 60,
        maxOrder = 20,
    },
    ["Heavy Modular Frame"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 50,
        maxOrder = 6,
    },
    ["Crystal Oscillator"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 30,
        maxOrder = 10,
    },
    ["Copper Sheet"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 100,
        maxOrder = 50,
    },
    ["Empty Canister"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 100,
        maxOrder = 50,
    },
    ["Plastic"] = {
        maintain = defaultSystemMaintain,
        userMaintain = defaultUserMaintain,
        treshold = 120,
        maxOrder = 60,
    },
    ["Circuit Board"] = {
        maintain = defaultSystemMaintain,
        treshold = 90,
        maxOrder = 45,
        userMaintain = defaultUserMaintain,
        recipeName = "Alternate: Silicone Circuit Board"
    },
    ["Computer"] = {
        maintain = defaultSystemMaintain,
        treshold = 10,
        maxOrder = 10,
        userMaintain = 5,
        recipeName = "Alternate: Caterium Computer"
    },
    ["High-Speed Connector"] = {
        maintain = defaultSystemMaintain,
        treshold = 4,
        maxOrder = 8,
        userMaintain = 30,
    },
    ["Rubber"] = {
        maintain = defaultSystemMaintain,
        treshold = 120,
        maxOrder = 60,
        userMaintain = defaultUserMaintain,
    },
    ["Packaged Water"] = {
        noCrafting = true,
        maintain = defaultSystemMaintain,
        treshold = 100,
        maxOrder = 50,
        userMaintain = defaultUserMaintain,
        topup = component.proxy(component.findComponent("TopUp_Packaged Water")[1])
    },
    ["Packaged Oil"] = {
        noCrafting = true,
        maintain = defaultSystemMaintain,
        treshold = 100,
        maxOrder = 50,
        userMaintain = defaultUserMaintain,
        topup = component.proxy(component.findComponent("TopUp_Packaged Oil")[1])
    }

}

for name,item in pairs(items) do
    if item.userMaintain == "stacks" then
        local stacks = stacksToMaintain
        if item.userStacks then
            stacks = item.userStacks
        end
        if stackSize[name] then
            item.userMaintain = stackSize[name] * stacks
        else
            error("No stack size for " .. name .. ", cant set user maintain")
            item.userMaintain = nil
        end
    end
    if item.maintain == "stacks" then
        local stacks = systemStacksToMaintain
        if item.maintainStacks then
            stacks = item.maintainStacks
        end
        if stackSize[name] then
            item.maintain = stackSize[name] * stacks
        else
            error("No stack size for " .. name .. ", cant set user maintain")
            item.maintain = nil
        end
    end
end

--function processOutputs()
--    for _,resource in pairs(items) do
--        if not resource.processOutputs then
--            error(resource.name .. " is missing outputs")
--        end
--        resource:processOutputs()
--    end
--end


local button = panel:getModule(0, 10)
button:setColor(0,0,0,0)
registerEvent(button, button, function(self, evt)
    if autoCraft then
        autoCraft = false
        self:setColor(0, 0, 0, 0)
    else
        autoCraft = true
        self:setColor(0, 1, 0, 5)
        processMaintained()
    end
end)
event.listen(button)
local button = panel:getModule(0, 2)
button:setColor(0.3,0.3,0.3,0)
registerEvent(button, button, function(self, evt)
    items["Copper Ingot"]:request(1, "B")
end)
event.listen(button)
local button = panel:getModule(0, 4)
button:setColor(0.3,0.3,0.3,0)
registerEvent(button, button, function(self, evt)
    items["Copper Ingot"]:request(1, "A")
end)
event.listen(button)
local button = panel:getModule(2, 2)
button:setColor(0.3,0.3,0.3,0)
registerEvent(button, button, function(self, evt)
    items["Iron Ingot"]:request(1, "B")
end)
event.listen(button)
local button = panel:getModule(2, 4)
button:setColor(0.3,0.3,0.3,0)
registerEvent(button, button, function(self, evt)
    items["Iron Ingot"]:request(1, "A")
end)
event.listen(button)
local button = panel:getModule(4, 2)
button:setColor(0.3,0.3,0.3,0)
registerEvent(button, button, function(self, evt)
    items["Wire"]:request(1, "B")
end)
event.listen(button)


local button = panel:getModule(4, 4)
button:setColor(0.3,0.3,0.3,0)
registerEvent(button, button, function(self, evt)
    items["Wire"]:request(1, "A")
end)
event.listen(button)

local button = panel:getModule(6, 6)
button:setColor(0.3,0.3,0.3,0)
registerEvent(button, button, function(self, evt)
    items["Rubber"]:request(60, "Store")
end)
event.listen(button)

local button = panel:getModule(7, 6)
button:setColor(0.3,0.3,0.3,0)
registerEvent(button, button, function(self, evt)
    items["Plastic"]:request(60, "Store")
end)
event.listen(button)

local button = panel:getModule(8, 6)
button:setColor(0.3,0.3,0.3,0)
registerEvent(button, button, function(self, evt)
    items["Computer"]:request(2, "User")
end)
event.listen(button)

function userOrderComplete(resource)
    resource.userOrder = false
end

function processMaintained()
    if autoCraft then
        for _,item in pairs(items) do
            if item.maintain then
                local has = item.amount - item.reserved + item.inProduction
                --print ( item.name)
                --print ("Has: " .. tostring(has))
                if has < item.maintain then
                    if item.maintain - has > item.treshold then
                        local missing = item.maintain - has
                        --print ("Missing: " .. tostring(missing))
                        if missing > 0 then
                            local toOrder = missing
                            if toOrder > item.maxOrder then
                                toOrder = item.maxOrder
                            end
                            item:order(toOrder)
                            missing = missing - toOrder
                            computer.skip()
                        end
                    end
                end
            end
            if item.userMaintain and item.userContainer and not item.userOrder then
                local has = item.userContainer:getInventories()[1].ItemCount
                if has < item.userMaintain then
                    if item.userMaintain - has > item.treshold then
                        local missing = item.userMaintain - has
                        --print ("Missing: " .. tostring(missing))
                        if missing > 0 then
                            local toOrder = missing
                            if toOrder > item.maxOrder then
                                toOrder = item.maxOrder
                            end
                            --print(item.name.. ":Request(".. tostring(toOrder) ..", \"User\", func)")
                            item.userOrder = true
                            item:request(toOrder, "User", userOrderComplete)
                            missing = missing - toOrder
                            computer.skip()
                        end
                    end
                end
            end
            computer.skip()
        end
    end
end

function createItem(sourceSplitter, resourceName, mode)
    --print("Creating item: " .. resourceName)
    local _t = component.findComponent("User_" .. resourceName)
    local userContainer = nil
    if _t and _t[1] then
        userContainer = component.proxy(_t[1])
    end
    local resource = {
        sourceSplitter = sourceSplitter,
        name = resourceName,
        busOutputs = {},
        requestOutput = 1,
        container = component.proxy(component.findComponent("Store_" .. resourceName)[1]),
        amount = 0,
        inProduction = 0,
        future = 0,
        reserved = 0,
        treshold = 50,
        recipeName = resourceName,
        craftDependencies = true,
        userContainer = userContainer,
        system = defaultProcess,
        requestQueue = createLinkedList(),
        processOutputs = function(self)
            local req = self.requestQueue.first
            local item = self.sourceSplitter:getInput()
            if item then
                if req then
                    if self.sourceSplitter:transferItem(req.value.output) then
                        req.value.count = req.value.count - 1
                        if self.reserved > 0 then
                            self.reserved = math.max(self.reserved - 1, 0 )
                        end
                        if req.value.count <= 0 then
                            if req.value.callback then
                                req.value.callback(self)
                            end
                            req:delete()
                        end
                        return 1
                    end
                --else
                    --if self.sourceSplitter:canOutput(self.requestOutput) then
                       -- self.sourceSplitter:transferItem(self.requestOutput)
                    --    return 1
                    --end
                end
            end
            return 0
        end,
        order = function(self, count)
            if not self.noCrafting then
                if self.system and craftSystems[self.system.name] then
                    local amount = count
                    while amount > 0 do
                        local toOrder = amount
                        if self.maxOrder and toOrder > self.maxOrder then
                            toOrder = self.maxOrder
                        end
                        rdebug("Raw order for " .. tostring(count) .. " " .. self.name)
                        craftSystems[self.system.name]:order(self.recipeName, toOrder)
                        amount = amount - toOrder
                        self.inProduction = self.inProduction + toOrder
                    end
                else
                    rerror("No craft system for " .. self.name)
                end
            end
        end,
        request = function(self, count, output, callback, purpouse)
            rdebug("Resquest to deliver " .. tostring(count) .. " " .. self.name .. " to " .. (output or "nil") )
            local req = {
                count = count,
                callback = callback
            }
            local o = self.requestOutput
            if output and self.busOutputs[output] then
                o = self.busOutputs[output]
            end
            req.output = o
            self.requestQueue:push(req)
            local reserved = self.reserved
            if self.noReserve == nil or self.noReserve == false then
                self.reserved = self.reserved + count
            end
            rdebug( "s.a = " .. tostring(self.amount) .. ", s.ip = " .. tostring(self.inProduction) .. ", s._r_b = " .. tostring(reserved) .. ", s._r = " .. tostring(self.reserved))
            local available = self.amount + self.inProduction - reserved
            rdebug("  * Have " .. tostring(available) .. "")
            if not self.noCrafting and available < count then
                local missing = count - available
                if self.craftDependencies and self.dependencies then
                    local _count = 1
                    if self.produces then
                        _count = math.ceil(missing / self.produces)
                    end
                    for _,dep in pairs(self.dependencies) do
                        if items[dep.name] then
                            local i2 = items[dep.name]
                            if i2.amount + i2.inProduction - i2.reserved < _count * dep.count then
                                local ia = _count * dep.count - (i2.amount + i2.inProduction - i2.reserved)
                                if not i2.noCrafting then
                                    --i2.future = i2.future + ia
                                end
                                i2:order(ia)
                            end
                        else
                            rwarning("No store for " .. dep.name .. ", cannot produce")
                        end
                    end
                end
                rdebug("  * Need to craft " .. tostring(missing) .. "")
                if craftSystems[self.system.name] then
                    while missing > 0 do
                        local toOrder = missing
                        if toOrder > self.maxOrder then
                            toOrder = self.maxOrder
                        end
                        if toOrder == 0 then
                            error("Null order?")
                        end
                        craftSystems[self.system.name]:order(self.recipeName, toOrder, purpouse)
                        missing = missing - toOrder
                        self.inProduction = self.inProduction + toOrder
                    end
                else
                    rerror("No craft system for " .. self.system.name)
                end
            end
            self:processOutputs()
        end,
        print = function(self)
            for k,v in pairs(self) do
                --print( tostring(k) .. " = " .. tostring(v))
            end
        end
    }
    if not resource.container then
        error("Missing container for " .. resource.name)
    end
    local connectors = resource.container:getFactoryConnectors()
    local connectorIn
    local connectorIn2
    local connectorOut
    --
    --  Big Container:
    --      -----------------
    --      |               |
    -- 2 -> |               | -> 1
    --      |               |
    -- 4 -> |               | -> 3
    --      |               |
    --      -----------------
    --
    --  Small Container:
    --      -----------------
    --      |               |
    -- 2 -> |               | -> 1
    --      |               |
    --      -----------------
    --
    resource.addFunction = function(self)
        --print(resource.name .. ":Connector In")
        self.amount = self.amount + 1
        if not self.topup then
            self.inProduction = math.max(self.inProduction - 1, 0)
        end
        --error("Container In!")
    end
    resource.subtractFunction = function(self)
        --print(resource.name .. ":Connector Out")
        --print("Item subtract")
        --self:print()
        self.amount = self.amount - 1
        --error("Container Out!")
    end
    if connectors[1] and connectors[2] and connectors[3] and connectors[4] then
        connectorIn = resource.container:getFactoryConnectors()[2]
        connectorOut = resource.container:getFactoryConnectors()[3]
        connectorIn2 = resource.container:getFactoryConnectors()[4]
    elseif connectors[1] and connectors[2] then
        connectorIn = resource.container:getFactoryConnectors()[2]
        connectorOut = resource.container:getFactoryConnectors()[1]
    end
    registerEvent(connectorIn, resource, resource.addFunction)
    event.listen(connectorIn)
    if connectorIn2 then
        registerEvent(connectorIn2, resource, resource.addFunction)
        event.listen(connectorIn2)
    end
    registerEvent(connectorOut, resource, resource.subtractFunction)
    event.listen(connectorOut)
    --registerEvent(resource.sourceSplitter, resource, function(self)
    --    self:processOutputs()
    --    --error("Splitter event!")
    --end)
    --event.listen(resource.sourceSplitter)
    splitters:push({
        reference = resource.sourceSplitter,
        instance = resource,
        callback = resource.processOutputs
    })

    resource.amount = resource.container:getInventories()[1].ItemCount
    if mode == "M1" then
        resource.busOutputs["A"] = 0
        resource.busOutputs["B"] = 2
    elseif mode == "M2" then
        resource.busOutputs["A"] = 2
        resource.busOutputs["B"] = 0
    elseif mode == "M3" then
        resource.busOutputs["A"] = 1
        resource.busOutputs["B"] = 2
        resource.requestOutput = 0
    elseif mode == "M4" then
        resource.busOutputs["A"] = 0
        resource.busOutputs["B"] = 1
        resource.requestOutput = 2
    end
    if resourceName == "Copper Ingot" then
        resource:print()
    end

    if items[resourceName] then
        local _item = items[resourceName]
        for k,v in pairs(_item) do
            resource[k] = v
        end
    end
    if resource.topup then
        print("Resource " .. resource.name .. " has topup system")
        resource.processOutputTopup = function(self)
            local item = self.topup:getInput()
            if item then
                --print(self.name .. " topup amount = " .. tostring(self.amount) .. ", maintain = " .. tostring(self.maintain))
                if self.amount < self.maintain then
                    if self.topup:transferItem(1) then
                        return 1
                    end
                end
            end
            return 0
        end
        splitters:push({
            reference = resource.topup,
            instance = resource,
            callback = resource.processOutputTopup
        })
    end
    items[resourceName] = resource
end

function enumItems()
    local allComponents = component.findComponent("")
    for _,v in pairs(allComponents) do
        local comp = component.proxy(v)
        local p = explode("_", comp.nick)
        if p[1] == "Source" and p[2] then
            createItem(comp, p[2], p[3])
        end
       --
    end

    for _,system in pairs(craftSystems) do
        scriptInfo.network:send(system.address, 100, "enumRecipes")
    end

end

rmessage("Computer started")


local lastProcessedSplitter = nil

function processOutputs()
    if lastProcessedSplitter == nil then
        lastProcessedSplitter = splitters.first
    end
    local j = 0
    local r = 0
    while lastProcessedSplitter do
        --processSplitterOutput(lastProcessedSplitter.value.object, lastProcessedSplitter.value.reference)
        r = r + lastProcessedSplitter.value.callback(lastProcessedSplitter.value.instance)
        lastProcessedSplitter = lastProcessedSplitter.next
        j = j + 1
        if j == 10 then
            break
        end
    end
    return r
end

enumItems()

function printScreen()
    local x = 0
    local y = 0
    local c = 40
    screens:clear()
    screens:setForeground(0.7,0.7,0.7,1)
    screens:print(x, y, "Item register: ");
    if autoCraft then
        screens:setForeground(0.3,1,0.3,1)
        screens:print(x + 16, y, "Auto on");
    else
        screens:setForeground(0.3,0.3,0.3,1)
        screens:print(x + 16, y, "Auto off");
    end
    y = y + 1
    x = 2
    for k,item in pairs(items) do
        if item.maintain then
            screens:setForeground(0.5,1,0.5,1)
        else
            screens:setForeground(0.7,0.7,0.7,1)
        end
        screens:print(x, y, item.name)
        if item.amount == 0 then
            if item.maintain then
                screens:setForeground(1,0.3,0.3,1)
            else
                screens:setForeground(1,0.3,0.3,1)
            end
        elseif item.amount > 0 then
            if item.maintain and item.amount < item.maintain then
                screens:setForeground(1,1,0.5,1)
            else
                screens:setForeground(0.4,1,0.4,1)
            end
        else
            screens:setForeground(1,0.3,1,1)
        end
        local l = string.len(item.name)
        if l < 28 then
            l = 28
        end
        screens:print(x + l + 2, y, string.format("%5d", item.amount))
        screens:setForeground(0.7,0.7,0.7,1)
        if item.userContainer then
            screens:print(x + l + 7, y, "/");
            screens:setForeground(0.5,0.5,1,1)
            screens:print(x + l + 8, y, string.format("%5d", item.userContainer:getInventories()[1].ItemCount))
        end
        --screens:print(x + l + 7, y, "/")
        --screens:setForeground(0.3,0.3,1,1)
        --screens:print(x + l + 8, y, string.format("%5d", item.container:getInventories()[1].ItemCount));
        x,y = gColumnAdvance(x, y, c)
        local x2 = x + 2
        local x3 = x2
        if item.inProduction > 0 then
            screens:setForeground(0.7,0.7,0.7,1)
            screens:print(x2, y, "+")
            screens:setForeground(0.3,0.3,1,1)
            screens:print(x2 + 1, y, string.format("%4d", item.inProduction))
            x2 = x2 + 6
        end
        if item.reserved > 0 then
            screens:setForeground(0.7,0.7,0.7,1)
            screens:print(x2, y, "-")
            screens:setForeground(0.3,0.3,1,1)
            screens:print(x2 + 1, y, string.format("%4d", item.reserved))
            x2 = x2 + 6
        end
        local t = item.requestQueue.first
        if t ~= nil then
            screens:setForeground(0.7,0.7,0.7,1)
            screens:print(x2, y, ">")
            screens:setForeground(0.3,0.3,1,1)
            screens:print(x2 + 1, y, string.format("%4d", t.value.count))
            x2 = x2 + 6
        end
        if x2 > x3 then
            x,y = gColumnAdvance(x, y, c)
        end
        item = item.next
    end
    screens:flush()
end

local requests = {}
local freeRequests = createLinkedList()
local nextRequestID = 1

networkHandler(100, function(self, address, parameters, parameterOffset)  -- Initiate handler for port 100
    local msg = parameters[parameterOffset] -- extract message identifier
    --print(msg)
    if msg and self.subhandlers[msg] then  -- if msg is not nil and we have a subhandler for it
        local handler = self.subhandlers[msg] -- put subhandler into local variable for convenience
        handler(address, parameters, parameterOffset + 1) -- call subhandler
    elseif not msg then -- no handler or nil message
        print ("No message identifier defined")
    else
        print ("No handler for " .. parameters[parameterOffset])
    end
end, { -- table of message handlers
    order = function(address, parameters, po)
        local resourceName = parameters[po]
        local count = parameters[po + 1]
        local bus = parameters[po + 2]
        local purpouse = parameters[po + 3]
        if items[resourceName] then
            if not bus then
                rerror("Bus cant be nil")
            elseif bus == "Internal" then
                items[resourceName]:order(count)
            else
                items[resourceName]:request(count, bus, nil, purpouse)
            end
        else
            rerror("No such resource available: " .. resourceName)
        end
    end,
    orderUser = function(address, parameters, po)
        local resourceName = parameters[po]
        local count = parameters[po + 1]
        if items[resourceName] then
            userPuller:request(resourceName, count, "UserCollectable")
        else
            rerror("No such resource available: " .. resourceName)
        end
    end,
    craftable = function(address, parameters, po)
        local name = parameters[po]
        if items[name] and items[name].noCrafting then
            scriptInfo.network:send(address, 100, "craftableResponse", name, true, items[name].maxOrder)
        else
            scriptInfo.network:send(address, 100, "craftableResponse", name, false)
        end
    end,
    recipe = function(address, parameters, po)
        --for _,p in pairs(parameters) do
         --   print(_ .. " = " .. p)
        --end
        local name = parameters[po]
        local recipeName = parameters[po + 4]
        local ingredientCount = parameters[po + 1]
        local dependencies = {}
        local data = parameters[po + 1]
        local _dep = explode("|", data)
        local produce = parameters[po + 3]
        local maxMultiplier = 1
        local currentIndex = parameters[po + 2]
        --print ("Index: " .. tostring(currentIndex) .. " - " .. name)
        if items[name] and items[name].recipeName == recipeName then
            for _,_s in pairs(_dep) do
                local _i = explode("#", _s)
                local depName = _i[1]
                dependencies[depName] = {
                    name = depName,
                    count = tonumber(_i[2])
                }
            end
            local breakLoop = false
            while true do
                for _,_s in pairs(dependencies) do
                    if stackSize[_s.name] and _s.count * maxMultiplier > stackSize[_s.name] then
                        maxMultiplier = maxMultiplier - 1
                        breakLoop = true
                        break
                    elseif not stackSize[_s.name] then
                        error("No stack size for " .. _s.name)
                    end
                    computer.skip()
                end
                if breakLoop then
                    break
                end
                maxMultiplier = maxMultiplier + 1
            end
            --print(addressToSystems[address].name)
            items[name].system = addressToSystems[address]
            items[name].produces = produce
            items[name].dependencies = dependencies
            --if name == "Rubber" then
            --    for _,p in pairs(parameters) do
            --       print(_ .. " = " .. p)
            --    end
            --    error()
            --end
            --rdebug("Max craft size for "..name.. " determined to " .. tostring(maxMultiplier * produce))
            items[name].maxOrder = maxMultiplier * produce
            if items[name].treshold == nil then
                items[name].treshold = items[name].maxOrder
            end
        else
            --print (data)
            --print("Ignoring recipe " .. name .. " by recipe " .. recipeName .. ", no store")
        end
        scriptInfo.network:send(address, 100, "sendNextRecipe", currentIndex + 1)
    end,
    enumRecipesDone = function(address, parameters, po)
        --error("Meow?")
        --for _,v in pairs(items["Iron Rod"].dependencies) do
        --    print("dep: ".. _ .. " = " .. tostring(v.count))
        --end
        --print(items["Screw"].produces)
        rmessage("Recieved " .. tostring(parameters[po]) .. " from " .. parameters[po + 1])
    end,
    enumItems = function(address, parameters, po)
        local requestID = freeRequests.first
        if not requestID then
            requestID = nextRequestID
            nextRequestID = nextRequestID + 1
        end
        requests[requestID] = {}
        local request = requests[requestID]
        request.items = {}
        request.next = 1
        request.count = 0
        for _,item in pairs(items) do
            table.insert(request.items, item.name)
            request.count = request.count + 1
        end
        sendNextItem(address, requestID)
    end,
    nextItem = function(address, parameters, po)
        local requestID = parameters[po]
        sendNextItem(address, requestID)
    end
})

function sendNextItem(address, requestID)
    local request = requests[requestID]
    if request then
        do
            repeat
                local item = items[request.items[request.next]]
                if item then
                    request.next = request.next + 1
                    if not item.noCrafting then
                        local data = "data"
                        data = data .. "|maxOrder#" .. tostring(item.maxOrder) .. "|i"
                        data = data .. "|system#" .. tostring(item.system.name)
                        data = data .. "|amount#" .. tostring(item.amount).. "|i"
                        if item.maintain then
                            data = data .. "|maintain#" .. tostring(item.maintain) .. "|i"
                        end
                        if item.userMaintain then
                            data = data .. "|userMaintain#" .. tostring(item.userMaintain).. "|i"
                        end
                        if item.userContainer then
                            data = data .. "|userContainer#" .. tostring(item.userContainer.id)
                        end
                        if item.container then
                            data = data .. "|systemContainer#" .. tostring(item.container.id)
                        end

                        scriptInfo.network:send(address, 100, "item", requestID, item.name, data)
                        return
                    end
                else
                    scriptInfo.network:send(address, 100, "itemListingEnded")
                end
            until(not item)
        end
    else
        rerror("Unknown request")
    end
end

local seldomCounter = 0
local nilCounter = 0
local timeout = 1

while true do
    local result = {event.pull(timeout) }
    local status, err
    if result[1] then
        timeout = 0
        nilCounter = 0
        --print("Timeout reset")
    elseif nilCounter == 1000 then
        timeout = 1
        --print("Slow Timeout")
    else
        nilCounter = nilCounter + 1
    end
    status, err = pcall(processEvent, result)
    if not status and err then
        rerror("Error in processEvent; ".. tostring(err))
        error(err)
    end
    --processOutputs()
    status, err = pcall(processOutputs)
    if not status and err then
        rerror("Error in processOutputs; "..tostring(err))
        error(err)
    elseif status and err > 0 then
        nilCounter = 0
        timeout = 0
        --print("Timeout reset 2")
    end
    if timeout == 1 or seldomCounter <= 0 then
        status, err = pcall(processMaintained)
        if not status and err then
            rerror("Error in processMaintained; "..tostring(err))
            error(err)
        end
        printScreen()
        --local status, err = pcall(printScreen)
        if not status and err then
            rerror("Error in print; ".. tostring(err))
            error(err)
        end
        seldomCounter = 1000
    else
        seldomCounter = seldomCounter - 1
    end
end

