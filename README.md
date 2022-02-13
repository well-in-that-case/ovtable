# VirtualOrderedFields
(Lua 5.4): Virtual ordered fields for tables. Retains support for numeric indices, and unordered fields in the same table. This won't modify your fields at all, because it only keeps track of what keys are inserted at what times when you tell it to.

## How It Works
See this [article](https://dev.to/wellinthatcase/new-lua-54-ordered-field-implementation-not-a-linked-list-nor-proxy-table-1ia5-temp-slug-7081040?preview=491d3eb0f22954861537e87991e4aa453e95cdd5c1122e4265e1caf32b6168671329a0193f9150d9b960a0f1f59c15eccb4e5c4bd55051c94bc2b818).

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
