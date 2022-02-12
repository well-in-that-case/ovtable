local otable = require "impl"

local t = otable.orderedtable()

for i = 1, 10 do
    local k, v = "key"..tostring(i), "value"..tostring(i)
    if otable.add(t, k, v) then
        print(("Successfully added the following pair: %s=%s"):format(k, v))
    end
end

otable.mod(t, "key1", "new", false)

t[1] = "ok"
t["unordered field"] = "ok2"

print("Numeric indice support: "..tostring(t[1] == "ok"))
print("Unordered field support: "..tostring(t["unordered field"] == "ok2"))

for k, v in pairs(t) do
    print(k, v)
end
