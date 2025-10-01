function ssh_host_fingerprints
    for f in /etc/ssh/*.pub
        echo $f:
        echo "   $(ssh-keygen -lf $f)"
        log_blankline
    end
end

function ssh_bitbucket_known_hosts
    set url "https://bitbucket.org/site/ssh"
    begin
        echo "# $url"
        curl --fail-with-body -sSL "$url"
    end | bat -l known_hosts
end

function ssh_bitbucket_fingerprints
    # fingerprint for each known_host entry (public key)
    ssh_bitbucket_known_hosts | ssh-keygen -lf -
end

function ssh_github
    # PRN parse / extract fingerprints and/or known_hosts entries?
    set url "https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints"
    echo "both fingerprints and known_hosts entries:"
    echo "$url"
end
