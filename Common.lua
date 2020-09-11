
local eventHandlers = {}


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
    ["Coal"] = 100,
    ["Bauxite"] = 100,
    ["Quartz"] = 100,
    ["Limestone"] = 100,
    ["Encased Industrial Beam"] = 100,
    ["Plastic"] = 100,
    ["Rubber"] = 100,
    ["Crystal Oscillator"] = 100,
    ["Circuit Board"] = 200,
    ["High-Speed Connector"] = 100,
    ["Computer"] = 50,
    ["A.I. Limiter"] = 100,
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
    ["Water"] = 50,
    ["Packaged Oil"] = 100,
    ["Packaged Water"] = 100,
    ["Packaged Heavy Oil Residue"] = 100,
    ["Packaged Fuel"] = 100,
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
}

craftSystems = {
    Smelting = {
        name = "Smelting",
        short = "S",
        address = "2ACBF2BB40D9E7FB393FD5972D1A2A48",
        order = function(self, item, amount, purpouse)
            if purpouse and purpouse == "Dependency" then
                scriptInfo.network:send(self.address, 100, "orderFirst", item, amount)
            else
                scriptInfo.network:send(self.address, 100, "order", item, amount)
            end
        end
    },
    Crafting = {
        name = "Crafting",
        short = "T1",
        address = "667B553E4C69859C89B0B4A4F3D9D3A7",
        order = function(self, item, amount, purpouse)
            if purpouse and purpouse == "Dependency" then
                scriptInfo.network:send(self.address, 100, "orderFirst", item, amount)
            else
                scriptInfo.network:send(self.address, 100, "order", item, amount)
            end
            --error("Crafting Not implemented")
        end
    },
    CraftingT2 = {
        name = "CraftingT2",
        short = "T2",
        address = "00A40EEE4356018B3366B8BD380C73F2",
        order = function(self, item, amount, purpouse)
            if purpouse and purpouse == "Dependency" then
                scriptInfo.network:send(self.address, 100, "orderFirst", item, amount)
            else
                scriptInfo.network:send(self.address, 100, "order", item, amount)
            end
        end
    },
    CraftingT3 = {
        name = "CraftingT3",
        short = "T3",
        address = "5A16F0B541A433104F846B8FDA2A4650",
        order = function(self, item, amount, purpouse)
            if purpouse and purpouse == "Dependency" then
                scriptInfo.network:send(self.address, 100, "orderFirst", item, amount)
            else
                scriptInfo.network:send(self.address, 100, "order", item, amount)
            end
        end
    },
    Fluids = {
        name = "Fluids",
        short = "F",
        address = "DFEBAB504E31B927CDEB7E9432F64B96",
        order = function(self, item, amount, purpouse)
            if purpouse and purpouse == "Dependency" then
                scriptInfo.network:send(self.address, 100, "orderFirst", item, amount)
            else
                scriptInfo.network:send(self.address, 100, "order", item, amount)
            end
        end
    }
}

function registerEvent(key, instance, callback, triggerHandlers)
    local evt = {
        instance = instance,
        reference = key,
        callback = callback,
        triggers = triggerHandlers
    }
    if key and key.hash then
        print("Registering event by hash: " .. key.hash)
        eventHandlers[key.hash] = evt
    else
        eventHandlers[key] = evt
    end
end

local itemManagerAddress = "429823144AEF8331B86B00943C6576F9"


local networkHandlers = {}

function networkHandler(port, func, subhandlers) -- function for creating a handler
    networkHandlers[port] = {
        ["func"] = func,
        ["subhandlers"] = subhandlers
    }
end

registerEvent("NetworkMessage", nil, function(instance, params, po)
    local address = params[3] -- address param
    local port = params[4] -- port param
    if networkHandlers[port] then -- check if we have a port handler
        networkHandlers[port]:func(address, params, 5)   -- call func with : OR with itself as first param
    else
        print ( "No handler for " .. tostring(port))
    end
end)

function processEvent(pullResult)
    if pullResult[1] and pullResult[1] == "FileSystemUpdate" then
        if eventHandlers["FileSystemUpdate"] then
            eventHandlers["FileSystemUpdate"].callback(pullResult)
        end
        return
    end
    if pullResult[2] then
        if pullResult[2].hash and eventHandlers[pullResult[2].hash] then
            print("Event by hash: " .. pullResult[2].hash .. ", " .. tostring(pullResult[2]))
            local v = eventHandlers[pullResult[2].hash]
            if v.callback then
                v.callback(v.instance, pullResult[1], pullResult, 2)
            end
            if v.triggers and v.triggers[pullResult[1]] then
                v.triggers[pullResult[1]].callback(v.instance, pullResult, 2)
            end
            return
        end
        for k,v in pairs(eventHandlers) do
            if v.reference == pullResult[2] then
                if v.callback then
                    v.callback(v.instance, pullResult[1], pullResult, 2)
                end
                if v.triggers and v.triggers[pullResult[1]] then
                    v.triggers[pullResult[1]].callback(v.instance, pullResult, 2)
                end
                return
            end
        end
        error("No handler for " .. tostring(pullResult[2]) .. " by " .. pullResult[1])
    else
        --print(pullResult[1])
        if eventHandlers[pullResult[1]] then
            eventHandlers[pullResult[1]].callback(eventHandlers[pullResult[1]].instance, pullResult, 2)
        end
    end
end

function createLinkedList()
    local list = {
        length = 0,
        first = nil,
        last = nil,
        createItem = function (list, value)
            local t = {
                list = list,
                value = value,
                next = nil,
                previous = nil,
                insert = function(after, value)
                    local self = after.list
                    if after then
                        if after.next then
                            after.next.prev = t
                            t.next = after.next
                        else
                            self.last = t
                        end

                        t.prev = after
                        after.next = t
                    elseif not self.first then
                        -- this is the first node
                        self.first = t
                        self.last = t
                    end
                    self.length = self.length + 1
                end,
                delete = function(t)
                    local self = t.list
                    if t.next then
                        if t.prev then
                            t.next.prev = t.prev
                            t.prev.next = t.next
                        else
                            -- this was the first node
                            t.next.prev = nil
                            self.first = t.next
                        end
                    elseif t.prev then
                        -- this was the last node
                        t.prev.next = nil
                        self.last = t.prev
                    else
                        -- this was the only node
                        self.first = nil
                        self.last = nil
                    end
                    t.next = nil
                    t.prev = nil
                    self.length = self.length - 1
                end,
                print = function(self)
                    for k,v in pairs(self) do
                        print(tostring(k).." = " ..tostring(v))
                    end
                end
            }
            return t
        end,
        push = function(self, value)
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
        end,
        shift = function(self, value)
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
        end,
        pop = function(self)
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
        end,
        clear = function(self)
            self.first = nil
            self.last = nil
            self.length = 0
        end
    }
    return list
end

scriptInfo = {
    name = "Unknown",
    network = nil,
    debugging = false,
}


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


local srep = string.rep

-- all of these functions return their result and a boolean
-- to notify the caller if the string was even changed

-- pad the left side

lpad =
function (s, l, c)
    local res = srep(c or ' ', l - #s) .. s

    return res, res ~= s
end

-- pad the right side
rpad =
function (s, l, c)
    local res = s .. srep(c or ' ', l - #s)

    return res, res ~= s
end

-- pad on both sides (centering with left justification)
pad =
function (s, l, c)
    c = c or ' '

    local res1, stat1 = rpad(s,    (l / 2) + #s, c) -- pad to half-length + the length of s
    local res2, stat2 = lpad(res1,  l,           c) -- right-pad our left-padded string to the full length

    return res2, stat1 or stat2
end

return _M