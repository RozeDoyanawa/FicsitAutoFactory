--
-- Created by IntelliJ IDEA.
-- User: Roze
-- Date: 2020-08-15
-- Time: 11:51
-- To change this template use File | Settings | File Templates.
--


local dev = component.proxy(component.findComponent("Smelting Computer Network Adapter")[1])
scriptInfo.name = "Smelting"
scriptInfo.network = dev
if dev then
    dev:open(100)
    event.listen(dev)
else
    print ("No such adapter")
end

local itemManagerAddress = "429823144AEF8331B86B00943C6576F9"

local busses = {}
local outputSplitters = {}

local sourceOutputSlot = 1
local requestedItems = 0
local autoCraft = false
local doPurge = false


local panel = component.proxy(component.findComponent("Smelting Panel 1")[1])
local testButton = panel:getModule(0,0)
local purgeButton = panel:getModule(1,0)

local craftAmountDisplay = panel:getModule(0, 10)
local craftAmountPot = panel:getModule(4, 9)
local craftProcessButton = panel:getModule(4, 10)
local craftProcessButton2 = panel:getModule(5, 10)
local craftProcessButton3 = panel:getModule(6, 10)
local craftProcessButton4 = panel:getModule(7, 10)
local craftProcessButton5 = panel:getModule(8, 10)

local autoCraftButton = panel:getModule(10, 0)

local craftRequested = panel:getModule(0, 3)
local craftPassingby = panel:getModule(0, 5)

screens.init("Smelting", 1, 1, math.floor(115 * 1.25),math.floor(45 * 1.25))


craftAmountDisplay:setSize(100)
craftAmountDisplay:setMonospace(true)

craftRequested:setSize(100)
craftRequested:setMonospace(true)

craftPassingby:setSize(100)
craftPassingby:setMonospace(true)

testButton:setColor(0,1,0,4)
purgeButton:setColor(0,0,0,1)
autoCraftButton:setColor(1,0, 0, 1)

event.listen(testButton)
event.listen(purgeButton)
event.listen(craftProcessButton)
event.listen(craftProcessButton2)
event.listen(craftProcessButton3)
event.listen(craftProcessButton4)
event.listen(craftProcessButton5)
event.listen(craftAmountPot)
event.listen(autoCraftButton)

local craftingQueue = createLinkedList()

busses['A'] = {
    name = "A",
    sourceSplitters = {
        ["Iron Ore"] = component.proxy(component.findComponent("IronOreOutA")[1]),
        ["Copper Ore"] = component.proxy(component.findComponent("CopperOreOutA")[1]),
        ["Caterium Ore"] = component.proxy(component.findComponent("CateriumOutA")[1]),
        ["Coal"] = component.proxy(component.findComponent("CoalOutA")[1]),
        ["Bauxite"] = component.proxy(component.findComponent("BauxiteOutA")[1])
    },
    queue = createLinkedList(),
    children = {}
}
busses['B'] = {
    name = "B",
    sourceSplitters = {
        ["Iron Ore"] = component.proxy(component.findComponent("IronOreOutB")[1]),
        ["Copper Ore"] = component.proxy(component.findComponent("CopperOreOutB")[1]),
        ["Caterium Ore"] = component.proxy(component.findComponent("CateriumOutB")[1]),
        ["Coal"] = component.proxy(component.findComponent("CoalOutB")[1]),
        ["Bauxite"] = component.proxy(component.findComponent("BauxiteOutB")[1])
    },
    consumerSplitters = {
        [1] = {

        }
    },
    queue = createLinkedList(),
    children = {}
}

local sortedBusses = {
    busses.A,
    busses.B
}

table.sort(sortedBusses, function(a, b)
    return a.name < b.name
end)


local smelters = {
    {
        reference = component.proxy(component.findComponent("Smelter1")[1]),
        busses = {busses.A, busses.B},
        remaining = 0,
        queue = {},
        outputConnector = 1
    },
    {
        reference = component.proxy(component.findComponent("Smelter2")[1]),
        busses = {busses.A, busses.B},
        remaining = 0,
        queue = {},
        outputConnector = 1
    },
    {
        reference = component.proxy(component.findComponent("Smelter3")[1]),
        busses = {busses.A, busses.B},
        remaining = 0,
        queue = {},
        outputConnector = 1
    },
    {
        reference = component.proxy(component.findComponent("Smelter4")[1]),
        busses = {busses.A, busses.B},
        remaining = 0,
        queue = {},
        outputConnector = 1
    },
    {
        reference = component.proxy(component.findComponent("Smelter5")[1]),
        busses = {busses.A, busses.B},
        remaining = 0,
        queue = {},
        outputConnector = 1
    },
    {
        reference = component.proxy(component.findComponent("Smelter6")[1]),
        busses = {busses.A, busses.B},
        remaining = 0,
        queue = {},
        outputConnector = 1
    },
    {
        reference = component.proxy(component.findComponent("Smelter7")[1]),
        busses = {busses.A, busses.B},
        remaining = 0,
        queue = {},
        outputConnector = 1
    },
    {
        reference = component.proxy(component.findComponent("Smelter8")[1]),
        busses = {busses.A, busses.B},
        remaining = 0,
        queue = {},
        outputConnector = 1
    },
    {
        reference = component.proxy(component.findComponent("Foundry1")[1]),
        busses = {busses.A, busses.B},
        remaining = 0,
        queue = {},
        outputConnector = 2
    },
    {
        reference = component.proxy(component.findComponent("Foundry2")[1]),
        busses = {busses.A, busses.B},
        remaining = 0,
        queue = {},
        outputConnector = 2
    },
    {
        reference = component.proxy(component.findComponent("Foundry3")[1]),
        busses = {busses.A, busses.B},
        remaining = 0,
        queue = {},
        outputConnector = 2
    },
    {
        reference = component.proxy(component.findComponent("Foundry4")[1]),
        busses = {busses.A, busses.B},
        remaining = 0,
        queue = {},
        outputConnector = 2
    }
}

for i,s in pairs(smelters) do
    for i2,b in pairs(s.busses) do
        --table.insert(s.queue, b.name, {})
        s.queue[b.name] = createLinkedList()
    end
    s.total = 0
    s.name = s.reference.nick
    s.inputs = {}
    s.remaining = 0
    s.workObject = ""
    local connector = s.reference:getFactoryConnectors()[s.outputConnector]
    registerEvent(connector, s, function(self, param)
        processSmelterOutput(self)
    end)
    s.outConnector = connector
    event.listen(connector)
end

outputSplitters = {
    {
        reference = component.proxy(component.findComponent("Smelter1InB")[1]),
        bus = busses.B,
        manufacturer = smelters[1],
        outputSlot = 1,
        passthroughSlot = 2,
        outputConnector = 2
    },{
        reference = component.proxy(component.findComponent("Smelter1InA")[1]),
        bus = busses.A,
        manufacturer = smelters[1],
        outputSlot = 1,
        passthroughSlot = 2,
        outputConnector = 2
    },{
        reference = component.proxy(component.findComponent("Smelter2InB")[1]),
        bus = busses.B,
        manufacturer = smelters[2],
        outputSlot = 0,
        passthroughSlot = 1,
        outputConnector = 2
    },{
        reference = component.proxy(component.findComponent("Smelter2InA")[1]),
        bus = busses.A,
        manufacturer = smelters[2],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Smelter3InB")[1]),
        bus = busses.B,
        manufacturer = smelters[3],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Smelter3InA")[1]),
        bus = busses.A,
        manufacturer = smelters[3],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Smelter4InB")[1]),
        bus = busses.B,
        manufacturer = smelters[4],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Smelter4InA")[1]),
        bus = busses.A,
        manufacturer = smelters[4],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Smelter5InA")[1]),
        bus = busses.A,
        manufacturer = smelters[5],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Smelter5InB")[1]),
        bus = busses.B,
        manufacturer = smelters[5],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Smelter6InA")[1]),
        bus = busses.A,
        manufacturer = smelters[6],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Smelter6InB")[1]),
        bus = busses.B,
        manufacturer = smelters[6],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Smelter7InA")[1]),
        bus = busses.A,
        manufacturer = smelters[7],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Smelter7InB")[1]),
        bus = busses.B,
        manufacturer = smelters[7],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Smelter8InA")[1]),
        bus = busses.A,
        manufacturer = smelters[8],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Smelter8InB")[1]),
        bus = busses.B,
        manufacturer = smelters[8],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Foundry1In1B")[1]),
        bus = busses.B,
        manufacturer = smelters[9],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Foundry1In1A")[1]),
        bus = busses.A,
        manufacturer = smelters[9],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Foundry2In1B")[1]),
        bus = busses.B,
        manufacturer = smelters[10],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Foundry2In1A")[1]),
        bus = busses.A,
        manufacturer = smelters[10],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Foundry3In1B")[1]),
        bus = busses.B,
        manufacturer = smelters[11],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Foundry3In1A")[1]),
        bus = busses.A,
        manufacturer = smelters[11],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Foundry4In1B")[1]),
        bus = busses.B,
        manufacturer = smelters[12],
        outputSlot = 0,
        passthroughSlot = 1
    },{
        reference = component.proxy(component.findComponent("Foundry4In1A")[1]),
        bus = busses.A,
        manufacturer = smelters[12],
        outputSlot = 0,
        passthroughSlot = 1
    }
}

busses.B.paired = {busses.A}

for i,v in pairs(busses) do
    for i2,v2 in pairs(v.sourceSplitters) do
        registerEvent(v2, v, function(self)
            process(self)
        end)
        event.listen(v2)
    end
end

for i,v in pairs(outputSplitters) do
    registerEvent(v.reference, v, function(self)
        processOutputEvent(self)
    end)
    v.name = v.reference.nick
    table.insert(v.bus.children, v)
    table.insert(v.manufacturer.inputs, v)
    --event.listen(v.reference)
    --print("Listening for events on output splitter " .. tostring(i))
end

function queue2(recipeName, count)
    --print("Adding to queue2")
    craftingQueue:push({
        recipeName = recipeName,
        count = count
    })
    processQueue()
end
function queue2First(recipeName, count)
    --print("Adding to queue2")
    craftingQueue:shift({
        recipeName = recipeName,
        count = count
    })
    processQueue()
end

function processQueue()
    --print("Processing production queue ... ")
    if craftingQueue.length then
        local item = craftingQueue.first
        while item do
            local smelter = getLeastBusySmelter(item.value.recipeName)
            --print(item.value.recipeName)
            if smelter then
                --print("Free smelter, project")
                queue(smelter, item.value.recipeName, item.value.count)
                local toRemove = item
                item = item.next
                toRemove:delete()
            else
                --print("Cannot produce yet: " .. item.value.recipeName)
                item = item.next
            end
            computer.skip()
        end
    else
        --print("Queue empty")
    end
end

function queue(smelter, recipeName, count)
    local lowQue = 100000
    local bus
    if not count then
        count = 1
    end
    --print("Queue called for recipe "..recipeName)
    for i,v in pairs(smelter.busses) do
        if v.queue.length < lowQue then
            lowQue = v.queue.length
            bus = v
        end
    end
    if(smelter.remaining > 0) then
        -- print("Smelter is busy")
    end
    --print("Selected bus " .. bus.name)
    local ref = smelter.reference
    --print(smelter.reference)
    for i,recipe in pairs(ref:getRecipes()) do
        if recipe:getName() == recipeName then
            for _,v in pairs(ref:getInventories()) do
                if not v:getStack(0).item then
                    v:flush()
                elseif tostring(v:getStack(0).item.type) ~= "Power Shard" then
                    v:flush()
                end
            end
            smelter.reference:setRecipe(recipe)
            smelter.workObject = recipe:getProducts()[1].item:getName()
            local resultCount = recipe:getProducts()[1].count
            local _count = math.ceil(count / resultCount)
            if not doPurge then
                smelter.remaining = smelter.remaining + _count * resultCount
            end
            for i2,v in pairs(recipe:getIngredients()) do
                local item = {
                    name = v.item:getName(),
                    delivercount = v.count * _count,
                    receivecount = v.count * _count
                }
                if item.name == nil then
                    print(recipe)
                    print(recipe:getName())
                    error("NIL ITEM NAME!")
                end

                --print("Appended item " .. tostring(item) .. " to que")
                if not doPurge then
                    bus.queue:push(item)
                    smelter.queue[bus.name]:push(item)
                end
                --printLinkedList(bus.queue)
            end
            process(bus)
            return true
        end
    end
    --print("No Recipe match request")
    return false
end


function process(bus)
    if bus.queue.length > 0 then
        --print("Stuff in queue")
        local element = bus.queue.first
        local item = element.value
        local source = bus.sourceSplitters[item.name]
        if source ~= nil then
            local v = source:getInput()
            --print (" ** item : " .. tostring(v))
            if v then
                if v.type:getName() == item.name then
                    if source:transferItem(sourceOutputSlot) then
                        item.delivercount = item.delivercount - 1
                        if item.delivercount == 0 then
                            element:delete()
                        elseif item.delivercount < 0 then
                            rerror("Negative deliver count")
                        end
                        requestedItems = requestedItems + 1
                        craftRequested:setText(tostring(requestedItems))
                    end
                else
                    --print(" ** Invalid item on bus "..v.type:getName())
                    testButton:setColor(1,0,0,5)
                end
            else
                --print(" ** No Input at source")
            end
        else
            --print(" ** No source splitter for resource: " .. item.name)
        end
    end
end



function purgeOutputSplitters()
    for i,v in pairs(outputSplitters) do
        local item = v.reference:getInput()
        if item then
            --print("Purgeing item from output splitter " .. tostring(i))
            v.reference:transferItem(v.passthroughSlot)
        end
    end
end

function processOutput(splitter, transferrable)
    local manuf = splitter.manufacturer
    local item = manuf.queue[splitter.bus.name].first
    transferrable = splitter.reference:getInput()
    if transferrable then
        print(transferrable)
        local name = transferrable.type:getName()
        --print(" ** Look for need for " .. name)
        while item do
            if item.value.name == name then
                if splitter.reference:transferItem(splitter.outputSlot) then
                    item.value.receivecount = item.value.receivecount - 1
                    --print(" ** Receive Count after : " .. tostring(item.value.receivecount))
                    if item.value.receivecount == 0 then
                        item:delete()
                        --print(" ** Deleting item consumed")
                    elseif item.value.receivecount < 0 then
                        rerror("Receive count less than 0")
                    end
                end
                return
            end
            item = item.next
        end
        --printLinkedList(manuf.queue[splitter.bus.name])
        --print(" ** Splitter does not need it")
        splitter.reference:transferItem(splitter.passthroughSlot)
    else
        --print("Unknown error: transferrable is null")
    end
end

function getLeastBusySmelter(recipeName)
    local max = 100000
    local smelter
    --print("Get least busy smelter... ")
    for i,v in pairs(smelters) do
        local valid
        --print("Testing " .. v.reference.nick)
        local c = v.remaining
        for i2,v2 in pairs(v.queue) do
            c = c + v2.length
        end
        if c == 0 then
            for i,recipe in pairs(v.reference:getRecipes()) do
                if recipe:getName() == recipeName then
                    valid = true
                    --print("Can produce : " .. recipeName)
                end
            end
        else
            --print("Queue not empty")
        end
        if valid then
            local c = 0
            for i2,v2 in pairs(v.queue) do
                c = c + v2.length
            end
            if c < max then
                max = c
                smelter = v
            end
        end
    end
    if smelter then
        --print("Got smelter " .. smelter.reference.nick)
    end
    return smelter
end

if doPurge then
    purgeButton:setColor(1,0,0,4)
    purgeOutputSplitters()
    for i,v in pairs(busses) do
        v.queue:clear()
    end
    for i,v in pairs(smelters) do
        for i2,v2 in pairs(v.queue) do
            v2:clear()
        end
    end
end


function processSmelterOutput(smelter)
    smelter.remaining = smelter.remaining - 1
    smelter.total = smelter.total + 1
    if smelter.remaining < 0 then
        smelter.remaining = 0
        rmessage("Mysterious extra item!")
    end
    --print(smelter.reference.nick .. " has " .. tostring(smelter.remaining) .. " items remaining to produce")
    if smelter.remaining == 0 then
        processQueue()
    end
end
--queue(smelters[1], "Iron Ingot")

local craftAmount = 1
local passingBy = 0
craftAmountDisplay:setText(" ")
craftAmountDisplay:setText(tostring(craftAmount))
craftRequested:setText(tostring(requestedItems))
craftPassingby:setText(tostring(passingBy))

function inTable(list, searchFor, column)
    for k,v in pairs(list) do
        if column then
            if v[column] == searchFor then
                return v
            end
        end
    end
    return nil
end

function findConnector(list, refColumn, connectorColumn, compareto)
    for k,v in pairs(list) do
        if v[refColumn] and v[connectorColumn] then
            local c = v[refColumn]:getFactoryConnections()[v[connectorColumn]]
            --print("c: " .. tostring(c))
            if c == compareto then
                return v
            end
        elseif not v[refColumn] then
            --print "Ref Column null"
        elseif not v[connectorColumn] then
            --print "Connector Column null"
        end
    end
end

--queue2("Iron Ingot", 1)
--queue2("Steel Ingot", 1)

function processOutputEvent(splitter, param)
    print(splitter)
    local comp = splitter.reference
    if(comp == outputSplitters[1].reference or comp == outputSplitters[2].reference) then
        passingBy = passingBy + 1
        craftPassingby:setText(tostring(passingBy))
    end
    --print("Event matched output splitter")
    if doPurge then
        comp:transferItem(splitter.passthroughSlot)
    else
        processOutput(splitter, splitter.reference:getInput())
    end
end



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
        input = input.bus
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
    screens:setForeground(0.7,0.3,0.7,1)
    if station.remaining > 0 then
        screens:setForeground(0.7,0.7,0.3,1)
    elseif station.error then
        screens:setForeground(1,0.3,0.3,1)
    else
        screens:setForeground(0.7,1,0.7,1)
    end
    screens:dprint(0, mx + 0, cy, station.name)
    cy = cy + 1

    if station.remaining > 0 then
        screens:setForeground(0.1,0.7,0.1,1)
        screens:dprint(0, mx + 0, cy, "←")
        screens:setForeground(0.7,0.7,0.7,1)
        screens:dprint(0, mx + 2, cy, station.workObject)
        screens:setForeground(0.3,0.3,1,1)
        screens:dprint(0, mx + width - 2 - 5, cy, string.format("%3d", station.remaining))
        cy = cy + 1
    end
    if printQueue then
        for qname,q in pairs(station.queue) do
            local f = q.first
            while f do
                screens:setForeground(0.7,0.7,0.4,1)
                screens:dprint(0, mx + 2, cy, qname)
                screens:setForeground(0.7,0.7,0.2,1)
                screens:dprint(0, mx + 3, cy, "→")
                screens:setForeground(0.7,0.7,0.7,1)
                screens:dprint(0, mx + 5, cy, f.value.name)
                screens:setForeground(0.3,0.3,1,1)
                screens:dprint(0, mx + width - 2 - 5, cy, string.format("%3d", f.value.receivecount))
                cy = cy + 1
                f = f.next
                computer.skip()
            end
        end
    end

    c = 0

    screens:setForeground(0.7,0.7,0.5,1)
    screens:dprint(0, mx - 1, y + 1, "┌")
    screens:dfill(0, mx, y + 1, width - 2, 1, "─")
    screens:dfill(0, mx, y + 1 + height, width - 2, 1, "─")
    c = 0
    for _,input in pairs(station.inputs) do
        input = input.bus
        screens:setForeground(0.3,0.3,0.3,1)
        screens:dfill(0, input.paintX, input.paintY, mx - input.paintX + width, 1, "═")
        screens:dprint(0, mx + c, input.paintY, "╦")
        screens:dfill(0, mx + c, input.paintY + 1, 1, y - input.paintY - 1, "║")
        computer.skip()
        screens:setForeground(0.7,0.7,0.5,1)
        screens:dprint(0, mx + c, y + 1, "╨")
        c = c + 2
    end
    screens:dprint(0, mx + width - 2, y + 1, "┐")
    screens:dprint(0, mx - 1, y + 1 + height, "└")
    screens:dprint(0, mx + width - 2, y + 1 + height, "┘")
    screens:dfill(0, mx - 1, y + 2, 1, height - 1, "│")
    screens:dfill(0, mx + width - 2, y + 2, 1, height - 1, "│")
    screens:setForeground(0.3,0.3,0.3,1)


    if pdirection == "right" then
        x = mx + width
    elseif pdirection == "left" then
        x = mx
    end
    for _,input in pairs(station.inputs) do
        input = input.bus
        input.paintX = x
        computer.skip()
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
        bus.paintX = bus.paintX + 2
        bus.pdirection = "left"
    else
        local x = lowX - 1
        screens:dfill(0, x + sub, bus.paintY, bus.paintX - x - sub, 1, "═")
        screens:dprint(0, x + sub, bus.paintY, "╔")
        screens:dfill(0, x + sub, bus.paintY + 1, 1, toY - bus.paintY - 3 + sub, "║")
        screens:dprint(0, x + sub, __y - 2 + sub, "╚")
        screens:dfill(0, x + sub + 1, __y - 2 + sub, maxsnake, 1, "═")
        fromY = __y + maxsnake - sub - 3
        bus.paintY = __y - 2 + sub
        bus.paintX = x + sub + maxsnake
        bus.pdirection = "right"
    end
    computer.skip()
    return lowX, fromY
end

function printBus2(bus, x, y)
    screens:setForeground(0.7,0.7,0.7,1)
    screens:dprint(0, x, 0, bus.name)
    --screens:dprint(0, x, 1, bus.name)
    screens:setForeground(0.3,0.3,0.3,1)
    y = y + 1
    bus.paintX = x
    local _y = y + 1
    local c = 0
    local t = 0
    for _,child in pairs(sortedBusses) do
        if child == bus then
            t = c
        end
        c = c + 1
    end
    --t = c - t
    --print("Y=" .. tostring(y) .. ", t=" ..tostring(t) .. ", c=" ..tostring(c))
    screens:dfill(0, x, y, 1, t + 2, "║")
    --for qy=y,y + 1 + t,1 do
    --    screens:dprint(0, x, qy, "║")
    --end
    screens:dprint(0, x, y + t * 2 + 1, "╚")
    y = y + 1 + t * 2
    screens:dfill(0, x + 1, y, 2 + c * 2 - x, 1, "═")
    for qx=x + 1,2 + (c) * 2 + 1,1 do
        screens:dprint(0, qx, y, "═")
    end
    _y = y
    local n = false
    local bx = x + c * 2
    local cindex = 0
    local drawWidth = screens.cellWidth - stationWidth - 30
    local maxY = _y
    local maxX = 0
    bus.paintX = bx
    bus.paintY = _y
    bus.painted = true
    screens:setForeground(0.7,0.7,0.3,1)
    screens:dprint(0, bus.paintX - 3, bus.paintY - 1, bus.name)
    if bus.queue.length > 0 then
        screens:setForeground(0.3,0.3,0.7,1)
        screens:dprint(0, bus.paintX - 3 + string.len(bus.name) + 2, bus.paintY - 1, string.format("%5d", bus.queue.length))
        screens:setForeground(0.7,0.7,0.3,1)
        screens:dprint(0, bus.paintX - 3 + string.len(bus.name) + 2 + 5, bus.paintY - 1, " items")
    else
        screens:setForeground(0.3,0.3,0.3,1)
        screens:dprint(0, bus.paintX - 3 + string.len(bus.name) + 2, bus.paintY - 1, "Nothing needed")
    end

    screens:setForeground(0.3,0.3,0.3,1)
    local qx = 0; local qy = 0
    for _,q in pairs(smelters) do
        computer.skip()
        if (bus.pdirection == "right" and bus.paintX > drawWidth - 1) or (bus.pdirection == "left" and bus.paintX < bx + 3) then
            x, _y = printSnake(bus, bx, _y, maxY + 5, cindex, 2)
            if bus.paired then
                local mod = 1
                for _,p in pairs(bus.paired) do
                    printSnake(p, bx, _y, maxY + 5, cindex + mod, 2)
                    mod = mod + 1
                end
            end
        end
        if q.inputs then
            local depPainted = true
            local paint = false
            for _,qlbus in pairs(q.inputs) do
                local lbus = qlbus.bus
                --print(lbus.name)
                if bus.name == lbus.name then
                    paint = true
                end
                if not lbus.painted then
                    depPainted = false
                    break
                end
            end
            if depPainted and paint then
                --print("Meow")
                qx, qy = paintStation(q, x + 5, _y)
                --lbus.parent.paintX = x + qx
            elseif not depPainted then
                --print("No deps for "..q.reference.nick)
            else
                --print("No paint for "..q.reference.nick)
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
    return _y
end

function printScreen()
    screens:clear()
    local x = 2
    local y = 5
    for _,bus in pairs(sortedBusses) do
        bus.painted = false
        bus.pdirection = "right"
    end
    for _,bus in pairs(sortedBusses) do
        local y = 0
        if not bus.parent then
            y = printBus2(bus, x, y)
            x = x + 2
        end
    end
    screens:setForeground(0.3,0.3,0.3,1)
    screens:dfill(0,  screens.cellWidth - 30, 0, 1, screens.cellHeight, "┃")
    screens:setForeground(0.7,0.7,0.7,1)
    x = screens.cellWidth - 29
    screens:dprint(0, x,0,"Future");
    y = 1
    local item = craftingQueue.first
    if item then
        local m = 0
        while item do
            m = m + 1
            screens:setForeground(0.7,0.7,0.7,1)
            screens:dprint(0,  x+ 2, y, item.value.recipeName)
            screens:setForeground(0.3,0.3,1,1)
            screens:dprint(0, x + 23, y, string.format("%3d", item.value.count))
            item = item.next
            y = y + 1
            if y + 2 > screens.cellHeight then
                screens:setForeground(0.7,0.7,0.7,1)
                screens:dprint(0, x,y, " + " .. tostring(craftingQueue.length - m) .. " more")
                break
            end
        end
    else
        screens:setForeground(1,1,0.6,1)
        screens:dprint(0,  x+ 2, y, "Nothing to do")
        y = y + 1
    end

    screens:flush()
end


function printScreen2()
    screens:clear()
    local y = 0
    local x = 0
    local c = 30
    screens:setForeground(1,1,1,0.8)
    screens:dprint(0, 0,y,"Queue"); x,y = gColumnAdvance(x,y,c)
    local item = craftingQueue.first
    if not item then
        screens:dprint(0, 3,y,"Nothing to do"); x,y = gColumnAdvance(x,y,c)
    else
        local i = 0
        while item do
            local v = item.value
            i = i + 1
            screens:dprint(0, 3, y, v.recipeName)
            screens:setForeground(0.3,0.3,1,0.8)
            screens:dprint(0, 20,y,tostring(v.count)); x,y = gColumnAdvance(x,y,c)
            screens:setForeground(1,1,1,0.8)
            if y >= 17 then
                break
            end
            item = item.next
        end
        if i < craftingQueue.length then
            screens:dprint(0, 3,y,tostring(craftingQueue.length - i) .. " additional items"); x,y = gColumnAdvance(x,y,c)
        end
    end
    y = 0
    screens:setForeground(1,1,1,0.8)
    screens:dprint(0, 30,y,"Smelters"); x,y = gColumnAdvance(x,y,c)
    local i = 1
    local x = 32
    local yStart = y
    for k,v in pairs(smelters) do
        screens:setForeground(1,1,1,0.8)
        screens:dprint(0, x,y, v.reference.nick .. " (#" .. tostring(i) .. ")"); x,y = gColumnAdvance(x,y,c)
        screens:setForeground(1,1,1,0.8)
        if v.remaining > 0 then
            screens:setForeground(0,1,0,0.8)
            screens:dprint(0, x + 2, y, "Working");
            screens:setForeground(1,1,1,0.8)
            screens:dprint(0, x + 10, y, "Q'd:");
            screens:setForeground(0.3,0.3,1,0.8)
            screens:dprint(0, x + 14, y, string.format("%3d", v.remaining));
            screens:dprint(0, x + 17, y, "#");
            screens:setForeground(0.3,0.3,1,0.8)
            screens:dprint(0, x + 18, y, string.format("%4d", v.total));
            x,y = gColumnAdvance(x,y,c)
            for _,bus in pairs(v.queue) do
                local q = bus.first
                while q do
                    screens:setForeground(1,1,1,0.8)
                    screens:dprint(0, x + 4, y, q.value.name .. "  " .. string.format("%3d", q.value.delivercount) .. "/" .. string.format("%3d", q.value.receivecount));
                    q = q.next
                    x,y = gColumnAdvance(x,y,c)
                end
            end
        else
            screens:setForeground(0.5,0.5,0.5,0.8)
            screens:dprint(0, x + 2, y, "Idle");x,y = gColumnAdvance(x,y,c)
        end
        screens:setForeground(1,1,1,0.8)
    end
    if doPurge then
        screens:setForeground(1,0,0,1)
        screens:dprint(0, 0, 41, "Purging is active!");y = y+1
    end
    screens:flush()
end

printScreen()

registerEvent(testButton, testButton, function()
    queue(smelters[1], "Iron Ingot")
end)
registerEvent(autoCraftButton, autoCraftButton, function()
    if autoCraft then
        autoCraft = false
        autoCraftButton:setColor(1,0,0,1)
    else
        autoCraft = true
        autoCraftButton:setColor(0,1,0,4)
        processAutoCraft()
    end
end)
registerEvent(craftAmountPot, craftAmountPot, function(self, evt, params, po)
    if evt == "PotRotate" then
        if param then
            craftAmount = craftAmount - 1
        else
            craftAmount = craftAmount + 1
        end
        if craftAmount > 10 then
            craftAmount = 10
        elseif craftAmount < 0 then
            craftAmount = 0
        end
        craftAmountDisplay:setText(tostring(craftAmount))
    end
end)
registerEvent(craftProcessButton, craftProcessButton, function()
    for i=1,craftAmount,1 do
        queue2("Iron Ingot", 1)
    end
end)
registerEvent(craftProcessButton2, craftProcessButton2, function()
    for i=1,craftAmount,1 do
        queue2("Copper Ingot", 1)
    end
end)
registerEvent(craftProcessButton3, craftProcessButton3, function()
    queue2("Iron Ingot", craftAmount)
end)
registerEvent(craftProcessButton4, craftProcessButton4, function()
    queue2("Copper Ingot", craftAmount)
end)
registerEvent(craftProcessButton5, craftProcessButton5, function()
    queue2("Steel Ingot", craftAmount)
end)

registerEvent(purgeButton, purgeButton, function()
    if doPurge then
        doPurge = false
        purgeButton:setColor(0,0,0,1)
    else
        doPurge = true
        purgeButton:setColor(1,0,0,4)
        requestedItems = 0
        passingBy = 0
        craftRequested:setText(tostring(requestedItems))
        craftPassingby:setText(tostring(passingBy))
        craftingQueue:clear()
        purgeOutputSplitters()
    end
end)

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
        purgeButton:setColor(1,0,0,4)
        requestedItems = 0
        passingBy = 0
        craftRequested:setText(tostring(requestedItems))
        craftPassingby:setText(tostring(passingBy))
        craftingQueue:clear()
        purgeOutputSplitters()
    end,
    enumRecipes = function(address, parameters, po)
        local total = 0
        local enumerated = {}
        for _,station in pairs(smelters) do
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
        sendNextRecipe(address, 0)
    end,
    sendNextRecipe = function(address, parameter, po)
        sendNextRecipe(address, parameter[po])
    end
})

function sendNextRecipe(address, recipeIndex)
    print("Sending " .. tostring(recipeIndex) .. " of " .. recipeCount )
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
                for k,v in pairs(sendParams) do
                    print(k .. " = " .. v)
                end
                scriptInfo.network:send(address, 100, table.unpack(sendParams))
            end
        else
            rerror("No such recipe: " .. tostring(index) .. ", max is "..tostring(recipeCount))
        end
    end
end


function processPeriodic(result)
    for i,splitter in pairs(outputSplitters) do
        local item = splitter.reference:getInput()
        if item then
            processOutputEvent(splitter, item)
        end
    end
    for i,bus in pairs(busses) do
        process(bus)
    end
end

rmessage("Computer started")
local seldomCounter = 0
local nilCounter = 0
local timeout = 1

while true do
    local result = {event.pull(timeout) }
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
    local status, err
    status, err = pcall(processEvent, result)
    if err then
        rerror("Error in processEvent; ".. tostring(err))
        error(err)
    end
    status, err = pcall(processPeriodic, result)
    if err then
        rerror("Error in processPeriodic; ".. tostring(err))
        error(err)
    end

    if timeout == 1 or seldomCounter <= 0 then
        --printScreen()
        status, err = pcall(printScreen)
        if err then
            rerror("Error in print; ".. tostring(err))
            error(err)
        end
        seldomCounter = 5000
    else
        seldomCounter = seldomCounter - 1
    end
end
