-- 优化后的四叉树实现
local Quadtree = {}
Quadtree.__index = Quadtree

function Quadtree.new(bounds, maxObjects, maxLevels, level)
    local self = setmetatable({}, Quadtree)
    self.bounds = bounds
    self.maxObjects = maxObjects or 10
    self.maxLevels = maxLevels or 4
    self.level = level or 0
    self.objects = {}
    self.nodes = {}
    return self
end

-- 初始化四叉树
function Quadtree:init(x, y, width, height)
    self.bounds = {x = x, y = y, width = width, height = height}
    self:clear()
end

-- 插入对象
function Quadtree:insert(obj)
    if #self.nodes > 0 then
        local index = self:_getIndex(obj)
        if index ~= -1 then
            self.nodes[index]:insert(obj)
            return
        end
    end
    
    table.insert(self.objects, obj)
    
    -- 检查是否需要分裂
    if #self.objects > self.maxObjects and self.level < self.maxLevels then
        if #self.nodes == 0 then
            self:_split()
        end
        
        -- 重新分配对象
        for i = #self.objects, 1, -1 do
            local index = self:_getIndex(self.objects[i])
            if index ~= -1 then
                self.nodes[index]:insert(table.remove(self.objects, i))
            end
        end
    end
end

-- 查询区域内的对象
function Quadtree:query(area, found)
    found = found or {}
    
    if #self.nodes > 0 then
        local index = self:_getIndex(area)
        if index ~= -1 then
            self.nodes[index]:query(area, found)
        else
            for _, node in ipairs(self.nodes) do
                if self:_intersects(node.bounds, area) then
                    node:query(area, found)
                end
            end
        end
    end
    
    for _, obj in ipairs(self.objects) do
        if self:_intersects(obj, area) then
            table.insert(found, obj)
        end
    end
    
    return found
end

-- 更新对象位置
function Quadtree:update(obj, newBounds)
    -- 尝试从当前节点移除
    local removed = false
    for i, o in ipairs(self.objects) do
        if o == obj then
            table.remove(self.objects, i)
            removed = true
            break
        end
    end
    
    -- 如果不在当前节点，检查子节点
    if not removed and #self.nodes > 0 then
        for _, node in ipairs(self.nodes) do
            -- 只有当对象可能在该节点中时才递归检查
            if self:_intersects(node.bounds, {x=newBounds.x, y=newBounds.y, width=newBounds.width, height=newBounds.height}) then
                node:update(obj, newBounds)
                -- 检查对象是否已被子节点移除
                if node:contains(obj) then
                    removed = true
                    break
                end
            end
        end
        -- 如果对象仍未找到，返回
        if not removed then
            return
        end
    end
    
    -- 更新对象边界并重新插入
    obj.x = newBounds.x
    obj.y = newBounds.y
    obj.width = newBounds.width
    obj.height = newBounds.height
    self:insert(obj)
end

-- 检查节点是否包含指定对象
function Quadtree:contains(obj)
    for _, o in ipairs(self.objects) do
        if o == obj then
            return true
        end
    end
    
    if #self.nodes > 0 then
        for _, node in ipairs(self.nodes) do
            if node:contains(obj) then
                return true
            end
        end
    end
    
    return false
end

-- 清空逻辑
function Quadtree:clear()
    self.objects = {}
    self.nodes = {}
end

-- 检测两个矩形是否相交
function Quadtree:_intersects(rect1, rect2)
    return rect1.x < rect2.x + rect2.width and
           rect1.x + rect1.width > rect2.x and
           rect1.y < rect2.y + rect2.height and
           rect1.y + rect1.height > rect2.y
end

-- 获取对象应该插入的节点索引
function Quadtree:_getIndex(obj)
    local index = -1
    local verticalMidpoint = self.bounds.x + (self.bounds.width / 2)
    local horizontalMidpoint = self.bounds.y + (self.bounds.height / 2)
    
    -- 完全在左上角
    local topLeftQuadrant = obj.y < horizontalMidpoint and obj.y + obj.height < horizontalMidpoint and
                            obj.x < verticalMidpoint and obj.x + obj.width < verticalMidpoint
    
    -- 完全在右上角
    local topRightQuadrant = obj.y < horizontalMidpoint and obj.y + obj.height < horizontalMidpoint and
                             obj.x > verticalMidpoint
    
    -- 完全在左下角
    local bottomLeftQuadrant = obj.y > horizontalMidpoint and
                              obj.x < verticalMidpoint and obj.x + obj.width < verticalMidpoint
    
    -- 完全在右下角
    local bottomRightQuadrant = obj.y > horizontalMidpoint and obj.x > verticalMidpoint
    
    if topLeftQuadrant then
        index = 1
    elseif topRightQuadrant then
        index = 2
    elseif bottomLeftQuadrant then
        index = 3
    elseif bottomRightQuadrant then
        index = 4
    end
    
    return index
end

-- 分裂四叉树
function Quadtree:_split()
    local subWidth = self.bounds.width / 2
    local subHeight = self.bounds.height / 2
    local x = self.bounds.x
    local y = self.bounds.y
    
    -- 创建四个子节点
    self.nodes[1] = Quadtree.new({
        x = x,
        y = y,
        width = subWidth,
        height = subHeight
    }, self.maxObjects, self.maxLevels, self.level + 1)
    
    self.nodes[2] = Quadtree.new({
        x = x + subWidth,
        y = y,
        width = subWidth,
        height = subHeight
    }, self.maxObjects, self.maxLevels, self.level + 1)
    
    self.nodes[3] = Quadtree.new({
        x = x,
        y = y + subHeight,
        width = subWidth,
        height = subHeight
    }, self.maxObjects, self.maxLevels, self.level + 1)
    
    self.nodes[4] = Quadtree.new({
        x = x + subWidth,
        y = y + subHeight,
        width = subWidth,
        height = subHeight
    }, self.maxObjects, self.maxLevels, self.level + 1)
end

return Quadtree