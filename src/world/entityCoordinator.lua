-- 实体协调器（ECS架构）
local EntityCoordinator = {}
EntityCoordinator.__index = EntityCoordinator

--  工具类导入
local tableUtils = require("src.utils.tableUtils")

-- 组件类型
local ComponentType = {
    TRANSFORM = "transform",
    RENDER = "render",
    PHYSICS = "physics",
    PLAYER_CONTROL = "playerControl",
    AI = "ai",
    ANIMATION = "animation",  -- 动画组件类型
    DIALOG = "dialog"         -- 对话组件类型
}

function EntityCoordinator.new()
    local self = setmetatable({}, EntityCoordinator)
    self.entities = {}  -- 初始化实体列表
    self.components = {}
    for _, compType in pairs(ComponentType) do
        self.components[compType] = {}
    end
    self.playerEntity = nil
    return self
end

-- 创建实体
function EntityCoordinator:createEntity(entityType, config)
    -- 加载实体配置文件
    local entityConfig = require("assets.entities."..entityType)
    if not entityConfig then
        print("[ERROR] Missing config for entity type:", entityType)
        return
    end
    
    -- 合并全局配置和场景特定配置
    local mergedConfig = tableUtils.merge(tableUtils.deepCopy(entityConfig), config)
    
    local entity = {
        id = #self.entities + 1,
        type = entityType,
        components = {}
    }
    
    -- 添加基础变换组件
    self:addComponent(entity, ComponentType.TRANSFORM, {
        x = mergedConfig.x or 0,
        y = mergedConfig.y or 0,
        width = mergedConfig.width or 32,
        height = mergedConfig.height or 32
    })
    
    -- 添加渲染组件（如果配置中存在）-- 关键修复点
    if mergedConfig.render then
        self:addComponent(entity, ComponentType.RENDER, mergedConfig.render)
    end
    
    -- 添加物理组件（如果配置中存在）
    if mergedConfig.physics then
        self:addComponent(entity, ComponentType.PHYSICS, mergedConfig.physics)
    end
    
    -- 特殊实体处理
    if entityType == "player" then
        self:addComponent(entity, ComponentType.PLAYER_CONTROL, {
            controller = require("src.entities.playerController").new(entity)
        })
        
        -- 添加动画系统组件
        self:addComponent(entity, ComponentType.ANIMATION, {
            system = require("src.systems.playerAnimationSystem").new(entity)
        })
        
        self.playerEntity = entity
    elseif entityType == "npc" then
        -- 添加对话组件
        self:addComponent(entity, ComponentType.DIALOG, mergedConfig.dialog)
    end
    
    table.insert(self.entities, entity)
    EventBus.emit(EventBus.WorldEvents.ENTITY_ADDED, entity)
    return entity
end

-- 添加组件
function EntityCoordinator:addComponent(entity, componentType, data)
    entity.components[componentType] = data
    table.insert(self.components[componentType], entity)
end

-- 更新所有实体
function EntityCoordinator:update(dt)
    -- 更新玩家控制实体
    for _, entity in ipairs(self.components[ComponentType.PLAYER_CONTROL]) do
        local controller = entity.components[ComponentType.PLAYER_CONTROL].controller
        controller:update(dt)
    end
    
    -- 更新AI实体
    for _, entity in ipairs(self.components[ComponentType.AI]) do
        -- AI更新逻辑
    end
end

-- 绘制实体
function EntityCoordinator:draw()
    local layers = {"background", "entities", "foreground", "ui"}
    for _, layer in ipairs(layers) do
        for _, entity in ipairs(self.components[ComponentType.RENDER]) do
            local render = entity.components[ComponentType.RENDER]
            if render.layer == layer and render.draw then
                render.draw(entity)
            end
        end
    end
end

-- 其他方法...

return EntityCoordinator