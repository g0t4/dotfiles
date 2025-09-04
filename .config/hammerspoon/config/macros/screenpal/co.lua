function run_async(what, ...)
    if coroutine.running() then
        what(...) -- equivalent of resume below
        return
    end

    local co = coroutine.create(what)
    local ok, err = coroutine.resume(co, ...)
    if not ok then
        error(err)
    end
end

function sleep_ms(ms)
    local co = coroutine.running()
    assert(co, "sleep can only be called within a coroutine")

    function callback()
        coroutine.resume(co)
    end

    if vim ~= nil and vim.defer_fn ~= nil then
        -- useful in nvim lua code
        -- ALSO useful for plenary test runs
        -- print("sleep found vim")
        vim.defer_fn(callback, ms)
        coroutine.yield()
        return
    end

    local is_hs = hs ~= nil and hs.timer ~= nil and hs.timer.doAfter ~= nil
    if is_hs then
        -- useful in my hammerspoon "prod" config
        -- print("sleep found hs")
        seconds = ms / 1000
        hs.timer.doAfter(seconds, callback)
        coroutine.yield()
        return
    end

    local luv = require("luv")
    if luv then
        -- NOT working... smth with luv.run... event loop
        -- print("LUV")
        -- print(coroutine.running())
        luv.new_timer():start(ms, 0, callback)
        -- print(coroutine.running())
        -- print(coroutine.status(co))
        error("FFS use plenary for running these coroutine tests, do not waste time implementing this in luv with busted")
        coroutine.yield() -- throws nonsense about no coroutine when coroutine.status() returns "running"
        return
    end

    error("NOT SUPPORTED TEST ENV... USE _PLENARY_")
end
