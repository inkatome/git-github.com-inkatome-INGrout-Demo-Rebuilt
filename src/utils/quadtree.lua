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
                table.insert(self.nodes[index], table.remove(self.objects, i))
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

-- 更新对象位置（优化版本）
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
            node:update(obj, newBounds)
        end
        return
    end
    
    -- 更新对象边界并重新插入
    obj.x = newBounds.x
    obj.y = newBounds.y
    obj.width = newBounds.width
    obj.height = newBounds.height
    self:insert(obj)
end

-- 清空逻辑
function Quadtree:clear()
    self.objects = {}
    self.nodes = {}
end

-- 其他方法保持不变...

return Quadtree