--
-- Created by IntelliJ IDEA.
-- User: Roze
-- Date: 2020-08-22
-- Time: 09:53
-- To change this template use File | Settings | File Templates.
--

local panel = component.proxy(component.findComponent("Crafting Panel 1")[1])


local stations = {}

local orderQueue = createLinkedList()


function queue2(recipeName, count)
    orderQueue:push({
        name = recipeName,
        count = count
    })
    processOrderQueue()
end
function queue2First(recipeName, count)
    orderQueue:shift({
        name = recipeName,
        count = count,
    })
    processOrderQueue()
end

function processOrderQueue()
    local i = orderQueue.first
    while i do
        local n = i.next
        local b = false
        for _,station in pairs(stations) do
            if station:canMake(i.value.name) then
                station:order(i.value.name, i.value.count)
                i:delete()
                b = true
                break;
            end
        end
        if not b then
            print("No station to craft " .. i.value.name)
        end
        i = n
    end
end


function createStation(comp, stationIndex, type, prefix)
    local inputFilter = prefix .. "_" .. stationIndex .. "_Input"
    print(inputFilter)
    local inputs = component.findComponent(inputFilter)
    local station = {
        name = "Station " .. stationIndex,
        index = tonumber(stationIndex),
        reference = comp,
        inputs = {},
        inputCount = 0,
        toProduce = 0,
        recipe = {},
        localOutput = 2,
        busOutput = 1,
        nextInput = 1,
        queue = createLinkedList(),
        order = function(self, recipeName, count)
            for i,recipe in pairs(self.reference:getRecipes()) do
                if recipe:getName() == recipeName then
                    self.reference:setRecipe(recipe)
                    self.workObject = recipe:getProducts()[1].item:getName()
                    local _count = math.ceil(count / recipe:getProducts()[1].count)
                    for i2,v in pairs(recipe:getIngredients()) do
                        local input = self.inputs[self.nextInput]
                        self.nextInput = self.nextInput + 1
                        if self.nextInput > self.inputCount then
                            self.nextInput = 1
                        end
                        local item = {
                            name = v.item:getName(),
                            count = v.count * _count,
                            bus = input.name,
                        }
                        if item.name == nil then
                            print("NIL ITEM NAME!")
                            print(recipe)
                            print(recipe:getName())
                        end

                        --print("Appended item " .. tostring(item) .. " to que")
                        if not doPurge then
                            self.queue:push(item)
                            input:request(item.name, item.count, "Dependency")
                        end
                        --printLinkedList(bus.queue)
                    end
                    self.toProduce = self.toProduce + _count * recipe:getProducts()[1].count
                    return true
                end
            end
        end,
        canMake = function(self, recipeName)
            if self.toProduce > 0 then
                return false
            end
            for _,recipe in pairs(self.reference:getRecipes()) do
                if recipe:getName() == recipeName then
                    return true
                end
            end
            return false
        end
    }
    station.outputConnector = stationOutputSlot
    local inventories = station.reference:getInventories()
    for _,inv in pairs(inventories) do
        for _,v in pairs(station.reference:getInventories()) do
            if not v:getStack(0).item then
                if inv.ItemCount > 0 then
                    rmessage(station.name .. " had " .. tostring(inv.ItemCount) .. "residual items; cleared")
                end
                v:flush()
            elseif tostring(v:getStack(0).item.type) ~= "Power Shard" then
                if inv.ItemCount > 0 then
                    rmessage(station.name .. " had " .. tostring(inv.ItemCount) .. "residual items; cleared")
                end
                v:flush()
            end
        end
    end
    for _,id in pairs(inputs) do
        print(id)
        local splitter = component.proxy(id)
        local _space = explode(" ", splitter.nick)
        local bus = _space[2]
        station.inputCount = station.inputCount + 1
        station.inputs[station.inputCount] = getBus(bus)
        --registerEvent(splitter, {station = station, splitter = splitter}, function(self, evt, params, po)
        --    processSplitterOutput(self.station, self.splitter)
        --end)
        splitters:push({
            reference = splitter,
            object = station,
            name = bus
        })
        --event.listen(splitter)
    end
    print("OC = " .. tostring(station.outputConnector))
    local connector = comp:getFactoryConnectors()[station.outputConnector]
    registerEvent(connector, station, function(self, param)
        --print(tostring(param))
        self.toProduce = self.toProduce - 1
        if self.toProduce < 0 then
            rwarning("Mysterious extra item from " .. tostring(station.index))
        end
        if self.toProduce <= 0 then
            self.toProduce = 0
        end
    end)
    station.outConnector = connector
    event.listen(connector)
    stations[comp] = station
end

function enumStations(prefix)
    local allComps = component.findComponent("")
    for _,id in pairs(allComps) do
        local comp = component.proxy(id)
        local _spaces = explode(" ", comp.nick)
        local q = explode("_", comp.nick)
        if _spaces[1] == comp.nick and q[1] == prefix then
            local index = q[2]
            createStation(comp, index, q[3], prefix)
        end
    end
end


local recipesToSend = {}
local recipeCount = 0

networkHandler(100, function(self, address, parameters, parameterOffset)  -- Initiate handler for port 100
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
    order = function(address, parameters, po)
        local resourceName = parameters[po]
        local count = parameters[po + 1]
        rmessage("Order to craft " .. tostring(count) .. " " .. resourceName)
        queue2(resourceName, count)
    end,
    orderFirst = function(address, parameters, po)
        local resourceName = parameters[po]
        local count = parameters[po + 1]
        rmessage("Order to craft " .. tostring(count) .. " " .. resourceName)
        queue2First(resourceName, count)
    end,
    purge = function(address, parameters, po)
        local state = parameters[po]
        doPurge = state
        if state then
            rwarning("Purging active")
        end
    end,
    enumRecipes = function(address, parameters, po)
        local total = 0
        local enumerated = {}
        for _,station in pairs(stations) do
            local recipes = station.reference:getRecipes()
            for _,recipe in pairs(recipes) do
                if not enumerated[recipe:getName()] then
                    recipesToSend[total] = recipe;
                    enumerated[recipe:getName()] = true
                    total = total + 1
                end
            end
        end
        recipeCount = total
        print("Enum Recipes received; Sending " .. tostring(recipeCount) .. " recipes")
        sendNextRecipe(address, 0)
    end,
    sendNextRecipe = function(address, parameter, po)
        sendNextRecipe(address, parameter[po])
    end
})

function sendNextRecipe(address, recipeIndex)
    if recipeIndex == recipeCount then
        scriptInfo.network:send(address, 100, "enumRecipesDone", recipeIndex, scriptInfo.name)
    else
        local recipe = recipesToSend[recipeIndex]
        if recipe then
            local ingredients = recipe:getIngredients()
            local sendParams = {}
            sendParams[1] = "recipe"
            sendParams[2] = recipe:getProducts()[1].item:getName()
            sendParams[6] = recipe:getName()
            sendParams[5] = recipe:getProducts()[1].count
            local data = ""
            local count = 0
            for _,regent in pairs(ingredients) do
                --sendParams[index] = regent.item:getName()
                --sendParams[index + 1] = regent.count
                if count > 0 then
                    data = data .. "|"
                end
                data = data .. regent.item:getName() .. "#" .. regent.count
                count = count + 1
            end
            sendParams[3] = data
            sendParams[4] = recipeIndex
            if count > 0 then
                --for k,v in pairs(sendParams) do
                --    print(k .. " = " .. v)
                --end
                scriptInfo.network:send(address, 100, table.unpack(sendParams))
            end
        else
            rerror("No such recipe: " .. tostring(index) .. ", max is "..tostring(recipeCount))
        end
    end
end


rmessage("Prefix: " .. stationPrefix)

enumStations(stationPrefix)


rmessage("Computer started")

local printQueue = true

--queue2("Iron Plate", 2)

function printScreen()
    screens:clear()
    local y = 0
    local x = 0
    local c = 35
    screens:setForeground(0.7,0.7,0.7,1)
    screens:print(x,y,"Busses"); x,y = gColumnAdvance(x,y,c)
    for _,bus in pairs(busses) do
        if bus.parent then
            screens:setForeground(0.7,0.7,0.3,1)
            screens:print( x+ 2, y, bus.parent.name)
            screens:setForeground(0.7,0.7,0.7,1)
            screens:print(x + string.len(bus.parent.name) + 4, y, "> " .. bus.name)
            if bus.queue then
                screens:setForeground(0.3,0.3,1,1)
                screens:print(x + 28, y, string.format("%5d", bus.queue.length))
            end
            screens:setForeground(0.7,0.7,0.7,1)
            x,y = gColumnAdvance(x, y, c)
            if printQueue and bus.queue then
                local f = bus.queue.first
                while f do
                    screens:setForeground(0.6,0.4,0.4,1)
                    screens:print(x + 4, y, f.value.name .. "   "  .. string.format("%3d", f.value.count))
                    x,y = gColumnAdvance(x, y, c)
                    f = f.next
                end
            end
        end
    end
    y = y + 1
    screens:setForeground(0.7,0.7,0.7,1)
    screens:print(x,y,"Future"); x,y = gColumnAdvance(x,y,c)
    local item = orderQueue.first
    if item then
        local m = 0
        while item do
            m = m + 1
            screens:setForeground(0.7,0.7,0.7,1)
            screens:print( x+ 2, y, item.value.name)
            screens:setForeground(0.3,0.3,1,1)
            screens:print(x + 23, y, string.format("%3d", item.value.count))
            item = item.next
            x,y = gColumnAdvance(x, y, c)
            if y + 2 > screens.cellHeight then
                screens:setForeground(0.7,0.7,0.7,1)
                screens:print(x,y, " + " .. tostring(orderQueue.length - m) .. " more")
                break
            end
        end
    else
        screens:setForeground(1,1,0.6,1)
        screens:print( x+ 2, y, "Nothing to do")
        x,y = gColumnAdvance(x, y, c)
    end

    y = 0
    x = 35
    c = 35
    screens:setForeground(0.7,0.7,0.7,1)
    screens:print(x,y,"Stations"); x,y = gColumnAdvance(x,y,c)
    for _,station in pairs(stations) do
        if station.toProduce > 0 then
            screens:setForeground(0.7,0.7,0.3,1)
        elseif station.error then
            screens:setForeground(1,0.3,0.3,1)
        else
            screens:setForeground(0.7,1,0.7,1)
        end
        screens:print(x + 2, y, station.name)
        x,y = gColumnAdvance(x, y, c)
        if station.toProduce > 0 then
            screens:setForeground(0.7,0.7,0.7,1)
            screens:print(x + 4, y, station.workObject)
            screens:setForeground(0.3,0.3,1,1)
            screens:print(x + 26, y, string.format("%3d", station.toProduce))
            x,y = gColumnAdvance(x, y, c)
        end
        if printQueue then
            local f = station.queue.first
            while f do
                screens:setForeground(0.7,0.7,0.7,1)
                screens:print(x + 6, y, f.value.name)
                screens:setForeground(0.3,0.3,1,1)
                screens:print(x + 26, y, string.format("%3d", f.value.count))
                x,y = gColumnAdvance(x, y, c)
                f = f.next
            end
        end
    end
    screens:flush()
end

local seldomCounter = 0

while true do
    local result = {event.pull(0) }
    processEvent(result)
    local status, err
    --local status, err = pcall(processEvent, result)
    if err then
        rerror("Error in processEvent; ".. tostring(err))
        error(err)
    end
    --processOutputs()
    status, err = pcall(processOutputs)
    if not status and err then
        rerror("Error in processOutputs; "..tostring(err))
        error(err)
    end
    if seldomCounter == 0 then
        --printScreen()
        status, err = pcall(printScreen)
        if err then
            rerror("Error in print; ".. tostring(err))
            error(err)
        end
        status, err = pcall(processOrderQueue)
        if err then
            rerror("Error in print; ".. tostring(err))
            error(err)
        end
        seldomCounter = 1000
    else
        seldomCounter = seldomCounter - 1
    end
end
