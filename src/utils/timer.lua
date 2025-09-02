-- 计时器系统
local Timer = {}
Timer.queue = {}

-- 添加延迟执行函数
function Timer.after(delay, callback)
    table.insert(Timer.queue, {
        time = delay,
        callback = callback
    })
end

-- 创建周期性计时器
function Timer.every(interval, callback)
    local timerObj = {
        interval = interval,
        callback = callback,
        time = interval,
        active = true
    }
    table.insert(Timer.queue, timerObj)
    return timerObj
end

-- 更新计时器
function Timer.update(dt)
    for i = #Timer.queue, 1, -1 do
        local timer = Timer.queue[i]
        timer.time = timer.time - dt
        
        if timer.time <= 0 then
            timer.callback()
            if timer.interval then
                timer.time = timer.interval
            else
                table.remove(Timer.queue, i)
            end
        end
    end
end

-- 停止计时器
function Timer.cancel(timerObj)
    for i, timer in ipairs(Timer.queue) do
        if timer == timerObj then
            table.remove(Timer.queue, i)
            return true
        end
    end
    return false
end

return Timer