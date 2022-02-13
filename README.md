# VirtualOrderedFields
(Lua 5.4): Virtual ordered fields for tables. Retains support for numeric indices, and unordered fields in the same table. This won't modify your fields at all, because it only keeps track of what keys are inserted at what times when you tell it to.

## How It Works
I remember every orderedtable by saving its memory address into the insertion tables. When you add a new ordered field (`pkg.add`), it gets the length of `insertion_table[memaddr]` which is your table's spot in the insertion table. Then, `insertion_table[memaddr][length + 1] = key` is performed to indirectly remember the insertion order of this key. 

VirtualOrderedFields does not use proxy tables, it doesn't change the behavior of you manually adding new fields, or indexing for them. The only difference is the metatable of your table, which modifies the `pairs` function to only list orderedfields, and also modifies the `__gc` metamethod to update the insertion table once you no longer need your orderedtable.

Deleting an orderedfield can be done manually but this may conflict with the insertion table, because I'm not aware that you delete an element unless you correctly use the `pkg.del` function to delete potentially ordered fields. You can read the return (`boolean`) of `pkg.del` to decide if it deleted an orderedfield. If it didn't, simply perform the assignment manually, because it'll only fail on unordered fields.

Unlike all other ordered field implementations, this does not use a linked list or a classic proxy table implementation. That makes this the most dynamic & freedom-oriented design that I've seen myself. This comes with one con though: since it's not a proxy table, I cannot control manual assignments, as `newindex` will only run once for each key.

## Signatures
- `pkg.orderedtable() -> table`
- `pkg.add(table, string, any) -> boolean`
- `pkg.mod(table, string, any) -> boolean`
- `pkg.del(table, string) -> boolean, (false, string)`
- `pkg.getindex(table, number) -> any, (nil, string)`
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

#### How can I loop over my table and include unordered fields / numeric indices?
Use this code:
```lua
for k, v in next, table do
  print(k, v)
end
```
Instead of this code:
```lua
for k, v in pairs(table) do 
  print(k, v)
end
```
Ordered tables modify the `__pairs` metamethod, so `pairs` will only work with ordered fields.

#### How do I modify a key without resetting its order?
Use the traditional `t.key = newvalue` syntax.

#### How do I modify a key and reset its order?
Use the `pkg.mod` function.

#### How do I get a field by its insertion index?
Use the `pkg.getindex` function.

#### How do I get a key's insertion index by name?
Use the `pkg.keyindex` function.
