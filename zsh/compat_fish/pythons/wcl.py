import argparse
from sys import argv
import os
import re
import subprocess

# https://pypi.org/project/giturlparse/
#   pip3 install giturlparse
#   (careful there are several other similar named packages)
import giturlparse

# set a constant to name False (for subprocess.run) to make it more readable:
IGNORE_FAILURE = False
STOP_ON_FAILURE = True


def wcl(args):
    url: str = args.url
    dry_run: bool = args.dry_run
    path_only: bool = args.path_only

    parsed = parse_repo(url)
    home_dir = os.path.expanduser("~")
    repos_dir = os.path.join(home_dir, "repos")
    repo_dir = os.path.join(repos_dir, relative_repo_dir(parsed))
    org_dir = os.path.dirname(repo_dir)

    if path_only:
        print(repo_dir)
        return

    # ensure org dir exists (including parents)
    if dry_run:
        print("mkdir -p", org_dir, "\n")
    else:
        os.makedirs(org_dir, exist_ok=True)

    is_zsh_present = not is_windows()
    if is_zsh_present:
        ### add dir to z ahead of cloning so I can CD to it while cloning
        # - or if dir already exists, then add to the stats count for it
        # - zsh's z (dir can be added before created)
        z_add_zsh = f"z --add '{repo_dir}'"
        # zsh -i => interactive which is where I load z command
        # check if zsh / * nix
        if dry_run:
            print("# zsh z add:")
            print(z_add_zsh, "\n")
        else:
            subprocess.run(['zsh', '-il', '-c', z_add_zsh], check=IGNORE_FAILURE)

    if os.path.isdir(repo_dir):
        print("repo_dir found, attempt pull latest", "\n")
        pull = ["git", "-C", repo_dir, "pull"]
        if dry_run:
            print(pull, "\n")
        else:
            subprocess.run(pull, check=IGNORE_FAILURE)
    else:
        clone_from = clone_url(parsed)
        print(f"# cloning {clone_from}...")
        clone = ["git", "clone", "--recurse-submodules", clone_from, repo_dir]
        if dry_run:
            print(clone, "\n")
        else:
            subprocess.run(clone, check=STOP_ON_FAILURE)


    is_pwsh_present = is_windows()
    if is_pwsh_present:
        # dir must exist b/c I am just using z command to add the path (AFAICT there is no --add arg in pwsh version and even if it existed, so in the future, check to see if it works like fish version and requires the path to exist)
        # could rework z add to before repo clone if I create dir before cloning it (letting git currently create the dir)
        # ok and now the issue is z in current pwsh won't reload database so... this is almost pointless to add the path in pwsh (unless I wanna not change to it and want to do that later in a new pwsh shell)
        # PRN perhaps add pwsh z wrapper like fish shell... that adds some logic to cd to cloned repos first before calling underlying z command... that would mean I don't even need the repo paths in z command history b/c they would always be a match before anything else in z history is tried

        z_add_pwsh = f"z '{repo_dir}'"

        if dry_run:
            print("# pwsh z add:")
            print(z_add_pwsh, "\n")
        else:
            subprocess.run(['pwsh', '-NoProfile', '-Command', z_add_pwsh], check=IGNORE_FAILURE)

    is_fish_present = not is_windows()
    if is_fish_present:
        ### add to fish's z:
        # - dir must exist before adding
        # - fish has __z_add which uses $PWD hence set cwd
        # - fish doesn't need interactive for z to be loaded (installed in functions dir)
        # - FYI I had issues w/ auto-venv (calling deactivate) in fish but not zsh, so I am not using interactive for fish and I disabled auto-venv for non-interactive fish shells
        z_add_fish = ['fish', '-c', "__z_add"]
        if dry_run:
            print("# fish z add:")
            print(z_add_fish, f"cwd={repo_dir}","\n")
        else:
            subprocess.run(z_add_fish, cwd=repo_dir, check=IGNORE_FAILURE)


def clone_url(parsed) -> str:
    # probably don't recreate url if not a major player? (bitbucket, github, gitlab)
    # PRN don't recreate url if is https and want https?
    # PRN also any cases where I want more than org/repo dir structure?
    use_https = parsed.domain in ["gitlab.gnome.org","sourceware.org"]
    # TODO change to default to https and override for github and specific others where I want ssh
    if use_https:
        return f"https://{parsed.domain}/{parsed.owner}/{parsed.repo}"
    if parsed.domain == "gcc.gnu.org":
        return parsed.url
    # prefer ssh for git repos (simple, standard, supports ssh auth), plus I've been using this forever now and it's been great.
    return f"git@{parsed.domain}:{parsed.owner}/{parsed.repo}"


def relative_repo_dir(parsed) -> str:
    # BTW for major players, I am dropping TLD (.com, .org)... everyone else includes it (i.e. nginx.org, sourceware.org, etc.)
    host = parsed.domain
    if host == "github.com":
        host = "github"
    elif host == "gitlab.com":
        host = "gitlab"
    elif host == "bitbucket.org":
        host = "bitbucket"
    # switch to host b/c platform is not the same as host, i.e. sourceware.org has gitlab as platform (IIGC that is the underlying private host that it runs, but I want repos organized based on domain they are hosted on)... in many cases platform==host so that is why that originally worked but no longer suffices.
    return host + "/" + parsed.owner + "/" + parsed.repo


def parse_repo(url: str):

    url = url.strip()

    p = giturlparse.parse(url, check_domain=True)
    if p.valid:
        return p

    # see if non-url passed and use defaults for github:
    if not re.search(r"\/", url):
        # repo name only (no slashes)
        #     "g0t4" => "github.com:g0t4/{url}"
        url = f"git@github.com:g0t4/{url}.git"
    elif re.search(r"\/", url):
        # org/repo name only (one slash)
        #     "g0t4/dotfiles" => "github.com:g0t4/dotfiles"
        url = f"git@github.com:{url}.git"

    p = giturlparse.parse(url)
    # PRN raise on `not p.valid`
    return p

    # p.url = 'git@github.com:g0t4/dotfiles'
    # p.domain = 'github.com'
    #   p.platform = 'github'
    # p.owner = 'g0t4'
    #   p.repo = 'dotfiles'
    #   p.pathname = 'g0t4/dotfiles'
    # p._user = 'git'
    #   p.protocol = 'ssh'
    # dump p obj nicely formatted:
    # pprint.pprint(vars(p))
    # docs lists attrs nicely:
    #   https://pypi.org/project/giturlparse/
    #   https://github.com/nephila/giturlparse

def is_windows():
    return os.name == 'nt'

if __name__ == "__main__":

    parser = argparse.ArgumentParser(description="(w)es (cl)one", prog="wcl")
    parser.add_argument("url", type=str, help="repository clone url")
    # --dry-run flag:
    parser.add_argument("--dry-run", action="store_true", help="preview changes")
    parser.add_argument("--path-only", action="store_true", help="return path (do not clone)")
    parsed_args = parser.parse_args()
    wcl(parsed_args)


# TODO add some tests that i can run on demand