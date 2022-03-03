--- Fast, friendly, and dynamic ordered table support for your codebase.
-- Ordered tables from this package work like any other table.
-- Whether you want to use unordered keys, ordered ones, or even numeric indices. It all works fine.
-- That's stellar compatibility, and it's zero-overhead when you're doing native operations.

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
        Additionally, it must implement `__index = pkg` (pkg = ovtable.lua) for method syntax support.
--]]

local pkg = {} -- Main package.
local use_assert = true

local L1_indexkey = setmetatable({}, { __mode = "k" }) -- L1
local L2_keyindex = setmetatable({}, { __mode = "k" }) -- L2

--[[
    Metatable used to implement ordered tables. Stored in a local for identification purposes.
--]]
local orderedmetatable = {
    __pairs = function (t)
        local idx = 1

        local L1 = L1_indexkey[t]
        local L2 = L2_keyindex[t]

        if not L1 or not L2 then
            return nil, "internal tables are empty."
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
        L1_indexkey[t] = nil
        L2_keyindex[t] = nil
    end,

    __index = pkg
}

--- This is your base metatable when you wish to create overrides.
-- It needs __gc to garbage collect the internal tables and it needs __index for method support.
pkg.orderedmetatable = orderedmetatable

--- Returns a new orderedtable. Optionally override the __pairs metamethod.
-- @param override_pairs A boolean indicating whether to overrride the __pairs metamethod.
function pkg.orderedtable(override_pairs)
    if override_pairs == true then
        return setmetatable({}, orderedmetatable)
    else
        return setmetatable({}, { __gc = orderedmetatable.__gc, __index = orderedmetatable.__index })
    end
end

--- Returns an iterator for ordered fields. If you set override_pairs as true, this is the same as pairs.
-- This function takes the same parameters you'd give to __pairs.
function pkg.orderediterator(...)
    return orderedmetatable.__pairs(...)
end

--- Performs t[key] = value & updates the insertion table accordingly.
-- This is the only way to make an ordered key.
-- @param t The ordered table.
-- @param key The key to use.
-- @param value The value to use.
-- @param raw A boolean indicating whether to use raw assignment (via rawset) or __newindex assignment.
-- @return A boolean indicating if the key was added successfully.
function pkg.add(t, key, value, raw)
    if use_assert == true then
        assert(type(key) == "string", "key must be a string.")
        assert(value ~= nil, "value must not be nil. Use the del function to remove elements.")
        assert(getmetatable(t).__gc == orderedmetatable.__gc, "t must be an orderedtable.")
    end

    if not L1_indexkey[t] then
        L1_indexkey[t] = {}
    end

    local idx = #L1_indexkey[t] + 1

    L1_indexkey[t][idx] = key

    if not L2_keyindex[t] then
        L2_keyindex[t] = {}
    end

    L2_keyindex[t][key] = idx

    if raw ~= true then
        t[key] = value
    else
        rawset(t, key, value)
    end

    return t[key] ~= nil
end

--- Modify and reorder this key.
-- Use traditional reassignment if you do not wish to reorder.
-- @param t The ordered table.
-- @param key The key to modify.
-- @param value The new value for this key.
function pkg.mod(t, key, value)
    if use_assert == true then
        assert(getmetatable(t).__gc == orderedmetatable.__gc, "t must be an orderedtable.")
        assert(type(key) == "string", "key must be a string.")
    end

    return pkg.del(t, key) and pkg.add(t, key, value, true)
end

--- Deletes and removes the insertion table entries for the keys you pass.
-- This function takes an indefinite amount of string arguments. It uses raw assignment to nil values.
-- @param t The ordered table.
-- @param ... The keys you wish to delete.
-- @return Returns the amount of keys deleted.
function pkg.del(t, ...)
    if use_assert then
        assert(getmetatable(t).__gc == orderedmetatable.__gc, "t must be an orderedtable.")
    end

    local L1 = L1_indexkey[t]
    local L2 = L2_keyindex[t]

    if not L1 or not L2 then
        return false
    end

    local rem = table.remove
    local raw = rawset
    local tbl = {...}
    local amt = 0

    for i = 1, #tbl do
        local key = tbl[i]
        local idx = L1[key]

        if idx then
            rem(L1_indexkey[t], idx)

            L2_keyindex[t][key] = nil
            raw(t, key, nil)

            amt = amt + 1
        end
    end

    return amt
end

--- Gets an ordered field's value by its insertion index.
-- @param t The ordered table.
-- @param idx The numeric index to read.
-- @param give_key_name A boolean indicating whether to also return the key's name.
-- @return The key's value or the key's name and value, respectively.
function pkg.getindex(t, idx, give_key_name)
    if use_assert == true then
        assert(type(idx) == "number", "idx must be a number.")
        assert(getmetatable(t).__gc == orderedmetatable.__gc, "t must be an orderedtable.")
    end

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
-- @param t The ordered table.
-- @param key The key to read.
-- @return The key's insertion index (number), or nil if it wasn't found.
function pkg.keyindex(t, key)
    if use_assert == true then
        assert(type(key) == "string", "key must be a string.")
        assert(getmetatable(t).__gc == orderedmetatable.__gc, "t must be an orderedtable.")
    end

    local kstr = L2_keyindex[t]

    if not kstr then
        return nil
    else
        return kstr[key]
    end
end

--- Returns the amount of ordered keys in this ordered table.
-- @param t The ordered table.
-- @return The amount of ordered keys, or nil if this table isn't an ordered table.
function pkg.orderedlen(t)
    local entry = L1_indexkey[t]

    if entry == nil then
        return nil
    else
        return #entry
    end
end

--- Whether or not to use assertion calls in these package's functions.
-- Assertion calls can add upwards of 30% overhead during heavy stress.
-- There's no reason to keep using assertion calls if your code is stable & you're familiar with ovtable.
-- @param state A boolean indicating whether to use assertion calls.
-- @return This function has no return.
function pkg.assertioncalls(state)
    use_assert = state
end

--- Fetch the internal L1 table. Useful for debugging and issue reporting.
function pkg.get_l1() return L1_indexkey end
--- Fetch the internal L2 table. Useful for debugging and issue reporting.
function pkg.get_l2() return L2_keyindex end

--- Sets a predefined table identifier.
-- Deprecated; first-class table references are used instead of strings now.
function pkg.set_predef_table_unqid(...) return "a" end
--- Returns the unique ID for this table.
-- Deprecated; first-class table references are used instead of strings now.
function pkg.generate_unqid(...) end

return pkg
