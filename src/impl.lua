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
        - If you want to completely abolish an element, use the `del` function. It's O(n); n = #table - 1.

        - Numeric indices aren't supported. They're already ordered.
        - Adding them to the table works fine, I just don't interact with them.

        - Manually adding fields doesn't order them. I also just ignore them, so you can mix your table up.
        - Careful with the ignore though, because pairs won't show your elements. They're still there however.
]]

local pkg = {} -- Main package.
local ins_order = {} -- Tracks insertion order.
local key_ins_order = {} -- Mirror of `ins_order` to fetch the order of the key by its name.

local ssub,
      rawset,
      assert,
      tremove,
      tostring = string.sub, rawset, assert, table.remove, tostring

--[[
    Metatable used to implement ordered tables. Stored in a local for identification purposes.
--]]
local orderedmetatable = {
    __pairs = function (t, order)
        local idx = 1
        local id = ssub(tostring(t), 8)

        return function ()
            local k, v = ins_order[id][idx], t[ins_order[id][idx]]

            while t[ins_order[id][idx]] == nil and idx <= #ins_order[id] do
                idx = idx + 1
                k, v = ins_order[id][idx], t[ins_order[id][idx]]
            end

            idx = idx + 1

            return k, v
        end
    end
}

-- Returns a new orderedtable.
function pkg.orderedtable()
    return setmetatable({}, orderedmetatable)
end

-- Performs t[key] = value & updates the insertion table accordingly. Optionally order the element.
function pkg.add(t, key, value, reorder)
    assert(type(key) == "string", "key must be a string.")
    assert(value ~= nil, "value must not be nil. Use the rem function to remove elements.")
    assert(getmetatable(t) == orderedmetatable, "t must be an orderedtable.")

    local id = ssub(tostring(t), 8)

    if reorder == nil then
        reorder = true
    end

    if reorder == true then
        if not ins_order[id] then
            ins_order[id] = {}
        end
        ins_order[id][#ins_order[id] + 1] = key

        if not key_ins_order[id] then
            key_ins_order[id] = {}
        end
        key_ins_order[id][key] = #key_ins_order[id] + 1
    end

    rawset(t, key, value)

    return t[key] ~= nil
end

-- Syntactic sugar for calling `del` and `add` in succession. Optionally reorder the element.
function pkg.mod(t, key, value, reorder)
    assert(getmetatable(t) == orderedmetatable, "t must be an orderedtable.")
    assert(type(key) == "string", "key must be a string.")

    if reorder == nil then
        reorder = true
    end

    if reorder == false then
        return pkg.add(t, key, value, reorder)
    else
        return pkg.del(t, key) and pkg.add(t, key, value, true)
    end
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

return pkg
