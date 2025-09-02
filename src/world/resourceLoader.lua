-- 工具类引用
local tableUtils = require("src.utils.tableUtils")

-- 资源加载系统
local ResourceLoader = {}

ResourceLoader.__index = ResourceLoader

function ResourceLoader.new()
    local self = setmetatable({}, ResourceLoader)
    self.loadedAssets = {}
    self.currentScene = nil
    return self
end

-- 加载场景资源
function ResourceLoader:loadForScene(sceneName)
    self.currentScene = sceneName
    self.loadedAssets[sceneName] = {
        entities = {},
        collision = {}
    }
    
    -- 加载场景数据
    local sceneData = self:loadSceneData(sceneName)
    if not sceneData then return end
    
    -- 加载实体
    if sceneData.entities then
        for _, entityDef in ipairs(sceneData.entities) do
            self:loadEntity(entityDef)
        end
    end
    
    print("Loaded resources for:", sceneName)
end

-- 加载场景数据
function ResourceLoader:loadSceneData(sceneName)
    local success, sceneData = pcall(require, "assets.maps."..sceneName)
    if success then
        return sceneData
    else
        print("[ERROR] Failed to load scene data for:", sceneName)
        return nil
    end
end

-- 加载实体
function ResourceLoader:loadEntity(entityDef)
    local entityConfig = self:loadEntityConfig(entityDef.type)
    if not entityConfig then return end
    
    -- 合并配置和定义
    local entity = tableUtils.merge(tableUtils.deepCopy(entityConfig), entityDef)
    table.insert(self.loadedAssets[self.currentScene].entities, entity)
    
    -- 添加碰撞体
    if entity.collision then
        -- 优先使用entityDef中的坐标（通常来自地图定义），如果没有则使用entity中的默认值
        local x = entityDef.x or entity.x or 0
        local y = entityDef.y or entity.y or 0
        local width = entity.collision.width or entity.width or 32
        local height = entity.collision.height or entity.height or 32
        
        table.insert(self.loadedAssets[self.currentScene].collision, {
            x = x,
            y = y,
            width = width,
            height = height,
            type = entity.type
        })
    end
end

-- 加载实体配置
function ResourceLoader:loadEntityConfig(entityType)
    local success, config = pcall(require, "assets.entities."..entityType)
    if success then
        return config
    else
        print("[WARNING] No config found for entity type:", entityType)
        return nil
    end
end

-- 获取当前场景实体
function ResourceLoader:getEntities()
    if not self.currentScene then return {} end
    return self.loadedAssets[self.currentScene].entities or {}
end

-- 获取当前场景碰撞体
function ResourceLoader:getColliders()
    if not self.currentScene then return {} end
    return self.loadedAssets[self.currentScene].collision or {}
end

-- 卸载资源
function ResourceLoader:unload()
    self.loadedAssets = {}
    self.currentScene = nil
    print("Unloaded resources")
end

return ResourceLoader