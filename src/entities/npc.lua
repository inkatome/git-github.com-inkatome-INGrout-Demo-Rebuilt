-- NPC实体
local NPC = {}
NPC.__index = NPC

function NPC.new(config)
    local self = setmetatable({}, NPC)
    self.type = "npc"
    self.id = config.id or ("npc_" .. math.random(1000))
    self.x = config.x or 0
    self.y = config.y or 0
    self.width = config.width or 32
    self.height = config.height or 32
    self.dialog = config.dialog or "Hello!"
    return self
end

function NPC:update(dt)
    -- NPC特定更新逻辑
end

function NPC:draw()
    love.graphics.setColor(0.2, 1, 0.2)
    love.graphics.rectangle("fill", self.x, self.y, self.width, self.height)
    love.graphics.setColor(1, 1, 1)
    love.graphics.print(self.dialog, self.x, self.y - 20)
end

return NPC