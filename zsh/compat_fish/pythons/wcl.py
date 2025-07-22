import argparse
import os
import re
import subprocess
from rich import print

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

    if is_executable_present("zsh"):
        ### add dir to z ahead of cloning so I can CD to it while cloning
        # - or if dir already exists, then add to the stats count for it
        # - zsh's z (dir can be added before created)
        z_add_zsh = f"z --add '{repo_dir}'"
        # zsh -i => interactive which is where I load z command
        # check if zsh / * nix
        if dry_run:
            print(z_add_zsh, "\n")
        else:
            subprocess.run(["zsh", "-il", "-c", z_add_zsh], check=IGNORE_FAILURE)

    if os.path.isdir(repo_dir):
        print(f"repo_dir exists {repo_dir}, attempt pull latest", "\n")
        pull = ["git", "-C", repo_dir, "pull"]
        if dry_run:
            print(pull, "\n")
        else:
            subprocess.run(pull, check=IGNORE_FAILURE)
    else:
        clone_from = clone_url(parsed)
        print(f"# cloning [bold cyan]{clone_from}[reset]...")
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
            print(z_add_pwsh, "\n")
        else:
            subprocess.run(["pwsh", "-NoProfile", "-Command", z_add_pwsh], check=IGNORE_FAILURE)

    if is_executable_present("fish"):
        ### add to fish's z:
        # - dir must exist before adding
        # - fish has __z_add which uses $PWD hence set cwd
        # - fish doesn't need interactive for z to be loaded (installed in functions dir)
        # - FYI I had issues w/ auto-venv (calling deactivate) in fish but not zsh, so I am not using interactive for fish and I disabled auto-venv for non-interactive fish shells
        z_add_fish = ["fish", "-c", "__z_add"]
        if dry_run:
            print(z_add_fish, f"cwd={repo_dir}", "\n")
        else:
            subprocess.run(z_add_fish, cwd=repo_dir, check=IGNORE_FAILURE)

def is_executable_present(cmd) -> bool:
    if is_windows():
        return False

    result = subprocess.run(f"which {cmd}", shell=True, check=IGNORE_FAILURE, stdout=subprocess.DEVNULL)
    return result.returncode == 0

def clone_url(parsed) -> str:
    # probably don't recreate url if not a major player? (bitbucket, github, gitlab)
    # PRN don't recreate url if is https and want https?
    # PRN also any cases where I want more than org/repo dir structure?
    # todo multi level namespaces => https://git.kernel.org/pub/scm/linux/kernel/git/next/linux-next.git/
    use_https = parsed.domain in ["gitlab.gnome.org", "sourceware.org", "git.kernel.org", "huggingface.co", "git.sr.ht"]
    # TODO change to default to https and override for github and specific others where I want ssh
    if use_https:
        return f"https://{parsed.domain}/{parsed.repo}"
    if parsed.domain == "gcc.gnu.org":
        return parsed.url
    # prefer ssh for git repos (simple, standard, supports ssh auth), plus I've been using this forever now and it's been great.
    return f"git@{parsed.domain}:{parsed.repo}"

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
    return host + "/" + parsed.repo

class ParsedRepo:

    def __init__(self, domain, repo):
        if domain == "git.sv.gnu.org" or domain == "git.savannah.gnu.org":
            domain = "cgit.git.savannah.gnu.org"

        self.domain = domain
        self.repo = repo

    def __str__(self):
        return f"ParsedRepo(domain={self.domain}, repo={self.repo})"

def parse_repo(url: str) -> ParsedRepo | None:
    url = url.strip()

    from urllib.parse import urlparse

    # strip .git
    if url.endswith(".git"):
        url = url[:-4]

    # TODO turn http into https?

    if url.startswith("git@"):  # SSH URL
        # git@host:path/to/repo.git
        ssh_pattern = r"git@([^:]+):(.+)"
        match = re.match(ssh_pattern, url)
        if match:
            host, path = match.groups()
            return ParsedRepo(domain=host, repo=path)

    elif url.startswith("https://") or url.startswith("git://"):  # HTTPS or similar
        parsed = urlparse(url)
        path = parsed.path.lstrip("/")  # Remove leading '/'
        path = path.rstrip("/")  # Remove trailing '/' => wcl https://github.com/Hammerspoon/Spoons/

        # org/repo/blob/branch/path/to/file, strip blob+ (must have org/repo before blob)
        # PRN if it happens to be that a repo is named blob/tree then we have issues... on third+ component (fixed for 1/2)
        # TODO I should add checks for domain... and have diff logic based on # of namespace components allowed instead of just regex
        if re.search(r"[^/]+/[^/]+/(blob|tree|pulls|issues)(/|$)", path):
            path = re.sub(r"([^/]+/[^/]+)/(blob|tree|pulls|issues).*", "\\1", path)

        return ParsedRepo(domain=parsed.netloc, repo=path)

    # see if non-url passed and use defaults for github:
    if not re.search(r"\/", url):
        # repo name only (no slashes)
        #     "g0t4" => "github.com:g0t4/{url}"
        return ParsedRepo(domain="github.com", repo="g0t4/" + url)
    elif re.search(r"\/", url):
        # org/repo name only (one slash)
        #     "g0t4/dotfiles" => "github.com:g0t4/dotfiles"
        # or more levels too
        #
        return ParsedRepo(domain="github.com", repo=url)

    return None  # Unable to parse

def is_windows():
    return os.name == "nt"

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="(w)es (cl)one", prog="wcl")
    parser.add_argument("url", type=str, help="repository clone url")
    # --dry-run flag:
    parser.add_argument("--dry-run", action="store_true", help="preview changes")
    parser.add_argument("--path-only", action="store_true", help="return path (do not clone)")
    parsed_args = parser.parse_args()
    wcl(parsed_args)

# TODO add some tests that i can run on demand
