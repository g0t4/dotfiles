local function foo()
end

local function bar()
end

local function both()
    foo()
    bar()
end

local function none()
end

local function one()
    foo()
end


describe("learn upvalues (aka closures)", function()
    it("lua_getinfo to get nups (number of upvalues)", function()
        local info = debug.getinfo(both) -- no what param (2nd = all)
        assert.is_equal(2, info.nups)
        -- vim.print(info)

        info = debug.getinfo(both, "u")
        assert.is_equal(2, info.nups)
        -- vim.print(info)
    end)


    it("get up values from both function => has two", function()
        -- 0 is invalid ID, starts at 1
        local name, value = debug.getupvalue(both, 0)
        assert.is_nil(name)
        assert.is_nil(value)

        name, value = debug.getupvalue(both, 1)
        assert.equal("foo", name)
        assert.equal(value, foo)

        name, value = debug.getupvalue(both, 2)
        assert.equal("bar", name)
        assert.equal(value, bar)

        name, value = debug.getupvalue(both, 3)
        assert.is_nil(name)
        assert.is_nil(value)
    end)

    it("get up values from none => has none", function()
        local name, value = debug.getupvalue(none, 1)
        assert.is_nil(name)
        assert.is_nil(value)
    end)

    it("replace both's foo using newfoo", function()
        local count = 0
        function newfoo()
            count = count + 1
        end

        local name, value = debug.getupvalue(both, 1)
        assert.equal("foo", name)
        both()
        assert.equal(0, count)

        debug.setupvalue(both, 1, newfoo)
        both()
        assert.equal(1, count)
    end)
end)
