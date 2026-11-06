# *** platform-specific abbreviations: manually maintained, NOT auto-synced to Xonsh
# These are intentionally platform-specific (macOS vs Linux) and complex enough
# that we no longer sync them automatically between Fish and Xonsh. Edit by hand.

# *** ls* abbrs
if $IS_LINUX then

    # lscpue
    abbr lscpue "lscpu -e" # table like extended view
    abbr lscpuon "lscpu -e --online"
    abbr lscpuoff "lscpu -e --offline"

    # lspci
    abbr lspcit "lspci -tv" # tree, verbose
    abbr lspcik "lspci -k" # show kernel drivers (compatible and in use)
    #
    # -d [<vendor>]:[<device>][:<class>]		Show only devices with specified ID's
    # classes: https://admin.pci-ids.ucw.cz/read/PD/
    abbr lspciu "lspci -k -d ::00xx" # unclassified
    abbr lspcii "lspci -k -d ::01xx" # storage
    abbr lspcin "lspci -k -d ::02xx" # network
    abbr lspcig "lspci -k -d ::03xx" # graphics

    # lsblk # PRN

    # lshw
    abbr lshw "sudo lshw"
    abbr lshws "sudo lshw -sanitize"
    abbr lshwb "sudo lshw -businfo"
    abbr lshwcd "sudo lshw -class display"
    abbr lshwcn "sudo lshw -class network"
    abbr lshwcs "sudo lshw -class storage"

    # lsmod
    abbr --set-cursor lsmodg "sudo lsmod | rg_grep -i '%'"

    # lsmem
    abbr lsmem "lsmem --output-all"

    # lspath
    # lstopo

    # lsusb
    abbr lsusb "lsusb -tv" # concise tree, a few more details
    abbr lsusbv "lsusb -v" # very detailed

    # dmesg
    abbr --set-cursor dmesgg "sudo dmesg | rg_grep -i '%'"

end

# TODO get rid of need to have these here too
if $IS_MACOS

    # map some abbrs so I can get similar info on my mac to what I am used to using on linux/arch
    # FYI these are just a first take, ok to change and/or nuke
    abbr sp "system_profiler"
    abbr sp_list_datatypes "system_profiler -listDataTypes"
    abbr lsusb "system_profiler SPUSBHostDataType" # FYI macos Tahoe renamed SPUSBDataType => SPUSBHostDataType
    abbr lspci "system_profiler SPPCIDataType"
    abbr lscpu "sysctl -n machdep.cpu.brand_string; sysctl -n hw.physicalcpu; sysctl -n hw.logicalcpu"
    abbr lsblk "diskutil list"
    abbr dmidecode "system_profiler SPHardwareDataType" # would just system_profiler make more sense here?
    abbr inxi "system_profiler SPHardwareDataType; system_profiler SPSoftwareDataType"
    abbr hwinfo "system_profiler SPHardwareDataType"
    abbr free vm_stat
    abbr dmesg "log show --predicate 'eventMessage contains \"kernel\"' --info --debug --last 1m"

else if $IS_LINUX
    abbr lsblk_fs "lsblk --fs"
    abbr lsblk_nvme "lsblk --nvme"
    abbr lsblk_scsi "lsblk --scsi"
    abbr lsblk_virtio "lsblk --virtio"

    abbr lsblk_topology "lsblk --topology"

    abbr fdisk_ls "sudo fdisk -l"
    abbr fdisk_details "sudo fdisk -lx"

    abbr findmnt_fstab "findmnt --fstab" # based on /etc/fstab (not necessarily loaded)
    abbr findmnt_verify "findmnt --verify --verbose" # will report warning if new fstab entries are not yet loaded, that is ok
end
