"""Xonsh port of fish/load_last_interactive_only/prompt.fish."""

import getpass
import os
import re
import shutil
import signal
import socket
import subprocess

# from wes_logging import get_logger
# log = get_logger("prompt")


_prompt_state = {
    "command_generation": 0,
    "displayed_generation": 0,
    "statuses": [],
    "show_status": False,
    "failure_streak": 0,
    "show_failure_assist": False,
}


def _prompt_flag(name):
    """Accept both the original Fish-style name and an uppercase Xonsh name."""
    return bool(${...}.get(name) or ${...}.get(name.upper()))


def _prompt_repo_info(cwd):
    """Return (repo root, prefix within repo), falling back to cwd."""
    if shutil.which("git"):
        result = subprocess.run(
            ["git", "-C", cwd, "rev-parse", "--show-toplevel", "--show-prefix"],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            lines = result.stdout.splitlines()
            if lines:
                return os.path.realpath(lines[0]), (lines[1] if len(lines) > 1 else "").rstrip("/")

    if shutil.which("hg"):
        result = subprocess.run(
            ["hg", "--cwd", cwd, "root"], capture_output=True, text=True
        )
        if result.returncode == 0:
            root = os.path.realpath(result.stdout.strip())
            relative = os.path.relpath(cwd, root)
            return root, "" if relative == "." else relative

    return cwd, ""


def _prompt_verbose_pwd(cwd):
    repo_root, prefix = _prompt_repo_info(cwd)
    match = re.match(r"(?P<host_dir>.*/(?:bitbucket|github|gitlab))/(?P<repo>.*)", repo_root)

    if match:
        value = (
            "{RESET}"
            + match.group("host_dir")
            + "/{CYAN}"
            + match.group("repo")
        )
    else:
        value = "{RESET}" + repo_root

    if prefix:
        value += "/{YELLOW}" + prefix
    return value


def _prompt_login():
    if _prompt_flag("wes_recording_youtube_shorts_need_small_prompt"):
        return ""

    # parts = ["🪣"]
    # parts = ["🐽"]
    parts = []
    virtual_env = ${...}.get("VIRTUAL_ENV")
    if virtual_env:
        parts.append("{CYAN}\ue73c")
        if _prompt_flag("show_verbose_prompt"):
            parent = os.path.basename(os.path.dirname(virtual_env))
            base = os.path.basename(virtual_env)
            parts.append(f" ({parent}/{base})")
        parts.append("{RESET} ")

    hostname = socket.gethostname()
    if _prompt_flag("show_verbose_prompt"):
        parts.append(f"{getpass.getuser()}@{hostname}")
        return "".join(parts)

    if hostname.startswith("mbp"):
        if ${...}.get("SSH_CONNECTION"):
            parts.append("{CYAN}󰌘 {RESET}")
        parts.append("mac")
    else:
        parts.append(re.sub(r"\.(?:lan|local)$", "", hostname))
    return "".join(parts)


def _prompt_pwd():
    if _prompt_flag("wes_recording_youtube_shorts_need_small_prompt"):
        return ""

    cwd = os.path.realpath(os.getcwd())
    home = os.path.realpath(os.path.expanduser("~"))

    if _prompt_flag("show_verbose_prompt"):
        return _prompt_verbose_pwd(cwd)

    color = "{RED}" if os.geteuid() == 0 else "{GREEN}"

    hf_base = os.path.join(home, "repos/huggingface.co")
    if cwd.startswith(hf_base + os.sep):
        return color + "hf:" + os.path.relpath(cwd, hf_base)

    ask_base = os.path.join(home, "repos/github/g0t4/datasets/ask_traces")
    if cwd.startswith(ask_base + os.sep):
        relative = os.path.relpath(cwd, ask_base)
        category, separator, rest = relative.partition(os.sep)
        return color + category + ((":" + rest) if separator else "")

    if cwd == os.path.join(home, "repos/github/g0t4/course-ansible-admin"):
        return color + "course"
    private_repo_prefix = os.path.join(home, "repos/github/g0t4/private")
    if cwd.startswith(private_repo_prefix):
        # shows as PRIVATE-foo-repo/bar/baz so it is always clear where I am at but also never loses PRIVATE label
        return color + "PRIVATE" + cwd[len(private_repo_prefix):]

    repo_root, prefix = _prompt_repo_info(cwd)
    if not prefix and re.match(r".*/(?:bitbucket|github|gitlab)/.+", repo_root):
        host_marker = re.search(r"/(?:bitbucket|github|gitlab)/", repo_root)
        return "{CYAN}" + repo_root[host_marker.end():]

    if cwd == home:
        return color + "~"
    return color + os.path.basename(cwd)


def _prompt_signal_name(return_code):
    signum = -return_code if return_code < 0 else return_code - 128
    if 0 < signum < signal.NSIG:
        try:
            return signal.Signals(signum).name
        except ValueError:
            pass
    return str(return_code)


def _prompt_status():
    if not _prompt_state["show_status"]:
        return ""

    rendered = []
    for status in _prompt_state["statuses"]:
        value = _prompt_signal_name(status) if status < 0 or status > 128 else str(status)
        color = "{RED}" if status == 0 else "{BOLD_RED}"
        rendered.append(color + value)
    return "{RED}[" + "{RED}|".join(rendered) + "{RED}]{RESET}\n"


def _prompt_failure_assist():
    if not _prompt_state["show_failure_assist"]:
        return ""
    if not ${...}.get("XONSH_AI_AUTOSUGGEST", True):
        return ""
    return "{INTENSE_BLACK}◌ two commands failed in a row — want help?{RESET}\n"


def _prompt_ai_snout():
    if not ${...}.get("XONSH_AI_AUTOSUGGEST", True):
        return " @"
    return " 🐽"


def _prompt_pipeline_status(rtn, cmd):
    pipeline = getattr(__xonsh__, "lastcmd", None)
    statuses = list(getattr(pipeline, "pipestatus", []) or [])
    # Python commands leave the previous subprocess pipeline in lastcmd.
    if "|" not in cmd or not statuses:
        statuses = [rtn]
    return [rtn if status is None else status for status in statuses]


@events.on_postcommand
def _wes_prompt_record_status(cmd, rtn, **_):
    _prompt_state["command_generation"] += 1
    _prompt_state["statuses"] = _prompt_pipeline_status(rtn, cmd)
    failed = any(status != 0 for status in _prompt_state["statuses"])
    _prompt_state["failure_streak"] = (
        _prompt_state["failure_streak"] + 1 if failed else 0
    )


@events.on_pre_prompt_format
def _wes_prompt_choose_status(**_):
    generation = _prompt_state["command_generation"]
    is_new_command = generation != _prompt_state["displayed_generation"]
    _prompt_state["show_status"] = is_new_command and any(
        status != 0 for status in _prompt_state["statuses"]
    )
    _prompt_state["show_failure_assist"] = (
        is_new_command and _prompt_state["failure_streak"] >= 2
    )
    _prompt_state["displayed_generation"] = generation


$PROMPT_FIELDS["wes_status"] = _prompt_status
$PROMPT_FIELDS["wes_failure_assist"] = _prompt_failure_assist
$PROMPT_FIELDS["wes_login"] = _prompt_login
$PROMPT_FIELDS["wes_pwd"] = _prompt_pwd
$PROMPT_FIELDS["wes_ai_snout"] = _prompt_ai_snout

# iTerm2's rc.d integration wraps this with its OSC 133 prompt markers.
$PROMPT = "{wes_status}{wes_failure_assist}{wes_login} {wes_pwd}{RESET}{wes_ai_snout} "
$RIGHT_PROMPT = ""
$TITLE = "{user}"

# iterm2.xsh always exposes its helper object, including on unsupported or
# non-iTerm terminals. Only wrap when it actually registered the OSC fields.
if bool(${...}.get("ITERM2_INTEGRATION", False)) and hasattr(__xonsh__, "iterm2"):
    __xonsh__.iterm2.add_iterm2_to_prompt()
