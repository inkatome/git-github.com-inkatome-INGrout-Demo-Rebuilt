-- 敌人实体
local Enemy = {}
Enemy.__index = Enemy

function Enemy.new(config)
    local self = setmetatable({}, Enemy)
    self.type = "enemy"
    self.x = config.x or 300
    self.y = config.y or 300
    self.width = config.width or 32
    self.height = config.height or 32
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
    
    -- 计算移动方向
    local dx = target.x - self.x
    local dy = target.y - self.y
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
    self.x = self.x + (dx / distance) * speed
    self.y = self.y + (dy / distance) * speed
end

-- 绘制敌人
function Enemy:draw()
    -- 实际项目中应使用纹理
    love.graphics.setColor(1, 0.2, 0.2)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1)
    
    -- 显示敌人类型
    love.graphics.print(self.aiType, self.x, self.y - 15)
end

return Enemy