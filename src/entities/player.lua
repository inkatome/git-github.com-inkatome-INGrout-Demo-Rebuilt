-- 玩家实体
local Player = {}
Player.__index = Player

function Player.new(config)
    local self = setmetatable({}, Player)
    self.type = "player"
    
    -- 初始化组件系统
    self.components = {
        transform = {
            x = config.x or 100,
            y = config.y or 100,
            width = config.width or 32,
            height = config.height or 32
        },
        collision = config.collision or {
            width = 28,
            height = 28,
            offsetX = 2,
            offsetY = 2
        }
    }
    
    -- 兼容直接访问属性
    self.x = self.components.transform.x
    self.y = self.components.transform.y
    self.width = self.components.transform.width
    self.height = self.components.transform.height
    self.speed = config.speed or 200
    self.health = config.health or 100
    return self
end

-- 玩家不需要自己的更新方法，由PlayerController处理
function Player:update(dt)
    -- 由PlayerController处理移动逻辑
end

-- 玩家不需要自己的绘制方法，由PlayerAnimationSystem处理
function Player:draw()
    -- 由PlayerAnimationSystem处理绘制
end

return Player