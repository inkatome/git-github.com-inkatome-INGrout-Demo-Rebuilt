-- 整合四叉树的碰撞系统
local Quadtree = require('src.utils.quadtree')
local CollisionSystem = {}
CollisionSystem.__index = CollisionSystem

function CollisionSystem.new()
    local self = setmetatable({}, CollisionSystem)
    self.staticQuadtree = nil  -- 静态碰撞体四叉树
    self.dynamicColliders = {} -- 动态碰撞体列表
    self.mapBounds = {x=0, y=0, width=0, height=0} -- 地图边界
    self.debug = false -- 调试标志
    return self
end

-- 初始化碰撞系统
function CollisionSystem:init(bounds)
    self.mapBounds = bounds or {x=0, y=0, width=0, height=0}
    self.dynamicColliders = {}
    self.debug = false
    
    -- 初始化静态碰撞体四叉树
    self.staticQuadtree = Quadtree.new(self.mapBounds, 10, 4, 0)
    
    if self.debug then
        print(string.format("[Collision] System initialized with bounds: %d, %d, %d, %d",
            self.mapBounds.x, self.mapBounds.y, self.mapBounds.width, self.mapBounds.height))
    end
end

-- 添加静态碰撞体
function CollisionSystem:addStaticCollider(collider)
    if not collider or not collider.x or not collider.y or not collider.width or not collider.height then
        if self.debug then
            print("[Collision] Invalid static collider skipped")
        end
        return
    end
    self.staticQuadtree:insert(collider)
    
    if self.debug then
        print(string.format("[Collision] Added static collider: %d, %d, %d, %d",
            collider.x, collider.y, collider.width, collider.height))
    end
end

-- 添加动态碰撞体
function CollisionSystem:addDynamicCollider(entity, collider)
    if not entity or not collider or not collider.width or not collider.height then
        if self.debug then
            print("[Collision] Invalid dynamic collider skipped")
        end
        return
    end
    self.dynamicColliders[entity] = collider
    
    if self.debug then
        print(string.format("[Collision] Added dynamic collider for entity: %s", tostring(entity)))
    end
end

-- 更新动态碰撞体位置
function CollisionSystem:updateDynamicCollider(entity, x, y)
    local collider = self.dynamicColliders[entity]
    if collider then
        collider.x = x
        collider.y = y
        
        if self.debug then
            print(string.format("[Collision] Updated dynamic collider: %s to %d, %d",
                tostring(entity), x, y))
        end
    end
end

-- 位置碰撞检测
function CollisionSystem:checkPosition(entity, x, y)
    -- 获取实体的碰撞矩形和偏移量
    local collision = entity.collision or {}
    local width = collision.width or 32
    local height = collision.height or 32
    local offsetX = collision.offsetX or 0
    local offsetY = collision.offsetY or 0
    
    -- 使用传入的位置加上偏移量，与添加动态碰撞体时保持一致
    local collider = {x=x + offsetX, y=y + offsetY, width=width, height=height}
    
    
    -- 检查地图边界
    if self:_checkMapBoundsCollision(collider) then
        if self.debug then
            print(string.format("[Collision] Map bounds collision at: %d, %d", collider.x, collider.y))
        end
        return true, "map_bounds"
    end
    
    -- 检查静态碰撞体 (使用四叉树优化)
    local staticCollisions = self.staticQuadtree:query(collider)
    for _, staticCollider in ipairs(staticCollisions) do
        if self:_checkAABB(collider, staticCollider) then
            if self.debug then
                print(string.format("[Collision] Static collision at: %d, %d", collider.x, collider.y))
            end
            return true, "obstacle"
        end
    end
    
    -- 检查动态碰撞体（除自身外）
    for otherEntity, otherCollider in pairs(self.dynamicColliders) do
        if otherEntity ~= entity and self:_checkAABB(collider, otherCollider) then
            if self.debug then
                print(string.format("[Collision] Dynamic collision with %s at: %d, %d",
                    tostring(otherEntity), collider.x, collider.y))
            end
            return true, "entity"
        end
    end
    
    if self.debug then
        print(string.format("[Collision] No collision at: %d, %d", collider.x, collider.y))
    end
    return false
end

-- 获取实体碰撞矩形
function CollisionSystem:_getEntityCollider(entity, x, y)
    -- 从实体组件获取碰撞信息
    local collision = entity.collision or {}
    local width = collision.width or 32
    local height = collision.height or 32
    local offsetX = collision.offsetX or 0
    local offsetY = collision.offsetY or 0
    
    -- 计算最终位置
    local finalX = x + offsetX
    local finalY = y + offsetY
    
    return {x=finalX, y=finalY, width=width, height=height}
end

-- 检查地图边界碰撞
function CollisionSystem:_checkMapBoundsCollision(collider)
    return collider.x < self.mapBounds.x or
           collider.y < self.mapBounds.y or
           collider.x + collider.width > self.mapBounds.x + self.mapBounds.width or
           collider.y + collider.height > self.mapBounds.y + self.mapBounds.height
end

-- AABB碰撞检测
function CollisionSystem:_checkAABB(rect1, rect2)
    return rect1.x < rect2.x + rect2.width and
           rect1.x + rect1.width > rect2.x and
           rect1.y < rect2.y + rect2.height and
           rect1.y + rect1.height > rect2.y
end

return CollisionSystem