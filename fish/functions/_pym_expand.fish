function _pym_expand
    set file $argv[1]
    set extension (path extension $file)
    set module (string replace --all "/" "." (string trim --chars $extension $file))
    echo python3 -m $module
end

