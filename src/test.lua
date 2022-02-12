local otable = require "orderedfields"

do
    local t = otable.orderedtable()

    for i = 1, 1000 do
        local k, v = "key"..tostring(i), "value"..tostring(i)
        if otable.add(t, k, v) then
            print(("Successfully added the following pair: %s=%s"):format(k, v))
        end
    end
    print("Memory usage: ", collectgarbage "count")

    otable.mod(t, "key1", "new", false)

    t[1] = "ok"
    t["unordered field"] = "ok2"

    print("Numeric indice support: "..tostring(t[1] == "ok"))
    print("Unordered field support: "..tostring(t["unordered field"] == "ok2"))

    print("Memory usage: ", collectgarbage "count")
    collectgarbage()
    print("Memory usage: ", collectgarbage "count")
    collectgarbage()
    collectgarbage()
    collectgarbage()
    print("Memory usage: ", collectgarbage "count")

    for key, value in pairs(t) do
        print(key, value)
    end
end

collectgarbage()
collectgarbage()
collectgarbage()

print("Memory usage: ", collectgarbage "count")
