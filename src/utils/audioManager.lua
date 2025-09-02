-- 音频管理系统
local AudioManager = {}
AudioManager.__index = AudioManager

function AudioManager.new()
    local self = setmetatable({}, AudioManager)
    self.sources = {}
    self.globalVolume = 1.0
    self:preloadCommonAudio()
    return self
end

-- 预加载常用音频
function AudioManager:preloadCommonAudio()
    self:load("bgm_menu", "assets/audio/menu.mp3", "stream")
    self:load("sfx_click", "assets/audio/click.wav", "static")
    self:load("bgm_village", "assets/audio/bgm_village.mp3", "stream")  -- 添加村庄BGM
end

-- 加载音频
function AudioManager:load(id, path, audioType)
    local success, source = pcall(love.audio.newSource, path, audioType or "static")
    if success then
        self.sources[id] = {source = source, type = audioType}
        return true
    else
        print("[AUDIO] Failed to load:", path, source)
        return false
    end
end

-- 播放音频
function AudioManager:play(id, startTime)
    local data = self.sources[id]
    if data then
        if startTime then
            data.source:seek(startTime)
        end
        data.source:setVolume(self.globalVolume)
        data.source:play()
        return true
    end
    return false
end

-- 设置全局音量
function AudioManager:setVolume(volume)
    self.globalVolume = math.clamp(volume, 0, 1)
    for _, data in pairs(self.sources) do
        if data.source:isPlaying() then
            data.source:setVolume(self.globalVolume)
        end
    end
end

function AudioManager:stop(id)
    local data = self.sources[id]
    if data then
        data.source:stop()
        return true
    end
    return false
end

-- 其他音频管理函数...

return AudioManager