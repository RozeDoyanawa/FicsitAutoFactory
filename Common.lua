local eventHandlers = {}

local ADMIN_PORT = 10
local ARP = {}

function getAdminPort()
    return ADMIN_PORT
end

function getARP()
    return ARP
end



lineHeight = 1

itemForms = {
    Solid = 1,
    Fluid = 2,
    Gas = 3,
    Heat = 4
}
scriptInfo.resetting = false
scriptInfo.stopping = false



---@class FluidType
---@field public name string @Fluid name
---@field public unpack string @Recipe name for unpacking
---@field public pack string @Recipe name for packing
---@field public packaged string @Packaged name of product
---@field public unpackCount string @Amount received on unpack
local FluidType = {}

---@param name string @Fluid name
---@param unpack string @Recipe name for unpacking
---@param pack string @Recipe name for packing
---@param packaged string @Packaged name of product
---@param unpackCount string @Amount received on unpack
---@return FluidType
function FluidType.new(name, unpack, pack, packaged, unpackCount)
    ---@type FluidType
    local c = {}
    c.name = name
    c.unpack = unpack
    c.pack = pack
    c.unpackCount = unpackCount
    c.packaged = packaged
    return c
end

---@type table<string, FluidType>
local fluidTypes = {
    ["Heavy Oil Residue"] = FluidType.new(
        "Heavy Oil Residue",
        "Roze Unpackage Heavy Oil Residue",
        "Packaged Heavy Oil Residue",
        "Packaged Heavy Oil Residue",
        2
    ),
    ["Water"] = FluidType.new(
        "Water",
        "Roze Unpackage Water",
        "Packaged Water",
        "Packaged Water",
        2
    ),
    ["Crude Oil"] = FluidType.new(
        "Crude Oil",
        "Roze Unpackage Oil",
        "Packaged Oil",
        "Packaged Oil",
        2
    ),
    ["Fuel"] = FluidType.new(
        "Fuel",
        "Roze Unpackage Fuel",
        "Packaged Fuel",
        "Packaged Fuel",
        2
    ),
    ["Liquid Biofuel"] = FluidType.new(
        "Liquid Biofuel",
        "Roze Unpackage Liquid Biofuel",
        "Packaged Liquid Biofuel",
        "Packaged Liquid Biofuel",
        2
    ),
    ["Alumina Solution"] = FluidType.new(
        "Alumina Solution",
        "Roze Unpackage Alumina Solution",
        "Packaged Alumina Solution",
        "Packaged Alumina Solution",
        2
    ),
}



function fixFluids()
    local packedFluids  = {}
    for _,v in pairs(fluidTypes) do
        packedFluids[v.packaged] = v
    end

    for _,v in pairs(packedFluids) do
        fluidTypes[_] = v
    end
end

fixFluids()


---@return table<string, FluidType>
function getFluidTypes()
    return fluidTypes
end



stackSize = {
    ["Iron Ingot"] = 100,
    ["Copper Ingot"] = 100,
    ["Caterium Ore"] = 100,
    ["Caterium Ingot"] = 100,
    ["Steel Ingot"] = 90,
    ["Iron Plate"] = 100,
    ["Iron Rod"] = 100,
    ["Steel Beam"] = 100,
    ["Steel Pipe"] = 100,
    ["Quickwire"] = 500,
    ["Wire"] = 500,
    ["Cable"] = 100,
    ["Screw"] = 500,
    ["Copper Sheet"] = 100,
    ["Heavy Modular Frame"] = 50,
    ["Modular Frame"] = 50,
    ["Concrete"] = 100,
    ["Silica"] = 100,
    ["Iron Ore"] = 100,
    ["Copper Ore"] = 100,
    ["Uranium"] = 100,
    ["Coal"] = 100,
    ["Petroleum Coke"] = 100,
    ["Bauxite"] = 100,
    ["Quartz"] = 100,
    ["Limestone"] = 100,
    ["Encased Industrial Beam"] = 100,
    ["Plastic"] = 100,
    ["Rubber"] = 100,
    ["Crystal Oscillator"] = 100,
    ["Circuit Board"] = 200,
    ["High-Speed Connector"] = 100,
    ["Supercomputer"] = 50,
    ["Computer"] = 50,
    ["AI Limiter"] = 100,
    ["Rotor"] = 100,
    ["Motor"] = 50,
    --["Photovoltaic Cell"] = 10,
    ["Biomass"] = 100,
    ["Reinforced Iron Plate"] = 100,
    ["Quartz Crystal"] = 100,
    ["Raw Quartz"] = 100,
    ["Stator"] = 50,
    ["Empty Canister"] = 100,
    ["Crude Oil"] = 50,
    ["Heavy Oil Residue"] = 50,
    ["Sulfuric Acid"] = 50,
    ["Water"] = 50,
    ["Black powder"] = 100,
    ["Sulfur"] = 100,
    ["Carbon Mesh"] = 10,
    ["Carbon Dust"] = 10,
    ["Packaged Oil"] = 100,
    ["Packaged Water"] = 100,
    ["Packaged Heavy Oil Residue"] = 100,
    ["Packaged Fuel"] = 100,
    ["Packaged Alumina Solution"] = 100,
    ["Packaged Liquid Biofuel"] = 100,
    ["Packaged Sulfuric Acid"] = 100,
    ["Fuel"] = 100,
    ["Liquid Biofuel"] = 100,
    ["Alien Organs"] = 100,
    ["Alien Carapace"] = 100,
    ["Wood"] = 100,
    ["Mycelia"] = 100,
    ["Leaves"] = 500,
    ["Automated Wiring"] = 50,
    ["Smart Plating"] = 50,
    ["Modular Engine"] = 50,
    ["Versatile Framework"] = 50,
    ["Adaptive Control Unit"] = 50,
    ["Flower Petals"] = 200,
    ["Blue Power Slug"] = 50,
    ["Green Power Slug"] = 50,
    ["Yellow Power Slug"] = 50,
    ["Purple Power Slug"] = 50,
    ["FICSMAS Gift"] = 100,
    ["Polymer Resin"] = 200,
    ["Solid Biofuel"] = 200,
    ["Radio Control Unit"] = 50,
    ["Alumina Solution"] = 50,
    ["Aluminum Casing"] = 200,
    ["Aluminum Ingot"] = 100,
    ["Aluminum Scrap"] = 500,
    ["Aluminum Clad Sheet"] = 200,
    ["Alclad Aluminum Sheet"] = 200,
    ["Beacon"] = 100,
    ["Gunpowder"] = 50,
    ["Nobelisk"] = 50,
}


function rgba(r,g,b,a)
    ---@type RGBAColor
    local col = {}
    col.R = r
    col.G = g
    col.B = b
    col.A = a
    return col
end
local defaultAlpha = 1

scriptInfo.systemColors = {
    Normal = rgba(0.5, 0.5, 0.5, defaultAlpha),
    Number = rgba(0.1, 0.1, 0.5, defaultAlpha),
    White = rgba(1,1,1,defaultAlpha),
    Black = rgba(0,0,0,defaultAlpha),
    Blue = rgba(0,0,0.5, defaultAlpha),
    Green = rgba(0, 0.57, 0, defaultAlpha),
    LightRed = rgba(1, 0, 0, defaultAlpha),
    Brown = rgba(0.5, 0,0,defaultAlpha),
    Purple = rgba(0.61, 0, 0.61, defaultAlpha),
    Orange = rgba(0.99, 0.5, 0, defaultAlpha),
    Yellow = rgba(1, 1, 0, defaultAlpha),
    LightGreen = rgba(0, 0.99, 0, defaultAlpha),
    Cyan = rgba(0, 0.57, 0.57, defaultAlpha),
    LightCyan = rgba(0, 1, 1, defaultAlpha),
    LightBlue = rgba(0.4, 0.4, 0.99, defaultAlpha),
    Pink = rgba(1, 0, 1, defaultAlpha),
    Grey = rgba(0.5, 0.5, 0.5, defaultAlpha),
    LightGrey = rgba(0.83, 0.83, 0.83, defaultAlpha),
}

scriptInfo.addresses = {
    InvMgr1 = "952B4E8C4EE276DBF4C2DF9C9057F888",
    InvMgr2 = "",
    BusMgr = "B35461CC45566F0ED431BC9CA6DB10B9",
    ProdMgr = "B0FB35C4420EA149FC17A29793CF765B",
    LogMgr = "3825B51947382D003E6ADB8FA817DB0F"
}


function wait(millisToWait)
    local millis = computer.millis()
    while computer.millis() - millis < millisToWait do
        computer.skip()
    end
end


---@class EventData
---@field public instance any @Instance reference
---@field public reference string|Actor @The reference that was listened for
---@field public callback fun(
local EventData


---@param key string|Actor @The key to map this event to. Pass an Actor or a string
---@param instance any @The object that will be called as the self param to the callback function
---@param callback fun(instance:any, event:string, parameters:string[], parameterOffset:number) @The callback function
---@param triggerHandlers table<string,fun(instance:any, parameters:string[], parameterOffset:number)> @SubTriggers
function registerEvent(key, instance, callback, triggerHandlers, listen)
    computer.skip()
    local evt = {
        instance = instance,
        reference = key,
        callback = callback,
        triggers = triggerHandlers
    }
    if key and key.hash then
        --print("Registering event by hash: " .. key.hash)
        eventHandlers[key.hash] = evt
    else
        eventHandlers[key] = evt
    end
    if listen ~= nil and listen == true then
        if key and key.hash then
            event.listen(key)
        else
            error("Cant listen to a null component or a non component object")
        end
    end
end

function enum(tbl)
    local length = #tbl
    for i = 1, length do
        local v = tbl[i]
        tbl[v] = i
    end

    return tbl
end

function roundUp(numToRound, multiple)

    if multiple == 0 then
        return numToRound;
    end

    local remainder = numToRound % multiple;
    if remainder == 0 then
        return numToRound;
    end

    return numToRound + multiple - remainder;
end

function roundDown(numToRound, multiple)

    if multiple == 0 then
        return numToRound;
    end

    local remainder = numToRound % multiple;
    if remainder == 0 then
        return numToRound;
    end

    return numToRound - remainder;
end


---@type table<number, NetworkHandler>
local networkHandlers = {}

---@param port number @Remote Host Port
---@param func fun(address:string, parameters:table<number,string>|table<string,string>, parameterOffset:number)
---@param subhandlers table<string, fun(address:string, parameters:table<number,string>|table<string, string>, parameterOffset:number) @List of command handlers for the given port
function networkHandler(port, func, subhandlers) -- function for creating a handler
    if func == nil then
        func = defNetworkHandler
    end
    networkHandlers[port] = {
        func = func,
        subhandlers = subhandlers,
    }
end

local REFRESH_DELAY = 60000


ComponentReference = {}



---@return Actor
function ComponentReference:get()
    if self.object == nil or computer.millis() - self.lastFetch > REFRESH_DELAY then
        self.object = component.proxy(self.id)
        self.lastFetch = computer.millis()
    end
    return self.object
end

---@param networkID string
---@return ComponentReference
function ComponentReference.new(networkID)
    ---@type ComponentReference
    local t = {
        id = networkID,
        lastFetch = 0,
        object = nil
    }
    setmetatable(t, ComponentReference)
    ComponentReference.__index = ComponentReference
    return t
end

---@return ComponentReference
---@param stringID string
function createReference(stringID)
    --print("Create reference for " .. stringID)
    --local item = {
    --    id = stringID,
    --    object = nil,
    --    get = getReference,
    --    lastFetch = 0
    --}
    return ComponentReference.new(stringID)
end

--function getReference(reference)
--    if reference.object == nil or computer.millis() - reference.lastFetch > REFRESH_DELAY then
--        reference.object = component.proxy(reference.id)
--        reference.lastFetch = computer.millis()
--    end
--    return reference.object
--end

function resetComputer()
    --print(debug.backtrace)
    --error(err)
    scriptInfo.resetting = true
    if scriptInfo.network then
        scriptInfo.network:broadcast(10, "identifyReset")
        computer.skip()
    end
    rwarning("Computer reset issued!")
    local millis = computer.millis()
    event.clear()
    while computer.millis() - millis < math.random(5000,10000) do --
        event.pull(1)
        print("Reset wait loop ", tostring(computer.millis()), tostring(millis))
    end
    computer.skip()
    computer.reset()
end

function stopComputer()
    --print(debug.backtrace)
    --error(err)
    scriptInfo.stopping = true
    if scriptInfo.network then
        scriptInfo.network:broadcast(10, "identifyStop")
    end
    pcall(updateStatus)
    rwarning("Computer stop issued!")
    local millis = computer.millis()
    event.clear()
    while computer.millis() - millis < math.random(5000,10000) do --
        event.pull(1)
    end
    computer.skip()
    computer.stop()
end

function defNetworkHandler(self, address, parameters, parameterOffset)  -- Initiate handler for port 100
    local msg = parameters[parameterOffset] -- extract message identifier
    --print(msg)
    if msg and self.subhandlers[msg] then  -- if msg is not nil and we have a subhandler for it
        local handler = self.subhandlers[msg] -- put subhandler into local variable for convenience
        if parameters[parameterOffset + 1] == "json" then
            parameters = json.decode(parameters[parameterOffset + 2])
            handler(address, parameters, nil) -- call subhandler
        else
            handler(address, parameters, parameterOffset + 1) -- call subhandler
        end
    elseif not msg then -- no handler or nil message
        print ("No message identifier defined")
    else
        print ("No handler for " .. parameters[parameterOffset])
    end
end

if scriptInfo.network then
    print("Startup network")
    registerEvent(scriptInfo.network, null, function(instance, msg, params, po)
        local address = params[3] -- address param
        local port = params[4] -- port param
        --printArray(params, 2)
        --rdebug("Network message from " .. address .. " by port " .. port .. " msg " .. params[5])
        if networkHandlers[port] then -- check if we have a port handler
            computer.skip()
            networkHandlers[port]:func(address, params, 5)   -- call func with : OR with itself as first param
            computer.skip()
        else
            print ( "No handler for " .. tostring(port))
        end
    end)

    function sendIdentify(address)
        local info = {
            name = scriptInfo.name,
            fileSystemMonitor = scriptInfo.fileSystemMonitor,
            port = scriptInfo.port
        }
        if address ~= nil then
            scriptInfo.network:broadcast(ADMIN_PORT, "identifyResponse", "json", json.encode(info))
        else
            scriptInfo.network:broadcast(ADMIN_PORT, "identifyResponse", "json", json.encode(info))
        end
    end
    if scriptInfo.disableAdminListener == nil or disableAdminListener ~= true then
        networkHandler(ADMIN_PORT, defNetworkHandler, { -- table of message handlers
            ping = function(address, parameters, po)
                scriptInfo.network:send(address, ADMIN_PORT, "pong", parameters[po])
            end,
            pong = function(address, parameters, po)
                if ARP[address] then
                    local time = tonumber(parameters[po])
                    ARP[address].rtt = computer.millis() - time
                    ARP[address].lastPing = computer.millis()
                    ARP[address].online = true
                end
                --print("Pong from: " .. address)
            end,
            identifyError = function(address)
                if ARP[address] ~= nil then
                    ARP[address].errored = true
                    ARP[address].online = false
                end
            end,
            identifyReset = function(address)
                if ARP[address] ~= nil then
                    ARP[address].resetting = true
                end
            end,
            stop = function()
                if scriptInfo.preventStopAll == nil or not scriptInfo.preventStopAll then
                    stopComputer()
                end
            end,
            stopAll = function()
                if scriptInfo.preventStopAll == nil or not scriptInfo.preventStopAll then
                    stopComputer()
                end
            end,
            reset = function()
                resetComputer()
            end,
            resetAll = function()
                if scriptInfo.preventResetAll == nil or not scriptInfo.preventResetAll then
                    resetComputer()
                end
            end,
            identifyResponse = function(address, parameters)
                --print("ARP Response from " .. address)
                --printArray(parameters)
                local item = {
                    address = address,
                    name = parameters.name,
                    scriptInfo = parameters,
                    lastPing = computer.millis(),
                    identified = true,
                    online = true,
                    errored = false,
                    resetting = false,
                    rtt = -1
                }
                ARP[parameters.name] = item
                ARP[address] = item
            end,
            identify = function(address, parameters)
                --if address ~= scriptInfo.network.id then
                sendIdentify(address)
                --end
            end
        })
        scriptInfo.network:open(ADMIN_PORT) -- Administrative port
    end
end

function processEvent(pullResult)
    if pullResult[1] and pullResult[1] == "FileSystemUpdate" then
        if eventHandlers["FileSystemUpdate"] then
            eventHandlers["FileSystemUpdate"].callback(pullResult)
        end
        return
    end
    if pullResult[2] then
        if pullResult[2].hash and eventHandlers[pullResult[2].hash] then
            local v = eventHandlers[pullResult[2].hash]
            if v.callback then
                v.callback(v.instance, pullResult[1], pullResult, 2)
            end
            if v.triggers and v.triggers[pullResult[1]] then
                v.triggers[pullResult[1]].callback(v.instance, pullResult, 2)
            end
            computer.skip()
            return
        end
        error("No handler for " .. tostring(pullResult[2]) .. " by " .. pullResult[1])
    else
        if eventHandlers[pullResult[1]] then
            eventHandlers[pullResult[1]].callback(eventHandlers[pullResult[1]].instance, pullResult, 2)
        end
    end
    computer.skip()
end


---@class LinkedListItem
---@generic T
---@field public list LinkedList @Reference to this items parent list
---@field public value T @The value of this node
---@field public next LinkedListItem<T> @The next item in the list
---@field public previous LinkedListItem<T> @The previous item in the list
--@field public insert fun(value:any):LinkedListItem @Inserts an item after this in the list
--@field public delete fun() @Deletes this item from the list
--@field public print fun() @Prints this item and all its children
LinkedListItem = {}


---@class LinkedList
---@generic T
---@field public length number @The number of items in this list
---@field public first LinkedListItem<T> @The first item in the list, nil if no items
---@field public last LinkedListItem<T> @The last item in the list, nil if no items
LinkedList = {}


PeriodicTask = {}


---@param func fun(self:any)
---@param ref any
---@param minimumInterval
---@param comment string
---@return PeriodicTask
function PeriodicTask.new(func, ref, minimumInterval, comment)
    ---@type PeriodicTask
    local q = {}
    q.ref = ref
    q.func = func
    q.lastExecution = 0
    q.comment = comment
    if minimumInterval == nil then
        q.minimumInterval = 0
    else
        q.minimumInterval = minimumInterval
    end
    setmetatable(q, PeriodicTask)
    PeriodicTask.__index = PeriodicTask
    return q
end

--function LinkedListItem:insert(value)
--    local self = after.list
--    if after then
--        if after.next then
--            after.next.prev = t
--            t.next = after.next
--        else
--            self.last = t
--        end
--
--        t.prev = after
--        after.next = t
--    elseif not self.first then
--        -- this is the first node
--        self.first = t
--        self.last = t
--    end
--    self.length = self.length + 1
--end

function LinkedListItem:delete()
    local list = self.list
    if self.next then
        if self.prev then
            self.next.prev = self.prev
            self.prev.next = self.next
        else
            -- this was the first node
            self.next.prev = nil
            list.first = self.next
        end
    elseif self.prev then
        -- this was the last node
        self.prev.next = nil
        list.last = self.prev
    else
        -- this was the only node
        list.first = nil
        list.last = nil
    end
    self.next = nil
    self.prev = nil
    list.length = list.length - 1
end

function LinkedListItem:print()
    for k,v in pairs(self) do
        print(tostring(k).." = " ..tostring(v))
    end
end

---@return LinkedListItem
---@generic T
---@param value T
function LinkedList:push(value)
    local t = self:createItem(value)
    if self.last then
        self.last.next = t
        t.prev = self.last
        self.last = t
    else
        -- this is the first node
        self.first = t
        self.last = t
    end
    self.length = self.length + 1
    return t
end

---@return LinkedListItem
function LinkedList:shift(value)
    local t = self:createItem(value)
    if self.first then
        t.next = self.first
        self.first.prev = t
        self.first = t
    else
        -- this is the first node
        self.first = t
        self.last = t
    end
    self.length = self.length + 1
    return t
end

---@return LinkedListItem
function LinkedList:pop()
    if not self.last then return end
    local ret = self.last

    if ret.prev then
        ret.prev.next = nil
        self.last = ret.prev
        ret.prev = nil
    else
        -- this was the only node
        self.first = nil
        self.last = nil
    end

    self.length = self.length - 1
    return ret
end

function LinkedList:clear()
    self.first = nil
    self.last = nil
    self.length = 0
end

function LinkedList:print(depth)
    local item = self.first
    print("Linked list... {")
    local index = 1
    while item ~= nil do
        print("Item " .. index .. "={")
        printArray(item.value, depth)
        print("}")
        item = item.next
    end
    print("}")
end

---@private
---@generic T
---@param value T @The value to initialize the item with
---@return LinkedListItem
function LinkedList:createItem(value)
    return LinkedListItem.new( self, value)
end

---@private
---@generic T
---@param value T @The value to initialize the item with
---@return LinkedListItem
function LinkedListItem:new(value)
    ---@type LinkedListItem
    local t = {
        list = self,
        value = value,
        next = nil,
        previous = nil,
    }
    setmetatable(t, LinkedListItem)
    LinkedListItem.__index = LinkedListItem
    return t
end


---@generic T
---@param clazz T
---@return LinkedList<T>
function LinkedList.new(clazz)
    ---@type LinkedList
    local list = {
        first = nil,
        last = nil,
        length = 0,
        clazz = clazz
    }
    setmetatable(list, LinkedList)
    LinkedList.__index = LinkedList
    return list
end

---@generic T
---@return LinkedList<T>
---@deprecated
function createLinkedList()
    return LinkedList.new()
end

---@return table<string,string>
function parseOutputs(param)
    local p = explode(":", param)
    local ret = {}
    for _,v in pairs(p) do
        local name = string.sub(v,1,1)
        local value = string.sub(v, 2)
        ret[name] = value
    end
    return ret
end


---@type LinkedList
---@generic T:PeriodicTask
local periodicStuff = LinkedList.new(PeriodicTask)

---@param task PeriodicTask
function schedulePeriodicTask(task)
    periodicStuff:push(task)
end

function rmessage(message)
    if scriptInfo.network then
        scriptInfo.network:broadcast(101, "msg", message, scriptInfo.name)
        print(message)
    else
        error("No network")
    end
end
function rerror(message)
    if scriptInfo.network then
        scriptInfo.network:broadcast(10, "identifyError")
        scriptInfo.network:broadcast(101, "error", message, scriptInfo.name)
    else
        error("No network")
    end
end
function rwarning(message)
    if scriptInfo.network then
        scriptInfo.network:broadcast(101, "warning", message, scriptInfo.name)
    else
        error("No network")
    end
end
function rdebug(message)
    if scriptInfo.debugging and scriptInfo.debugging == true then
        if scriptInfo.network then
            scriptInfo.network:broadcast(101, "debug", message, scriptInfo.name)
            print(message)
        else
            error("No network")
        end
    end
end


function initBrightnessPanel()
    if scriptInfo.screen ~= nil then
        local panelBrightness = component.proxy(component.findComponent(scriptInfo.name .. "_BrightnessPanel")[1])
        local dispBrightness = panelBrightness:getXModule(1)
        local knobBrightness = panelBrightness:getXModule(0)
        local data = {
            disp = dispBrightness,
            knob = knobBrightness,
        }

        registerEvent(knobBrightness, data, function(self, msg, params)
            data.disp:setText(tostring(params[3]))
            scriptInfo.screen:setTransparency(params[3] / 100)
        end, nil, true)

        dispBrightness:setText(tostring(knobBrightness.value))
        scriptInfo.screen:setTransparency(knobBrightness.value / 100)
    end
end

---@param gpu GPU_T1_C
---@param a RGBAColor
function rsSetColorA(gpu, a)
    gpu:setForeground(a.R,a.G,a.B,a.A)
end

---@param GPU_T1_C
function rsClear(gpu)
    gpu:fill(0,0,scriptInfo.screenWidth,scriptInfo.screenHeight," ")
end


---@param x number X Position
---@param y number Y Position
---@param colwidth number Width to advance by if y exceeds screen height
function rsadvanceY(x, y, colwidth)
    y = y + lineHeight
    if y > scriptInfo.screenHeight - 1 then
        y = 0
        x = x + colwidth
    end
    computer.skip()
    return x, y
end

---@param div string @Divisor
---@param str string @String to be split
---@return string[]|boolean
function explode(div,str) -- credit: http://richard.warburton.it
    if (div=='') then return false end
    local pos,arr = 0,{}
    -- for each divider found
    for st,sp in function() return string.find(str,div,pos,true) end do
        table.insert(arr,string.sub(str,pos,st-1)) -- Attach chars left of current divider
        pos = sp + 1 -- Jump past current divider
    end
    table.insert(arr,string.sub(str,pos)) -- Attach chars right of last divider
    return arr
end



-- all of these functions return their result and a boolean
-- to notify the caller if the string was even changed

-- pad the left side

---@param s string @The string to pad
---@param l number @How long to pad the string to
---@param c string @The character to pad with
---@return string, boolean @The new padded string and if the new string is equal to the old string
function lpad(s, l, c)
    local res = string.rep(c or ' ', l - #s) .. s

    return res, res ~= s
end

-- pad the right side
---@param s string @The string to pad
---@param l number @How long to pad the string to
---@param c string @The character to pad with
---@return string, boolean @The new padded string and if the new string is equal to the old string
function rpad(s, l, c)
    local res = s .. string.rep(c or ' ', l - #s)

    return res, res ~= s
end

-- pad on both sides (centering with left justification)
---@param s string @The string to pad
---@param l number @How long to pad the string to
---@param c string @The character to pad with
---@return string, boolean @The new padded string and if the new string is equal to the old string
function pad(s, l, c)
    c = c or ' '

    local res1, stat1 = rpad(s,    (l / 2) + #s, c) -- pad to half-length + the length of s
    local res2, stat2 = lpad(res1,  l,           c) -- right-pad our left-padded string to the full length

    return res2, stat1 or stat2
end



function printArray(arr, depth)
    ArrayPrinter.new(arr, depth):printToConsole()
end


---@class OutputStream
local OutputStream = {}

---@class FileOutputStream:OutputStream
---@field private outputFile file @Internal holder for the open file
---@field private fileName string @Internal comment for the name of the open file
local FileOutputStream = {}

---Constructs a new output stream to write to the console
function OutputStream.new()
    ---@type OutputStream
    local obj = {}
    setmetatable(obj, OutputStream)
    OutputStream.__index = OutputStream
    return obj
end

---Constructs a new output stream to the given file
---@param fileName string @The name of the file to write to
function FileOutputStream.new(fileName)
    local file = filesystem.open(fileName, "w")
    ---@type FileOutputStream
    local obj = {
        outputFile = file,
        fileName = fileName
    }
    setmetatable(obj, FileOutputStream)
    FileOutputStream.__index = FileOutputStream
    return obj
end

---@param text string
function OutputStream:write(text)
    print(text)
end

---@param text string
function FileOutputStream:write(text)
    self.outputFile:write(text .. "\n")
end

---Closes the current open stream
function FileOutputStream:close()
    self.outputFile:close()
end


---@class ArrayPrinter
---@field private targetDepth number
---@field private history table<table,boolean>
---@field private highIndex number @The highest index reached for references
---@field private array any @The array to work on
---@field private output OutputStream @Internally used to hold the output writer
---public
ArrayPrinter = {}


---Creates a new ArrayPrinter working on the given array
---@param array table @The array to work on
---@param depth number @The maximum depth in the table to work to
function ArrayPrinter.new(array, depth)
    if depth == nil then
        depth = -1
    end
    ---@type ArrayPrinter
    local obj = {
        targetDepth = depth,
        highIndex = 1,
        history = {},
        array = array,
    }
    setmetatable(obj, ArrayPrinter)
    ArrayPrinter.__index = ArrayPrinter
    return obj
end

---Internal worker function, do not call this directly, there will be no output to write to
---@param arr any @The current table object
---@param level number @The current level to print to
---@private
function ArrayPrinter:_print(arr, level)
    if self.array == nil then
        print "[nil]"
        return
    end
    local spaces1 = rpad("", (level) * 2, " ")
    local spaces = rpad("", (level + 1) * 2, " ")
    self.output:write(spaces1.."Array<" .. tostring(self.highIndex) .. ">{")
    self.history[arr] = self.highIndex
    self.highIndex = self.highIndex + 1
    level = level + 1
    for k,v in pairs(arr) do
        if v == nil then
            self.output:write(spaces..tostring(k).."=nil")
        elseif type(v) == "string" then
            self.output:write(spaces..tostring(k) .. "='"..v.."'")
        elseif type(v) == "table" then
            if self.history[v] ~= nil then
                self.output:write(spaces .. tostring(k) .. " = <Reference#" .. tostring(self.history[v]) .. ">")
            else
                if self.targetDepth < 0 or level < self.targetDepth then
                    self.output:write(spaces..tostring(k) .. "=")
                    self:_print(v, level + 1)
                else
                    self.output:write(spaces..tostring(k) .. "= <limited by detph>")
                end
            end
        else
            self.output:write(spaces.. tostring(k) .. "="..tostring(v))
        end
    end
    self.output:write(spaces1.."}")
end

---Internal function to reset the print data
---@private
function ArrayPrinter:reset()
    self.history = {}
    self.highIndex = 1
end

---Prints the content of the bound array to the console
function ArrayPrinter:printToConsole()
    self:reset()
    self.output = OutputStream.new()
    self:_print(self.array, 0)
end

---Prints the content of the bound array to the given file
function ArrayPrinter:printToFile(fileName)
    self:reset()
    self.output = FileOutputStream.new(fileName)
    self:_print(self.array, 0)
    self.output:close()
end


function printArrayToFile(fileName, arr, depth)
    ArrayPrinter.new(arr, depth):printToFile(fileName)
end

function initGPU()
    local gpu = computer.getPCIDevices(findClass("GPU_T1_C"))[1]
    print("GPU", gpu)
    local screen = scriptInfo.screen
    print("Screen", screen)
    if screen ~= nil and gpu ~= nil then
        scriptInfo.gpu = gpu
        gpu:bindScreen(screen)
        gpu:setBackground(0,0,0,0)
        gpu:setsize (scriptInfo.screenWidth, scriptInfo.screenHeight)
        local screenW,screenH = gpu:getSize()
        gpu:fill(0,0,screenW,screenH," ")
        gpu:setForeground(1,1,1,1)
        print("Screen init done")
        gpu:flush()
    --else
        --rerror("Screen: " .. tostring(screen) .. ", GPU: " .. tostring(gpu))
    end
end


--printArrayToFile("fluidTypes_init.txt", fluidTypes)

--function setCommandLabelText(panel, index, text, vertical, color)
--	if vertical == nil then
--		vertical = true
--	end
--	if color == nil then
--		color = rgba(1, 1, 1, 1)
--	end
--	panel:setForeground(index, color[1], color[2], color[3])
--	panel:setText(index, text, vertical)
--end

---@param module FINModuleBase
---@param color RGBAColor
function setModuleColor(module, color)
    module:setColor(color.R, color.G, color.B, color.A)
end


---@param ref FINModuleBase @Actor reference
---@param callback fun(self:FINModuleBase, parameters:string[], parameterOffset:number) @Actor Event Callback Function
---@param defColor RGBAColor @The new color, nil if no change
---@param subscribe boolean @If true, will subscribe the ref to event.listen()
function initModularButton(ref, callback, defColor, subscribe)
    if defColor ~= nil then
        setModuleColor(ref, defColor)
    end
	registerEvent(ref, ref, callback);
    if subscribe ~= nil then
        event.listen(ref)
    end
end


function commonError(err)

end

function computer.getGPUs()
    return computer.getPCIDevices(findClass("GPU_T1_C"))
end


function coroutine.xpcall(co)
    local output = {coroutine.resume(co)}
    if output[1] == false then
        return false, output[2], debug.traceback(co)
    end
    return table.unpack(output)
end

DOUBLE_LINE_BOX = {"╔", "═", "╗", "║", " ", "║", "╚", "═", "╝"}

function generateSquareFrame(subset, width, height)
    local box = {}
    box[#box + 1] = subset[1] .. string.rep(subset[2], width - 2) .. subset[3]
    local space = string.rep(subset[5], width - 2)
    for i = 1, height - 2 do
        box[#box + 1] = subset[4] .. space .. subset[6]
    end
    box[#box + 1] = subset[7] .. string.rep(subset[8], width - 2) .. subset[9]
    return box;
end

function rsprintSquareFrame(gpu, subset, x, y, width, height)
    local box = generateSquareFrame(subset, width, height)
    for _,v in pairs(box) do
        gpu:setText(x, y, v)
        y = y + 1
    end
end

local commonMainCounter = 0
--error("TestError")

--error("test")
local timeout = 1


---@param timeoutLong number
---@param timeoutShort number
---@param seldomCallback fun()
function commonMain(timeoutLong, timeoutShort, seldomCallback)
    ---@type PeriodicTask
    local periodicTask

    while true do
        local result = {event.pull(timeout) }
        if result[1] then
            timeout = timeoutShort
        else
            timeout = timeoutLong
        end
        --print(result[1])
        processEvent(result)

        if periodicTask == nil then
            periodicTask = periodicStuff.first
        end
        if periodicTask ~= nil then
            ---@type PeriodicTask
            local item = periodicTask.value
            local m = computer.millis()
            if item.func == nil then
                if item.comment ~= nil then
                    error("Function in periodic task " .. item.comment .. " is null")
                else
                    error("Function in periodic task without comment is null")
                end
            end
            if item.minimumInterval == 0 or m - item.lastExecution >= item.minimumInterval then
                item.lastExecution = m
                if item.func(item.ref) then
                    timeout = timeoutShort
                end
            end
            periodicTask = periodicTask.next
            --print(periodicTask.value.ref.stock.resource)
        end

        if timeout > 0 or seldomCounter == 0 then
            if seldomCallback ~= nil then
                seldomCallback()
            end
            commonMainCounter = 1000
        else
            commonMainCounter = commonMainCounter - 1
        end
    end
end


function commonInit()
    --event.clear()
    if scriptInfo.network and scriptInfo.port then
        scriptInfo.network:open(scriptInfo.port)
        event.listen(scriptInfo.network)
        scriptInfo.network:broadcast(ADMIN_PORT, "identify")
    else
        print ("No such adapter")
    end
    initGPU()
    if scriptInfo.fileSystemMonitor then
        print("Reboot on FileSystemUpdate is Enabled")
        registerEvent("FileSystemUpdate", nil, function(pullRequest)
			--printArray(pullRequest, 2)
            if pullRequest[4] and pullRequest[4] == "/Common.lua" or pullRequest[4] == "/Program.lua" then
                resetComputer()
            end
        end)
		event.listen(computer.getInstance())
    end

    filesystem.doFile("Program.lua")


    --local co = coroutine.create(main)
    --local ret = {coroutine.resume(co)}
    --print(coroutine.status(co))
    --printArray(ret, 1)
    --if not errorFree then
    --    rerror("Error in main; "..tostring(value).."   "..debug.traceback(co))
    --    computer.skip()
    --    resetComputer()
    --else
    --    print(coroutine.status(co))
    --    print(errorFree)
    --    print(value)
    --end

    local status,err,LAST_ERROR_TRACE = main()

    --local routine = coroutine.create(main)
    --coroutine.resume(routine)


    --local status, err = xpcall(main, function(err)
    --    LAST_ERROR_TRACE = debug.traceback()
    --    return err
    --end)

    --local status, err, LAST_ERROR_TRACE = coroutine.xpcall(routine)

    --print(err)
    --printArray(LAST_ERROR_TRACE)
    --print(status)
    if not status and err then
        print(err)
        print(LAST_ERROR_TRACE)
        rerror("Error in main; "..tostring(err).."   "..LAST_ERROR_TRACE)
        computer.skip()
        if scriptInfo.preventRestartError == nil or scriptInfo.preventRestartError == false then
            resetComputer()
        end
    end

    print("Done")

end

