-- 玩家控制器
local PlayerController = {}
PlayerController.__index = PlayerController

function PlayerController.new(playerEntity)
    local self = setmetatable({}, PlayerController)
    self.player = playerEntity
    self.moveSpeed = 200
    self.lastDirection = {x = 0, y = 1}
    self.proposedX = playerEntity.x
    self.proposedY = playerEntity.y
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
        
        self.proposedX = self.player.x + dx * self.moveSpeed * dt
        self.proposedY = self.player.y + dy * self.moveSpeed * dt
        
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
        self.proposedX = self.player.x
        self.proposedY = self.player.y
    end
end

function PlayerController:getProposedPosition()
    return self.proposedX, self.proposedY
end

return PlayerController