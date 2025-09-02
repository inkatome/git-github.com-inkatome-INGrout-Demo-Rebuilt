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
                love.graphics.setColor(0, 0.5, 1, 1)
                love.graphics.rectangle("fill", entity.x, entity.y, entity.width, entity.height)
            end
        end
    }
}