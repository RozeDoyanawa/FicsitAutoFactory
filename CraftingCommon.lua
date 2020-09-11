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
        --print("Station: " .. station.reference.nick .. ", Inv: ".. tostring(_))
        if not inv:getStack(0).item then
            if inv.ItemCount > 0 then
                rmessage(station.name .. " had " .. tostring(inv.ItemCount) .. "residual items; cleared;")
            end
            inv:flush()
        elseif tostring(inv:getStack(0).item.type) ~= "Power Shard" then
            if inv.ItemCount > 0 then
                rmessage(station.name .. " had " .. tostring(inv.ItemCount) .. "residual items; cleared; " .. inv:getStack(0).item.type:getName())
            end
            inv:flush()
        end
    end
    for _,id in pairs(inputs) do
        print(id)
        local splitter = component.proxy(id)
        local _space = explode(" ", splitter.nick)
        local bus = _space[2]
        station.inputCount = station.inputCount + 1
        station.inputs[station.inputCount] = getBus(bus)
        if station.inputCount > 1 then
            if not station.inputs[station.inputCount].paired then
                station.inputs[station.inputCount].paired = {}
            end
            if not station.inputs[station.inputCount].paired[station.inputs[station.inputCount - 1].name] then
                station.inputs[station.inputCount].paired[station.inputs[station.inputCount - 1].name] = station.inputs[station.inputCount - 1]
            end
        end
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
    --stations[comp] = station
    table.insert(stations, station)
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

table.sort(stations, function(a,b)
    return a.index < b.index
end)


rmessage("Computer started")

local printQueue = true

--queue2("Iron Plate", 2)

local stationWidth = 25

function paintStation(station, x, y)
    local lx = x
    --
    local mx = 0
    local width = stationWidth
    local height = 5
    local c = 0
    local pdirection
    for _,input in pairs(station.inputs) do
        --print(input.name .. " :before " .. tostring(input.paintX))
        if input.pdirection == "right" and input.paintX > mx then
            mx = input.paintX
            pdirection = "right"
        elseif input.pdirection == "left" and input.paintX < mx or mx == 0 then
            mx = input.paintX
            pdirection = "left"
        end
        computer.skip()
    end
    --print(station.reference.nick .. " mx " .. tostring(mx) )

    local cy = y + 2
    local cx = mx
    if pdirection == "left" then
        mx = mx - width
    end
    --print("pdirection="..pdirection..", mx=" .. tostring(mx) .. ", cx=" .. tostring(cx) .. ", cy=" .. tostring(cy))
    if true then
        screens:dsetForeground(0, 0.7,0.3,0.7,1)
        if station.toProduce > 0 then
            screens:dsetForeground(0, 0.7,0.7,0.3,1)
        elseif station.error then
            screens:dsetForeground(0, 1,0.3,0.3,1)
        else
            screens:dsetForeground(0, 0.7,1,0.7,1)
        end
        screens:dprint(0, mx + 0, cy, station.name)
        cy = cy + 1

        if station.toProduce > 0 then
            screens:dsetForeground(0, 0.1,0.7,0.1,1)
            screens:dprint(0, mx + 0, cy, "←")
            screens:dsetForeground(0, 0.7,0.7,0.7,1)
            screens:dprint(0, mx + 2, cy, station.workObject)
            screens:dsetForeground(0, 0.3,0.3,1,1)
            screens:dprint(0, mx + width - 2 - 5, cy, string.format("%3d", station.toProduce))
            cy = cy + 1
        end
        if printQueue then
            local f = station.queue.first
            while f do
                screens:dsetForeground(0, 0.7,0.7,0.2,1)
                screens:dprint(0, mx + 2, cy, "→")
                screens:dsetForeground(0, 0.7,0.7,0.7,1)
                screens:dprint(0, mx + 4, cy, f.value.name)
                screens:dsetForeground(0, 0.3,0.3,1,1)
                screens:dprint(0, mx + width - 2 - 5, cy, string.format("%3d", f.value.count))
                cy = cy + 1
                f = f.next
                computer.skip()
            end
        end

        c = 0
        screens:dsetForeground(0, 0.7,0.7,0.5,1)
        screens:dprint(0, mx - 1, y + 1, "┌")
        screens:dfill(0, mx, y + 1, width - 2, 1, "─")
        screens:dfill(0, mx, y + 1 + height, width - 2, 1, "─")
        c = 0
        for _,input in pairs(station.inputs) do
            screens:dsetForeground(0, 0.3,0.3,0.3,1)
            screens:dfill(0, input.paintX, input.paintY, mx - input.paintX + width, 1, "═")
            screens:dprint(0, mx + c, input.paintY, "╦")
            screens:dfill(0, mx + c, input.paintY + 1, 1, y - input.paintY - 1, "║")
            computer.skip()
            screens:dsetForeground(0, 0.7,0.7,0.5,1)
            screens:dprint(0, mx + c, y + 1, "╨")
            c = c + 2
        end
        screens:dprint(0, mx + width - 2, y + 1, "┐")
        screens:dprint(0, mx - 1, y + 1 + height, "└")
        screens:dprint(0, mx + width - 2, y + 1 + height, "┘")
        screens:dfill(0, mx - 1, y + 2, 1, height - 1, "│")
        screens:dfill(0, mx + width - 2, y + 2, 1, height - 1, "│")
        screens:dsetForeground(0, 0.3,0.3,0.3,1)
    end
    if pdirection == "right" then
        x = mx + width
    elseif pdirection == "left" then
        x = mx
    end
    for _,input in pairs(station.inputs) do
        input.paintX = x
        --print(input.name .. ":after " .. tostring(input.paintX))
    end
    return x - lx, y + height
end

function printSnake2(bus, lowX, fromY, toY, sub, maxsnake)
    local __y = toY
    screens:dfill(0, bus.paintX - 1, bus.paintY, sub + 1, 1, "═")
    screens:dprint(0, bus.paintX + sub, bus.paintY, "╗")
    screens:dfill(0, bus.paintX + sub, bus.paintY + 1, 1, toY - bus.paintY - 3 + sub, "║")
    screens:dprint(0, bus.paintX + sub, __y - 2 + sub, "╝")
    screens:dfill(0, lowX + 2 + sub, __y - 2 + sub, bus.paintX + sub - (lowX + 2 + sub), 1, "═")
    screens:dprint(0, lowX + 2 + sub, __y - 2 + sub, "╔")
    local lowY = __y - sub + maxsnake
    screens:dfill(0, lowX + 2 + sub, __y - 1 + sub, 1, (lowY - (__y - 1 + sub)), "║")
    screens:dprint(0, lowX + 2 + sub, lowY, "╚")
    fromY = __y + maxsnake - sub
    bus.paintY = fromY
    bus.paintX = lowX + 3 + sub
    computer.skip()
    return lowX, fromY
end

function printSnake(bus, lowX, fromY, toY, sub, maxsnake)
    local __y = toY
    local oldDirection = bus.pdirection
    if oldDirection == "right" then
        screens:dfill(0, bus.paintX - 1, bus.paintY, sub + 1, 1, "═")
        screens:dprint(0, bus.paintX + sub, bus.paintY, "╗")
        screens:dfill(0, bus.paintX + sub, bus.paintY + 1, 1, toY - bus.paintY - 3 + sub, "║")
        screens:dprint(0, bus.paintX + sub, __y - 2 + sub, "╝")
        screens:dfill(0, lowX + 2 + sub, __y - 2 + sub, bus.paintX + sub - (lowX + 2 + sub), 1, "═")
        fromY = __y + maxsnake + sub - 3
        bus.paintY = __y - 2 + sub
        bus.paintX = bus.paintX + 3
        bus.pdirection = "left"
    else
        local x = lowX
        screens:dfill(0, x + sub, bus.paintY, bus.paintX - x - sub, 1, "═")
        screens:dprint(0, x + sub, bus.paintY, "╔")
        screens:dfill(0, x + sub, bus.paintY + 1, 1, toY - bus.paintY - 3 + sub, "║")
        screens:dprint(0, x + sub, __y - 2 + sub, "╚")
        screens:dfill(0, x + sub + 1, __y - 2 + sub, maxsnake, 1, "═")
        fromY = __y + maxsnake + sub - 3
        bus.paintY = __y - 2 + sub
        bus.paintX = x + sub + maxsnake
        bus.pdirection = "right"
    end
    computer.skip()
    return lowX, fromY
end

function printBus2(bus, x, y)
    screens:dsetForeground(0, 0.7,0.7,0.7,1)
    screens:dprint(0, x, 0, bus.name)
    --screens:dprint(0, x, 1, bus.name)
    screens:dsetForeground(0, 0.3,0.3,0.3,1)
    y = y + 1
    screens:dfill(0, x, 1, 1, screens.cellHeight - 1, "║")
    --for _y = 1,screens.cellHeight - 1,1 do
    --    screens:dprint(0, x, _y, "║")
    --end
    bus.paintX = x
    local _y = y + 1
    local c = 0
    for _,child in pairs(sortedBusses) do
        c = c + 1
    end
    local n = false
    local bx = x + c * 2
    local cindex = 0
    local drawWidth = screens.cellWidth - stationWidth - 30
    for _,child in pairs(bus.children) do
        local maxY = _y
        local maxX = 0
        screens:dprint(0, x, _y, "╠")
        screens:dfill(0, x + 1, _y, c * 2 - 1, 1, "═")
        --for _c = 1,c*2,1 do
        --    screens:dprint(0, x + _c, _y, "═")
        --end
        child.paintX = bx
        child.paintY = _y
        child.painted = true
        screens:dsetForeground(0, 0.7,0.7,0.3,1)
        screens:dprint(0, child.paintX - 3, child.paintY - 1, child.name)
        if child.queue.length > 0 then
            screens:dsetForeground(0, 0.3,0.3,0.7,1)
            screens:dprint(0, child.paintX - 3 + string.len(child.name) + 2, child.paintY - 1, string.format("%5d", child.queue.length))
            screens:dsetForeground(0, 0.7,0.7,0.3,1)
            screens:dprint(0, child.paintX - 3 + string.len(child.name) + 2 + 5, child.paintY - 1, " items")
        else
            screens:dsetForeground(0, 0.3,0.3,0.3,1)
            screens:dprint(0, child.paintX - 3 + string.len(child.name) + 2, child.paintY - 1, "Nothing needed")
        end

        screens:dsetForeground(0, 0.3,0.3,0.3,1)
        local qx = 0; local qy = 0
        for _,q in pairs(stations) do
            computer.skip()
            if q.inputs then
                if q.inputs.name then
                    local lbus = q.inputs
                    if lbus.name == child.name then
                        qx, qy = paintStation(q, x + 5, _y)
                    end
                else
                    local depPainted = true
                    local paint = false
                    for _,lbus in pairs(q.inputs) do
                        --print(lbus.name)
                        if child.name == lbus.name then
                            paint = true
                        end
                        if not lbus.painted then
                            depPainted = false
                            break
                        end
                    end
                    if depPainted and paint then
                        if (child.pdirection == "right" and child.paintX > drawWidth - 1) or (child.pdirection == "left" and child.paintX < bx + 4) then
                            local maxSnake = 1
                            if child.paired then
                                maxSnake = 2
                            end
                            x, _y = printSnake(child, bx, _y, maxY + 5, cindex, maxSnake)
                            if child.paired then
                                local mod = 1
                                for _,p in pairs(child.paired) do
                                    printSnake(p, bx, _y, maxY + 5, cindex + mod, maxSnake)
                                    mod = mod + 1
                                end
                            end
                        end
                        --print("Meow")
                        qx, qy = paintStation(q, x + 5, _y)
                        --lbus.parent.paintX = x + qx
                    elseif not depPainted then
                        --print("No deps for "..q.reference.nick)
                    else
                        --print("No paint for "..q.reference.nick)
                    end
                end
            end
            x = x + qx
            if maxY < qy then
                maxY = qy
            end
            computer.skip()
        end
        _y = maxY + 1
        cindex = cindex + 1
    end
    return _y
end

function printScreen()
    screens:clear()
    local x = 2
    local y = 1
    for _,bus in pairs(busses) do
        bus.painted = false
        bus.pdirection = "right"
    end
    for _,bus in pairs(sortedBusses) do
        if not bus.parent then
            y = printBus2(bus, x, y)
            x = x + 2
        end
    end
    screens:dsetForeground(0, 0.3,0.3,0.3,1)
    screens:dfill(0,  screens.cellWidth - 30, 0, 1, screens.cellHeight, "┃")
    --for _y = 0,screens.cellHeight,1 do
    --    screens:dprint(0,  screens.cellWidth - 50, _y, "┃")
    --end
    screens:dsetForeground(0, 0.7,0.7,0.7,1)
    x = screens.cellWidth - 29
    screens:dprint(0, x,0,"Future");
    y = 1
    local item = orderQueue.first
    if item then
        local m = 0
        while item do
            m = m + 1
            screens:dsetForeground(0, 0.7,0.7,0.7,1)
            screens:dprint(0,  x+ 2, y, item.value.name)
            screens:dsetForeground(0, 0.3,0.3,1,1)
            screens:dprint(0, x + 23, y, string.format("%3d", item.value.count))
            item = item.next
            y = y + 1
            if y + 2 > screens.cellHeight then
                screens:dsetForeground(0, 0.7,0.7,0.7,1)
                screens:dprint(0, x,y, " + " .. tostring(orderQueue.length - m) .. " more")
                break
            end
        end
    else
        screens:dsetForeground(0, 1,1,0.6,1)
        screens:dprint(0,  x+ 2, y, "Nothing to do")
        y = y + 1
    end

    screens:flush()
end

function printScreen2()
    screens:clear()
    local y = 0
    local x = 0
    local c = 35
    screens:dsetForeground(0, 0.7,0.7,0.3,1)
    screens:dprint(0, x,y,"Busses"); x,y = gColumnAdvance(x,y,c)
    for _,bus in pairs(busses) do
        if bus.parent then
            screens:dsetForeground(0, 0.7,0.7,0.3,1)
            screens:dprint(0,  x+ 2, y, bus.parent.name)
            screens:dsetForeground(0, 0.7,0.7,0.7,1)
            screens:dprint(0, x + string.len(bus.parent.name) + 4, y, "> " .. bus.name)
            if bus.queue then
                screens:dsetForeground(0, 0.3,0.3,1,1)
                screens:dprint(0, x + 28, y, string.format("%5d", bus.queue.length))
            end
            screens:dsetForeground(0, 0.7,0.7,0.7,1)
            x,y = gColumnAdvance(x, y, c)
            if printQueue and bus.queue then
                local f = bus.queue.first
                while f do
                    screens:dsetForeground(0, 0.6,0.4,0.4,1)
                    screens:dprint(0, x + 4, y, f.value.name .. "   "  .. string.format("%3d", f.value.count))
                    x,y = gColumnAdvance(x, y, c)
                    f = f.next
                end
            end
        end
    end
    y = y + 1
    screens:dsetForeground(0, 0.7,0.7,0.7,1)
    screens:dprint(0, x,y,"Future"); x,y = gColumnAdvance(x,y,c)
    local item = orderQueue.first
    if item then
        local m = 0
        while item do
            m = m + 1
            screens:dsetForeground(0, 0.7,0.7,0.7,1)
            screens:dprint(0,  x+ 2, y, item.value.name)
            screens:dsetForeground(0, 0.3,0.3,1,1)
            screens:dprint(0, x + 23, y, string.format("%3d", item.value.count))
            item = item.next
            x,y = gColumnAdvance(x, y, c)
            if y + 2 > screens.cellHeight then
                screens:dsetForeground(0, 0.7,0.7,0.7,1)
                screens:dprint(0, x,y, " + " .. tostring(orderQueue.length - m) .. " more")
                break
            end
        end
    else
        screens:dsetForeground(0, 1,1,0.6,1)
        screens:dprint(0,  x+ 2, y, "Nothing to do")
        x,y = gColumnAdvance(x, y, c)
    end

    y = 0
    x = 35
    c = 35
    screens:dsetForeground(0, 0.7,0.7,0.7,1)
    screens:dprint(0, x,y,"Stations"); x,y = gColumnAdvance(x,y,c)
    for _,station in pairs(stations) do
        if station.toProduce > 0 then
            screens:dsetForeground(0, 0.7,0.7,0.3,1)
        elseif station.error then
            screens:dsetForeground(0, 1,0.3,0.3,1)
        else
            screens:dsetForeground(0, 0.7,1,0.7,1)
        end
        screens:dprint(0, x + 2, y, station.name)
        x,y = gColumnAdvance(x, y, c)
        if station.toProduce > 0 then
            screens:dsetForeground(0, 0.7,0.7,0.7,1)
            screens:dprint(0, x + 4, y, station.workObject)
            screens:dsetForeground(0, 0.3,0.3,1,1)
            screens:dprint(0, x + 26, y, string.format("%3d", station.toProduce))
            x,y = gColumnAdvance(x, y, c)
        end
        if printQueue then
            local f = station.queue.first
            while f do
                screens:dsetForeground(0, 0.7,0.7,0.7,1)
                screens:dprint(0, x + 6, y, f.value.name)
                screens:dsetForeground(0, 0.3,0.3,1,1)
                screens:dprint(0, x + 26, y, string.format("%3d", f.value.count))
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
        printScreen()
        --status, err = pcall(printScreen)
        if err then
            rerror("Error in print; ".. tostring(err))
            error(err)
        end
        status, err = pcall(processOrderQueue)
        if err then
            rerror("Error in print; ".. tostring(err))
            error(err)
        end
        seldomCounter = 5000
    else
        seldomCounter = seldomCounter - 1
    end
end
