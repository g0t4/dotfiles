import os

# NOTES from crude benchmarking (comment out generate command call and only return fixed string so do everything except the API call b/c I am mostly interested in overhad indepedent of API call)
# hyperfine  'python3 -c "import single"' 'python3 -c "print(1)"' 'python3 -c "import km_devtools"'
#   import single => 76.8ms
#   import km_devtools => 259ms (w/o openai => 64.9ms! so almost 200ms for openai import)
#   print(1) => 17.4ms

# *** comment out generating commands as that timing is not going to be relevant to my optimizations (before/after) calling generate

# use cprofile/pstats directly so I can format output w/o truncating meanignful parts of file path/name
import cProfile, pstats, io
from pstats import SortKey

pr = cProfile.Profile()
pr.enable()
# *** START of PROFILING

# import km_devtools # 350ms (cProfile, import only)
# import single # 74ms (cProfile, import only)

# *** FYI run with:
#    echo foo | python3 cprof.py
#    echo foo | python3 cprof.py --ollama # args work w/ single.py/etc
# or, override args:
#    sys.argv = [sys.argv[0], "--ollama"]
#
# from single import main
# main()
#
# from devtools import main
# main()
from tests.keyring import main
main()

# *** END of PROFILING
pr.disable()




def custom_print_stats(pr, stream, sortby=SortKey.CUMULATIVE, strip_path=None):
    ps = pstats.Stats(pr, stream=stream).sort_stats(sortby)
    stats = ps.stats
    print(f"    ncalls   tottime   percall   cumtime   percall  filename:lineno(function)")

    items = [(func, data) for func, data in stats.items()]
    # [3] is cumtime
    items = sorted(items, key=lambda x: x[1][3], reverse=True)

    items = [(func, data) for func, data in items if data[3] > 0.01] # FILTER cumtime (optionally include high percalls?)
    for func, data in items:
        filename, line, name = func
        ncalls = data[0]
        tottime = data[2]
        percall = data[2]/ncalls
        cumtime = data[3]
        percall_cumtime = data[3]/ncalls

        # could do this: cwd for first path to string, then venv lib dir... to sitepackages... then Python.framework dir to current python exe (sys.path[0]?, venv is env var)
        filepath = filename.replace("/Users/wesdemos/repos/github/g0t4/dotfiles/zsh/universals/3-last/ask-openai/", "* ")
        filepath = filepath.replace("/Users/wesdemos/repos/github/g0t4/dotfiles/.venv/lib/python3.13/site-packages", "")
        filepath = filepath.replace("/opt/homebrew/Cellar/python@3.13/3.13.0_1/Frameworks/Python.framework/Versions/3.13", "py3.13")

        print(f"   {ncalls:>7}  {tottime:.6f}  {percall:.6f}  {cumtime:.6f}  {percall_cumtime:.6f}  {filepath}:{line}({name})")


s = io.StringIO()
sortby = SortKey.CUMULATIVE



# *** BUILTIN formatting:
# ps = pstats.Stats(pr, stream=s).sort_stats(sortby)
# ps.print_stats()

# *** OR, CUSTOM formatting:
strip_path = os.getcwd() + "/"
custom_print_stats(pr, s, sortby, strip_path)



print(s.getvalue())

