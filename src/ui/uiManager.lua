-- UI管理系统
local Button = require("src.ui.button")

local UIManager = {}
UIManager.__index = UIManager

function UIManager.new()
    local self = setmetatable({}, UIManager)
    self.elements = {}
    self.focusElement = nil
    return self
end

-- 添加UI元素
function UIManager:addElement(element)
    table.insert(self.elements, element)
    return element
end

-- 移除UI元素
function UIManager:removeElement(element)
    for i, el in ipairs(self.elements) do
        if el == element then
            table.remove(self.elements, i)
            return true
        end
    end
    return false
end

-- 更新UI元素
function UIManager:update(dt)
    for _, element in ipairs(self.elements) do
        if element.update then
            element:update(dt)
        end
    end
end

-- 绘制UI元素
function UIManager:draw()
    for _, element in ipairs(self.elements) do
        if element.draw then
            element:draw()
        end
    end
end

-- 处理点击事件
function UIManager:handleClick(x, y)
    -- 从顶部元素开始检测
    for i = #self.elements, 1, -1 do
        local element = self.elements[i]
        if element.handleClick and element:handleClick(x, y) then
            self.focusElement = element
            return true
        end
    end
    self.focusElement = nil
    return false
end

-- 添加按钮
function UIManager:addButton(x, y, width, height, text, callback)
    local button = Button.new(x, y, width, height, text, callback)
    return self:addElement(button)
end

-- 处理鼠标移动事件
function UIManager:handleMouseMove(x, y)
    for _, element in ipairs(self.elements) do
        if element.handleMouseMove then
            element:handleMouseMove(x, y)
        end
    end
end

return UIManager