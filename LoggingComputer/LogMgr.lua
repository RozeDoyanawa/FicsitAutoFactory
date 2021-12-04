--
-- Created by IntelliJ IDEA.
-- User: Roze
-- Date: 2020-08-22
-- Time: 09:49
-- To change this template use File | Settings | File Templates.
--

local dev = scriptInfo.network


local logg = createLinkedList()
print(logg)

local maxLines = scriptInfo.screenHeight - 1

function prepareLogFor(msg, type, source)
    if scriptInfo.screen ~= nil or scriptInfo.rscreen ~= nil then
        local t = explode("\n", msg)
        local i = 0
        for _,l in pairs(t) do
            i = i + 1
            computer.skip()
        end
        print("Ensuring capacity for " .. tostring(i) .. " lines")
        while logg.length + i >= maxLines - 1 do
            logg.first:delete()
        end
        local file = filesystem.open("log.txt", "a")
        file:write("[" .. type .. "] " .. source .. ": " .. msg .. "\n")
        file:close()
        for _,l in pairs(t) do
            local item = {
                text = l,
                type = type,
                source = source,
                time = computer.time(),
                subline = false
            }
            if _ > 1 then
                item.subline = true
            end
            logg:push(item)
            computer.skip()
        end
        return t
    end
end

function initNetwork()
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
            prepareLogFor(message, "error", parameters[po + 1])
            print ("Network error: " .. message)
        end,msg = function(address, parameters, po) -- subhandler for message postOrder
            local message = parameters[po] -- po, short for parameterOffset, index local message params from this
            prepareLogFor(message, "msg", parameters[po + 1])
            print ("Network Message: " .. message)
        end,warning = function(address, parameters, po) -- subhandler for message postOrder
            local message = parameters[po] -- po, short for parameterOffset, index local message params from this
            prepareLogFor(message,"warning", parameters[po + 1])
            print ("Network Alert: " .. message)
        end,debug = function(address, parameters, po) -- subhandler for message postOrder
            local message = parameters[po] -- po, short for parameterOffset, index local message params from this
            prepareLogFor(message, "debug", parameters[po + 1])
            print ("Network Alert: " .. message)
        end
    })
end


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

local defaultAlpha = 1


function printScreen()
    if scriptInfo.gpu ~= nil then
        local gpu = scriptInfo.gpu
        local item = logg.first
        local x = 0
        local y = 0
        rsClear(gpu)
        gpu:setForeground(0.7, 0.7, 0.7, defaultAlpha)
        gpu:setText(x, y, "Global Event logg: "); y = y + 1
        local lastX = 0
        while item do
            local itemValue = item.value
            if itemValue.subline == false then
                x = 2
                gpu:setForeground(0.3, 0.3, 0.7, defaultAlpha)
                gpu:setText(x, y, getTimeString(itemValue.time))
                x = x + 13
                if itemValue.source then
                    gpu:setForeground(0.3, 0.3, 0.3, defaultAlpha)
                    gpu:setText(x, y, itemValue.source .. ": ");
                    x = x + string.len(itemValue.source) + 2
                end
                itemValue.x = x
                lastX = x
            elseif itemValue.x == nil then
                itemValue.x = lastX
            end
            if itemValue.type == "error" then
                gpu:setForeground(1, 0.5, 0.5, defaultAlpha)
            elseif itemValue.type == "warning" then
                gpu:setForeground(1, 1, 0.5, defaultAlpha)
            elseif itemValue.type == "debug" then
                gpu:setForeground(0.5, 1, 0.8, defaultAlpha)
            else
                gpu:setForeground(0.7, 0.7, 0.7, defaultAlpha)
            end
            gpu:setText(itemValue.x, y, itemValue.text); y = y + 1
            item = item.next
        end
        gpu:flush()
    end
end


rerror = function (msg)
    error(msg)
end


function main()
    local seldomCounter = 0

    initNetwork()

    schedulePeriodicTask(PeriodicTask.new( function() printScreen()  end, nil, 1000))

    commonMain(1, 0.1)

    --while true do
    --    local timeout = 1
    --    local result = {event.pull(timeout) }
    --    if result[1] then
    --        timeout = 0.1
    --    else
    --        timeout = 1
    --    end
    --    processEvent(result)
    --    if timeout == 1 or seldomCounter == 0 then
    --        printScreen()
    --        seldomCounter = 1000
    --    else
    --        seldomCounter = seldomCounter - 1
    --    end
    --end
end
