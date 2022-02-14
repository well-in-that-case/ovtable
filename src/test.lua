local otable = require "orderedfields"

do
    local t = otable.orderedtable()

    for i = 1, 900 do
        local k, v = "key"..tostring(i), "value"..tostring(i)
        if otable.add(t, k, v) then
            print(("Successfully added the following pair: %s=%s"):format(k, v))
        end
    end
    print("Memory usage: ", collectgarbage "count")

    otable.mod(t, "key899", "newvalue", true)
    --t.key899 = "newvalue"

    for key, value in pairs(t) do
        print(key, value)
    end

    t[1] = "ok"
    t["unordered field"] = "ok2"

    print("Numeric indice support: "..tostring(t[1] == "ok"))
    print("Unordered field support: "..tostring(t["unordered field"] == "ok2"))
end

collectgarbage()
collectgarbage()
collectgarbage()

print("Memory usage: ", collectgarbage "count")

local t = otable.orderedtable()

for i = 1, 10 do
    otable.add(t, "key"..tostring(i), "value"..tostring(i))
end

for i = 1, 10 do
    local key, _ = otable.getindex(t, i, true)
    print("Key @ Index "..tostring(i)..": "..key)
end

for i = 1, 10 do
    print("Value @ Index "..tostring(i)..": "..tostring(otable.getindex(t, i)))
end

t.key11 = "hello world!"
t.key12 = "hello world, again!"

for k, v in t:orderediterator() do
    print(k, v)
end

print "Performing benchmarking..."

do
    local tt = otable.orderedtable()
    local now = os.clock()

    for i = 1, 100000 do
        local k = "key"..tostring(i)
        local v = "val"..tostring(i)

        tt:add(k, v)
    end

    print("Took "..tostring(os.clock() - now).." to insert 100,000 keys.")
end

do
    local tt = otable.orderedtable()
    local now = os.clock()

    tt:add("key", "value")

    for i = 1, 100000 do
        local v = tt["key"]
    end

    print("Took "..tostring(os.clock() - now).." to lookup 100,000 keys.")
end

do
    local tt = otable.orderedtable()
    local now = os.clock()

    tt:add("key", "value")

    for i = 1, 100000 do
        tt:mod("key", "newvalue")
    end

    print("Took "..tostring(os.clock() - now).." to modify & reorder 100,000 keys.")
end

do
    local tt = otable.orderedtable()
    local now = os.clock()

    tt:add("key", "value")

    for i = 1, 100000 do
        tt.key = "newvalue"
    end

    print("Took "..tostring(os.clock() - now).." to modify 100,000 keys.")
end

do
    local tt = otable.orderedtable()

    for i = 1, 10000 do
        tt:add("key"..tostring(i), "val"..tostring(i))
    end

    local now = os.clock()

    tt:add("key", "value")

    for i = 1, 100000 do
        local val = tt:getindex(i)
    end

    print("Took "..tostring(os.clock() - now).." to index 100,000 keys by their insertion index.")
end
