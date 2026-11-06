"""Platform-specific abbreviations that are manually maintained (NOT auto-synced).

These abbreviations differ between macOS and Linux in ways that are complex
enough that syncing them automatically from Fish is a waste of time.  They are
edited by hand here and in ``fish/load_last_interactive_only/platform-specific-not-migrated.fish``.

The OS is chosen via the xonsh globals ``$IS_MACOS`` / ``$IS_LINUX`` (set in
``rc.d/00-env.xsh``).  They live in the xonsh environment, so we read them from
``XSH.env`` (a ``$VAR`` reference is only available inside a ``.xsh`` file, not
a plain ``.py`` module).
"""

from __future__ import annotations

from xonsh.built_ins import XSH
from wes_abbreviations import abbr


def register_platform_specific_not_migrated():
    is_macos = XSH.env.get("IS_MACOS", False)
    is_linux = XSH.env.get("IS_LINUX", not is_macos)

    if is_linux:
        # lscpue
        abbr('lscpue', 'lscpu -e')
        abbr('lscpuon', 'lscpu -e --online')
        abbr('lscpuoff', 'lscpu -e --offline')

        # lspci
        abbr('lspcit', 'lspci -tv')
        abbr('lspcik', 'lspci -k')
        abbr('lspciu', 'lspci -k -d ::00xx')
        abbr('lspcii', 'lspci -k -d ::01xx')
        abbr('lspcin', 'lspci -k -d ::02xx')
        abbr('lspcig', 'lspci -k -d ::03xx')

        # lshw
        abbr('lshw', 'sudo lshw')
        abbr('lshws', 'sudo lshw -sanitize')
        abbr('lshwb', 'sudo lshw -businfo')
        abbr('lshwcd', 'sudo lshw -class display')
        abbr('lshwcn', 'sudo lshw -class network')
        abbr('lshwcs', 'sudo lshw -class storage')

        # lsmod
        abbr('lsmodg', "sudo lsmod | rg_grep -i '%'", cursor_marker="%")

        # lsmem
        abbr('lsmem', 'lsmem --output-all')

        # lsusb
        abbr('lsusb', 'lsusb -tv')
        abbr('lsusbv', 'lsusb -v')

        # dmesg
        abbr('dmesgg', "sudo dmesg | rg_grep -i '%'", cursor_marker="%")

    if is_macos:
        # map some abbrs so I can get similar info on my mac to what I am used to
        # using on linux/arch.  FYI these are just a first take, ok to change.
        abbr('sp', 'system_profiler')
        abbr('sp_list_datatypes', 'system_profiler -listDataTypes')
        abbr('lsusb', 'system_profiler SPUSBHostDataType')
        abbr('lspci', 'system_profiler SPPCIDataType')
        abbr('lscpu', 'sysctl -n machdep.cpu.brand_string; sysctl -n hw.physicalcpu; sysctl -n hw.logicalcpu')
        abbr('lsblk', 'diskutil list')
        abbr('dmidecode', 'system_profiler SPHardwareDataType')
        abbr('inxi', 'system_profiler SPHardwareDataType; system_profiler SPSoftwareDataType')
        abbr('hwinfo', 'system_profiler SPHardwareDataType')
        abbr('free', 'vm_stat')
        abbr('dmesg', "log show --predicate 'eventMessage contains \"kernel\"' --info --debug --last 1m")
    elif is_linux:
        abbr('lsblk_fs', 'lsblk --fs')
        abbr('lsblk_nvme', 'lsblk --nvme')
        abbr('lsblk_scsi', 'lsblk --scsi')
        abbr('lsblk_virtio', 'lsblk --virtio')
        abbr('lsblk_topology', 'lsblk --topology')
        abbr('fdisk_ls', 'sudo fdisk -l')
        abbr('fdisk_details', 'sudo fdisk -lx')
        abbr('findmnt_fstab', 'findmnt --fstab')
        abbr('findmnt_verify', 'findmnt --verify --verbose')
