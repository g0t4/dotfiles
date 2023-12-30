from sys import argv
import os
import re
import subprocess

# https://pypi.org/project/giturlparse/
#   pip3 install giturlparse
#   (careful there are several other similar named packages)
import giturlparse


def wcl(url: str):

    parsed = parse_repo(url)
    repos_dir = os.path.join(os.environ["HOME"], "repos")
    repo_dir = os.path.join(repos_dir, relative_repo_dir(parsed))
    org_dir = os.path.dirname(repo_dir)

    # ensure org dir exists (including parents)
    os.makedirs(org_dir, exist_ok=True)

    ### add dir to z ahead of cloning so I can CD to it while cloning
    # - or if dir already exists, then add to the stats count for it
    # - zsh's z (dir can be added before created)
    z_add_zsh = f"z --add '{repo_dir}'"
    # zsh -i => interactive which is where I load z command
    subprocess.run(['zsh', '-il', '-c', z_add_zsh])

    if os.path.isdir(repo_dir):
        print("repo_dir found, pulling latest")
        pull = ["git", "-C", repo_dir, "pull"]
        subprocess.run(pull)
    else:
        clone_from = clone_url(parsed)
        print(f"cloning {clone_from}...")
        clone = ["git", "clone", "--recurse-submodules", clone_from, repo_dir]
        subprocess.run(clone)

    ### add to fish's z:
    # - dir must exist before adding
    # - fish has __z_add which uses $PWD hence set cwd
    # - fish doesn't need interactive for z to be loaded (installed in functions dir)
    # - FYI I had issues w/ auto-venv (calling deactivate) in fish but not zsh, so I am not using interactive for fish and I disabled auto-venv for non-interactive fish shells
    subprocess.run(['fish', '-c', "__z_add"], cwd=repo_dir)


def clone_url(parsed) -> str:
    # prefer ssh for git repos (simple, standard, supports ssh auth), plus I've been using this forever now and it's been great.
    return f"git@{parsed.domain}:{parsed.owner}/{parsed.repo}"


def relative_repo_dir(parsed) -> str:
    return parsed.platform + "/" + parsed.owner + "/" + parsed.repo


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


if __name__ == "__main__":
    if len(argv) < 2:
        print("missing repository url")
        print(" usage: wcl <url>")
        exit(1)
    url = argv[1]
    wcl(url)
