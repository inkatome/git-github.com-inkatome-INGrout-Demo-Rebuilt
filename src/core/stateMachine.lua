-- 游戏状态机
local state = {}
state.States = {
    BOOT = "BOOT",
    LOADING = "LOADING",
    MENU = "MENU",
    PLAY = "PLAY",
    PAUSE = "PAUSE",
    DIALOG = "DIALOG"
}

state.current = nil
state.handlers = {}

-- 初始化状态机
function state.init()
    -- 注册状态处理函数
    state.register(state.States.BOOT, {
        enter = function(previousState)
            print("Entering BOOT state, previous state:", previousState or "nil")
            state.transitionTo(state.States.LOADING)
        end
    })
    
    state.register(state.States.LOADING, {
        enter = function(previousState)
            print("Entering LOADING state")
            state.loadProgress = 0
            
            -- 异步加载资源
            Timer.after(0.1, function()
                -- 初始化世界管理器
                WorldManager = require("src.world.worldManager").new()
                
                -- 加载主菜单资源
                ResourceLoader = require("src.world.resourceLoader").new()
                ResourceLoader:loadForScene("main_menu")
            end)
        end,
        update = function(dt)
            state.loadProgress = math.min(1, state.loadProgress + dt * 0.3)
            if state.loadProgress >= 1 then
                state.transitionTo(state.States.MENU)
            end
        end,
        draw = function()
            love.graphics.clear(0.1, 0.1, 0.1)
            local progress = math.floor(state.loadProgress * 100)
            love.graphics.print("Loading... ".. progress .."%", 100, 100)
            
            -- 绘制进度条
            local barWidth = 400
            love.graphics.rectangle("line", 100, 150, barWidth, 30)
            love.graphics.rectangle("fill", 100, 150, barWidth * state.loadProgress, 30)
        end
    })
    
    -- 主菜单状态
    state.register(state.States.MENU, {
        enter = function(previousState)
            print("Entering MENU state")
            
            -- 初始化UI管理器
            UIManager = require("src.ui.uiManager").new()
            
            -- 添加菜单按钮
            local screenW, screenH = love.graphics.getDimensions()
            UIManager:addButton(
                screenW/2 - 100, screenH/2 - 60, 
                200, 50, 
                "开始游戏",
                function() 
                    state.transitionTo(state.States.PLAY)
                end
            )
            
            UIManager:addButton(
                screenW/2 - 100, screenH/2 + 20, 
                200, 50, 
                "设置",
                function()
                    print("打开设置菜单")
                end
            )
            
            UIManager:addButton(
                screenW/2 - 100, screenH/2 + 100, 
                200, 50, 
                "退出游戏",
                function()
                    love.event.quit()
                end
            )
            
            -- 播放菜单背景音乐
            Audio:play("bgm_menu")
        end,
        exit = function()
            UIManager = nil
            Audio:stop("bgm_menu")
        end,
        update = function(dt)
            if UIManager then
                UIManager:update(dt)
            end
        end,
        draw = function()
            love.graphics.clear(0.2, 0.2, 0.3)
            
            -- 绘制菜单背景
            if ResourceLoader and ResourceLoader:getEntities() then
                for _, entity in ipairs(ResourceLoader:getEntities()) do
                    if entity.draw then
                        entity:draw()
                    end
                end
            end
            
            -- 绘制UI
            if UIManager then
                UIManager:draw()
            end
            
            -- 绘制标题
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(Fonts.title)
            love.graphics.print("像素冒险", 100, 50)
        end,

        mousepressed = function(x, y, button)
            if UIManager then
                return UIManager:handleClick(x, y)
            end
            return false
        end,
        
        mousemoved = function(x, y, dx, dy)
        if UIManager then
            UIManager:handleMouseMove(x, y)
        end
    end
    })
    
    -- 游戏进行状态
    state.register(state.States.PLAY, {
        enter = function(previousState, sceneName)
            print("Entering PLAY state")
            
            -- 加载游戏场景
            local scene = sceneName or "village"
            WorldManager:load(scene)

                -- 播放场景音乐
            if scene == "village" then
                Audio:play("bgm_village")  -- 播放村庄BGM
            end
            
            -- 设置相机跟随玩家
            if WorldManager.entityCoordinator.playerEntity then
                WorldManager.mapService:setCameraTarget(WorldManager.entityCoordinator.playerEntity)
            end
        end,
        exit = function()
            Audio:stop("bgm_village")  -- 停止村庄BGM
        end,
        update = function(dt)
            -- 更新游戏世界（MapService更新包含在WorldManager更新中）
            WorldManager:update(dt)
        end,
        draw = function()
            -- 绘制游戏世界
            WorldManager:draw()
        end,
        keypressed = function(key)
            -- 处理玩家与NPC交互
            if key == GameConfig:get("controls.interact", "e") then
                local player = WorldManager.entityCoordinator.playerEntity
                if player then
                    local interactRange = 50
                    local entities = WorldManager.entityCoordinator.entities
                    
                    for _, entity in ipairs(entities) do
                        if entity.type == "npc" then
                            local dist = math.distance(
                                player.x, player.y,
                                entity.x, entity.y
                            )
                            
                            if dist < interactRange then
                                state.transitionTo(state.States.DIALOG, entity)
                                return true
                            end
                        end
                    end
                end
            end
            return false
        end
    })
    
    -- 游戏暂停状态
    state.register(state.States.PAUSE, {
        enter = function(previousState)
            print("Entering PAUSE state")
            
            -- 创建暂停菜单
            UIManager = require("src.ui.uiManager").new()
            
            local screenW, screenH = love.graphics.getDimensions()
            UIManager:addButton(
                screenW/2 - 100, screenH/2 - 80, 
                200, 50, 
                "继续游戏",
                function() 
                    state.transitionTo(state.States.PLAY)
                end
            )
            
            UIManager:addButton(
                screenW/2 - 100, screenH/2, 
                200, 50, 
                "返回主菜单",
                function()
                    state.transitionTo(state.States.MENU)
                end
            )
        end,
        exit = function()
            UIManager = nil
        end,
        update = function(dt)
            if UIManager then
                UIManager:update(dt)
            end
        end,
        draw = function()
            -- 绘制游戏背景（半透明）
            love.graphics.setColor(0, 0, 0, 0.7)
            love.graphics.rectangle("fill", 0, 0, love.graphics.getWidth(), love.graphics.getHeight())
            
            -- 绘制UI
            if UIManager then
                UIManager:draw()
            end
            
            -- 绘制暂停标题
            love.graphics.setColor(1, 1, 1)
            love.graphics.setFont(Fonts.title)
            love.graphics.print("游戏暂停", 
                love.graphics.getWidth()/2 - 80, 
                love.graphics.getHeight()/2 - 150
            )
        end,
        mousepressed = function(x, y, button)
            if UIManager then
                return UIManager:handleClick(x, y)
            end
            return false
        end,

        mousemoved = function(x, y, dx, dy)
        if UIManager then
            UIManager:handleMouseMove(x, y)
        end
    end
    })
    
    -- 对话状态
    state.register(state.States.DIALOG, {
        enter = function(previousState, npcEntity)
            print("Entering DIALOG state with NPC:", npcEntity.id)
            
            -- 存储对话信息
            state.currentDialog = {
                npc = npcEntity,
                currentLine = 1,
                options = npcEntity.dialog.options or {}
            }
            
            -- 创建对话UI
            UIManager = require("src.ui.uiManager").new()
            
            -- 添加对话选项
            for i, option in ipairs(state.currentDialog.options) do
                UIManager:addButton(
                    100, 300 + i * 60,
                    400, 50,
                    option.text,
                    function()
                        if option.action then
                            option.action()
                        end
                        state.transitionTo(state.States.PLAY)
                    end
                )
            end
            
            -- 添加退出对话按钮
            UIManager:addButton(
                500, 500,
                200, 50,
                "退出对话",
                function()
                    state.transitionTo(state.States.PLAY)
                end
            )
        end,
        exit = function()
            UIManager = nil
            state.currentDialog = nil
        end,
        update = function(dt)
            if UIManager then
                UIManager:update(dt)
            end
        end,
        draw = function()
            -- 绘制游戏世界（半透明）
            love.graphics.setColor(1, 1, 1, 0.5)
            GameState.draw()  -- 绘制上一个状态（PLAY）的内容
            
            -- 绘制对话框背景
            love.graphics.setColor(0.1, 0.1, 0.2, 0.9)
            love.graphics.rectangle("fill", 50, 250, 700, 400)
            
            -- 绘制NPC信息
            if state.currentDialog.npc then
                love.graphics.setColor(1, 1, 1)
                love.graphics.print(
                    state.currentDialog.npc.dialog.title or "NPC", 
                    70, 260
                )
                
                -- 绘制对话内容
                local dialogText = state.currentDialog.npc.dialog.lines[state.currentDialog.currentLine] or "。。。"
                love.graphics.printf(
                    dialogText, 
                    80, 300, 
                    600, "left"
                )
            end
            
            -- 绘制UI
            if UIManager then
                UIManager:draw()
            end
        end,
        keypressed = function(key)
            if key == "space" or key == "return" then
                if state.currentDialog then
                    state.currentDialog.currentLine = state.currentDialog.currentLine + 1
                    
                    -- 检查对话是否结束
                    if state.currentDialog.currentLine > #state.currentDialog.npc.dialog.lines then
                        state.currentDialog.currentLine = #state.currentDialog.npc.dialog.lines
                    end
                end
                return true
            end
            return false
        end,
        mousepressed = function(x, y, button)
            if UIManager then
                return UIManager:handleClick(x, y)
            end
            return false
        end,

        mousemoved = function(x, y, dx, dy)
        if UIManager then
            UIManager:handleMouseMove(x, y)
        end
    end
    })
end

-- 注册状态处理器
function state.register(stateName, handler)
    state.handlers[stateName] = handler
end

-- 切换到新状态
function state.transitionTo(newState, ...)
    if state.current == newState then return end
    
    -- 调用退出回调
    local currentHandler = state.handlers[state.current]
    if currentHandler and currentHandler.exit then
        currentHandler.exit()
    end
    
    -- 更新当前状态
    local previousState = state.current
    state.current = newState
    
    -- 调用进入回调
    local newHandler = state.handlers[newState]
    if newHandler and newHandler.enter then
        newHandler.enter(previousState, ...)
    end
end

-- 状态更新
function state.update(dt)
    local handler = state.handlers[state.current]
    if handler and handler.update then
        handler.update(dt)
    end
end

-- 状态绘制
function state.draw()
    local handler = state.handlers[state.current]
    if handler and handler.draw then
        handler.draw()
    end
end

-- 事件处理
function state.handleEvent(eventName, ...)
    local handler = state.handlers[state.current]
    if handler and handler[eventName] then
        return handler[eventName](...)
    end
    return false
end

function love.mousemoved(x, y, dx, dy)
    if Core then -- 使用全局Core变量
        Core.handleEvent("mousemoved", x, y, dx, dy)
    end
end

return state