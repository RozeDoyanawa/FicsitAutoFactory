--
-- Created by IntelliJ IDEA.
-- User: Roze
-- Date: 2020-08-22
-- Time: 09:49
-- To change this template use File | Settings | File Templates.
--

local dev = component.proxy(component.findComponent("Logging Computer Network Adapter")[1])
scriptInfo.name = "Logging"
scriptInfo.network = dev

if dev then
    dev:open(101)

    event.listen(dev)

    dev:broadcast(101, "msg", "Logg Initiated", "System")
else
    print ("No such adapter")
end

local logg = createLinkedList()
print(logg)

networkHandler(101, function(self, address, parameters, parameterOffset)  -- Initiate handler for port 100
    local msg = parameters[parameterOffset] -- extract message identifier
    if msg and self.subhandlers[msg] then  -- if msg is not nil and we have a subhandler for it
        local handler = self.subhandlers[msg] -- put subhandler into local variable for convenience
        handler(address, parameters, parameterOffset + 1) -- call subhandler
    elseif not msg then -- no handler or nil message
        print ("No message identifier defined")
    else
        print ("No handler for " .. parameters[parameterOffset])
    end
end, { -- table of message handlers
    error = function(address, parameters, po) -- subhandler for message postOrder
        local message = parameters[po] -- po, short for parameterOffset, index local message params from this
        print(logg)
        while logg.length >= screens.cellHeight - 2 do
            logg.first:delete()
        end
        logg:push({
            text = message,
            type = "error",
            source = parameters[po + 1],
            time = computer.time()
        })
        print ("Network error: " .. message)
    end,msg = function(address, parameters, po) -- subhandler for message postOrder
        local message = parameters[po] -- po, short for parameterOffset, index local message params from this
        print(logg)
        while logg.length >= screens.cellHeight - 2 do
            logg.first:delete()
        end
        logg:push({
            text = message,
            type = "msg",
            source = parameters[po + 1],
            time = computer.time()
        })
        print ("Network Message: " .. message)
    end,warning = function(address, parameters, po) -- subhandler for message postOrder
        local message = parameters[po] -- po, short for parameterOffset, index local message params from this
        print(logg)
        while logg.length >= screens.cellHeight - 2 do
            logg.first:delete()
        end
        logg:push({
            text = message,
            type = "warning",
            source = parameters[po + 1],
            time = computer.time()
        })
        print ("Network Alert: " .. message)
    end,debug = function(address, parameters, po) -- subhandler for message postOrder
        local message = parameters[po] -- po, short for parameterOffset, index local message params from this
        print(logg)
        while logg.length >= screens.cellHeight - 2 do
            logg.first:delete()
        end
        logg:push({
            text = message,
            type = "debug",
            source = parameters[po + 1],
            time = computer.time()
        })
        print ("Network Alert: " .. message)
    end
})

screens.init("Logging", 1, 1, 100, 25)

function getTimeString(time)
    --print(time)
    if not time then
        time = computer.time()
    end
    local day = math.floor(time / 86400)
    time = time % 86400
    local hour = math.floor(time / 3600)
    time = time % 3600
    local minute = math.floor(time / 60)
    time = time % 60
    local second = math.floor(time)
    return string.format("%2d;%02d:%02d:%02.s", day, hour, minute, second)
end


function printScreen()
    local item = logg.first
    local x = 0
    local y = 0
    screens:clear()
    screens:setForeground(0.7,0.7,0.7,1)
    screens:print(x, y, "Global Event logg: "); y = y + 1
    while item do
        x = 2
        screens:setForeground(0.3, 0.3, 0.7, 1)
        screens:print(x, y, getTimeString(item.value.time))
        x = x + 13
        if item.value.source then
            screens:setForeground(0.3,0.3,0.3,1)
            screens:print(x, y, item.value.source .. ": ");
            x = x + string.len(item.value.source) + 2
        end
        if item.value.type == "error" then
            screens:setForeground(1,0.5,0.5,1)
        elseif item.value.type == "warning" then
            screens:setForeground(1,1,0.5,1)
        elseif item.value.type == "debug" then
            screens:setForeground(0.5,1,0.8,1)
        else
            screens:setForeground(0.7,0.7,0.7,1)
        end
        screens:print(x, y, item.value.text); y = y + 1
        item = item.next
    end
    screens:flush()
end

local seldomCounter = 0

while true do
    local timeout = 1
    local result = {event.pull(timeout) }
    if result[1] then
        timeout = 0
    else
        timeout = 1
    end
    processEvent(result)
    if timeout == 1 or seldomCounter == 0 then
        printScreen()
        seldomCounter = 1000
    else
        seldomCounter = seldomCounter - 1
    end
end
