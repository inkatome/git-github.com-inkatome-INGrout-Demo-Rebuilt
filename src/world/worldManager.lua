-- 世界管理器（协调各子系统）
local WorldManager = {}
WorldManager.__index = WorldManager

function WorldManager.new()
    local self = setmetatable({}, WorldManager)
    
    -- 子系统
    self.resourceLoader = require("src.world.resourceLoader").new()
    self.entityCoordinator = require("src.world.entityCoordinator").new()
    self.mapService = require("src.world.mapService").new()
    self.questSystem = require("src.world.questSystem").new()
    self.collisionSystem = require("src.world.collisionSystem").new()
    
    -- 世界状态
    self.currentScene = nil
    self.isWorldReady = false
    self.debugMode = false
    
    return self
end

-- 加载场景
function WorldManager:load(sceneName)
    if self.isWorldReady then
        self:unload()
    end
    
    self.currentScene = sceneName
    self.resourceLoader:loadForScene(sceneName)
    -- 创建实体

    local entities = self.resourceLoader:getEntities()
    for _, entityDef in ipairs(entities) do
        self.entityCoordinator:createEntity(entityDef.type, entityDef)
    end

    -- 加载地图
    self.mapService:load(sceneName)
    
    -- 设置碰撞系统
    local mapSize = self.mapService:getMapSize()
    self.collisionSystem:init({x=0, y=0, width=mapSize.width, height=mapSize.height})
    
    -- 添加静态碰撞体
    local colliders = self.resourceLoader:getColliders()
    for _, collider in ipairs(colliders) do
        self.collisionSystem:addStaticCollider(collider)
    end
    
    self.isWorldReady = true
end

-- 更新世界
function WorldManager:update(dt)
    if not self.isWorldReady then return end
    
    self.entityCoordinator:update(dt)
    self.mapService:update(dt)
    
    -- 玩家移动处理
        local player = self.entityCoordinator.playerEntity
        if player then
            local controller = player.components.playerControl.controller
            local proposedX, proposedY = controller:getProposedPosition()
            
            -- 优先从transform组件获取当前位置
            local transform = player.components and player.components.transform
            local currentX, currentY = 0, 0
            local currentWidth, currentHeight = 32, 32
            
            if transform then
                currentX = transform.x or 0
                currentY = transform.y or 0
                currentWidth = transform.width or 32
                currentHeight = transform.height or 32
            else
                currentX = player.x or 0
                currentY = player.y or 0
                currentWidth = player.width or 32
                currentHeight = player.height or 32
            end
            
            if proposedX ~= currentX or proposedY ~= currentY then
                local collided = self.collisionSystem:checkPosition(
                    player, proposedX, proposedY
                )
                
                if not collided then
                    -- 更新transform组件或直接属性
                    if transform then
                        transform.x = proposedX
                        transform.y = proposedY
                    else
                        player.x, player.y = proposedX, proposedY
                    end
                    
                    -- 更新碰撞系统中的动态物体位置
                    self.collisionSystem:updateDynamicCollider(player, {
                        x = proposedX, y = proposedY,
                        width = currentWidth, height = currentHeight
                    })
                end
            end
        end
end

-- 绘制世界
function WorldManager:draw()
    if not self.isWorldReady then return end
    
    love.graphics.push()
    local camera = self.mapService:getCamera()
    love.graphics.translate(-camera.x, -camera.y)
    
    self.mapService:drawBackground()
    self.entityCoordinator:draw()  -- 这里会调用实体绘制，包括动画系统
    self.mapService:drawForeground()
    
    love.graphics.pop()
    
    -- UI绘制
    self.questSystem:draw()
    
    -- 调试信息
    if self.debugMode then
        self:drawDebugInfo()
    end
end

function WorldManager:toggleDebugMode()  -- 
    self.debugMode = not self.debugMode
    print("Debug mode:", self.debugMode and "ON" or "OFF")
end

-- 其他方法...

return WorldManager