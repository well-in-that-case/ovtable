# VirtualOrderedFields
Performant, friendly, and extendable ordered fields for tables. This implementation retains support for numeric indices and unordered fields in the same table to ensure the most user-friendly experience while providing native performance identical with a normal table.

## Why you should use this over other implementations?
- Efficency:
  - VirtualOrderedFields avoids usage of proxy tables to ensure the highest lookup and insertion performance. Likewise, linked lists are avoided to prevent unneeded hash lookups and seamlessly implement ordered fields in any dynamic environment that may not restrict this table to ordered operations only. You can make any table an ordered table anywhere in your codebase, and behavior will remain identical. Among other design aspects, this makes VirtualOrderedFields faster than every LuaWiki implementation, while boasting superior features.

- Features & user-friendliness:
  - Direct table behavior isn't modified in any way. You can replace every table in a large codebase, and it'll be compatible.
    - The only change is a metatable which, by default, only modifies garbage collection to clean the internal tables.
  - VirtualOrderedFields has some neat functions, such as getting a field by insertion index, that put it above many other implementations.

- Extendable:
  - VirtualOrderedFields exposes almost every facet of implementation to the user.
    - As of now, it's restricted to "almost" because the internal tables are hidden. This will change to allow low-level modification.

## How It Works
- VirtualOrderedFields doesn't modify your table at all. 
  - It only attaches a metatable to handle garbage collection and optionally extend `pairs` functionality.
- When you add a new key, VirtualOrderedFields _only_ keeps a record of _when_ it was added to an internal structure.

## Signatures
- `pkg.orderedtable() -> table`
- `pkg.add(table, string, any) -> boolean`
- `pkg.mod(table, string, any) -> boolean`
- `pkg.del(table, string) -> boolean, (false, string)`
- `pkg.getindex(table, number, boolean) -> any, (string, string), (nil, string)`
- `pkg.keyindex(table, string) -> number, (nil, string)`

## Examples
I'll inline it for now.

Creating a new orderedtable:
```lua
local otable = require "orderedtable"
local mytable = otable.orderedtable()
```

Adding a new ordered field to your table:
```lua
local otable = require "orderedtable"
local mytable = otable.orderedtable()

otable.add(mytable, "key", value)
```

Deleting an ordered field from your table:
```lua
local otable = require "orderedtable"
local mytable = otable.orderedtable()

otable.del(mytable, "key1", "key2", "key3")
```

Modifying an ordered field from your table:
```lua
local otable = require "orderedtable"
local mytable = otable.orderedtable()

otable.mod(mytable, "key", value)
```

Modifying an ordered field without changing the insertion index:
```lua
local otable = require "orderedtable"
local mytable = otable.orderedtable()

mytable.key = value
```

Getting the insertion index of a key:
```lua
local otable = require "orderedtable"
local mytable = otable.orderedtable()

otable.add(mytable, "key", "value")
otable.add(mytable, "key1", "value1")

otable.keyindex(mytable, "key1") --> 2
```

Getting the value @ an insertion index:
```lua
local otable = require "orderedtable"
local mytable = otable.orderedtable()

otable.add(mytable, "key", "value")
otable.add(mytable, "key1", "value1")

otable.getindex(mytable, 2) --> "value1"
```

#### Can I still use numeric indices or normal fields?
Yes!
```lua
local otable = require "orderedtable"
local mytable = otable.orderedtable()

mytable[1] = "hello world"
mytable.key = "hello world"
```
Works fine!

#### Can I use these functions with method syntax?
Yes! `t:getindex(...)` is equal to `pkg.getindex(t, ...)`.

#### Nuance on how loops work
- If you set `override_pairs` as `true`, then `pairs` will behave as an `orderediterator`.
  - If you wish to circumvent this behavior in one specific loop, use the `next` function instead of `pairs`.
 
- If `pairs` was not overridden, then you can use the `orderediterator` function as your iterator:
```lua
local o = require "orderedfields"
local t = o.orderedtable()

for key, value in t:orderediterator() do
  print(key, value)
end
```

#### How do I modify a key without resetting its order?
Use the traditional `t.key = newvalue` syntax.

#### How can I change the metatable of my ordered table?
Your boilerplate metatable needs to implement `pkg.orderedmetatable.__gc` and `pkg.orderedmetatable.__index`. See this code:
```lua
local o = require "orderedfields"
local t = o.orderedtable()

local basemt = o.orderedmetatable
basemt.__metamethod = ...

setmetatable(t, basemt)
```
If you fail to set `__gc` as `orderedmetatable.__gc`, then your memory will leak, because L1 & L2 table cleanup won't invoke.
You may override `__index`, but you'll need to implement method support yourself when you do that. It points to the package table by default.

## Documentation
- `function orderedtable(override_pairs)`
  - Returns a new ordered table, which can optionally change `pairs` to an ordered iterator when used on ordered tables.
- `function orderediterator(t)`
  - Returns an iterator that appropriately loops over ordered fields.
- `function getindex(t, idx, give_key_name)` 
  - Gets the field's value by insertion index (`idx`). `give_key_name = true` will return the key name and key value.
  - Returns `key_value` inherently.
  - Returns `nil` and `reason` if the search fails.
  - Returns `key_name` and `key_value` if `give_key_name` is set as `true`.
- `function keyindex(t, key`)
  - Returns the numeric insertion index of `key` in `t`.
  - Returns `nil` and `reason` if the search fails.
- `function add(t, key, value)`
  - Adds a new ordered field to `t` with the respective parameters.
  - Returns a boolean indicating if the key was added.
- `function mod(t, key, value)`
  - Modifies an ordered field by calling `del` and `add` in succession. This is how you reorder on modification.
  - Returns the combined result of `mod` and `add`.
- `function del(t, key)`
  - Deletes an ordered field and its insertion table entries.
  - Returns `false` and `reason` if the key wasn't deleted.

## Performance
### Insertion Times
```lua
local tt = otable.orderedtable()
local now = os.clock()

for i = 1, 100000 do
    local k = "key"..tostring(i)
    local v = "val"..tostring(i)

    tt:add(k, v)
end

print("Took "..tostring(os.clock() - now).." to insert 100,000 keys.")
```
- Results:
  - ~350ms for 100,000 keys, probably inflated by string computation times.

### Hash Lookup Times
```lua
local tt = otable.orderedtable()
local now = os.clock()

tt:add("key", "value")

for i = 1, 100000 do
    local v = tt["key"]
end

print("Took "..tostring(os.clock() - now).." to lookup 100,000 keys.")
```
- Results:
  - ~900ns (0.9ms) for 100,000 keys.

### Key Modification & Reorder Times
```lua
local tt = otable.orderedtable()
local now = os.clock()

tt:add("key", "value")

for i = 1, 100000 do
    tt:mod("key", "newvalue")
end

print("Took "..tostring(os.clock() - now).." to modify & reorder 100,000 keys.")
```
- Results:
  - ~250ms for 100,000 keys. This is less than the benchmark for `add`, so string computation definitely added a lot of overhead.

### Traditional Key Modification Times
```lua
local tt = otable.orderedtable()
local now = os.clock()

tt:add("key", "value")

for i = 1, 100000 do
    tt.key = "newvalue"
end

print("Took "..tostring(os.clock() - now).." to modify 100,000 keys.")
```
- Results:
  - Typically less than 1 millisecond for 100,000 keys.

### Lookup By Insertion Index Times
```lua
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
```
- Results:
  - ~80ms for 100,000 keys.

These benchmarks were performed on an AMD-FX6300 @ 4.1GHz, using 800Mhz dual-channel DDR3 memory. You may see *much* better results on modern hardware.
