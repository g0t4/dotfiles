

function to_human_bytes
    # FYI homebrew coreutils has numfmt ... I should try using it as needed, or at least wrap it here so I am not reinventing the wheel
    #   numfmt --from=si --to=iec-i 1024

    # thresholds to switch up to next unit (doesn't have to pass actual threshold of the unit, just be close such that a human would want to see a fraction of the next unit)
    #   perhaps do it at half way point 0.5x+? or any time over fraction of next theshold (ie fraction based on scale so 100B => 0.1x+ looks good too)
    set kb_threshold 1000
    set kib 1024
    set mb_threshold 1000000
    set mib 1048576
    set gb_threshold 1000000000
    set gib 1073741824
    set tb_threshold 1000000000000
    set tib 1099511627776

    set scale 2
    set --local bytes $argv[1]
    if test $bytes -lt $kb_threshold
        echo $bytes B
    else if test $bytes -lt $mb_threshold
        echo (math --scale $scale $bytes / $kib) K
    else if test $bytes -lt $gb_threshold
        echo (math --scale $scale $bytes / $mib) M
    else if test $bytes -lt $tb_threshold
        echo (math --scale $scale $bytes / $gib) G
    else
        echo (math --scale $scale $bytes / $tib) T
    end
end
