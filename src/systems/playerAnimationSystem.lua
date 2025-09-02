-- 玩家动画系统
local PlayerAnimationSystem = {}
PlayerAnimationSystem.__index = PlayerAnimationSystem

-- 动画资源缓存
PlayerAnimationSystem.animationCache = {}

-- 动画状态枚举
local AnimationState = {
    IDLE = "idle",
    WALKING = "walking",
    ATTACKING = "attacking"
}

function PlayerAnimationSystem.new(playerEntity)
    local self = setmetatable({}, PlayerAnimationSystem)
    self.player = playerEntity
    self.state = AnimationState.IDLE
    self.direction = "down"
    self.currentFrame = 1
    self.frameTimer = 0
    self.animations = {}
    self.isActive = true
    self.eventListeners = {}
    self:loadAnimations() -- 确保创建时加载动画
    return self
end

-- 加载动画资源
function PlayerAnimationSystem:loadAnimations()
    -- 尝试从缓存加载动画
    if not PlayerAnimationSystem.animationCache[AnimationState.IDLE] then
        PlayerAnimationSystem.animationCache[AnimationState.IDLE] = {
            down = self:loadAnimation("assets/animations/player_idle_down.png", 4, 0.2),
            up = self:loadAnimation("assets/animations/player_idle_up.png", 4, 0.2),
            left = self:loadAnimation("assets/animations/player_idle_left.png", 4, 0.2),
            right = self:loadAnimation("assets/animations/player_idle_right.png", 4, 0.2)
        }
    end
    
    if not PlayerAnimationSystem.animationCache[AnimationState.WALKING] then
        PlayerAnimationSystem.animationCache[AnimationState.WALKING] = {
            down = self:loadAnimation("assets/animations/player_walk_down.png", 6, 0.1),
            up = self:loadAnimation("assets/animations/player_walk_up.png", 6, 0.1),
            left = self:loadAnimation("assets/animations/player_walk_left.png", 6, 0.1),
            right = self:loadAnimation("assets/animations/player_walk_right.png", 6, 0.1)
        }
    end
    
    -- 引用缓存的动画
    self.animations = PlayerAnimationSystem.animationCache
    
    -- 订阅方向变化事件并保存监听器引用
    local listener = EventBus.on(EventBus.PlayerEvents.DIRECTION_CHANGED, function(direction)
        if self.isActive then
            self:setDirection(direction)
        end
    end)
    table.insert(self.eventListeners, listener)
end

-- 加载动画序列（使用缓存优化）
function PlayerAnimationSystem:loadAnimation(imagePath, frameCount, frameDuration)
    -- 检查是否已经加载过此动画
    local cacheKey = imagePath .. ":" .. frameCount .. ":" .. frameDuration
    if PlayerAnimationSystem.animationCache[cacheKey] then
        -- 销毁动画系统，清理资源和事件监听器
function PlayerAnimationSystem:destroy()
    self.isActive = false
    
    -- 取消所有事件订阅
    for _, listener in ipairs(self.eventListeners) do
        EventBus.off(listener)
    end
    self.eventListeners = {}
end

return PlayerAnimationSystem.animationCache[cacheKey]
    end
    
    local texture = love.graphics.newImage(imagePath)
    local frameWidth = texture:getWidth() / frameCount
    local frameHeight = texture:getHeight()
    
    local animation = {
        texture = texture,
        quads = {},
        frameCount = frameCount,
        frameDuration = frameDuration,
        frameWidth = frameWidth,
        frameHeight = frameHeight
    }
    
    -- 创建每个帧的quad
    for i = 0, frameCount - 1 do
        table.insert(animation.quads, love.graphics.newQuad(
            i * frameWidth, 0, 
            frameWidth, frameHeight, 
            texture:getDimensions()
        ))
    end
    
    -- 缓存动画
    PlayerAnimationSystem.animationCache[cacheKey] = animation
    return animation
end

-- 设置动画方向
function PlayerAnimationSystem:setDirection(direction)
    -- 只有当方向实际改变时才更新
    local newDirection
    if math.abs(direction.x) > math.abs(direction.y) then
        newDirection = direction.x > 0 and "right" or "left"
    else
        newDirection = direction.y > 0 and "down" or "up"
    end
    
    if newDirection ~= self.direction then
        self.direction = newDirection
        -- 重置当前帧以确保动画平滑过渡
        self.currentFrame = 1
        self.frameTimer = 0
    end
end

-- 设置动画状态
function PlayerAnimationSystem:setState(state)
    if state ~= self.state then
        self.state = state
        self.currentFrame = 1
        self.frameTimer = 0
    end
end

-- 更新动画帧
function PlayerAnimationSystem:update(dt)
    if not self.isActive then return end
    
    -- 检查玩家是否在屏幕范围内（简单视口剔除）
    local transform = self.player.components and self.player.components.transform
    local playerX, playerY = 0, 0
    if transform then
        playerX = transform.x or 0
        playerY = transform.y or 0
    else
        playerX = self.player.x or 0
        playerY = self.player.y or 0
    end
    
    -- 假设屏幕宽高为800x600
    if playerX < -100 or playerX > 900 or playerY < -100 or playerY > 700 then
        return  -- 玩家不在屏幕范围内，跳过更新
    end
    
    local animation = self.animations[self.state][self.direction]
    if not animation then return end
    
    self.frameTimer = self.frameTimer + dt
    if self.frameTimer >= animation.frameDuration then
        self.frameTimer = self.frameTimer - animation.frameDuration
        self.currentFrame = (self.currentFrame % animation.frameCount) + 1
    end
end

-- 绘制玩家（增加视口剔除优化）
function PlayerAnimationSystem:draw()
    if not self.isActive then return end
    
    -- 优先从transform组件获取位置
    local transform = self.player.components and self.player.components.transform
    local playerX, playerY = 0, 0
    
    if transform then
        playerX = transform.x or 0
        playerY = transform.y or 0
    else
        playerX = self.player.x or 0
        playerY = self.player.y or 0
    end
    
    -- 检查玩家是否在屏幕范围内（简单视口剔除）
    -- 假设屏幕宽高为800x600
    if playerX < -100 or playerX > 900 or playerY < -100 or playerY > 700 then
        return  -- 玩家不在屏幕范围内，跳过绘制
    end
    
    -- 考虑碰撞偏移量
    local collision = self.player.collision or {}
    local offsetX = collision.offsetX or 0
    local offsetY = collision.offsetY or 0
    local renderX = playerX - offsetX
    local renderY = playerY - offsetY
    
    local animation = self.animations[self.state][self.direction]
    if not animation then
        -- 默认渲染
        love.graphics.setColor(0, 0.5, 1)
        love.graphics.rectangle("fill", renderX, renderY, 32, 32)
        return
    end
    
    local quad = animation.quads[self.currentFrame]
    love.graphics.setColor(1, 1, 1)
    love.graphics.draw(
        animation.texture, 
        quad, 
        renderX, 
        renderY
    )
end

return PlayerAnimationSystem