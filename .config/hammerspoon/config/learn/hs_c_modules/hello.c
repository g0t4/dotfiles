#include <lua.h>
#include <lauxlib.h>

// The function we'll expose to Lua
static int world(lua_State *L) {
    lua_pushstring(L, "Hello, world!");
    return 1; // returning one value to Lua
}

// The module entry point
int luaopen_hello(lua_State *L) {
    lua_newtable(L);
    lua_pushcfunction(L, world);
    lua_setfield(L, -2, "world");
    return 1;
}

