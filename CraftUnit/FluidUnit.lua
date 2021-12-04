
local FactoryStatuses = {
    UNKNOWN = 0, IDLE = 1, WORKING = 2
}


local factoryCount = 0


local recipes = {}

local factories = {}

craftUnits = {}


function getFactories()
    return factories
end

function getFactoryCount()
    return factoryCount
end

function getRecipes()
    return recipes
end

local fluidTypes = getFluidTypes()

filesystem.doFile("/CraftCommon.lua")

function getPackerRecipe(packer, fluid)
    local fluidKind = fluidTypes[fluid]
    for _,v in pairs(packer:getRecipes()) do
        print(v.name .. " == " .. fluidKind.pack)
        if v.name == fluidKind.pack then
            return v
        end
    end
    return nil
end
function getUnackerRecipe(packer, fluid)
    local fluidKind = fluidTypes[fluid]
    for _,v in pairs(packer:getRecipes()) do
        print(v.name .. " == " .. fluidKind.unpack)
        if v.name == fluidKind.unpack then
            return v
        end
    end
    return nil
end

---@param rname string
---@param recipe Recipe
function makeRecipe(rname, recipe)
    ---@type CraftUnitRecipe
    local item = {
        recipeName = rname,
        needsCanisters = 0,
        givesCanisters = 0,
    }
    --print(recipe)
    --print(recipe.name)
    --print(recipe.getIngredients)
    ---@type ItemAmount[]
    local ingredients = recipe:getIngredients()
    ---@type ItemAmount[]
    local products =  recipe:getProducts()
    for _,product in pairs(products) do
        if product.type.form == itemForms.Fluid then
            item.needsCanisters = item.needsCanisters + math.ceil(product.amount / 1000)
        end
    end
    local primary = true
    for _,regent in pairs(ingredients) do
        if regent.type.form == itemForms.Fluid then
            item.givesCanisters = item.givesCanisters + math.ceil(regent.amount / 1000)
        end
    end
    for _,product in pairs(products) do
        if primary then
            item.recipeMakes = product.type.name
            if product.type.form == itemForms.Fluid then
                item.recipeMakesAmount = math.ceil(product.amount / 1000)
            else
                item.recipeMakesAmount = product.amount
            end
            item.regents = {}
            for _,regent in pairs(ingredients) do
                --sendParams[index] = regent.item:getName()
                --sendParams[index + 1] = regent.count
                local count = regent.amount
                if regent.type.form == itemForms.Fluid then
                    count = count / 1000
                end
                table.insert(item.regents, {
                    name = regent.type.name,
                    count = count
                })
            end
            primary = false
        else
            item.sideProduct = product.type.name
            if product.type.form == itemForms.Fluid then
                item.sideProductAmount = math.ceil(product.amount / 1000)
            else
                item.sideProductAmount = product.amount
            end
        end
    end
    return item
end


---@class FluidUnitFactory
---@field public source string
---@field public unpackerSource string
---@field public packerSource string
---@field public busses string[]
---@field public lastBusIndex number
---@field public name string
---@field public maker ComponentReference
---@field public packer ComponentReference
---@field public unpacker ComponentReference
---@field public taskID number
---@field public makerIndex number
---@field public remaining number
---@field public remainingFluid number
---@field public nextSource number
---@field public outConnector FactoryConnection
---@field public packerConnector FactoryConnection
---@field public status number
local FluidUnitFactory = {}

---@param name string
---@param unit any
---@param makerIndex number
---@param compID string
---@return FluidUnitFactory
function FluidUnitFactory.new(name, unit, makerIndex, compID)
    ---@type FluidUnitFactory
    local obj = {
        status = FactoryStatuses.IDLE,
        source = "",
        unpackerSource = "",
        packerSource = "",
        busses = {},
        lastBusIndex = 0,
        taskID = 0,
        maker = ComponentReference.new(compID),
        packer = nil,
        unpacker = nil,
        name = name,
        makerIndex = makerIndex,
        remaining = 0,
        remainingFluid = 0,
        unit = unit,
        packerConnector = nil,
        outConnector = nil,
    }
    setmetatable(obj, FluidUnitFactory)
    FluidUnitFactory.__index = FluidUnitFactory
    return obj
end


---@param recipeName string
---@param count number
---@param taskID number
---@param primary string
function FluidUnitFactory:make(recipeName, count, taskID, primary)
    if self.status == FactoryStatuses.IDLE then
        self.status = FactoryStatuses.WORKING
        self.taskID = taskID
        ---@type Build_OilRefinery_C
        local maker = self.maker:get()
        local pipes = maker:getPipeConnectors()
        for _,pipe in pairs(pipes) do
            pipe:flushPipeNetwork()
        end
        for _,recipe in pairs(maker:getRecipes()) do
            if recipe.name == recipeName then
                local packer = self.packer:get()
                local unpacker = self.unpacker:get()
                clearInventories(maker)
                maker:setRecipe(recipe):await()
                self.workObject = recipe:getProducts()[1].type.name
                local _count =  count --math.ceil(count / recipe:getProducts()[1].count)
                local inputCanisters = 0;
                local outputCanisters = 0;

                for _,v in pairs(recipe:getIngredients()) do
                    if v.type.form == itemForms.Fluid then
                        inputCanisters = inputCanisters + roundUp((v.amount / 1000), fluidTypes[v.type.name].unpackCount)
                    end
                end

                for _,v in pairs(recipe:getProducts()) do
                    local name = v.type.name
                    if v.type.form == itemForms.Fluid then
                        local ur = getPackerRecipe(packer, name)
                        if ur == nil then
                            error("Packer recipe for " .. name .. " not found")
                        end
                        clearInventories(packer)
                        packer:setRecipe(ur):await()
                        rdebug("Need " .. tostring(math.floor(v.amount / 1000)) .. " empty canisters for " .. v.type.name)
                        local toMake
                        if name ~= primary then
                            toMake = math.max(0, (_count) * v.amount)
                        else
                            toMake = _count * v.amount
                        end
                        if name ~= primary then
                            local q = math.ceil(toMake / 1000)
                            self.remainingFluid = roundDown(q,  fluidTypes[name].unpackCount)
                            outputCanisters = outputCanisters + roundDown(q,  fluidTypes[name].unpackCount)
                            rmessage("Remaining fluid to make " .. self.remainingFluid .. "(" .. toMake .. ") " .. name .. " ")
                        else
                            local q = math.floor(toMake / 1000)
                            self.remainingFluid = roundUp(q,  fluidTypes[name].unpackCount)
                            outputCanisters = outputCanisters + roundDown(q,  fluidTypes[name].unpackCount)
                            rmessage("Remaining fluid to make " .. self.remainingFluid .. "(" .. toMake .. ") " .. name .. " (Primary)")
                        end
                    else
                        self.remaining = _count * v.amount
                        rmessage("Remaining solid to make " .. self.remaining .. " " .. name)
                    end
                end
                if outputCanisters > 0 then
                    local remainder = outputCanisters
                    if remainder >= 0 then
                        ---@type BusMgrOrderParams
                        local item = {
                            name = "Empty Canister",
                            bus = self.packerSource .. "-" .. self:getBus(),
                            taskID = taskID,
                            count = remainder
                        }
                        requestItem(item)
                    end
                end

                for _,v in pairs(recipe:getIngredients()) do
                    local item = {
                        name = v.type.name,
                        count = v.amount * _count,
                        taskID = taskID
                    }
                    if v.type.form == itemForms.Fluid then
                        item.count = roundUp((item.count / 1000), fluidTypes[item.name].unpackCount)
                        item.bus = self.unpackerSource .. "-" .. self:getBus()
                        local ur = getUnackerRecipe(unpacker, item.name)
                        if ur == nil then
                            error("Unpacker recipe for " .. item.name .. " not found")
                        end
                        item.name = fluidTypes[item.name].packaged
                        clearInventories(unpacker)
                        unpacker:setRecipe(ur):await()
                    else
                        item.bus = self.source .. "-" .. self:getBus()
                    end
                    print("Appended item " .. tostring(item) .. " to que")
                    requestItem(item)
                    --printLinkedList(bus.queue)
                end
                printArray(self, 1)
                return true
            end
        end
        rmessage("No recipe match")
    else
        rmessage("Factory not idle")
    end
    return false

end

function FluidUnitFactory:getBus()
    local index = self.nextSource
    self.nextSource = self.nextSource + 1
    if self.nextSource > #self.busses then
        self.nextSource = 1
    end
    return self.busses[index]
end

function FluidUnitFactory:packerOutputCallback()
    --print(tostring(param))
    self.remainingFluid = self.remainingFluid - 1
    if self.remainingFluid < 0 then
        rwarning("Mysterious extra item from " .. tostring(self.maker.index))
    end
    print("Remaining fluid: "..self.remainingFluid)
    if self.remainingFluid <= 0 and self.remaining <= 0 then
        self.remainingFluid = 0
        self.status = FactoryStatuses.IDLE
        reportFinishedTask(self)
    end
end

function FluidUnitFactory:makerOutputCallback()
    --print(tostring(param))
    self.remaining = self.remaining - 1
    if self.remaining < 0 then
        rwarning("Mysterious extra item from " .. tostring(self.maker.index))
    end
    print("Remaining solid: " .. self.remaining)
    if self.remaining <= 0 and self.remainingFluid <= 0 then
        self.remaining = 0
        self.status = FactoryStatuses.IDLE
        reportFinishedTask(self)
    end
end

function initFactories()
    local makerIndex = 1
    local all = component.findComponent("");
    local units
    if scriptInfo.units ~= nil then
        units = scriptInfo.units
    else
        units = {{
                     name = scriptInfo.name,
                     comment = scriptInfo.comment,
                     output = scriptInfo.makerOutputIndex,
                     factories = {}
                 }}
    end
    for _,unit in pairs(units) do
        ---@type CraftUnitClass
        local craftUnit = {
            factories = {},
            unitInfo = unit,
            recipes = {}
        }
        craftUnits[unit.name] = craftUnit;
        local unitFactoryCount = 0;

        for _,id in pairs(all) do
            local comp = component.proxy(id)
            local cname = comp.nick
            local p = explode("_", cname)
            if p[1] == "FluidProcesser" and p[2] == scriptInfo.name then
                computer.skip()
                print(cname)
                local index = tonumber(p[3])
                local bus = explode(":", p[4])
                local mkIndex = unit.name .. ":" .. p[3]
                printArray(bus)
                print("PackerSource: 'Packer_" .. scriptInfo.name .. "_".. index .. "'");
                unitFactoryCount = unitFactoryCount + 1
                local factory = FluidUnitFactory.new(cname, unit, mkIndex, comp.id)
                factory.source = scriptInfo.name .. "-S2-" .. index
                factory.unpackerSource = scriptInfo.name .. "-S1-" .. index
                factory.packerSource = scriptInfo.name .. "-S3-" .. index
                factory.packer = createReference(component.findComponent("Packer_" .. scriptInfo.name .. "_".. index)[1])
                factory.unpacker = createReference(component.findComponent("Unpacker_" .. scriptInfo.name .. "_".. index)[1])
                factory.busses = bus
                factory.nextSource = 1 + math.fmod((index - 1) , #bus)

                --local factory = {
                --    source = scriptInfo.name .. "-S2-" .. index,
                --    unpackerSource = scriptInfo.name .. "-S1-" .. index,
                --    packerSource = scriptInfo.name .. "-S3-" .. index,
                --    busses = bus,
                --    lastBusIndex = 1,
                --    name = cname,
                --    maker = comp,
                --    packer = createReference(component.findComponent("Packer_" .. scriptInfo.name .. "_".. index)[1]),
                --    unpacker = createReference(component.findComponent("Unpacker_" .. scriptInfo.name .. "_".. index)[1]),
                --    taskID = nil,
                --    makerIndex = mkIndex,
                --    remaining = 0,
                --    remainingFluid = 0,
                --    nextSource = 1 + math.fmod((index - 1) , #bus),
                --    getBus = factoryFunctions.getBus,
                --    status = FactoryStatuses.IDLE,
                --    make = factoryFunctions.make,
                --}
                clearInventories(comp)
                local rozeRecipes = {}
                for _,recipe in pairs(factory.maker:get():getRecipes()) do
                    local rname = recipe.name
                    if recipes[rname] == nil then
                        if string.sub( rname,1, 5) == "Roze " then
                            rozeRecipes[string.sub(rname, 6)] = makeRecipe(rname, recipe)
                        else
                            local item = makeRecipe(rname, recipe)
                            recipes[rname] = item
                            craftUnit.recipes[rname] = item
                        end
                        --table.insert(recipes, item)
                    else
                        --print("Invalid recipe: "..recipe.name)
                    end
                end
                --printArray(rozeRecipes)
                for _,recipe in pairs(rozeRecipes) do
                    recipes[_] = recipe;
                    craftUnit.recipes[_] = recipe
                end
                --print(factory)
                --print(factory.packer)
                --for _,recipe in pairs(factory.packer:get():getRecipes()) do
                --    local rname = recipe.name
                --    if recipes[rname] == nil then
                --        recipes[rname] = makeRecipe(rname, recipe)
                --        --table.insert(recipes, item)
                --    else
                --        --print("Invalid recipe: "..recipe.name)
                --    end
                --end

                local connector = comp:getFactoryConnectors()[1]
                factory.outConnector = connector
                registerEvent(connector, factory, factory.makerOutputCallback, nil, true)
                --event.listen(connector)
                local packerConnector = factory.packer:get():getFactoryConnectors()[2]
                factory.packerConnector = packerConnector
                registerEvent(packerConnector, factory, factory.packerOutputCallback, nil, true)
                event.listen(factory.maker:get())

                factories[factory.makerIndex] = factory
                craftUnit.factories[factory.makerIndex] = factory

                makerIndex = makerIndex + 1

            end
        end
        craftUnit.factoryCount = unitFactoryCount
    end
    return makerIndex - 1
end
