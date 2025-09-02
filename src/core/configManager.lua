-- 配置管理系统
local tableUtils = require("src.utils.tableUtils")

local ConfigManager = {}
ConfigManager.__index = ConfigManager

-- 默认配置
local defaultConfig = {
    resolution = {1280, 720},
    fullscreen = false,
    volume = {
        master = 1.0,
        music = 0.8,
        sfx = 0.9
    },
    controls = {
        moveUp = "w",
        moveDown = "s",
        moveLeft = "a",
        moveRight = "d",
        attack = "space",
        interact = "e"
    },
    fonts = {
        default = "assets/fonts/SourceHanSansSC-Regular.otf",
        title = "assets/fonts/SourceHanSansSC-Bold.otf"
    }
}

function ConfigManager.new()
    local self = setmetatable({}, ConfigManager)
    self.settings = {}
    return self
end

-- 加载配置
function ConfigManager:load()
    local success, loaded = pcall(love.filesystem.load, "config.lua")
    if success and type(loaded) == "function" then
        self.settings = loaded() or tableUtils.deepCopy(defaultConfig)
        print("[CONFIG] Config loaded from file")
    else
        self.settings = tableUtils.deepCopy(defaultConfig)
        print("[CONFIG] Using default settings")
    end
    return self.settings
end

-- 保存配置
function ConfigManager:save()
    local data = "return "..tableUtils.serialize(self.settings)
    local success, msg = love.filesystem.write("config.lua", data)
    if success then
        EventBus.emit(EventBus.CoreEvents.CONFIG_SAVED)
    end
    return success, msg
end

-- 获取配置值
function ConfigManager:get(key, defaultValue)
    local parts = {}
    for part in key:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    
    local current = self.settings
    for _, part in ipairs(parts) do
        if type(current) == "table" then
            current = current[part]
        else
            return defaultValue
        end
    end
    
    return current or defaultValue
end

-- 设置配置值
function ConfigManager:set(key, value)
    local parts = {}
    for part in key:gmatch("[^%.]+") do
        table.insert(parts, part)
    end
    
    local current = self.settings
    for i = 1, #parts - 1 do
        local part = parts[i]
        if not current[part] or type(current[part]) ~= "table" then
            current[part] = {}
        end
        current = current[part]
    end
    
    current[parts[#parts]] = value
    return true
end

-- 获取所有设置
function ConfigManager:getSettings()
    return self.settings
end

return ConfigManager