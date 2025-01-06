co = coroutine.create(function(a)
    print("co", a, coroutine.status(co))
    x = coroutine.yield(a)
    print("co", x, coroutine.status(co))
    --  sleep for a second, call callback that calls yield
end)
print("out", coroutine.status(co))
coroutine.resume(co, 1, 2, 3) --> co  1  2  3
print("out", coroutine.status(co))
coroutine.resume(co, 4, 5, 6) --> co  4  5  6
print("out", coroutine.status(co))
