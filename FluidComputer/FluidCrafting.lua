--
-- Created by IntelliJ IDEA.
-- User: Roze
-- Date: 2020-08-22
-- Time: 09:53
-- To change this template use File | Settings | File Templates.
--

local panel = component.proxy(component.findComponent("Crafting Panel 1")[1])

local itemManagerAddress = "429823144AEF8331B86B00943C6576F9"

local stations = {}

local orderQueue = createLinkedList()

local fluids = {
    ["Heavy Oil Residue"] = {
        name = "Heavy Oil Residue",
        packaged = "Packaged Heavy Oil Residue",
        unpack = "Unpackage Heavy Oil Residue",
        pack = "Packaged Heavy Oil Residue"
    },
    ["Water"] = {
        name = "Water",
        packaged = "Packaged Water",
        unpack = "Unpackage Water",
        pack = "Packaged Water"
    },
    ["Crude Oil"] = {
        name = "Crude Oil",
        packaged = "Packaged Oil",
        unpack = "Unpackage Oil",
        pack = "Packaged Oil"
    },
    ["Fuel"] = {
        name = "Fuel",
        packaged = "Packaged Fuel",
        unpack = "Unpackage Fuel",
        pack = "Packaged Fuel"
    },
    ["Liquid Biofuel"] = {
        packaged = "Packaged Liquid Biofuel",
        name = "Liquid Biofuel",
        unpack = "Unpackage Liquid Biofuel",
        pack = "Packaged Liquid Biofuel"
    },
}

function queue2(recipeName, count)
    orderQueue:push({
        name = recipeName,
        count = count
    })
    processOrderQueue()
end

function queue2First(recipeName, count)
    --print("Adding to queue2")
    orderQueue:shift({
        name = recipeName,
        count = count
    })
    processOrderQueue()
end

function processOrderQueue()
    local i = orderQueue.first
    while i do
        for _,station in pairs(stations) do
            if station:canMake(i.value.name) then
                i:delete()
                station:order(i.value.name, i.value.count)
                return
            end
        end
        i = i.next
    end
end

function clearInventories(manufacturer)
    for _,v in pairs(manufacturer:getInventories()) do
        v:flush()
    end
end

function createStation(comp, stationIndex, prefix)
    print("Create station: " .. comp.nick)
    local inputFilter = prefix .. "_" .. stationIndex .. "_Input"
    local inputs = component.findComponent(inputFilter)
    local station = {
        name = "Station " .. stationIndex,
        index = tonumber(stationIndex),
        reference = comp,
        input = nil,
        inputCount = 0,
        toProduce = 0,
        recipe = {},
        localOutput = 2,
        busOutput = 1,
        nextInput = 1,
        remainingFluid = 0,
        remainingSolid = 0,
        packerBus = getBus(prefix .. "_" .. tostring(stationIndex) .. "_Packer_Input"),
        packer = component.proxy(component.findComponent(prefix .. "_" .. tostring(stationIndex) .. "_Packer")[1]),
        unpackerBus = getBus(prefix .. "_" .. tostring(stationIndex) .. "_Unpack_Input"),
        unpacker = component.proxy(component.findComponent(prefix .. "_" .. tostring(stationIndex) .. "_Unpack")[1]),
        queue = createLinkedList(),
        order = function(self, recipeName, count)
            for i,recipe in pairs(self.reference:getRecipes()) do
                if recipe:getName() == recipeName then
                    clearInventories(self.reference)
                    clearInventories(self.packer)
                    clearInventories(self.unpacker)
                    self.reference:setRecipe(recipe)
                    print("Craft order for " .. tostring(count) .. " " .. recipeName)
                    --error()
                    local __count = 0
                    local inputSolid = nil
                    local inputSolidCount = nil
                    local outputFluid = nil
                    local outputFluidCount = nil
                    local outputSolid = nil
                    local outputSolidCount = nil
                    local inputFluid = nil
                    local inputFluidCount = nil
                    for _,v in pairs(recipe:getProducts()) do
                        local name = v.item:getName()
                        if name == recipeName then
                            __count = v.count
                        end
                        if fluids[name] then
                            outputFluid = name
                            outputFluidCount = math.ceil(v.count / 1000)
                            print("Output Fluid: " .. outputFluid .. " / " .. tostring(outputFluidCount))
                        else
                            outputSolid = name
                            outputSolidCount = v.count
                            print("Output Solid: " .. outputSolid)
                        end
                    end

                    local _count = math.ceil(count / __count)
                    print("count / __count = " .. tostring(count) .. " / " .. tostring(__count) .. " = " .. tostring(_count))

                    for i2,v in pairs(recipe:getIngredients()) do
                        local name = v.item:getName()
                        if fluids[name] then
                            inputFluid = name
                            inputFluidCount = math.ceil(v.count / 1000)
                            print("Input Fluid: " .. inputFluid .. " / " .. tostring(inputFluidCount))
                        else
                            inputSolid = name
                            inputSolidCount = v.count
                            print("Input Fluid: " .. inputSolid)
                        end
                    end

                    if inputFluid then
                        local urecipes = self.unpacker:getRecipes()
                        for _,urecipe in pairs(urecipes) do
                            --print("Recipe: " .. urecipe:getName())
                            --print("Look for: " .. fluids[inputFluid].unpack)
                            if urecipe:getName() == fluids[inputFluid].unpack then
                                print("InputFluidCount * _count = " .. tostring(inputFluidCount) .. " * " .. tostring(_count) .. " = " .. inputFluidCount * _count)
                                print("IngredientCount = " .. tostring(urecipe:getIngredients()[1].count))
                                local amount = math.ceil((inputFluidCount * (_count + 1)) / urecipe:getIngredients()[1].count) * urecipe:getIngredients()[1].count
                                self.unpacker:setRecipe(urecipe)
                                self.unpackerBus:request(fluids[inputFluid].packaged, amount + 2 )
                                inputFluid = nil
                                break
                            end
                        end
                        if inputFluid then
                            error("No unpack recipe for fluid " .. outputFluid)
                        end
                    end
                    if outputFluid then
                        local urecipes = self.packer:getRecipes()
                        for _,urecipe in pairs(urecipes) do
                            --print("Recipe: " .. urecipe:getName())
                            --print("Look for: " .. fluids[outputFluid].pack)
                            if urecipe:getName() == fluids[outputFluid].pack then
                                print("outputFluidCount * _count = " .. tostring(outputFluidCount) .. " * " .. tostring(_count) .. " = " .. outputFluidCount * _count)
                                local ing1 = urecipe:getIngredients()[1]
                                local ing2 = urecipe:getIngredients()[2]
                                local ing = nil
                                if ing1.item:getName() == "Empty Canister" then
                                    ing = ing1
                                else
                                    ing = ing2
                                end
                                print("IngredientCount = " .. tostring(ing.count))
                                local amount = math.ceil((outputFluidCount * _count) / ing.count) * ing.count
                                self.packer:setRecipe(urecipe)
                                self.packerBus:request("Empty Canister", math.ceil(amount))
                                self.remainingFluid = self.remainingFluid + _count * outputFluidCount - 2
                                self.outputFluid = outputFluid
                                outputFluid = nil
                                break
                            end
                        end
                        if outputFluid then
                            error("No package recipe for fluid " .. outputFluid)
                        end
                    end
                    if inputSolid then
                        self.input:request(inputSolid, inputSolidCount)
                    end
                    if outputSolid then
                        self.outputSolid = outputSolid
                        self.remainingSolid = self.remainingSolid + _count * outputSolidCount
                    end
                    return true
                end
            end
        end,
        canMake = function(self, recipeName)
            if self.remainingSolid > 0 or self.remainingFluid > 0 then
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
        if inv.ItemCount > 0 then
            rmessage(station.name .. " had " .. tostring(inv.ItemCount) .. "residual items; cleared")
        end
        inv:flush()
    end
    for _,id in pairs(inputs) do
        print(id)
        local splitter = component.proxy(id)
        local _space = explode(" ", splitter.nick)
        local bus = _space[2]
        station.inputCount = station.inputCount + 1
        station.input = getBus(bus)
        --registerEvent(splitter, {station = station, splitter = splitter}, function(self, evt, params, po)
        --    processSplitterOutput(self.station, self.splitter)
        --end)
        splitters:push({
            reference = splitter,
            object = station,
            name = bus
        })
        --event.listen(splitter)
        break
    end
    print("OC = " .. tostring(1))
    local connector = station.reference:getFactoryConnectors()[station.outputConnector]
    registerEvent(connector, station, function(self, param)
        --print(tostring(param))
        self.remainingSolid = self.remainingSolid - 1
        if self.remainingSolid < 0 then
            rwarning("Mysterious extra item from " .. tostring(station.index))
        end
        if self.remainingSolid <= 0 then
            self.remainingSolid = 0
        end
    end)
    station.outConnector = connector
    event.listen(connector)
    connector = station.packer:getFactoryConnectors()[1]
    registerEvent(connector, station, function(self, param)
        --print(tostring(param))
        self.remainingFluid = self.remainingFluid - 1
        if self.remainingFluid < 0 then
            rwarning("Mysterious extra item from " .. tostring(station.index))
        end
        if self.remainingFluid <= 0 then
            self.remainingFluid = 0
        end
    end)
    station.outConnector2 = connector
    event.listen(connector)
    stations[comp] = station
    globalStation = station
end

function enumStations(prefix)
    local allComps = component.findComponent("")
    for _,id in pairs(allComps) do
        local comp = component.proxy(id)
        local _spaces = explode(" ", comp.nick)
        local q = explode("_", comp.nick)
        if _spaces[1] == comp.nick and q[1] == prefix and q[3] == nil then
            local index = q[2]
            createStation(comp, index, prefix)
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
        scriptInfo.network:send(itemManagerAddress, 100, "enumRecipesDone", recipeIndex, scriptInfo.name)
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
                local name = regent.item:getName()
                local _count = regent.count
                if fluids[name] then
                    name = fluids[name].packaged
                    _count = math.ceil(_count / 1000)
                end
                data = data .. name .. "#" .. _count
                count = count + 1
            end
            sendParams[3] = data
            sendParams[4] = recipeIndex
            if count > 0 then
                --for k,v in pairs(sendParams) do
                --    print(k .. " = " .. v)
                --end
                scriptInfo.network:send(itemManagerAddress, 100, table.unpack(sendParams))
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

--globalStation:order("Plastic", 1)

--queue2("Iron Plate", 2)

function printBus(bus, x, y, xmax)
    screens:setForeground(0.7,0.7,0.7,1)
    screens:print(x + 2, y, bus.name)
    if bus.queue then
        screens:setForeground(0.3,0.3,1,1)
        screens:print(xmax - 7, y, string.format("%5d", bus.queue.length))
    end
    screens:setForeground(0.7,0.7,0.7,1)
    y = y + 1
    screens:setForeground(0.7,0.7,0.7,1)
    screens:print(x + 4, y, "L:" .. tostring(bus.localOutput) .. " B:" ..tostring(bus.busOutput))
    y = y + 1
    if printQueue and bus.queue then
        local f = bus.queue.first
        while f do
            screens:setForeground(0.6,0.4,0.4,1)
            screens:print(x + 4, y, f.value.name .. "   "  .. string.format("%3d", f.value.count))
            y = y + 1
            f = f.next
        end
    end
    for _,bus2 in pairs(busses) do
        if bus2.parent and bus2.parent == bus then
            y = printBus(bus2, x + 2, y, xmax)
        end
    end
    return y
end

function printScreen()
    screens:clear()
    local y = 0
    local x = 0
    local c = 45
    screens:setForeground(0.7,0.7,0.7,1)
    screens:print(x,y,"Busses"); x,y = gColumnAdvance(x,y,c)
    for _,bus in pairs(busses) do
        if not bus.parent then
            y = printBus(bus, x, y, x + c)
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
    x = x + c
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
        if station.remainingSolid > 0 then
            screens:setForeground(0.7,0.7,0.7,1)
            screens:print(x + 4, y, station.outputSolid)
            screens:setForeground(0.3,0.3,1,1)
            screens:print(x + 26, y, string.format("%3d", station.remainingSolid))
            x,y = gColumnAdvance(x, y, c)
        end
        if station.remainingFluid > 0 then
            screens:setForeground(0.7,0.7,0.7,1)
            screens:print(x + 4, y, station.outputFluid)
            screens:setForeground(0.3,0.3,1,1)
            screens:print(x + 26, y, string.format("%3d", station.remainingFluid))
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

--queue2("Rubber", 66)

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
    if err then
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
