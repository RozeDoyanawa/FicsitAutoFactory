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
        station.input.isBus = false
        splitters:push({
            reference = splitter,
            object = station,
            name = bus
        })
        --event.listen(splitter)
        break
    end
    station.pinputs = {
        station.unpackerBus.parent,
        station.packerBus.parent,
        station.input
    }
    station.unpackerBus.parent.isBus = false
    station.packerBus.parent.isBus = false
    --station.input.parent.isBus = false
    station.unpackerBus.isBus = false
    station.packerBus.isBus = false
    station.unpackerBus.pignore = true
    station.packerBus.pignore = true
    --station.input.pignore = true
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
table.sort(stations, function(a,b)
    return a.index < b.index
end)



rmessage("Computer started")

local printQueue = true

--globalStation:order("Plastic", 1)

--queue2("Iron Plate", 2)

--queue2("Rubber", 66)


local stationWidth = 25

function paintStation(station, x, y)
    local lx = x
    --
    local mx = 0
    local width = stationWidth
    local height = 10
    local c = 0
    local pdirection
    for _,input in pairs(station.pinputs) do
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

    if station.remainingSolid > 0 then
        screens:dsetForeground(0, 0.1,0.7,0.1,1)
        screens:dprint(0, mx + 0, cy, "←")
        screens:dsetForeground(0, 0.7,0.7,0.7,1)
        screens:dprint(0, mx + 2, cy, station.outputSolid)
        screens:dsetForeground(0, 0.3,0.3,1,1)
        screens:dprint(0, mx + width - 2 - 3, cy, string.format("%3d", station.remainingSolid))
        cy = cy + 1
    end
    if station.remainingFluid > 0 then
        screens:dsetForeground(0, 0.1,0.7,0.1,1)
        screens:dprint(0, mx + 0, cy, "←")
        screens:dsetForeground(0, 0.7,0.7,0.7,1)
        screens:dprint(0, mx + 2, cy, station.outputFluid)
        screens:dsetForeground(0, 0.3,0.3,1,1)
        screens:dprint(0, mx + width - 2 - 3, cy, string.format("%3d", station.remainingFluid))
        cy = cy + 1
    end
    if printQueue then
        local f
        f = station.unpackerBus.queue.first
        while f do
            screens:dsetForeground(0, 0.7,0.7,0.2,1)
            screens:dprint(0, mx + 1, cy, "→")
            screens:dsetForeground(0, 0.7,0.7,0.7,1)
            screens:dprint(0, mx + 3, cy, f.value.name)
            screens:dsetForeground(0, 0.3,0.3,1,1)
            screens:dprint(0, mx + width - 2 - 3, cy, string.format("%3d", f.value.count))
            cy = cy + 1
            f = f.next
        end
        f = station.input.queue.first
        while f do
            screens:dsetForeground(0, 0.7,0.7,0.2,1)
            screens:dprint(0, mx + 1, cy, "→")
            screens:dsetForeground(0, 0.7,0.7,0.7,1)
            screens:dprint(0, mx + 3, cy, f.value.name)
            screens:dsetForeground(0, 0.3,0.3,1,1)
            screens:dprint(0, mx + width - 2 - 3, cy, string.format("%3d", f.value.count))
            cy = cy + 1
            f = f.next
        end
        f = station.packerBus.queue.first
        while f do
            screens:dsetForeground(0, 0.7,0.7,0.2,1)
            screens:dprint(0, mx + 1, cy, "→")
            screens:dsetForeground(0, 0.7,0.7,0.7,1)
            screens:dprint(0, mx + 3, cy, f.value.name)
            screens:dsetForeground(0, 0.3,0.3,1,1)
            screens:dprint(0, mx + width - 2 - 3, cy, string.format("%3d", f.value.count))
            cy = cy + 1
            f = f.next
        end
    end

    screens:dsetForeground(0, 0.3,0.3,0.3,1)
    c = 0
    screens:dsetForeground(0, 0.7,0.7,0.5,1)
    screens:dprint(0, mx - 1, y + 1, "┌")
    screens:dfill(0, mx, y + 1, width - 2, 1, "─")
    screens:dfill(0, mx, y + 1 + height, width - 2, 1, "─")
    c = 0
    for _,input in pairs(station.pinputs) do
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
    if pdirection == "right" then
        x = mx + width
    elseif pdirection == "left" then
        x = mx
    end
    for _,input in pairs(station.pinputs) do
        input.paintX = x
        --print(input.name .. ":after " .. tostring(input.paintX))
    end
    return x - lx, y + height
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
    --screens:dprint(0, x, 1, bus.name)
    screens:dsetForeground(0, 0.3,0.3,0.3,1)
    y = y + 1
    screens:dfill(0, x, 1, 1, screens.cellHeight - 1, "║")
    bus.paintX = x
    local _y = y + 1
    local c = 2 * 2
    for _,child in pairs(busses) do
        --c = c + 1
    end
    local n = false
    local bx = x + c * 2
    local cindex = 0
    local drawWidth = screens.cellWidth - stationWidth - 50
    if not bus.children then
        return y
    end
    for _,child in pairs(bus.children) do
        if child.pignore then
        else
            local maxY = _y
            local maxX = 0
            screens:dprint(0, x, _y, "╠")
            for _c = 1,c*2,1 do
                screens:dprint(0, x + _c, _y, "═")
            end
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
            if child.isBus then
                local px = child.paintX
                screens:dsetForeground(0, 0.3,0.3,0.3,1)
                --screens:dprint(0, px, _y, child.name)
                screens:dprint(0, px, _y, "╦")
                screens:dprint(0, px, _y + 1, "║")
                screens:dprint(0, px, _y + 2, "║")
                screens:dprint(0, px, _y + 3, "╚")
                y = printBus2(child, px, _y + 2)
                y = y + 5
            else
                screens:dsetForeground(0, 0.3,0.3,0.3,1)
                local qx = 0; local qy = 0
                for _,q in pairs(stations) do
                    computer.skip()
                    if q.pinputs then
                        if q.pinputs.name then
                            local lbus = q.pinputs
                            if lbus.name == child.name then
                                qx, qy = paintStation(q, x + 5, _y)
                            end
                        else
                            local depPainted = true
                            local paint = false
                            for _,lbus in pairs(q.pinputs) do
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
                                --print("Meow")
                                if (child.pdirection == "right" and child.paintX > drawWidth - 1) or (child.pdirection == "left" and child.paintX < bx + 4) then
                                    x, _y = printSnake(child, bx, _y, maxY + 5, cindex, 2)
                                    if child.paired then
                                        local mod = 1
                                        for _,p in pairs(child.paired) do
                                            printSnake(p, bx, _y, maxY + 5, cindex + mod, 2)
                                            mod = mod + 1
                                        end
                                    end
                                end
                                qx, qy = paintStation(q, x + 5, _y)
                                --lbus.parent.paintX = x + qx
                            elseif not depPainted then
                                --print("No deps for "..q.reference.nick)
                            else
                                --print("No paint for "..q.reference.nick)
                            end
                        end
                    end
                    qy = math.max(qy, _y + 2)
                    x = x + qx
                    if maxY < qy then
                        maxY = qy
                    end
                    computer.skip()
                end
            end
            _y = maxY + 1
            cindex = cindex + 1
        end
    end
    return _y
end

function printScreen()
    screens:clear()
    local x = 2
    for _,bus in pairs(busses) do
        bus.painted = false
        bus.pdirection = "right"
    end
    for _,bus in pairs(busses) do
        local y = 1
        if not bus.parent then
            screens:dsetForeground(0, 0.7,0.7,0.7,1)
            screens:dprint(0, x, 0, bus.name)
            y = printBus2(bus, x, y)
            x = x + 2
        end
    end
    screens:dsetForeground(0, 0.3,0.3,0.3,1)
    screens:dfill(0,  screens.cellWidth - 30, 0, 1, screens.cellHeight, "┃")
    screens:dsetForeground(0, 0.7,0.7,0.7,1)
    x = screens.cellWidth - 49
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

function printBus3(bus, x, y, xmax)
    screens:dsetForeground(0, 0.7,0.7,0.7,1)
    screens:dprint(0, x + 2, y, bus.name)
    if bus.queue then
        screens:dsetForeground(0, 0.3,0.3,1,1)
        screens:dprint(0, xmax - 7, y, string.format("%5d", bus.queue.length))
    end
    screens:dsetForeground(0, 0.7,0.7,0.7,1)
    y = y + 1
    screens:dsetForeground(0, 0.7,0.7,0.7,1)
    screens:dprint(0, x + 4, y, "L:" .. tostring(bus.localOutput) .. " B:" ..tostring(bus.busOutput))
    y = y + 1
    if printQueue and bus.queue then
        local f = bus.queue.first
        while f do
            screens:dsetForeground(0, 0.6,0.4,0.4,1)
            screens:dprint(0, x + 4, y, f.value.name .. "   "  .. string.format("%3d", f.value.count))
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

function printScreen2()
    screens:clear()
    local y = 0
    local x = 0
    local c = 45
    screens:dsetForeground(0, 0.7,0.7,0.7,1)
    screens:dprint(0, x,y,"Busses"); x,y = gColumnAdvance(x,y,c)
    for _,bus in pairs(busses) do
        if not bus.parent then
            y = printBus(bus, x, y, x + c)
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
    x = x + c
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
        if station.remainingSolid > 0 then
            screens:dsetForeground(0, 0.7,0.7,0.7,1)
            screens:dprint(0, x + 4, y, station.outputSolid)
            screens:dsetForeground(0, 0.3,0.3,1,1)
            screens:dprint(0, x + 26, y, string.format("%3d", station.remainingSolid))
            x,y = gColumnAdvance(x, y, c)
        end
        if station.remainingFluid > 0 then
            screens:dsetForeground(0, 0.7,0.7,0.7,1)
            screens:dprint(0, x + 4, y, station.outputFluid)
            screens:dsetForeground(0, 0.3,0.3,1,1)
            screens:dprint(0, x + 26, y, string.format("%3d", station.remainingFluid))
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
        seldomCounter = 5000
    else
        seldomCounter = seldomCounter - 1
    end
end
