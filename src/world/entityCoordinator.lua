-- 实体协调器（ECS架构）
local EntityCoordinator = {}
EntityCoordinator.__index = EntityCoordinator

--  工具类导入
local tableUtils = require("src.utils.tableUtils")
local EventBus = require("src.core.eventManager")

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
    self.layerEntities = {background={}, entities={}, foreground={}, ui={}}  -- 按图层分类实体
    self.eventThrottle = 0
    self.eventInterval = 0.1  -- 事件发送间隔（秒）
    return self
end

-- 创建实体
function EntityCoordinator:createEntity(entityType, config)
    -- 加载实体配置文件（缓存常用实体配置）
    local entityConfig = require("assets.entities."..entityType)
    if not entityConfig then
        -- print("[ERROR] Missing config for entity type:", entityType)
        return
    end
    
    -- 合并全局配置和场景特定配置（避免深拷贝，只复制必要字段）
    local mergedConfig = {}
    for k, v in pairs(entityConfig) do
        mergedConfig[k] = v
    end
    if config then
        for k, v in pairs(config) do
            mergedConfig[k] = v
        end
    end
    
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
    
    -- 添加渲染组件（如果配置中存在）
    if mergedConfig.render then
        self:addComponent(entity, ComponentType.RENDER, mergedConfig.render)
        
        -- 按图层分类实体
        local layer = mergedConfig.render.layer or "entities"
        if not self.layerEntities[layer] then
            layer = "entities"  -- 默认图层
        end
        table.insert(self.layerEntities[layer], entity)
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
        self:addComponent(entity, ComponentType.DIALOG, mergedConfig.dialog or {})
    end
    
    table.insert(self.entities, entity)
    
    -- 节流事件发送
    if not self.lastEventTime or (love.timer.getTime() - self.lastEventTime) > self.eventInterval then
        EventBus.emit(EventBus.WorldEvents.ENTITY_ADDED, entity)
        self.lastEventTime = love.timer.getTime()
    end
    
    return entity
end

-- 添加组件
function EntityCoordinator:addComponent(entity, componentType, data)
    entity.components[componentType] = data
    
    -- 优化组件存储，避免重复插入
    local found = false
    for _, e in ipairs(self.components[componentType]) do
        if e.id == entity.id then
            found = true
            break
        end
    end
    
    if not found then
        table.insert(self.components[componentType], entity)
    end
end

-- 更新所有实体
function EntityCoordinator:update(dt)
    -- 直接更新玩家实体（通常只有一个）
    if self.playerEntity and self.playerEntity.components[ComponentType.PLAYER_CONTROL] then
        local controller = self.playerEntity.components[ComponentType.PLAYER_CONTROL].controller
        controller:update(dt)
    end
    
    -- 更新AI实体
    for _, entity in ipairs(self.components[ComponentType.AI]) do
        -- AI更新逻辑
    end
    
    -- 更新动画组件
    for _, entity in ipairs(self.components[ComponentType.ANIMATION]) do
        local animationSystem = entity.components[ComponentType.ANIMATION].system
        if animationSystem.update then
            animationSystem:update(dt)
        end
    end
end

-- 绘制实体
function EntityCoordinator:draw()
    local layers = {"background", "entities", "foreground", "ui"}
    for _, layer in ipairs(layers) do
        -- 直接使用预分类的图层实体
        for _, entity in ipairs(self.layerEntities[layer]) do
            local render = entity.components[ComponentType.RENDER]
            if render and render.draw then
                render.draw(entity)
            end
        end
    end
end

-- 其他方法...

return EntityCoordinator