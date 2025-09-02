-- 优化后的碰撞系统
local Quadtree = require("src.utils.quadtree")

local CollisionSystem = {}
CollisionSystem.__index = CollisionSystem

function CollisionSystem.new()
    local self = setmetatable({}, CollisionSystem)
    self.quadtree = Quadtree.new()
    self.dynamicObjects = {}
    return self
end

-- 初始化碰撞系统
function CollisionSystem:init(bounds)
    self.quadtree:init(bounds.x, bounds.y, bounds.width, bounds.height)
end

-- 添加静态碰撞体
function CollisionSystem:addStaticCollider(collider)
    self.quadtree:insert(collider)
end

-- 添加动态碰撞体
function CollisionSystem:addDynamicCollider(collider)
    self.dynamicObjects[collider] = true
    self.quadtree:insert(collider)
end

-- 更新动态碰撞体
function CollisionSystem:updateDynamicCollider(collider, newBounds)
    self.quadtree:update(collider, newBounds)
end

-- 位置检测
function CollisionSystem:checkPosition(entity, x, y)
    local rect = self:_getEntityRect(entity, x, y)
    
    -- 地图边界检测
    if self:_isOutOfMapBounds(rect) then
        return true, "map_bounds"
    end
    
    -- 四叉树查询
    local colliders = self.quadtree:query(rect)
    for _, collider in ipairs(colliders) do
        if collider ~= entity and self:_checkAABB(rect, collider) then
            return true, "obstacle"
        end
    end
    
    return false
end

-- 获取实体碰撞矩形
function CollisionSystem:_getEntityRect(entity, x, y)
    x = x or entity.x
    y = y or entity.y
    return {
        x = x + (entity.collision.offsetX or 0),
        y = y + (entity.collision.offsetY or 0),
        width = entity.collision.width or entity.width,
        height = entity.collision.height or entity.height
    }
end

-- 其他方法保持不变...

return CollisionSystem