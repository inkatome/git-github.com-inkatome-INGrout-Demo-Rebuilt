-- 玩家控制器
local PlayerController = {}
PlayerController.__index = PlayerController

function PlayerController.new(playerEntity)
    local self = setmetatable({}, PlayerController)
    self.player = playerEntity
    self.moveSpeed = 200
    self.lastDirection = {x = 0, y = 1}
    
    -- 优先从transform组件获取坐标
    local transform = playerEntity.components and playerEntity.components.transform
    local x, y = 0, 0
    
    if transform then
        x = transform.x or 0
        y = transform.y or 0
    else
        x = playerEntity.x or 0
        y = playerEntity.y or 0
    end
    
    self.proposedX = x
    self.proposedY = y
    return self
end

function PlayerController:update(dt)
    local dx, dy = 0, 0
    
    -- 键盘控制
    if love.keyboard.isDown("w") then dy = dy - 1 end
    if love.keyboard.isDown("s") then dy = dy + 1 end
    if love.keyboard.isDown("a") then dx = dx - 1 end
    if love.keyboard.isDown("d") then dx = dx + 1 end
    
    -- 归一化移动向量
    if dx ~= 0 or dy ~= 0 then
        local length = math.sqrt(dx*dx + dy*dy)
        dx, dy = dx/length, dy/length
        
        -- 优先从transform组件获取当前位置
        local transform = self.player.components and self.player.components.transform
        local currentX, currentY = 0, 0
        
        if transform then
            currentX = transform.x or 0
            currentY = transform.y or 0
        else
            currentX = self.player.x or 0
            currentY = self.player.y or 0
        end
        
        self.proposedX = currentX + dx * self.moveSpeed * dt
        self.proposedY = currentY + dy * self.moveSpeed * dt
        
        -- 调试信息
        -- print(string.format("Player movement: dx=%.2f, dy=%.2f, proposedX=%.1f, proposedY=%.1f",
          --     dx, dy, self.proposedX, self.proposedY))
        
        -- 方向变化事件
        if dx ~= self.lastDirection.x or dy ~= self.lastDirection.y then
            EventBus.emit(EventBus.PlayerEvents.DIRECTION_CHANGED, {x=dx, y=dy})
            self.lastDirection = {x=dx, y=dy}
        end
        
        -- 移动事件
        EventBus.emit(EventBus.PlayerEvents.MOVED, {
            x = self.proposedX,
            y = self.proposedY,
            dx = dx,
            dy = dy
        })
    else
        -- 优先从transform组件获取当前位置
        local transform = self.player.components and self.player.components.transform
        local currentX, currentY = 0, 0
        
        if transform then
            currentX = transform.x or 0
            currentY = transform.y or 0
        else
            currentX = self.player.x or 0
            currentY = self.player.y or 0
        end
        
        self.proposedX = currentX
        self.proposedY = currentY
    end
end

function PlayerController:getProposedPosition()
    return self.proposedX, self.proposedY
end

return PlayerController