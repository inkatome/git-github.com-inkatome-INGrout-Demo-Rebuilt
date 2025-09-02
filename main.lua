
-- debug
if arg[2] == "debug" then
    require("lldebugger").start()
end

-- 添加全局变量声明
GameConfig = require("src.core.configManager").new()
WorldManager = require("src.world.worldManager").new()

-- 主游戏入口
local core = require("src.core.init")

function love.load()
    -- 初始化核心系统
    core.init()
    
    -- 应用配置
    local config = GameConfig:getSettings()
    love.window.setMode(config.resolution[1], config.resolution[2], {
        fullscreen = config.fullscreen
    })
    
    -- 设置渲染过滤器
    love.graphics.setDefaultFilter("nearest", "nearest")

    -- 加载中文字体
    Fonts = {
        default = love.graphics.newFont("assets/fonts/SourceHanSansCN-VF.otf", 24),
        title = love.graphics.newFont("assets/fonts/SourceHanSansCN-VF.otf", 36)
    }

    -- 将core模块设置为全局变量，供事件处理使用
    Core = core -- 新增这行
end

function love.update(dt)
    core.update(dt)
end

function love.draw()
    core.draw()
end

function love.keypressed(key)
    if core.handleEvent("keypressed", key) then return end
    
    -- 全局快捷键
    if key == "escape" then
        if GameState.current == GameState.States.PLAY then
            GameState.transitionTo(GameState.States.PAUSE)
        elseif GameState.current == GameState.States.PAUSE then
            GameState.transitionTo(GameState.States.PLAY)
        end
    elseif key == "f1" then
        WorldManager:toggleDebugMode()
    end
end

function love.mousepressed(x, y, button)
    core.handleEvent("mousepressed", x, y, button)
end

-- 其他事件处理...