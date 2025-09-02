-- 敌人实体
local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(config)
    local self = setmetatable({}, Enemy)
    self.type = "enemy"
    
    -- 优先从transform组件获取坐标（如果有）
    local configX = config.x or 300
    local configY = config.y or 300
    local configWidth = config.width or 32
    local configHeight = config.height or 32
    
    self.x = configX
    self.y = configY
    self.width = configWidth
    self.height = configHeight
    self.health = config.health or 50
    self.aiType = config.aiType or "patrol"
    self.collision = config.collision or {
        width = 32,
        height = 32
    }
    self.patrolPoints = config.patrolPoints or {}
    self.currentPatrolIndex = 1
    return self
end

-- 更新敌人AI
function Enemy:update(dt)
    if self.aiType == "patrol" then
        self:updatePatrol(dt)
    end
end

-- 巡逻AI
function Enemy:updatePatrol(dt)
    if #self.patrolPoints < 2 then return end
    
    local target = self.patrolPoints[self.currentPatrolIndex]
    if not target then return end
    
    -- 优先从transform组件获取当前位置
    local transform = self.components and self.components.transform
    local currentX, currentY = 0, 0
    
    if transform then
        currentX = transform.x or 0
        currentY = transform.y or 0
    else
        currentX = self.x or 0
        currentY = self.y or 0
    end
    
    -- 计算移动方向
    local dx = target.x - currentX
    local dy = target.y - currentY
    local distance = math.sqrt(dx*dx + dy*dy)
    
    if distance < 5 then
        -- 到达巡逻点，前往下一个点
        self.currentPatrolIndex = self.currentPatrolIndex + 1
        if self.currentPatrolIndex > #self.patrolPoints then
            self.currentPatrolIndex = 1
        end
        return
    end
    
    -- 向目标点移动
    local speed = 100 * dt
    local newX = currentX + (dx / distance) * speed
    local newY = currentY + (dy / distance) * speed
    
    -- 更新位置（同时更新transform组件和实体属性）
    if transform then
        transform.x = newX
        transform.y = newY
    end
    self.x = newX
    self.y = newY
end

-- 绘制敌人
function Enemy:draw()
    -- 优先从transform组件获取坐标
    local transform = self.components and self.components.transform
    local x, y, width, height = 0, 0, 32, 32
    
    if transform then
        x = transform.x or 0
        y = transform.y or 0
        width = transform.width or 32
        height = transform.height or 32
    else
        x = self.x or 0
        y = self.y or 0
        width = self.width or 32
        height = self.height or 32
    end
    
    -- 实际项目中应使用纹理
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.rectangle("fill", x, y, width, height)
    love.graphics.setColor(1, 1, 1)
    
    -- 显示敌人类型
    love.graphics.print(self.aiType, x, y - 15)
end

return Enemy