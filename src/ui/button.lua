-- src/ui/button.lua
local Button = {}
Button.__index = Button

-- 按钮状态
Button.State = {
    NORMAL = 1,
    HOVER = 2,
    PRESSED = 3
}

function Button.new(x, y, width, height, text, onClick)
    local self = setmetatable({}, Button)
    self.x = x
    self.y = y
    self.width = width
    self.height = height
    self.text = text
    self.onClick = onClick
    self.state = Button.State.NORMAL
    self.font = Fonts.default -- 使用全局中文字体
    self.textColor = {1, 1, 1, 1}
-- 添加默认颜色配置
    self.colors = {
        [Button.State.NORMAL] = {0.4, 0.4, 0.4, 1},   -- 正常状态颜色
        [Button.State.HOVER] = {0.6, 0.6, 0.6, 1},    -- 悬停状态颜色
        [Button.State.PRESSED] = {0.2, 0.2, 0.2, 1}   -- 按下状态颜色
    }

    return self
end

-- 更新按钮状态
function Button:update(dt)
    -- 不需要每帧更新，事件处理中更新状态
end

-- 绘制按钮
function Button:draw()
    local color = self.colors[self.state]
    love.graphics.setColor(color)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    
    -- 边框
    love.graphics.setColor(1, 1, 1)
    love.graphics.rectangle("line", self.x, self.y, self.width, self.height)
    
    -- 文字
    love.graphics.setFont(self.font)
    love.graphics.setColor(self.textColor)
    local textWidth = self.font:getWidth(self.text)
    local textHeight = self.font:getHeight()
    love.graphics.print(
        self.text, 
        self.x + (self.width - textWidth) / 2,
        self.y + (self.height - textHeight) / 2
    )
end

-- 处理鼠标点击
function Button:handleClick(x, y)
    if self:_isPointInside(x, y) then
        self.state = Button.State.PRESSED
        if self.onClick then
            Audio:play("sfx_click")
            self.onClick()
        end
        return true
    end
    return false
end

-- 处理鼠标移动（用于悬停效果）
function Button:handleMouseMove(x, y)
    if self:_isPointInside(x, y) then
        if self.state ~= Button.State.PRESSED then
            self.state = Button.State.HOVER
        end
    else
        self.state = Button.State.NORMAL
    end
end

-- 检测点是否在按钮内
function Button:_isPointInside(x, y)
    return x >= self.x and x <= self.x + self.width and
           y >= self.y and y <= self.y + self.height
end

-- 设置按钮文本
function Button:setText(newText)
    self.text = newText
end

-- 设置按钮位置
function Button:setPosition(x, y)
    self.x = x
    self.y = y
end

-- 设置按钮尺寸
function Button:setSize(width, height)
    self.width = width
    self.height = height
end

-- 设置按钮颜色
function Button:setColor(state, r, g, b, a)
    self.colors[state] = {r, g, b, a or 1}
end

-- 设置文本颜色
function Button:setTextColor(r, g, b, a)
    self.textColor = {r, g, b, a or 1}
end

-- 设置字体
function Button:setFont(font)
    self.font = font
end

return Button