## Fish Shell Code Preferences

- Use snake_case for functions and variables.
- When a condition is ambiguous, assign it to a well‑named variable before the `if`.
- Prefer long options, i.e. `--quiet` over `-q`, `--regex` over `-r`
- Fish shell does not do word splitting like bash, no need to wrap everything in quotes!

## Fish syntax examples

```fish
# exploit fish-isms!

# use `not`, avoid `!`
if not test -f spoon
    echo There is no spoon
    exit 1
end

# if + set
if set -l message (some_command)
    echo "ok: $message"
else
    echo "fail: $message"
end

# prefer named arguments
function show_variable -a name value
    echo "$name = $value"
end

# fish doesn't have heredocs, use begin/end
begin
    echo $header
    echo $table
end > out.html
# or multi-line strings
echo "
foo
bar
" > test

# every variable is an array
set names wes john bob jane
for name in $names
    echo $name
end

for i in *.tmp
    if grep DONE $i
        break
    end
    if grep SKIP $i
        continue
    end
    ...
end

# combine conditions
while test -f foo.txt; or test -f bar.txt
    ...
end

# conditional execution
make; and make install; or make clean
```

### builtin fish commands

Now that we have more than 2KB of system RAM, we can fix most of what sucks about bash...

```fish
# *** string command

# match: test, filter, extract
string match --quiet '*.lua' $file
set lua_files (string match '*.lua' $files)
set version (string match --regex 'v([0-9.]+)' $tag)
string match --index --regex 'ERROR' $line

# replace: transform text
set fixed (string replace foo bar $text)
set cleaned (string replace --regex '\s+' ' ' $line)
set base (string replace --regex '\.[^.]+$' '' $file)
set normalized (string replace --filter --regex '^./' '' $paths)

# split: tokenize
set parts (string split ':' $PATH)
set lines (string split '\n' $text)
set ext (string split --right --max 1 . $file)[2]

# trim: clean edges
set clean (string trim $line)
set unquoted (string trim --chars '"' $s)

# join: build strings
string join ' ' $argv
string join --no-empty ':' $PATH

# length and slicing
string length $name
string sub --start 2 --length 4 $word
string sub --start -5 $word

# case conversion
set key (string lower $key)
set name (string upper $name)

# shell-safe encoding
set escaped (string escape $path)
string unescape $escaped

# normalize piped output
set text (some_command | string collect)


# path command
path basename foo/bar.txt # bar.txt
path basename --no-extension foo/bar.txt # bar
path dirname foo/bar.txt # foo
path extension ./foo.mp4 # .mp4
path change-extension mov ./foo.mp4 # ./foo.mov

path normalize path/to//hello.txt # path/to/hello.txt
path normalize path/to/../hello.txt # path/hello.txt
# resolve = normalize + absolute path and follow symlinks
path resolve foo  # /home/wes/foo

path sort 10-foo 2-bar
# 2-bar
# 10-foo


# math command
math [(-s | --scale) N] [(-b | --base) BASE] [(-m | --scale-mode) MODE] EXPRESSION ...
math 10 / 6
math $status - 128
math "5 * 2"
math "sin(pi)"
math max 5,2,3,1


# count STRING1 STRING2 ...
# COMMAND | count
# count [...] < FILE
count $PATH
count *.txt
git ls-files --others --exclude-standard | count
printf '%s\n' foo bar | count baz # Returns 3 (2 lines from stdin plus 1 argument)
count < /etc/hosts # number of entries in hosts file


# contains [OPTIONS] KEY [VALUES ...]
if contains -- -q $argv
    echo '$argv contains a -q option'
end

# scripts
status filename # current running script
status basename
status dirname
status function # current function name
status line-number
status stack-trace

```
