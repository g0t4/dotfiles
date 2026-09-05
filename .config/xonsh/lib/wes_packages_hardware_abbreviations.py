"""Packages Hardware abbreviations generated from Fish misc-specific.fish."""

from __future__ import annotations

import platform
import re

from wes_abbreviations import abbr
from wes_misc_abbreviation_bridge import (
    fish_abbreviation,
    platform_abbreviation,
)


MAN_COMMAND = "gman" if platform.system() == "Darwin" else "man"

FISH_FUNCTIONS = (
    'dpkg_L_files',  # Fish line 1194
    'dpkg_L_tree',  # Fish line 1200
    'treeify',  # Fish line 1208
    'watch',  # Fish line 1219
    'viddy',  # Fish line 1230
    '_expand_watch_last',  # Fish line 1247
    'wordcount',  # Fish line 1281
    'yq_diff_docs',  # Fish line 1294
    'tellme_about',  # Fish line 1329
    '_indent',  # Fish line 1346
    'npm_install',  # Fish line 2040
    'npx',  # Fish line 2088
    'bitmaths',  # Fish line 2135
    'pretty_size',  # Fish line 2157
    'manlistX',  # Fish line 2196
    'show_hex_rgb_color',  # Fish line 2298
    'treeify_with_icons',  # Fish line 2529
    '__pactree_depth',  # Fish line 2578
    'zedraw',  # Fish line 2627
    'zedfull',  # Fish line 2636
    'trash',  # Fish line 2655
    '_fish_from_source',  # Fish line 2679
)


def register_packages_hardware_abbreviations():
    abbr('apts', 'apt search')  # Fish line 1181
    abbr('apti', 'sudo apt install')  # Fish line 1182
    abbr('aptu', 'sudo apt update')  # Fish line 1183
    abbr('aptug', 'sudo apt upgrade')  # Fish line 1184
    abbr('aptl', 'apt list --installed')  # Fish line 1186
    abbr('aptlu', 'apt list --upgradable')  # Fish line 1187
    abbr('aptcm', 'apt-cache madison')  # Fish line 1189
    abbr('dpkgL', 'dpkg -L')  # Fish line 1191
    abbr('dpkgS', 'dpkg -S')  # Fish line 1192
    abbr('watch', '$WATCH_COMMAND')  # Fish line 1245
    abbr('watch_last', fish_abbreviation('_expand_watch_last'))  # Fish line 1252
    abbr('wa', '$WATCH_COMMAND')  # Fish line 1254
    abbr('wag', '$WATCH_COMMAND --no-title -- grc --colour=on')  # Fish line 1256
    abbr('wak', '$WATCH_COMMAND --no-title -- grc --colour=on kubectl get --show-kind')  # Fish line 1261
    abbr('wad', '$WATCH_COMMAND --no-title -- grc --colour=on kubectl describe --show-kind')  # Fish line 1262
    abbr('wakp', '$WATCH_COMMAND --no-title -- grc --colour=on kubectl get --show-kind pods')  # Fish line 1263
    abbr('wah', '$WATCH_COMMAND --no-title -- http --pretty=colors')  # Fish line 1264
    abbr('wahv', '$WATCH_COMMAND --no-title -- http --pretty=colors --verbose')  # Fish line 1265
    abbr('wal', '$WATCH_COMMAND --no-title -- grc --colour=on ls')  # Fish line 1266
    abbr('wat', '$WATCH_COMMAND --no-title -- grc --colour=on tree')  # Fish line 1267
    abbr('wc', 'wordcount')  # Fish line 1280
    abbr('pyqi', "| yq eval 'select(documentIndex == 1) | .status'")  # Fish line 1290
    abbr('pyqp', '| yq -P')  # Fish line 1291
    abbr('_reminders_docker_binfmts', 'docker run --privileged --rm tonistiigi/binfmt')  # Fish line 1322
    abbr('npmi', 'npm_install')  # Fish line 2056
    abbr('npminit', 'npm init -y')  # Fish line 2057
    abbr('npml', 'npm list')  # Fish line 2058
    abbr('npmr', 'npm run')  # Fish line 2059
    abbr('npmt', 'npm test')  # Fish line 2060
    abbr('npma', 'npm audit')  # Fish line 2061
    abbr('npmv', 'npm version')  # Fish line 2062
    abbr('npms', 'npm start')  # Fish line 2063
    abbr('npmo', 'npm outdated')  # Fish line 2064
    abbr('npmun', 'npm uninstall')  # Fish line 2065
    abbr('npmup', 'npm update')  # Fish line 2066
    abbr('npxr', 'npx run')  # Fish line 2068
    abbr('ts', 'tree-sitter')  # Fish line 2077
    abbr('tsg', 'tree-sitter generate')  # Fish line 2078
    abbr('tsb', 'tree-sitter build')  # Fish line 2079
    abbr('tsp', 'tree-sitter parse')  # Fish line 2080
    abbr('tst', 'tree-sitter test')  # Fish line 2081
    abbr('tsq', 'tree-sitter query')  # Fish line 2082
    abbr('tsh', 'tree-sitter highlight')  # Fish line 2083
    abbr('tsplayground', 'tree-sitter playground')  # Fish line 2084
    abbr('bm', 'bitmaths')  # Fish line 2134
    abbr('man', 'gman')  # Fish line 2184
    abbr('man_commands_1', '$XONSH_MAN_COMMAND 1')  # Fish line 2186
    abbr('man_syscalls_2', '$XONSH_MAN_COMMAND 2')  # Fish line 2187
    abbr('man_c_stdlib_3', '$XONSH_MAN_COMMAND 3')  # Fish line 2188
    abbr('man_kernel_interfaces_4', '$XONSH_MAN_COMMAND 4')  # Fish line 2189
    abbr('man_file_formats_5', '$XONSH_MAN_COMMAND 5')  # Fish line 2190
    abbr('man_misc_7', '$XONSH_MAN_COMMAND 7')  # Fish line 2191
    abbr('man_system_8', '$XONSH_MAN_COMMAND 8')  # Fish line 2192
    abbr('man_kernel_dev_9', '$XONSH_MAN_COMMAND 9')  # Fish line 2193
    abbr(re.compile('manlist[0-9]'), fish_abbreviation('manlistX'))  # Fish line 2195
    abbr('man1', '$XONSH_MAN_COMMAND 1')  # Fish line 2200
    abbr('man2', '$XONSH_MAN_COMMAND 2')  # Fish line 2201
    abbr('man3', '$XONSH_MAN_COMMAND 3')  # Fish line 2202
    abbr('man4', '$XONSH_MAN_COMMAND 4')  # Fish line 2203
    abbr('man5', '$XONSH_MAN_COMMAND 5')  # Fish line 2204
    abbr('man6', '$XONSH_MAN_COMMAND 6')  # Fish line 2205
    abbr('man7', '$XONSH_MAN_COMMAND 7')  # Fish line 2206
    abbr('man8', '$XONSH_MAN_COMMAND 8')  # Fish line 2207
    abbr('man9', '$XONSH_MAN_COMMAND 9')  # Fish line 2208
    abbr('mana', '$XONSH_MAN_COMMAND --all --regex')  # Fish line 2211
    abbr('mank', 'apropos')  # Fish line 2212
    abbr('manf', 'whatis')  # Fish line 2213
    abbr('-K', '--global-apropos', position="anywhere", commands=(MAN_COMMAND,))  # Fish line 2218
    abbr('-k', '--apropos', position="anywhere", commands=(MAN_COMMAND,))  # Fish line 2219
    abbr('-w', '--where', position="anywhere", commands=(MAN_COMMAND,))  # Fish line 2221
    abbr('-a', '--all', position="anywhere", commands=(MAN_COMMAND,))  # Fish line 2222
    abbr('manK', '$XONSH_MAN_COMMAND -K')  # Fish line 2230
    abbr('manw', '$XONSH_MAN_COMMAND --where -K')  # Fish line 2231
    abbr('mgr', '$XONSH_MAN_COMMAND -K')  # Fish line 2234
    abbr('mgrw', '$XONSH_MAN_COMMAND --where -K')  # Fish line 2235
    abbr('manbash', '$XONSH_MAN_COMMAND $HOME/repos/github/g0t4/bash/doc/bash.1')  # Fish line 2239
    abbr('mbash', '$XONSH_MAN_COMMAND $HOME/repos/github/g0t4/bash/doc/bash.1')  # Fish line 2241
    abbr('mitm', 'mitmproxy')  # Fish line 2257
    abbr('mitml', 'mitmproxy --mode=local')  # Fish line 2258
    abbr('mitmw', 'mitmweb')  # Fish line 2260
    abbr('mitmwl', 'mitmweb --mode=local')  # Fish line 2261
    abbr('mitmd', 'mitmdump --mode=local')  # Fish line 2263
    abbr('mitmdl', 'mitmdump --mode=local')  # Fish line 2264
    abbr('mitmr', 'mitmproxy --no-server --rfile')  # Fish line 2267
    abbr('mitm_pgrep', 'pgrep -ilf mitmproxy | rg_grep -v "\\--no-server" || true')  # Fish line 2272
    abbr('mitm_kill', 'pgrep -ilf mitmproxy | rg_grep -v "\\--no-server" | awk \'{print $1}\' | xargs sudo kill -9 || true')  # Fish line 2273
    abbr('mitmlc', "mitmproxy --mode=local:'Visual Studio Code.app'")  # Fish line 2276
    abbr('mitmlci', "mitmproxy --mode=local:'Visual Studio Code - Insiders.app'")  # Fish line 2277
    abbr('mitmlcurl', "mitmproxy --mode=local:'curl'")  # Fish line 2278
    abbr('mitms', 'mitmproxy --scripts')  # Fish line 2280
    abbr('mitmsave', 'mitmproxy --save-stream-file')  # Fish line 2281
    abbr('lr', 'luarocks')  # Fish line 2467
    abbr('lrll', 'luarocks list --local')  # Fish line 2469
    abbr('lrl1', 'luarocks list --lua-version=5.1 --local')  # Fish line 2470
    abbr('lrl4', 'luarocks list --lua-version=5.4 --local')  # Fish line 2471
    abbr('lrl5', 'luarocks list --lua-version=5.5 --local')  # Fish line 2472
    abbr('lri1', 'luarocks install --lua-version=5.1 --local')  # Fish line 2476
    abbr('lri4', 'luarocks install --lua-version=5.4 --local')  # Fish line 2477
    abbr('lri5', 'luarocks install --lua-version=5.5 --local')  # Fish line 2478
    abbr('lrrm1', 'luarocks remove --lua-version=5.1 --local')  # Fish line 2480
    abbr('lrrm4', 'luarocks remove --lua-version=5.4 --local')  # Fish line 2481
    abbr('lrrm5', 'luarocks remove --lua-version=5.5 --local')  # Fish line 2482
    abbr('lrs1', 'luarocks search --lua-version=5.1')  # Fish line 2484
    abbr('lrs4', 'luarocks search --lua-version=5.4')  # Fish line 2485
    abbr('lrs5', 'luarocks search --lua-version=5.5')  # Fish line 2486
    abbr('lrshow1', 'luarocks show --lua-version=5.1')  # Fish line 2488
    abbr('lrshow4', 'luarocks show --lua-version=5.4')  # Fish line 2489
    abbr('lrshow5', 'luarocks show --lua-version=5.5')  # Fish line 2490
    abbr('pm', 'pacman')  # Fish line 2499
    abbr('pmss', "sudo pacman -Ss '^%'", cursor_marker="%")  # Fish line 2502
    abbr('pm_search', "sudo pacman -Ss '^%'", cursor_marker="%")  # Fish line 2503
    abbr('pmsi', 'pacman -Si')  # Fish line 2505
    abbr('pm_info', 'pacman -Si')  # Fish line 2506
    abbr('pms', 'sudo pacman --noconfirm -S')  # Fish line 2508
    abbr('pm_install', 'sudo pacman --noconfirm -S')  # Fish line 2509
    abbr('pmsu', 'sudo pacman -Syu')  # Fish line 2510
    abbr('pm_update', 'sudo pacman -Syu')  # Fish line 2511
    abbr('pmr', 'sudo pacman -R --recursive')  # Fish line 2514
    abbr('pm_uninstall', 'sudo pacman -R --recursive')  # Fish line 2515
    abbr('pmq', 'pacman -Q')  # Fish line 2518
    abbr('pm_listinstalled', 'pacman -Q')  # Fish line 2519
    abbr('pmqi', 'pacman -Qi')  # Fish line 2520
    abbr('pmqs', 'pacman -Qs')  # Fish line 2522
    abbr('pmqg', "pacman -Q | rg_grep -i '%'", cursor_marker="%")  # Fish line 2523
    abbr('pmqgs', "pacman -Q | rg_grep -i '^%'", cursor_marker="%")  # Fish line 2524
    abbr('pmql', 'pacman -Ql')  # Fish line 2526
    abbr('pmqlt', 'pacman -Qlq % | treeify_with_icons ', cursor_marker="%")  # Fish line 2528
    abbr('pm_listinstalledpkgfiles', 'pacman -Qlq % | treeify', cursor_marker="%")  # Fish line 2539
    abbr('pmqo', 'pacman -Qo')  # Fish line 2541
    abbr('pm_whoownsfile', 'pacman -Qo')  # Fish line 2542
    abbr('pmqe', 'pacman -Q --explicit')  # Fish line 2547
    abbr('pmqd', 'pacman -Q --deps')  # Fish line 2548
    abbr('pm_list_explicit_installs', 'pacman -Q --explicit')  # Fish line 2549
    abbr('pm_list_implicit_installs_aka_deps', 'pacman -Q --deps')  # Fish line 2550
    abbr('pm_list_upgrades', 'pacman -Q --upgrades')  # Fish line 2556
    abbr('pmf', 'pacman -F')  # Fish line 2559
    abbr('pmfl', 'pacman -Fl')  # Fish line 2564
    abbr('pmflt', 'pacman -Flq % | treeify', cursor_marker="%")  # Fish line 2565
    abbr('pm_listremotepkgfiles', 'pacman -Flq % | treeify', cursor_marker="%")  # Fish line 2566
    abbr('pmfy', 'sudo pacman -Fy')  # Fish line 2567
    abbr('pmtree_list_installed_pkgs_that_use', 'pactree --reverse --color')  # Fish line 2572
    abbr('pmtree_list_all_pkgs_used_by', 'pactree --sync --color')  # Fish line 2574
    abbr('pmtree_list_all_pkgs_that_use', 'pactree --sync --reverse --color')  # Fish line 2575
    abbr(re.compile('^d(\\d+)$'), fish_abbreviation('__pactree_depth'), position="anywhere", commands=('pactree',))  # Fish line 2577
    abbr('prm', 'sudo pacman -R')  # Fish line 2585
    abbr('pum', 'sudo pacman -U')  # Fish line 2587
    abbr('nv', 'nvidia-%', cursor_marker="%")  # Fish line 2596
    abbr('ns', 'nvidia-smi')  # Fish line 2602
    abbr('nsl', 'nvidia-smi -L')  # Fish line 2603
    abbr('nst', 'nvidia-smi -q -d temperature | bat -l yml')  # Fish line 2604
    abbr('nsu', 'nvidia-smi -q -d utilization | bat -l yml')  # Fish line 2605
    abbr('nstw', '\\$WATCH_COMMAND nvidia-smi -q -d temperature')  # Fish line 2606
    abbr('nsuw', '\\$WATCH_COMMAND nvidia-smi -q -d utilization')  # Fish line 2607
    abbr('nsm', 'nvidia-smi -q -d memory | bat -l yml')  # Fish line 2608
    abbr('nsmw', '\\$WATCH_COMMAND nvidia-smi -q -d memory')  # Fish line 2609
    abbr('nsp', 'nvidia-smi -q -d power | bat -l yml')  # Fish line 2610
    abbr('nspm', '\\$WATCH_COMMAND -n 1 nvidia-smi -q -d power,memory,utilization')  # Fish line 2611
    abbr('nsf', 'nvidia-smi -q -d clock | bat -l yml')  # Fish line 2612
    abbr('nsdmon', 'nvidia-smi dmon')  # Fish line 2615
    abbr('nspmon', 'nvidia-smi pmon')  # Fish line 2616
    abbr('nswatch', '\\$WATCH_COMMAND -n 1 nvidia-smi')  # Fish line 2617
    abbr('nspids', 'nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv')  # Fish line 2620
    abbr('nstopo', 'nvidia-smi topo -m')  # Fish line 2621
    abbr('nsnvlink', 'nvidia-smi nvlink -s')  # Fish line 2622
    abbr('nsgpu', 'nvidia-smi --query-gpu=gpu_name,gpu_bus_id,vbios_version --format=csv')  # Fish line 2623
    abbr('nsall', 'nvidia-smi --query-gpu=timestamp,name,pci.bus_id,driver_version,pstate,pcie.link.gen.max,pcie.link.gen.current,temperature.gpu,utilization.gpu,utilization.memory,memory.total,memory.free,memory.used --format=csv')  # Fish line 2624
    abbr('fuc', 'fish_update_completions')  # Fish line 2677
    abbr('fish_from_source', fish_abbreviation('_fish_from_source'))  # Fish line 2694
    abbr('lscpue', 'lscpu -e')  # Fish line 2700
    abbr('lscpuon', 'lscpu -e --online')  # Fish line 2701
    abbr('lscpuoff', 'lscpu -e --offline')  # Fish line 2702
    abbr('lspcit', 'lspci -tv')  # Fish line 2705
    abbr('lspcik', 'lspci -k')  # Fish line 2706
    abbr('lspciu', 'lspci -k -d ::00xx')  # Fish line 2710
    abbr('lspcii', 'lspci -k -d ::01xx')  # Fish line 2711
    abbr('lspcin', 'lspci -k -d ::02xx')  # Fish line 2712
    abbr('lspcig', 'lspci -k -d ::03xx')  # Fish line 2713
    abbr('lshw', 'sudo lshw')  # Fish line 2718
    abbr('lshws', 'sudo lshw -sanitize')  # Fish line 2719
    abbr('lshwb', 'sudo lshw -businfo')  # Fish line 2720
    abbr('lshwcd', 'sudo lshw -class display')  # Fish line 2721
    abbr('lshwcn', 'sudo lshw -class network')  # Fish line 2722
    abbr('lshwcs', 'sudo lshw -class storage')  # Fish line 2723
    abbr('lsmodg', "sudo lsmod | rg_grep -i '%'", cursor_marker="%")  # Fish line 2726
    abbr('lsmem', 'lsmem --output-all')  # Fish line 2729
    abbr('lsusb', platform_abbreviation('system_profiler SPUSBDataType', 'lsusb -tv'))  # Fish line 2735
    abbr('lsusbv', 'lsusb -v')  # Fish line 2736
    abbr('dmesgg', "sudo dmesg | rg_grep -i '%'", cursor_marker="%")  # Fish line 2739
    abbr('lspci', 'system_profiler SPPCIDataType')  # Fish line 2748
    abbr('lscpu', 'sysctl -n machdep.cpu.brand_string; sysctl -n hw.physicalcpu; sysctl -n hw.logicalcpu')  # Fish line 2749
    abbr('lsblk', 'diskutil list')  # Fish line 2750
    abbr('dmidecode', 'system_profiler SPHardwareDataType')  # Fish line 2751
    abbr('inxi', 'system_profiler SPHardwareDataType; system_profiler SPSoftwareDataType')  # Fish line 2752
    abbr('hwinfo', 'system_profiler SPHardwareDataType')  # Fish line 2753
    abbr('free', 'vm_stat')  # Fish line 2754
    abbr('dmesg', 'log show --predicate \'eventMessage contains "kernel"\' --info --debug --last 1m')  # Fish line 2755
    abbr('lsblk_fs', 'lsblk --fs')  # Fish line 2758
    abbr('lsblk_nvme', 'lsblk --nvme')  # Fish line 2759
    abbr('lsblk_scsi', 'lsblk --scsi')  # Fish line 2760
    abbr('lsblk_virtio', 'lsblk --virtio')  # Fish line 2761
    abbr('lsblk_topology', 'lsblk --topology')  # Fish line 2763
    abbr('fdisk_ls', 'sudo fdisk -l')  # Fish line 2765
    abbr('fdisk_details', 'sudo fdisk -lx')  # Fish line 2766
    abbr('findmnt_fstab', 'findmnt --fstab')  # Fish line 2768
    abbr('findmnt_verify', 'findmnt --verify --verbose')  # Fish line 2769
