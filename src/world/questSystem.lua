-- 任务管理系统
local QuestSystem = {}
QuestSystem.__index = QuestSystem

function QuestSystem.new()
    local self = setmetatable({}, QuestSystem)
    self.activeQuests = {}
    return self
end

-- 添加任务
function QuestSystem:addQuest(questId, title, objectives)
    self.activeQuests[questId] = {
        title = title,
        objectives = objectives,
        completed = false
    }
end

-- 更新任务目标
function QuestSystem:updateObjective(questId, objectiveIndex)
    local quest = self.activeQuests[questId]
    if not quest then return end
    
    if objectiveIndex and quest.objectives[objectiveIndex] then
        quest.objectives[objectiveIndex].completed = true
    end
    
    -- 检查任务是否完成
    local allCompleted = true
    for _, objective in ipairs(quest.objectives) do
        if not objective.completed then
            allCompleted = false
            break
        end
    end
    
    if allCompleted then
        quest.completed = true
        EventBus.emit(EventBus.QuestEvents.QUEST_COMPLETED, questId)
    end
end

-- 绘制任务UI
function QuestSystem:draw()
    local y = 50
    love.graphics.setColor(1, 1, 1)
    
    for id, quest in pairs(self.activeQuests) do
        -- 绘制任务标题
        local title = quest.completed and "[完成] "..quest.title or quest.title
        love.graphics.print(title, 20, y)
        
        -- 绘制任务目标
        for i, obj in ipairs(quest.objectives) do
            local status = obj.completed and "[✓]" or "[ ]"
            love.graphics.print(status..obj.text, 30, y + 20 * i)
        end
        
        y = y + 40 + 20 * #quest.objectives
    end
end

return QuestSystem