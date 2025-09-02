-- 核心系统初始化
local core = {}

core.modules = {
    state = nil,
    events = nil,
    config = nil,
    timer = nil,
    audio = nil
}

-- 初始化所有核心模块
function core.init()
    -- 初始化事件系统
    core.modules.events = require("src.core.eventManager")
    core.modules.events.init()
    
    -- 初始化配置管理
    local ConfigManager = require("src.core.configManager")
    core.modules.config = ConfigManager.new()  -- 创建配置管理器实例
    core.modules.config:load()
    
    -- 初始化工具模块
    core.modules.timer = require("src.utils.timer")
    core.modules.audio = require("src.utils.audioManager").new()
    
    -- 初始化状态机
    core.modules.state = require("src.core.stateMachine")
    core.modules.state.init()
    
    -- 设置全局单例
    GameState = core.modules.state
    EventBus = core.modules.events
    GameConfig = core.modules.config
    Timer = core.modules.timer
    Audio = core.modules.audio
    
    -- 添加统一的事件处理接口
function core.handleEvent(eventName, ...)
    if core.modules.state and core.modules.state.handleEvent then
        return core.modules.state.handleEvent(eventName, ...)
    end
    return false
end

    -- 切换至初始状态
    GameState.transitionTo(GameState.States.BOOT)
end

-- 状态机驱动更新
function core.update(dt)
    Timer.update(dt)
    GameState.update(dt)
end

-- 状态机驱动绘制
function core.draw()
    GameState.draw()
end

-- 事件处理
function core.handleEvent(eventName, ...)
    return GameState.handleEvent(eventName, ...)
end

return core