return {
    width = 32,
    height = 32,
    collision = {
        width = 28,
        height = 28,
        offsetX = 2,
        offsetY = 2
    },
    render = {  -- 渲染组件定义
        layer = "entities",
        draw = function(entity)
            -- 优先使用动画系统渲染
            local animComp = entity.components.animation
            if animComp and animComp.system then
                animComp.system:draw()
            else
                -- 备用渲染（调试状态可见）
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
                
                love.graphics.setColor(0, 0.5, 1, 1)
                love.graphics.rectangle("fill", x, y, width, height)
            end
        end
    }
}