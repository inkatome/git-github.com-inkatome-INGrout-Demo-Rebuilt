return {
    width = 32,
    height = 32,
    render = {  -- 渲染组件定义
        layer = "entities",
        draw = function(entity)
            -- 优先从transform组件获取坐标
            local transform = entity.components and entity.components.transform
            local x, y, width, height = 0, 0, 32, 32
            
            if transform then
                x = transform.x or 0
                y = transform.y or 0
                width = transform.width or 32
                height = transform.height or 32
            else
                -- 兼容直接存储在实体上的情况
                x = entity.x or 0
                y = entity.y or 0
                width = entity.width or 32
                height = entity.height or 32
            end
            
            love.graphics.setColor(0.2, 1, 0.2)
            love.graphics.rectangle("fill", x, y, width, height)
            love.graphics.setColor(1, 1, 1)
            love.graphics.print(entity.dialog and entity.dialog.title or "NPC", x, y - 20)
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