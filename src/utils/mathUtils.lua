-- 数学工具类
local mathUtils = {}

-- 数值钳制函数
function mathUtils.clamp(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

-- 两点间距离计算
function mathUtils.distance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

-- 向量归一化
function mathUtils.normalize(x, y)
    local length = math.sqrt(x * x + y * y)
    if length > 0 then
        return x / length, y / length
    end
    return 0, 0
end

-- 矩形相交检测
function mathUtils.rectIntersect(ax, ay, aw, ah, bx, by, bw, bh)
    return ax < bx + bw and
           ax + aw > bx and
           ay < by + bh and
           ay + ah > by
end

-- 添加全局访问
math.clamp = mathUtils.clamp
math.distance = mathUtils.distance
math.normalize = mathUtils.normalize
math.rectIntersect = mathUtils.rectIntersect

return mathUtils