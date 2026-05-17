local Stack = {}

Stack.__index = Stack

function Stack.new()
    local self = setmetatable({}, Stack)
    return self
end

function Stack:size()
    return 0
end

return Stack