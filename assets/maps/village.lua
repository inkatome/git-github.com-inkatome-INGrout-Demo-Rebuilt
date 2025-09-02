return {
    -- 地图基础信息
    name = "和平村庄",
    type = "village",
    
    -- 地图尺寸 (必须字段)
    size = {
        width = 2000,
        height = 2000
    },
    
    -- 背景层信息 (可绘制草地、河流等)
    backgroundLayers = {
        {
            texture = "assets/maps/village_background.png",
            parallax = 0.2,  -- 视差滚动系数
            tiling = true
        }
    },
    
    -- 前景层信息 (可绘制树木、建筑等)
    foregroundLayers = {
        {
            texture = "assets/maps/village_foreground.png",
            parallax = 1.0,
            tiling = false
        }
    },
    
    -- 碰撞层 (必须字段)
    collisionLayer = {
        -- 村庄边界
        {x = 0, y = 0, width = 2000, height = 20},     -- 顶部边界
        {x = 0, y = 1980, width = 2000, height = 20},  -- 底部边界
        {x = 0, y = 0, width = 20, height = 2000},     -- 左侧边界
        {x = 1980, y = 0, width = 20, height = 2000},   -- 右侧边界
        
        -- 建筑物碰撞体
        {x = 300, y = 400, width = 200, height = 150, tag = "house1"},
        {x = 800, y = 300, width = 250, height = 180, tag = "house2"},
        {x = 1400, y = 500, width = 300, height = 200, tag = "town_hall"},
        
        -- 树木和其他障碍物
        {x = 500, y = 700, width = 50, height = 50, tag = "tree1"},
        {x = 1200, y = 800, width = 60, height = 60, tag = "tree2"},
        {x = 600, y = 1200, width = 70, height = 70, tag = "rock1"},
        
        -- 可交互区域
        {x = 1000, y = 900, width = 100, height = 100, tag = "shop"},
        {x = 1500, y = 1000, width = 80, height = 80, tag = "quest_board"}
    },
    
    -- 出生点位置
    spawnPoints = {
        player = {x = 200, y = 200},
        enemies = {
            {x = 1700, y = 1700, type = "goblin"},
            {x = 1600, y = 400, type = "goblin"}
        }
    },
    
    -- 地图音乐
    audio = {
        bgm = "bgm_village"
    },

    -- 实体列表
    entities = {
        { type = "player", x = 200, y = 200 },
        { type = "npc", id = "villager1", x = 300, y = 300 }
    }
}