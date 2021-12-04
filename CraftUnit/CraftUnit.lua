
local FactoryStatuses = {
    UNKNOWN = 0, IDLE = 1, WORKING = 2
}


local factoryCount = 0

---@type table<string,CraftUnitRecipe>
local recipes = {}


---@type table<number,CraftUnitFactory>
local factories = {}

---@type table<string, CraftUnitClass>
craftUnits = {}

---@return table<number,CraftUnitFactory>
function getFactories()
    return factories
end

---@return number
function getFactoryCount()
    return factoryCount
end

---@return table<string,CraftUnitRecipe>
function getRecipes()
    return recipes
end


local CraftUnitFactory = {}

---@param name string
---@param unit any
---@param makerIndex number
---@return CraftUnitFactory
function CraftUnitFactory.new(name, unit, makerIndex, compID)
    ---@type CraftUnitFactory
    local obj = {
        status = FactoryStatuses.IDLE,
        taskID = 0,
        maker = createReference(compID),
        sources = {},
        name = name,
        makerIndex = makerIndex,
        remaining = 0,
        unit = unit,
    }
    setmetatable(obj, CraftUnitFactory)
    CraftUnitFactory.__index = CraftUnitFactory
    return obj
end

---@param recipeName string
---@param count number
---@param taskID number
---@return void
function CraftUnitFactory:make(recipeName, count, taskID)
    if self.status == FactoryStatuses.IDLE then
        self.status = FactoryStatuses.WORKING
        self.taskID = taskID
        local maker = self.maker:get()
        for _,recipe in pairs(maker:getRecipes()) do
            if recipe.name == recipeName then
                maker:setRecipe(recipe):await()
                self.workObject = recipe:getProducts()[1].type.name
                local _count =  count --math.ceil(count / recipe:getProducts()[1].count)
                for _,v in pairs(recipe:getIngredients()) do
                    local item = {
                        name = v.type.name,
                        count = v.amount * _count,
                        bus = self.sources[self.nextSource],
                        taskID = taskID
                    }
                    self.nextSource = self.nextSource + 1
                    if self.sources[self.nextSource] == nil then
                        self.nextSource = 1
                    end
                    if item.name == nil then
                        print("NIL ITEM NAME!")
                        print(recipe)
                        print(recipe.name)
                    end

                    --print("Appended item " .. tostring(item) .. " to que")
                    requestItem(item)
                    --printLinkedList(bus.queue)
                end
                self.remaining = _count * recipe:getProducts()[1].amount
                --printArray(self, 1)
                return true
            end
        end
        rmessage("No recipe match")
    else
        rmessage("Factory not idle, current status " .. tostring(self.status))
    end
    return false
end

function CraftUnitFactory:connectorCallback()
    --print(tostring(param))
    self.remaining = self.remaining - 1
    if self.remaining < 0 then
        rwarning("Mysterious extra item from " .. tostring(self.makerIndex))
    end
    print(self.remaining)
    if self.remaining <= 0 then
        self.remaining = 0
        self.status = FactoryStatuses.IDLE
        reportFinishedTask(self)
    end
end

filesystem.doFile("/CraftCommon.lua")




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
            local index = p[3]
            if p[1] == "Maker" and p[2] == unit.name then
                computer.skip()
                local sources = explode(":", p[4])
                local sourceCount = 0
                for k,v in pairs(sources) do
                    sources[k] = unit.name.. "-" .. v .. "-" .. index
                    sourceCount = sourceCount + 1
                end
                local mkIndex = unit.name .. ":" .. p[3]
                unitFactoryCount = unitFactoryCount + 1
                ---@type CraftUnitFactory
                local factory = CraftUnitFactory.new(cname, unit, mkIndex, comp.id)
                factory.sources = sources
                factory.nextSource = math.fmod(tonumber(index), sourceCount) + 1
                --local factory = {
                --    sources = sources,
                --    name = cname,
                --    maker = createReference(comp.id),
                --    taskID = nil,
                --    makerIndex = mkIndex,
                --    remaining = 0,
                --    unit = unit,
                --    nextSource = math.fmod(tonumber(index), sourceCount) + 1,
                --    status = FactoryStatuses.IDLE,
                --}
                clearInventories(comp)
                local maker = factory.maker:get()
                for _,recipe in pairs(maker:getRecipes()) do
                    local rname = recipe.name
                    if recipes[rname] == nil then
                        ---@type CraftUnitRecipe
                        local item = {
                            recipeName = rname,
                            needsCanisters = 0
                        }
                        --print(recipe)
                        --print(recipe.name)
                        --print(recipe.getIngredients)
                        local ingredients = recipe:getIngredients()
                        item.recipeMakes = recipe:getProducts()[1].type.name
                        item.recipeMakesAmount = recipe:getProducts()[1].amount
                        item.regents = {}
                        for _,regent in pairs(ingredients) do
                            --sendParams[index] = regent.item:getName()
                            --sendParams[index + 1] = regent.count
                            ---@type CraftUnitRecipeRegents
                            local regentItem = {
                                name = regent.type.name,
                                count = regent.amount
                            }
                            table.insert(item.regents, regentItem)
                        end
                        craftUnit.recipes[rname] = item
                        recipes[rname] = item
                        --table.insert(recipes, item)
                    else
                        --print("Invalid recipe: "..recipe.name)
                    end
                end

                local connector = comp:getFactoryConnectors()[unit.output]
                registerEvent(connector, factory, factory.connectorCallback)
                factory.outConnector = connector
                print("Listen " .. maker.nick .. ":" .. unit.output)
                event.listen(connector)
                event.listen(maker)

                factories[factory.makerIndex] = factory
                craftUnit.factories[factory.makerIndex] = factory

                makerIndex = makerIndex + 1

            end

        end
        craftUnit.factoryCount = unitFactoryCount
    end
    return makerIndex - 1
end
