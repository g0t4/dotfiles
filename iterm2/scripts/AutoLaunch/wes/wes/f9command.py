import asyncio
import iterm2
import re
from dataclasses import dataclass
from common import get_current_session, NOOP
from logs import log
from timing import Timer
from typing import Callable, Awaitable


async def forward_f9(session):
    await session.async_send_text("\x1b[20~")


# inspired by my F8-F11 bindings in neovim
# F8 `:q` close window (equivalent to a tab normally)
# F9 quit neovim (quit all) `:qa`
# F10 = restart neovim (:qa => nvim)
# F11 = restart + run last command (great for rapidly testing a command/line)


@dataclass(frozen=True, slots=True)
class RunningInfo:
    # use pascalCase to match iterm2 names
    deepestJob: str
    jobName: str  # only use jobName again if issues with new deepestJob
    commandLine: str
    session: iterm2.Session

    @classmethod
    async def get_whats_running(cls, session):
        return RunningInfo(
            deepestJob=await session.async_get_variable("deepestJob") or "",
            jobName=await session.async_get_variable("jobName") or "",
            commandLine=await session.async_get_variable("commandLine") or "",
            session=session,
        )

    async def refresh(self):
        """
        Return what is runnign now as new RunningInfo object
        new instance encourages before/after comparisons instead of replacing prior values
        """
        return RunningInfo(
            deepestJob=await self.session.async_get_variable("deepestJob") or "",
            jobName=await self.session.async_get_variable("jobName") or "",
            commandLine=await session.async_get_variable("commandLine") or "",
            session=self.session,
        )

    def is_nvim(self):
        return self.deepestJob == "nvim"

    def is_xonsh(self):
        if re.match("python.*xonsh", self.commandLine):
            return True
        return self.deepestJob == "xonsh"

    def is_python(self):
        # FYI can be versioned like python3.14
        # btw sometimes xonsh is running via python3.14
        if self.is_xonsh():
            # do not mark both python and xonsh, if it is xonsh then not python for control purposes
            return False
        return self.deepestJob.startswith("python")

    def __repr__(self):
        parts = []
        if self.is_nvim():
            parts.append("is_nvim")
        if self.is_xonsh():
            parts.append("is_xonsh")
        if self.is_python():
            parts.append("is_python")
        parts.append(f"deepestJob={self.deepestJob}")
        parts.append(f"jobName={self.jobName}")
        parts.append(f"commandLine={self.commandLine}")
        return f"<RunningInfo {', '.join(parts)}>"


async def on_f9(connection: iterm2.Connection, then: Callable[[RunningInfo], Awaitable[None]] | None = None):
    then = then or NOOP
    # this started out with how I use F9 to quit nvim
    #   might be nice to F9 nvim and F9 again to close iterm pane (not all of iterm though)
    #   yes, F9 quits nvim but it only quits the instance in the current pane (thus F9 to close pane)

    session = await get_current_session(connection)
    if session is None:
        return

    # if deepestJob in ["ssh"]:
    #   # this fucks over f9 to quit nvim remotely... obviously... but leave it off for now
    #   # assume safe to ctrl+d only (won't work if nested commands on remote... TBD)
    #     await session.async_send_text("\x04")  # ctrl+d (exit)
    #     log(f"ssh is not a reliable jobName to decide what to use to F9 remotely {deepestJob=} {jobName=}")
    #     return

    running = await RunningInfo.get_whats_running(session)
    log(f"on_f9 {running=}")

    if running.is_nvim():
        # send to neovim to handle it
        # await session.async_send_text(":qa\r")
        # send F9 to neovim...
        await forward_f9(session)
        await then(running)
        return
    if running.deepestJob in ["fish", "bash", "zsh", "xonsh", "Python", "lldb", "gdb", "codex"] \
      or running.is_xonsh() \
      or running.is_python():
        # shell command line must be empty to quit
        await session.async_send_text("\x03")  # ctrl+c (clear)
        await session.async_send_text("\x04")  # ctrl+d (exit)
        await then(running)
        return
    if running.deepestJob == "zellij":
        await session.async_send_text("\x11")  # ctrl+q
        await then(running)
        return
    # if deepestJob in ["ssh"]:
    #   # this fucks over f9 to quit nvim remotely... obviously... but leave it off for now
    #   # assume safe to ctrl+d only (won't work if nested commands on remote... TBD)
    #     await session.async_send_text("\x04")  # ctrl+d (exit)
    #     log(f"ssh is not a reliable jobName to decide what to use to F9 remotely {deepestJob=} {jobName=}")
    #     return

    await forward_f9(session)
    await then(running)
    log(f"fallback => forward F9, current executable not mapped to explicit action: {running=}")


async def on_f10(connection: iterm2.Connection, then: Callable[[RunningInfo], Awaitable[None]] | None = None):
    then = then or NOOP

    # restart app
    session = await get_current_session(connection)
    if session is None:
        return

    running = await RunningInfo.get_whats_running(session)
    log(f"on_f10 {running=}")

    if running.is_xonsh():
        # have to use wes_replace_pane for proper order else will lose window (possibly)
        from split import wes_replace_pane
        await wes_replace_pane(connection, then=lambda: then(running))
        return

    async def after_quit(was_running: RunningInfo):
        log(f'{was_running=}')
        if was_running.is_nvim():

            async def after_neovim_quits():
                await session.async_send_text("nvim\n")

            for _ in range(1, 30):
                await asyncio.sleep(0.1)
                running = await RunningInfo.get_whats_running(session)
                if running.deepestJob != "nvim":
                    await after_neovim_quits()
                    await then(was_running)
                    break
            return

        # # TODO! if top level shell is the only one then I need this to behave more like restart pane does
        # # for now lets have it refuse if there is no child process?
        # # see logic in wes_replace_pane
        #
        # if running.deepestJob in ["fish", "bash", "zsh", "xonsh", "Python", "lldb", "gdb", "codex"] \
        #   or running.is_python():
        #     # shell command line must be empty to quit
        #     await session.async_send_text("\x03")  # ctrl+c (clear)
        #     await session.async_send_text("\x04")  # ctrl+d (exit)
        #     return
        # if running.deepestJob == "zellij":
        #     await session.async_send_text("\x11")  # ctrl+q
        #     return
        #
        # TODO if is now a shell => then use up arrow to re-run? arguably this would be better for restarting neovim in case I had special args passed
        # await was_running.session.async_send_text("\x1b[A\r")

    await on_f9(connection, after_quit)


async def on_f11(connection: iterm2.Connection):
    """Restart the app and re‑run the last command."""

    session = await get_current_session(connection)
    if session is None:
        return

    async def after_restart(was_running: RunningInfo):
        # TODO callers should pass new running info?
        log(f'after_restart {was_running=}')

        if was_running.is_xonsh():
            await asyncio.sleep(1) # if you send arrow too soon the prompt won't be ready to up into history... so just wait
            # TODO check for shell integration status to know when it is safe to send arrow?
            session = await get_current_session(connection)
            if not session:
                log("NO SESSION found after xonsh restarted... WTF did you shut down iterm?")
                return
            await session.async_send_text("\x1b[A\r")
            return

        if was_running.is_nvim():

            async def after_neovim_starts():
                # BTW no sleep is needed in my testing... but it feels too fast (never failed) w/o this
                await asyncio.sleep(0.1)  # slight pause for neovim to load (could check smth to decide but this feels ok)
                #
                # : => commandline mode => up arrow to get last command => \r to run it
                await was_running.session.async_send_text(":\x1b[A\r")

            for _ in range(1, 30):
                await asyncio.sleep(0.1)
                running = await RunningInfo.get_whats_running(session)
                if running.deepestJob == "nvim":
                    await after_neovim_starts()
                    break
            return

    log(f"on_f11")

    # await after_restart(await RunningInfo.get_whats_running(session)) # test w/o restart
    await on_f10(connection, after_restart)  # restart app and run last command (app specific meaning)
