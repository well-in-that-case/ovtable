# VirtualOrderedFields
(Lua 5.4): Virtual ordered fields for tables. Retains support for numeric indices, and unordered fields in the same table. This won't modify your fields at all, because it only keeps track of what keys are inserted at what times when you tell it to.

# How It Works
I remember every orderedtable by saving its memory address into the insertion tables. When you add a new ordered field (`pkg.add`), it gets the length of `insertion_table[memaddr]` which is your table's spot in the insertion table. Then, `insertion_table[memaddr][length + 1] = key` is performed to indirectly remember the insertion order of this key. 

VirtualOrderedFields does not use proxy tables, it doesn't change the behavior of you manually adding new fields, or indexing for them. The only difference is the metatable of your table, which modifies the `pairs` function to only list orderedfields, and also modifies the `__gc` metamethod to update the insertion table once you no longer need your orderedtable.

Deleting an orderedfield can be done manually but this may conflict with the insertion table, because I'm not aware that you delete an element unless you correctly use the `pkg.del` function to delete potentially ordered fields. You can read the return (`boolean`) of `pkg.del` to decide if it deleted an orderedfield. If it didn't, simply perform the assignment manually, because it'll only fail on unordered fields.

Unlike all other ordered field implementations, this does not use a linked list or a classic proxy table implementation. That makes this the most dynamic & freedom-oriented design that I've seen myself.

# Performance
I've yet to benchmark against other implementations, but I can make theory on their designs. Since this design doesn't modify your table, all lookups are as fast as a hash lookup could possibly be; there are no secondary indexes to a proxy table for your values, and there are no indexes for a linking node. As a result, this implementation may be the most performant, lookup wise.

# Documentation
Read the source code, sorry. I've added some comments. I made this as a completely personal package and released it in case someone else may need it.

# Reliability
Not stress tested all that well, written in 15 minutes. I tested the features, they worked. Hopefully some others find use. Feel free to report any problems though.
