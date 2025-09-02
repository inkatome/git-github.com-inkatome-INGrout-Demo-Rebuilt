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
    
    -- 初始化中文字体
    self.defaultFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf")
    
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
    self.collisionSystem.debug = true -- 启用碰撞调试
    
    -- 添加静态碰撞体
    local colliders = self.resourceLoader:getColliders()
    for _, collider in ipairs(colliders) do
        self.collisionSystem:addStaticCollider(collider)
    end
    
    -- 添加玩家动态碰撞体
    local player = self.entityCoordinator.playerEntity
    if player then
        local collision = player.collision or {}
        local width = collision.width or 32
        local height = collision.height or 32
        local offsetX = collision.offsetX or 0
        local offsetY = collision.offsetY or 0
        
        -- 获取玩家初始位置
        local transform = player.components and player.components.transform
        local x, y = 0, 0
        if transform then
            x = transform.x or 0
            y = transform.y or 0
        else
            x = player.x or 0
            y = player.y or 0
        end
        
        -- 调试信息：打印玩家初始位置和碰撞体设置
        -- print(string.format("[WorldManager] Player initial position: %.1f, %.1f", x, y))
        -- print(string.format("[WorldManager] Collision offset: %.1f, %.1f", offsetX, offsetY))
        -- print(string.format("[WorldManager] Collision size: %.1f, %.1f", width, height))
        
        self.collisionSystem:addDynamicCollider(player, {
            x = x + offsetX,
            y = y + offsetY,
            width = width,
            height = height
        })
        
        -- 立即检查初始位置是否有碰撞 (考虑偏移量)
        local initialCollided, initialCollisionType = self.collisionSystem:checkPosition(player, x, y)
        -- print(string.format("[WorldManager] Initial position collision check: %s, type: %s",
        --     initialCollided and "true" or "false", initialCollisionType or "none"))
        
        -- 如果有碰撞，检查是哪个静态碰撞体
        if initialCollided and initialCollisionType == "obstacle" then
            -- print("[WorldManager] Checking which static collider is causing initial collision:")
            local playerCollider = self.collisionSystem:_getEntityCollider(player, x, y)
            
            -- 使用四叉树查询可能碰撞的静态碰撞体
            local potentialColliders = self.collisionSystem.staticQuadtree:query(playerCollider)
            for i, collider in ipairs(potentialColliders) do
                if self.collisionSystem:_checkAABB(playerCollider, collider) then
                    -- print(string.format("[WorldManager] Colliding with static collider %d: x=%.1f, y=%.1f, width=%.1f, height=%.1f, tag=%s",
                    --     i, collider.x, collider.y, collider.width, collider.height, collider.tag or "none"))
                end
            end
        end
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
                -- 调试信息：打印建议位置
                -- print(string.format("[WorldManager] Proposed position: %.1f, %.1f", proposedX, proposedY))
                
                -- 检查碰撞
                -- 检查碰撞时需要考虑碰撞体偏移量
                local collided, collisionType = self.collisionSystem:checkPosition(
                    player, proposedX, proposedY
                )
                
                -- 调试信息
                if collided then
                    -- print(string.format("[WorldManager] Collision detected: %s at position %.1f, %.1f",
                    --     collisionType or "unknown", proposedX, proposedY))
                else
                    -- print(string.format("[WorldManager] No collision, updating position to %.1f, %.1f",
                    --     proposedX, proposedY))
                     
                    -- 更新transform组件或直接属性
                    if transform then
                        transform.x = proposedX
                        transform.y = proposedY
                        -- print(string.format("[WorldManager] Updated transform position: %.1f, %.1f",
                        --     transform.x, transform.y))
                    else
                        player.x, player.y = proposedX, proposedY
                        -- print(string.format("[WorldManager] Updated player position: %.1f, %.1f",
            --     player.x, player.y))
                    end
                    
                    -- 更新碰撞系统中的动态物体位置（考虑偏移量）
                    local collision = player.collision or {}
                    local offsetX = collision.offsetX or 0
                    local offsetY = collision.offsetY or 0
                    self.collisionSystem:updateDynamicCollider(player, proposedX + offsetX, proposedY + offsetY)
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

function WorldManager:toggleDebugMode()
    self.debugMode = not self.debugMode
    -- print("Debug mode:", self.debugMode and "ON" or "OFF")
end

-- 绘制调试信息
function WorldManager:drawDebugInfo()
    local player = self.entityCoordinator.playerEntity
    if not player then return end

    -- 优先从transform组件获取当前位置
    local transform = player.components and player.components.transform
    local currentX, currentY = 0, 0
    if transform then
        currentX = transform.x or 0
        currentY = transform.y or 0
    else
        currentX = player.x or 0
        currentY = player.y or 0
    end

    -- 获取控制器和建议位置
    local controller = player.components.playerControl.controller
    local proposedX, proposedY = 0, 0
    if controller then
        proposedX, proposedY = controller:getProposedPosition()
    end

    -- 检查碰撞状态
    local collision = player.collision or {}
    local offsetX = collision.offsetX or 0
    local offsetY = collision.offsetY or 0
    local collided, collisionType = self.collisionSystem:checkPosition(player, proposedX, proposedY)

    -- 绘制调试信息
    -- 设置黑色文本
    love.graphics.setColor(0, 0, 0)
    -- 设置较小的中文字体
    local smallFont = love.graphics.newFont("assets/fonts/SourceHanSansSC-Regular.otf", 12)
    love.graphics.setFont(smallFont)
    
    love.graphics.print("=== 调试信息 ===", 10, 10)
    love.graphics.print(string.format("当前位置: X=%.1f, Y=%.1f", currentX, currentY), 10, 25)
    love.graphics.print(string.format("建议位置: X=%.1f, Y=%.1f", proposedX, proposedY), 10, 40)
    love.graphics.print(string.format("碰撞偏移: X=%.1f, Y=%.1f", offsetX, offsetY), 10, 55)
    love.graphics.print(string.format("碰撞状态: %s", collided and "碰撞" or "无碰撞"), 10, 70)
    if collided then
        love.graphics.print(string.format("碰撞类型: %s", collisionType or "未知"), 10, 85)
    end
    
    -- 重置字体为默认
    love.graphics.setFont(self.defaultFont)

    -- 重置颜色
    love.graphics.setColor(1, 1, 1, 1)
end

return WorldManager