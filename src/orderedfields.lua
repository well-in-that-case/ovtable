--[[
MIT License

Copyright (c) 2022 Ryan Starrett

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

-- Lua 5.4 Virtual Ordered Field Implementation, backwards-compatibility untested.

--[[
    Feature Implementation:
        - This ordered field implementation calls itself virtual because it doesn't modify anything.
        - A basic internal table is created to track insertion order. Each orderedtable creates a subtable.
        - Each subtable is referred to by its memory address, as a unique identifier.
        - The subtables contain index -> key pairs which indirectly map the insertion order.
        - The mirror subtable contains key -> index pairs which indirectly map the insertion order.
        - The purpose of the mirror table is to fetch insertion order by key in O(1).

        - Setting a key to nil won't reorder the insertion table, but it will by skipped by __pairs.
        - If you want to correctly abolish an ordered field, use the `del` function. It's O(n); n = #table - 1.

        - Numeric indices aren't supported. They're already ordered.
        - Adding them to the table works fine, I just don't interact with them.

        - Manually adding fields doesn't order them. I also just ignore them, so you can mix your table up.
        - Careful with the ignore though, because pairs won't show your elements. They're still there however.
--]]

local pkg = {} -- Main package.
local ins_order = {} -- Tracks insertion order; L1 table.
local key_ins_order = {} -- Mirror of `ins_order` to fetch the order of the key by its name; L2 table.

local ssub,
      type,
      rawset,
      assert,
      tremove,
      tostring,
      setmetatable,
      getmetatable = string.sub, type, rawset, assert, table.remove, tostring, setmetatable, getmetatable

--[[
    Metatable used to implement ordered tables. Stored in a local for identification purposes.
--]]
local orderedmetatable = {
    __pairs = function (t)
        local idx = 1
        local id = ssub(tostring(t), 8)

        local L1 = ins_order[id]
        local L2 = key_ins_order[id]

        if not L1 or not L2 then
            error "L1 & L2 tables are empty."
        end

        return function ()
            local k = L1[idx]
            local v = t[k]

            while v == nil and idx <= #L1 do
                idx = idx + 1

                k = L1[idx]
                v = t[k]
            end

            idx = idx + 1

            return k, v
        end
    end,

    __gc = function (t)
        local id = ssub(tostring(t), 8)

        if ins_order[id] then
            ins_order[id] = nil
        end

        if key_ins_order[id] then
            key_ins_order[id] = nil
        end
    end
}

-- Returns a new orderedtable.
function pkg.orderedtable()
    return setmetatable({}, orderedmetatable)
end

-- Performs t[key] = value & updates the insertion table accordingly. Optionally order the element.
-- If you don't want to order the element, you should prefer traditional assignment; that's faster.
function pkg.add(t, key, value, order)
    assert(type(key) == "string", "key must be a string.")
    assert(value ~= nil, "value must not be nil. Use the del function to remove elements.")
    assert(getmetatable(t) == orderedmetatable, "t must be an orderedtable.")

    local id = ssub(tostring(t), 8)

    if order ~= false then
        if not ins_order[id] then
            ins_order[id] = {}
        end

        local idx = #ins_order[id] + 1

        ins_order[id][idx] = key

        if not key_ins_order[id] then
            key_ins_order[id] = {}
        end

        key_ins_order[id][key] = idx
    end

    t[key] = value

    return t[key] ~= nil
end

-- Syntactic sugar for calling `del` and `add` in succession. Use this over `t[k] = v` when you want to reorder `k`.
function pkg.mod(t, key, value)
    assert(getmetatable(t) == orderedmetatable, "t must be an orderedtable.")
    assert(type(key) == "string", "key must be a string.")

    return pkg.del(t, key) and pkg.add(t, key, value, true)
end

-- Deletes and removes the insertion table entries for the keys you pass.
function pkg.del(t, ...)
    assert(getmetatable(t) == orderedmetatable, "t must be an orderedtable.")

    local id = ssub(tostring(t), 8)

    if not ins_order[id] or not key_ins_order[id] then
        return false, "this orderedtable is empty (ins_order[id] or key_ins_order[id] is nil/empty)"
    end

    for i = 1, select("#", ...) do
        local key = select(i, ...)
        local idx = key_ins_order[id][key]

        if not idx then -- Including this check above would potentially raise an attempt to index nil error.
            return false, "this ordered table is empty (idx == "..tostring(idx)..")"
        end

        tremove(ins_order[id], idx)
        key_ins_order[id][key] = nil
        rawset(t, key, nil)
    end

    return true
end

-- Gets an ordered field's value by its insertion index.
-- Setting `give_key_name` to `true` returns (key_name, key_value) instead of key_value.
function pkg.getindex(t, idx, give_key_name)
    assert(type(idx) == "number", "idx must be a number.")
    assert(getmetatable(t) == orderedmetatable, "t must be an orderedtable.")

    local id = ssub(tostring(t), 8)
    local kstr = ins_order[id]

    if not kstr then
        return nil, "this table has no keys"
    else
        local k = kstr[idx]

        if give_key_name == true then
            return k, t[k]
        else
            return t[k]
        end
    end
end

-- Returns the insertion index of the key.
function pkg.keyindex(t, key)
    assert(type(key) == "string", "key must be a string.")
    assert(getmetatable(t) == orderedmetatable, "t must be an orderedtable.")

    local addr = ssub(tostring(t), 8)
    local kstr = key_ins_order[addr]

    if not kstr then
        return nil, "this table has no keys"
    else
        return kstr[key]
    end
end

return pkg
