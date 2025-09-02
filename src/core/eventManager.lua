-- 事件系统核心模块
local events = {}
events.listeners = {}

-- 事件类型枚举
events.CoreEvents = {
    STATE_CHANGE = "STATE_CHANGE",
    CONFIG_LOADED = "CONFIG_LOADED",
    CONFIG_SAVED = "CONFIG_SAVED",
    GAME_SAVED = "GAME_SAVED"
}

-- 导入世界和玩家事件
events.WorldEvents = {
    COLLISION = "WORLD_COLLISION",
    ENTITY_REMOVED = "ENTITY_REMOVED",
    ENTITY_ADDED = "ENTITY_ADDED"
}

events.PlayerEvents = {
    MOVED = "PLAYER_MOVED",
    ATTACK = "PLAYER_ATTACK",
    INTERACT = "PLAYER_INTERACT",
    HEALTH_CHANGED = "PLAYER_HEALTH_CHANGED",
    ITEM_COLLECTED = "PLAYER_ITEM_COLLECTED",
    DIRECTION_CHANGED = "PLAYER_DIRECTION_CHANGED",
    COLLISION = "PLAYER_COLLISION",
    MOVEMENT_STOPPED = "PLAYER_MOVEMENT_STOPPED"
}

-- 初始化事件系统
function events.init()
    events.listeners = {}
    print("[EVENT] Event system initialized")
end

-- 注册事件监听器
function events.on(eventType, callback)
    if not events.listeners[eventType] then
        events.listeners[eventType] = {}
    end
    table.insert(events.listeners[eventType], callback)
    return #events.listeners[eventType] -- 返回监听器ID
end

-- 触发事件
function events.emit(eventType, ...)
    if not events.listeners[eventType] then return 0 end
    
    local count = 0
    for _, callback in ipairs(events.listeners[eventType]) do
        callback(...)
        count = count + 1
    end
    return count
end

-- 移除监听器
function events.off(eventType, id)
    if events.listeners[eventType] and events.listeners[eventType][id] then
        events.listeners[eventType][id] = nil
    end
end

return events