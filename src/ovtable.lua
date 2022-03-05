--- Fast, friendly, and dynamic ordered table support for your codebase.
-- Ordered tables from this package work like any other table.
-- Whether you want to use unordered keys, ordered ones, or even numeric indices. It all works fine.
-- That's stellar compatibility, and it's zero-overhead when you're doing native operations.
--
-- Need to report an issue? <a href="https://github.com/well-in-that-case/ovtable/issues">Click here!</a>
--
-- Has this project made your life a little easier? <a href="https://github.com/well-in-that-case/ovtable">Give it a star on github!</a>
--
-- <h3>How does it work?</h3>
-- Two external tables (named L1 & L2) track when you request to add an ordered key.
-- Upon this, the L1 table (index -> key) increments its latest index to reflect the increasing insertion indexes.
-- Conversly, the L2 table mirrors the L1 table (with key -> index) pairs for O(1) index lookup times.
--
-- I coined this "virtual", or "ordered virtual table" (hence, ovtable) because everything is tracked externally, without modifying the user's table.
-- It's incredibly simple to implement and it provides really good lookup/assignment performance. My favorite part is being able to use ordered, unordered, and numeric keys in the same table.
--
-- <h3>What are the cons of this package?</h3>
-- Well, you can replace every existing table in your codebase with an ordered one and it'll behave exactly the same with the exact same performance.
-- The only change I make is your metatable. I need to control garbage collection to prevent internal memory leaks, and I need to set the index metamethod for universal method support.
--
-- As a result, you need to implement these when you override the metatable yourself. Not much of a problem though, because the metatable field is the base metatable you can build on.
-- Take your metatable, set its GC metamethod as the metatable's base, and the index metamethod appropriately. Then you're fine.
--
-- <h3>Why should I use this module?</h3>
-- <ol>
--  <li>Zero-overhead lookups.</li>
--  <li>Helps enhance your readability.</li>
--  <li>Good overall run-time performance.</li>
--  <li>Zero-overhead assignment outside of ordered operations.</li>
--  <li>Becoming polished to reduce your key-strokes, and henceforth reduce errors.</li>
--  <li>Very good codebase compatibility with large windows for zero-overhead operations.</li>
--  <li>Interested in making the developer experience easier, for such syntactic sugar implementations.</li>
--  <li>Compatible with sandboxed developer environments, because it's written in plain Lua.</li>
--  <li>No limitation on your keys. Your table can harbor ordered, unordered, numeric, and first-class object keys.</li>
-- </ol>

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

-- Lua 5.4 Virtual Ordered Field Implementation.

--[[
    Feature Implementation:
        "Virtual", meaning tables aren't directly modified. Everything is tracked externally.
        As a result, this is the fastest implementation. Two internal tables are used to track data,
        and they're named the L1 and L2 tables, respectively.

        The L1 table maps index to key pairs, where 'index' represents the insertion index.
        The L1 table is a plain numeric indice array that's garbage collected appropriately.
        The L2 table maps key to index pairs, where 'index' and 'key' are alike to aforementioned.

        This design choice gives ovtable unrivaled lookup and assignment performance.
        Proxy-table implementations are destructive to codebase compatibility and have high assignment/lookup overhead.

        ovtable has a fair amount in common with linked list implementations, but we link against numeric nodes
        that virtually represent an index, instead of a tangible key. This method works like oil between gears.

        A substantial advantage of external tracking is compatibility though.
        Unordered and ordered keys, including numeric indices are legal to store in ordered tables.
        It's important to understand, your ordered table is literally just a table. Ovtable only remembers some stuff.

    Need-To-Knows:
        If you wish to replace the metatable of your ordered table, it must implement `orderedmetatable.__gc`.
        Additionally, it must implement `__index = ovtable` (ovtable = ovtable.lua) for method syntax support.
--]]

local ovtable = {} -- Main package.

local L1_indexkey = setmetatable({}, { __mode = "k" }) -- L1
local L2_keyindex = setmetatable({}, { __mode = "k" }) -- L2

local orderedmetatable = {
    __gc = function (t)
        L1_indexkey[t] = nil
        L2_keyindex[t] = nil
    end,

    __index = ovtable
}

--- This is your base metatable when you wish to create overrides.
-- It needs __gc to garbage collect the internal tables and it needs __index for method support.
ovtable.metatable = orderedmetatable

--- Returns a new ordered table.
function ovtable.new()
    return setmetatable({}, orderedmetatable)
end

--- Performs t[key] = value & updates the insertion table accordingly.
-- This is the only way to make an ordered key.
-- @tparam table t The ordered table.
-- @tparam any key The key to use.
-- @tparam any value The value to use.
-- @tparam boolean raw Whether to use raw assignment (via rawset) or __newindex assignment.
function ovtable.add(t, key, value, raw)
    assert(value ~= nil, "'add' function: value must not be nil.")

    local L1 = L1_indexkey[t]
    local L2 = L2_keyindex[t]

    if L1 == nil then
        local tmp = {}
        L1_indexkey[t] = tmp
        L1 = tmp
    end

    if L2 == nil then
        local tmp = {}
        L2_keyindex[t] = tmp
        L2 = tmp
    end

    local idx = #L1 + 1

    L1[idx] = key
    L2[key] = idx

    if raw ~= true then
        t[key] = value
    else
        rawset(t, key, value)
    end

    return t[key] ~= nil
end

--- Modify and reorder this key.
-- Use traditional reassignment if you do not wish to reorder.
-- @tparam table t The ordered table.
-- @tparam any key The key to modify.
-- @tparam any value The new value for this key.
-- @tparam boolean raw Whether to use raw operations to nil values.
function ovtable.mod(t, key, value, raw)
    return ovtable.del(t, key) and ovtable.add(t, key, value, raw)
end

--- Deletes and removes the insertion table entries for the keys you pass.
-- This function uses raw operations to remove keys from the table itself.
-- @tparam table tt The ordered table.
-- @param ... The keys you wish to delete.
-- @treturn number|false The amount of keys deleted, or false when tt is unknown.
function ovtable.del(tt, ...)
    local L1 = L1_indexkey[tt]
    local L2 = L2_keyindex[tt]

    if not L1 or not L2 then
        return false
    end

    local rem = table.remove
    local raw = rawset
    local amt = 0

    for _, key in pairs({...}) do
        local idx = L2[key]

        if idx ~= nil then
            rem(L1, idx - amt)
            raw(L2, key, nil)
            raw(tt, key, nil)

            amt = amt + 1
        end
    end

    -- L2 indexes don't match up anymore, so the L2 table needs to be rearranged.
    -- Hopefully this can be optimized, because ordered deletion is fairly expensive right now. (still fast though)
    for index, key in pairs(L1) do
        local existsAtL2 = L2[key]

        if existsAtL2 then
            L2[key] = index
        end
    end

    return amt
end

--- Swaps the insertion indexes of the keys.
-- @tparam table t The ordered table.
-- @tparam any key1 The first key.
-- @tparam any key2 The second key.
-- @treturn boolean Returns false if no keys were swapped (likely not ordered keys).
function ovtable.swap(t, key1, key2)
    local L1 = L1_indexkey[t]
    local L2 = L2_keyindex[t]

    if not L1 or not L2 then
        return false
    end

    local key1_Idx = L2[key1]
    local key2_Idx = L2[key2]

    if key1_Idx == nil or key2_Idx == nil then
        return false
    end

    L2[key1] = key2_Idx
    L2[key2] = key1_Idx

    L1[key1_Idx] = key2
    L1[key2_Idx] = key1
end

--- Returns an iterator for ordered fields.
-- @tparam table t The ordered table.
function ovtable.iterator(t)
    local L1 = assert(L1_indexkey[t], "'iterator' function: t is empty, or not an ordered table.")
    local state = 0

    return function ()
        local key, val

        repeat
            state = state + 1
            key = L1[state]
            val = t[key]
        until val ~= nil or state >= #L1

        return key, val
    end
end

--- Clears every ordered key up until index num.
-- @tparam table t The ordered table.
-- @tparam number num The amount of ordered keys to clear, from the bottom up.
-- @treturn number The amount of keys deleted.
function ovtable.clear_to(t, num)
    local L1 = L1_indexkey[t]
    local L2 = L2_keyindex[t]

    if not L1 or not L2 then
        return 0
    end

    local keys = {}

    for i = 1, num do
        keys[#keys + 1] = L1[i]
    end

    return ovtable.del(t, table.unpack(keys))
end

--- Clears every ordered key between insertion index num1 & num2.
-- @tparam table t The ordered table.
-- @tparam number num1 The starting index.
-- @tparam number num2 The ending index.
-- @treturn number The amount of keys deleted.
function ovtable.clear_from(t, num1, num2)
    local L1 = L1_indexkey[t]
    local L2 = L2_keyindex[t]

    if not L1 or not L2 then
        return 0
    end

    local keys = {}

    for i = num1, num2 do
        keys[#keys + 1] = L1[i]
    end

    return ovtable.del(t, table.unpack(keys))
end

--- Gets an ordered field's value by its insertion index.
-- Setting the last parameter as true will also return the key name.
-- @tparam table t The ordered table.
-- @tparam number idx The numeric index to read.
-- @tparam boolean give_key_name A boolean indicating whether to also return the key name.
-- @treturn any|any,any The key value, or alernatively the key name & value.
function ovtable.getindex(t, idx, give_key_name)
    local kstr = L1_indexkey[t]

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

--- Returns the insertion index of the key.
-- @tparam table t The ordered table.
-- @tparam any key The key to read.
-- @treturn number|nil The key's insertion index.
function ovtable.keyindex(t, key)
    local kstr = L2_keyindex[t]

    if not kstr then
        return nil
    else
        return kstr[key]
    end
end

--- Returns the amount of ordered keys in this ordered table.
-- @tparam table t The ordered table.
-- @treturn number The amount of ordered keys.
function ovtable.orderedlen(t)
    local entry = L1_indexkey[t]

    if entry == nil then
        return 0
    else
        return #entry
    end
end

--- Clears every ordered key up until key is found.
-- @tparam table t The ordered table.
-- @tparam any key The key.
-- @treturn number The amount of keys deleted.
function ovtable.clear_to_key(t, key)
    local L1 = L1_indexkey[t]
    local idx = ovtable.keyindex(t, key)

    if not L1 or L1[idx] == nil then
        return 0
    else
        return ovtable.clear_to(t, idx)
    end
end

--- Clears every ordered key that comes after key.
-- @tparam table t The ordered table.
-- @tparam any key The key.
-- @treturn number The amount of keys deleted.
function ovtable.clear_from_key(t, key)
    local L1 = L1_indexkey[t]
    local idx = ovtable.keyindex(t, key)

    if not L1 or L1[idx] == nil then
        return 0
    else
        return ovtable.clear_from(t, idx + 1, #L1)
    end
end

--- Clears every ordered key between key1 and key2.
-- @tparam table t The ordered table.
-- @tparam any key1 The starting key.
-- @tparam any key2 The ending key.
-- @treturn number The amount of keys deleted.
function ovtable.clear_between_keys(t, key1, key2)
    local L1 = L1_indexkey[t]
    local idx1 = ovtable.keyindex(t, key1)
    local idx2 = ovtable.keyindex(t, key2)

    if not L1 or idx1 == nil or idx2 == nil then
        return 0
    else
        return ovtable.clear_from(t, idx1, idx2)
    end
end

--- Fetch the internal L1 table. Useful for debugging and issue reporting.
-- @treturn table The internal L1 table, which maps index -> key pairs.
function ovtable.get_l1() return L1_indexkey end
--- Fetch the internal L2 table. Useful for debugging and issue reporting.
-- @treturn table The internal L2 table, which maps key -> index pairs.
function ovtable.get_l2() return L2_keyindex end

return ovtable
