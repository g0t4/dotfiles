ssh_local_sshd_fingerprints() {
    #! TODO port to fish
    for f in /etc/ssh/*.pub; do
        echo $f:
        echo "   $(ssh-keygen -lf $f)"
        echo
    done
}

ssh_bitbucket_known_hosts() {
    url="https://bitbucket.org/site/ssh"
    {
        echo "# $url"
        curl -fsSL "$url"
    } | bat -l known_hosts
}

ssh_bitbucket_fingerprints() {
    # fingerprint for each known_host entry (public key)
    ssh_bitbucket_known_hosts | ssh-keygen -lf -
}

ssh_github() {
    # PRN parse / extract fingerprints and/or known_hosts entries?
    url="https://docs.github.com/en/authentication/keeping-your-account-and-data-secure/githubs-ssh-key-fingerprints"
    echo "both fingerprints and known_hosts entries:"
    echo "$url"
}
