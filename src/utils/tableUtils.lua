-- 表操作工具类
local tableUtils = {}

-- 深拷贝函数
function tableUtils.deepCopy(original)
    if type(original) ~= "table" then return original end
    local copy = {}
    for key, value in pairs(original) do
        copy[key] = tableUtils.deepCopy(value)
    end
    return copy
end

-- 表合并函数
function tableUtils.merge(t1, t2)
    local res = {}
    for k, v in pairs(t1) do res[k] = v end
    for k, v in pairs(t2) do
        if type(v) == "table" and type(res[k]) == "table" then
            res[k] = tableUtils.merge(res[k], v)
        else
            res[k] = v
        end
    end
    return res
end

-- 表序列化函数
function tableUtils.serialize(t, indent, processed)
    indent = indent or 0
    processed = processed or {}
    
    if processed[t] then return "[[circular reference]]" end
    processed[t] = true
    
    local tab = string.rep(" ", indent * 4)
    local result = "{\n"
    
    for key, value in pairs(t) do
        local keyStr = type(key) == "number" and 
                      string.format("[%d]", key) or 
                      string.format("[%q]", tostring(key))
        
        local valStr
        if type(value) == "table" then
            valStr = tableUtils.serialize(value, indent + 1, processed)
        elseif type(value) == "string" then
            valStr = string.format("%q", value)
        else
            valStr = tostring(value)
        end
        
        result = result .. tab .. "    " .. keyStr .. " = " .. valStr .. ",\n"
    end
    
    return result .. tab .. "}"
end

-- 表克隆函数（浅拷贝）
function tableUtils.clone(t)
    local copy = {}
    for k, v in pairs(t) do
        copy[k] = v
    end
    return copy
end

return tableUtils