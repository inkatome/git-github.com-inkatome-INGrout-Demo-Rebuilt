-- 优化的碰撞系统
local Quadtree = require('src.utils.quadtree')
local CollisionSystem = {}
CollisionSystem.__index = CollisionSystem

function CollisionSystem.new()
    local self = setmetatable({}, CollisionSystem)
    self.staticQuadtree = nil  -- 静态碰撞体四叉树
    self.dynamicQuadtree = nil -- 动态碰撞体四叉树
    self.mapBounds = {x=0, y=0, width=0, height=0} -- 地图边界
    self.debug = false -- 调试标志
    self.collisionCache = {} -- 碰撞结果缓存
    return self
end

-- 初始化碰撞系统
function CollisionSystem:init(bounds)
    self.mapBounds = bounds or {x=0, y=0, width=0, height=0}
    self.collisionCache = {}
    self.debug = false
    
    -- 初始化四叉树，调整参数以提高性能
    -- 减少maxObjects，增加maxLevels以获得更细粒度的划分
    self.staticQuadtree = Quadtree.new(self.mapBounds, 4, 6, 0)
    self.dynamicQuadtree = Quadtree.new(self.mapBounds, 4, 4, 0)
    
    if self.debug then
        -- print(string.format("[Collision] System initialized with bounds: %d, %d, %d, %d",
    --     self.mapBounds.x, self.mapBounds.y, self.mapBounds.width, self.mapBounds.height))
    end
end

-- 添加静态碰撞体
function CollisionSystem:addStaticCollider(collider)
    if not collider or not collider.x or not collider.y or not collider.width or not collider.height then
        if self.debug then
            -- print("[Collision] Invalid static collider skipped")
        end
        return
    end
    self.staticQuadtree:insert(collider)
    
    if self.debug then
        -- print(string.format("[Collision] Added static collider: %d, %d, %d, %d",
            --     collider.x, collider.y, collider.width, collider.height))
    end
end

-- 添加动态碰撞体
function CollisionSystem:addDynamicCollider(entity, collider)
    if not entity or not collider or not collider.width or not collider.height then
        if self.debug then
            -- print("[Collision] Invalid dynamic collider skipped")
        end
        return
    end
    
    -- 存储实体引用以便后续更新
    collider.entity = entity
    self.dynamicQuadtree:insert(collider)
    
    if self.debug then
        -- print(string.format("[Collision] Added dynamic collider for entity: %s", tostring(entity)))
    end
end

-- 更新动态碰撞体位置
function CollisionSystem:updateDynamicCollider(entity, x, y)
    -- 查找实体对应的碰撞体
    local oldCollider = self:_findDynamicCollider(entity)
    if oldCollider then
        -- 创建新碰撞体数据
        local newCollider = {x=x, y=y, width=oldCollider.width, height=oldCollider.height, entity=entity}
        
        -- 更新四叉树中的碰撞体
        self.dynamicQuadtree:update(oldCollider, newCollider)
        
        if self.debug then
            -- print(string.format("[Collision] Updated dynamic collider: %s to %d, %d",
            --     tostring(entity), x, y))
        end
    end
end

-- 查找动态碰撞体
function CollisionSystem:_findDynamicCollider(entity)
    -- 四叉树没有直接的查找方法，我们需要遍历整个树
    -- 这是一个缺点，但在大多数情况下，更新操作比查询操作少
    local found = self.dynamicQuadtree:query(self.mapBounds)
    for _, collider in ipairs(found) do
        if collider.entity == entity then
            return collider
        end
    end
    return nil
end

-- 位置碰撞检测
function CollisionSystem:checkPosition(entity, x, y)
    -- 生成缓存键
    local cacheKey = string.format("%s_%d_%d", tostring(entity), x, y)
    
    -- 检查缓存
    if self.collisionCache[cacheKey] then
        return self.collisionCache[cacheKey].collided, self.collisionCache[cacheKey].type
    end
    
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
            -- print(string.format("[Collision] Map bounds collision at: %d, %d", collider.x, collider.y))
        end
        
        -- 更新缓存
        self.collisionCache[cacheKey] = {collided=true, type="map_bounds"}
        return true, "map_bounds"
    end
    
    -- 检查静态碰撞体 (使用四叉树优化)
    local staticCollisions = self.staticQuadtree:query(collider)
    for _, staticCollider in ipairs(staticCollisions) do
        if self:_checkAABB(collider, staticCollider) then
            if self.debug then
                -- print(string.format("[Collision] Static collision at: %d, %d", collider.x, collider.y))
            end
            
            -- 更新缓存
            self.collisionCache[cacheKey] = {collided=true, type="obstacle"}
            return true, "obstacle"
        end
    end
    
    -- 检查动态碰撞体 (使用四叉树优化)
    local dynamicCollisions = self.dynamicQuadtree:query(collider)
    for _, dynamicCollider in ipairs(dynamicCollisions) do
        if dynamicCollider.entity ~= entity and self:_checkAABB(collider, dynamicCollider) then
            if self.debug then
                -- print(string.format("[Collision] Dynamic collision with %s at: %d, %d",
                --     tostring(dynamicCollider.entity), collider.x, collider.y))
            end
            
            -- 更新缓存
            self.collisionCache[cacheKey] = {collided=true, type="entity"}
            return true, "entity"
        end
    end
    
    if self.debug then
        -- print(string.format("[Collision] No collision at: %d, %d", collider.x, collider.y))
    end
    
    -- 更新缓存
    self.collisionCache[cacheKey] = {collided=false, type="none"}
    return false
end

-- 清除碰撞缓存（在场景切换或实体大量移动时调用）
function CollisionSystem:clearCache()
    self.collisionCache = {}
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