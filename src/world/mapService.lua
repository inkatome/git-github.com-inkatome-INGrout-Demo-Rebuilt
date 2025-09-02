-- 地图服务系统
local MapService = {}
MapService.__index = MapService

function MapService.new()
    local self = setmetatable({}, MapService)
    self.currentMap = nil
    self.camera = {
        x = 0,
        y = 0,
        target = nil,
        smoothness = 0.1,
        deadzone = 50
    }
    self.layerTextures = {}  -- 存储加载的图层纹理
    return self
end

-- 加载地图
function MapService:load(mapName)
    local mapData = require("assets.maps." .. mapName)
    self.currentMap = mapData
    print("Loaded map:", mapName)

    -- 预加载背景层纹理
    self.layerTextures = {}
    if self.currentMap.backgroundLayers then
        for i, layer in ipairs(self.currentMap.backgroundLayers) do
            self.layerTextures["bg_"..i] = love.graphics.newImage(layer.texture)
        end
    end
    
    -- 预加载前景层纹理
    if self.currentMap.foregroundLayers then
        for i, layer in ipairs(self.currentMap.foregroundLayers) do
            self.layerTextures["fg_"..i] = love.graphics.newImage(layer.texture)
        end
    end
end

-- 获取地图尺寸
function MapService:getMapSize()
    if self.currentMap then
        return self.currentMap.size
    end
    return {width = 0, height = 0}
end

-- 设置相机跟随目标
function MapService:setCameraTarget(targetEntity)
    self.camera.target = {
        x = targetEntity.x + (targetEntity.width or 0)/2,
        y = targetEntity.y + (targetEntity.height or 0)/2,
        width = targetEntity.width,
        height = targetEntity.height
    }
end

-- 更新相机位置
function MapService:updateCamera(dt)
    if not self.camera.target or not self.currentMap then print("no camera target or map") return end

    local screenW, screenH = love.graphics.getDimensions()
    local mapW, mapH = self.currentMap.size.width, self.currentMap.size.height
    
    -- 计算理想相机位置
    local targetX = self.camera.target.x - screenW/2
    local targetY = self.camera.target.y - screenH/2
    
    -- 应用平滑移动
    self.camera.x = self.camera.x + (targetX - self.camera.x) * self.camera.smoothness
    self.camera.y = self.camera.y + (targetY - self.camera.y) * self.camera.smoothness
    
    -- 限制相机范围
    local maxX = math.max(0, mapW - screenW)
    local maxY = math.max(0, mapH - screenH)
    self.camera.x = math.clamp(self.camera.x, 0, maxX)
    self.camera.y = math.clamp(self.camera.y, 0, maxY)
end

-- 获取相机位置
function MapService:getCamera()
    return self.camera
end

-- 更新地图服务
function MapService:update(dt)
    self:updateCamera(dt)
end

-- 绘制背景层
function MapService:drawBackground()
    if not self.currentMap then return end
    
    -- 获取相机偏移量
    local camX, camY = self.camera.x, self.camera.y
    
    -- 绘制背景层
    if self.currentMap.backgroundLayers then
        for i, layer in ipairs(self.currentMap.backgroundLayers) do
            local texture = self.layerTextures["bg_"..i]
            if texture then
                -- 应用视差效果
                local parallaxX = camX * (layer.parallax or 1.0)
                local parallaxY = camY * (layer.parallax or 1.0)
                
                love.graphics.push()
                love.graphics.translate(-parallaxX, -parallaxY)
                
                -- 处理平铺逻辑
                if layer.tiling then
                    local texWidth, texHeight = texture:getDimensions()
                    local mapWidth, mapHeight = self.currentMap.size.width, self.currentMap.size.height
                    
                    for x = 0, math.ceil(mapWidth / texWidth) do
                        for y = 0, math.ceil(mapHeight / texHeight) do
                            love.graphics.draw(texture, x * texWidth, y * texHeight, 0, 1, 1)
                        end
                    end
                else
                    love.graphics.draw(texture, 0, 0, 0, 1, 1)
                end
                
                love.graphics.pop()
            end
        end
    end
end

-- 绘制前景层
function MapService:drawForeground()
    if not self.currentMap then return end
    
    -- 获取相机偏移量
    local camX, camY = self.camera.x, self.camera.y
    
    -- 绘制前景层
    if self.currentMap.foregroundLayers then
        for i, layer in ipairs(self.currentMap.foregroundLayers) do
            local texture = self.layerTextures["fg_"..i]
            if texture then
                -- 应用视差效果
                local parallaxX = camX * (layer.parallax or 1.0)
                local parallaxY = camY * (layer.parallax or 1.0)
                
                love.graphics.push()
                love.graphics.translate(-parallaxX, -parallaxY)
                love.graphics.draw(texture, 0, 0, 0, 1, 1)
                love.graphics.pop()
            end
        end
    end
end

-- 绘制碰撞调试信息
function MapService:drawCollisionDebug()
    if not self.currentMap then return end
    
    -- 1. 绘制静态碰撞体
    love.graphics.setColor(1, 0, 0, 0.5)
    for _, collider in ipairs(self.currentMap.collisionLayer or {}) do
        love.graphics.rectangle("line", collider.x, collider.y, 
            collider.width, collider.height)
    end
    
    -- 2. 绘制地图边界
    love.graphics.setColor(0, 0, 1, 0.5)
    local mapW, mapH = self.currentMap.size.width, self.currentMap.size.height
    love.graphics.rectangle("line", 0, 0, mapW, 1)      -- 顶部边界
    love.graphics.rectangle("line", 0, mapH-1, mapW, 1) -- 底部边界
    love.graphics.rectangle("line", 0, 0, 1, mapH)      -- 左侧边界
    love.graphics.rectangle("line", mapW-1, 0, 1, mapH) -- 右侧边界
    
    -- 3. 重置颜色
    love.graphics.setColor(1, 1, 1, 1)
end

return MapService