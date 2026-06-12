## Fish Shell

- Use snake_case for names
- Use long options, i.e. `--quiet` over `-q`, `--regex` over `-r`

Take advantage of fish-isms:
```fish

# use `not`, avoid `!`
if not test -f spoon
    echo There is no spoon
end

# capture command output and react to its success/failure (exit status)
if set some_output (some_command)
    echo "ok: $some_output"
else
    echo "fail: $some_output"
end

# prefer named arguments
function show_variable --argument-names name value
    echo "$name = $value"
end

# fish doesn't have heredocs, use mulit-line strings:
echo "foo
bar" | string join ","

# blocks combine the output of multiple commands:
begin
    echo -n "Hello Wes, the time is: "
    date
end > welcome.txt

# every variable is an array
set names wes john bob jane
for name in $names
    echo $name
end

string match '*.lua' $files
string replace wrong right $in_this_text
string replace --regex '\s+' ' ' $line
set lines (string split '\n' $text)
string join ',' $argv
string length $name

string escape $file_path
string unescape $escaped

path change-extension mov ./foo.mp4 # ./foo.mov
path sort 10-foo 2-bar # returns 2 before 10

math 10 / 5
math "5 * 2"

count *.txt

if contains -- "-q" $argv
    # ...
end

status filename # current script file
status function # current function
```
