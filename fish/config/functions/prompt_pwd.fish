function prompt_pwd --description 'wes mod - name of the current dir only'
    # PRN flush out other scenarios like I have with ~/repos/github/g0t4/foo => gh:g0t4/foo
    basename $PWD
end
