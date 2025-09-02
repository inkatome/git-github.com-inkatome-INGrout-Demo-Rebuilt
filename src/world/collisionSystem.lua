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
    -- 优先从transform组件获取坐标
    local transform = entity.components and entity.components.transform
    local entityX, entityY, entityWidth, entityHeight = 0, 0, 32, 32
    
    if transform then
        entityX = transform.x or 0
        entityY = transform.y or 0
        entityWidth = transform.width or 32
        entityHeight = transform.height or 32
    else
        -- 兼容直接存储在实体上的情况
        entityX = entity.x or 0
        entityY = entity.y or 0
        entityWidth = entity.width or 32
        entityHeight = entity.height or 32
    end
    
    -- 如果提供了x和y参数，使用它们
    x = x or entityX
    y = y or entityY
    
    -- 检查entity.collision是否存在，不存在则使用空表
    local collision = entity.collision or {}
    return {
        x = x + (collision.offsetX or 0),
        y = y + (collision.offsetY or 0),
        width = collision.width or entityWidth,
        height = collision.height or entityHeight
    }
end

-- 检查是否超出地图边界
function CollisionSystem:_isOutOfMapBounds(rect)
    -- 确保quadtree尺寸已初始化
    local quadtreeWidth = self.quadtree.width or 0
    local quadtreeHeight = self.quadtree.height or 0
    
    return rect.x < 0 or rect.y < 0 or 
           rect.x + rect.width > quadtreeWidth or 
           rect.y + rect.height > quadtreeHeight
end

-- AABB碰撞检测
function CollisionSystem:_checkAABB(rect1, rect2)
    return rect1.x < rect2.x + rect2.width and
           rect1.x + rect1.width > rect2.x and
           rect1.y < rect2.y + rect2.height and
           rect1.y + rect1.height > rect2.y
end

return CollisionSystem