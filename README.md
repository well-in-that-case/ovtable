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
- Zero-overhead lookups.
- Helps enhance your readability.
- Good overall run-time performance.
- Zero-overhead assignment outside of ordered operations.
- Becoming polished to reduce your key-strokes, and henceforth reduce errors.
- Very good codebase compatibility with large windows for zero-overhead operations.
- Interested in making the developer experience easier, for such syntactic sugar implementations.
- Compatible with sandboxed developer environments, because it's written in plain Lua.
- No limitation on your keys. Your table can harbor ordered, unordered, numeric, and first-class object keys.

## How It Works
- ovtable doesn't modify your table at all. 
  - It only attaches a metatable to handle garbage collection & add method support with `__index`.
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
