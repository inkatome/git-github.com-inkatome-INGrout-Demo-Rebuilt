return {
    width = 32,
    height = 32,
    render = {  -- 渲染组件定义
        layer = "entities",
        draw = function(entity)
            love.graphics.setColor(0.2, 1, 0.2)
            love.graphics.rectangle("fill", entity.x, entity.y, entity.width, entity.height)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(entity.dialog.title or "NPC", entity.x, entity.y - 20)
        end
    },
    dialog = {
        title = "村民",
        lines = {"你好，旅行者！", "最近村子不太平..."},
        options = {
            { text = "有什么任务吗？", action = function() end },
            { text = "再见", action = function() end }
        }
    }
}