-- 游戏配置文件
function love.conf(t)
    t.identity = "pixel_rpg"           -- 存档目录名
    t.version = "11.4"                 -- LOVE版本
    -- t.console = true                   -- 调试控制台关闭
    
    t.window.title = "Pixel RPG Adventure" 
    t.window.width = 1280              
    t.window.height = 720               
    t.window.resizable = false          
    t.window.vsync = 1                 
    
    t.modules.joystick = false         
    t.modules.physics = false          
end