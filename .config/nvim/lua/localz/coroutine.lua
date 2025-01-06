co = coroutine.create(function(a, b, c)
    while true do
        print("co", a, b, c)
        coroutine.yield()
        --  sleep for a second, call callback that calls yield
    end
end)
print("co", coroutine.status(co))
coroutine.resume(co, 1, 2, 3) --> co  1  2  3
print("co", coroutine.status(co))
coroutine.resume(co, 4, 5, 6) --> co  4  5  6
print("co", coroutine.status(co))
coroutine.resume(co, 7, 8, 9) --> co  7  8  9
