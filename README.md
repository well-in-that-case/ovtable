# ovtable
Fast, friendly, and dynamic ordered table support for your codebase.

## How to use?
Simply download, drag, and drop the `ovtable.lua` file. Alternatively, use [Luarocks](https://luarocks.org/modules/well-in-that-case/ovtable):
```
luarocks install --server=https://luarocks.org/dev ovtable
```

## Documentation
Visit the [reference.](https://well-in-that-case.github.io/ovtable/)

## Compatibility
Lua >= 5.2.

## Why you should use this over other implementations?
- Efficency:
  - ovtable avoids usage of proxy tables to ensure the highest lookup and insertion performance. Likewise, linked lists are avoided to prevent unneeded hash lookups and seamlessly implement ordered fields in any dynamic environment that may not restrict this table to ordered operations only. You can make any table an ordered table anywhere in your codebase, and behavior will remain identical. Among other design aspects, this makes ovtable faster than every LuaWiki implementation, while boasting superior features.

- Features & user-friendliness:
  - Direct table behavior isn't modified in any way. You can replace every table in a large codebase, and it'll be compatible.
    - The only change is a metatable which, by default, only modifies garbage collection to clean the internal tables & support universal method usage.
  - I enjoy neat QoL features inside packages that I use, so you can expect those here as well.

- Extendable:
  - ovtable is absurdly simple and allows you to do pretty much anything you want to your table.
- Slowly becoming time-tested:
  - ovtable is gaining nearly 2,000 downloads every day on Luarocks without a single issue reported.

## How It Works
- ovtable doesn't modify your table at all. 
  - It only attaches a metatable to handle garbage collection, optionally extend `pairs` functionality, and add method support with `__index`.
- When you add a new key, ovtable _only_ keeps a record of _when_ it was added to an internal structure.

#### Can I still use numeric indices or normal fields?
Yes!
```lua
local otable = require "ovtable"
local mytable = otable.new()

mytable[1] = "hello world"
mytable.key = "hello world"
```
Works fine!

#### Can I use these functions with method syntax?
Yes! `t:getindex(...)` is equal to `pkg.getindex(t, ...)`.

#### How do I modify a key without resetting its order?
Use the traditional `t.key = newvalue` syntax.

#### How can I change the metatable of my ordered table?
You need to implement `__gc` of the `ovtable.metatable` field, otherwise your memory will leak. You can implement this functionality yourself with a custom GC method by clearing your tables first-class entry key in the internal tables (that you can read with `get_l1()` and `get_l2()`. Furthermore, `__index` needs to implement the `ovtable` package as a failsafe for universal method support.

## The End
If you fancy this project, give it a star!
