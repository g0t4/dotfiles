co = coroutine.create(function(a, b, c)
    while true do
        print("co", a, b, c)
        coroutine.yield()
    end
end)
coroutine.resume(co, 1, 2, 3) --> co  1  2  3
coroutine.resume(co, 1, 2, 3) --> co  1  2  3
coroutine.resume(co, 1, 2, 3) --> co  1  2  3
