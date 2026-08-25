"""Packages Hardware abbreviations generated from Fish misc-specific.fish."""

from __future__ import annotations

import platform
import re


from wes_abbreviations import AbbreviationRegistry, abbr
from wes_misc_abbreviation_bridge import (
    fish_abbreviation,
    platform_abbreviation,
)



MAN_COMMAND = "gman" if platform.system() == "Darwin" else "man"
SED_COMMAND = "gsed" if platform.system() == "Darwin" else "sed"


FISH_FUNCTIONS = (
    'dpkg_L_files',  # Fish line 1197
    'dpkg_L_tree',  # Fish line 1203
    'treeify',  # Fish line 1211
    'watch',  # Fish line 1222
    'viddy',  # Fish line 1233
    '_expand_watch_last',  # Fish line 1250
    'wordcount',  # Fish line 1284
    'yq_diff_docs',  # Fish line 1297
    'tellme_about',  # Fish line 1332
    '_indent',  # Fish line 1349
    'npm_install',  # Fish line 2043
    'npx',  # Fish line 2091
    'bitmaths',  # Fish line 2138
    'pretty_size',  # Fish line 2160
    'manlistX',  # Fish line 2199
    'show_hex_rgb_color',  # Fish line 2301
    'treeify_with_icons',  # Fish line 2532
    '__pactree_depth',  # Fish line 2581
    'zedraw',  # Fish line 2630
    'zedfull',  # Fish line 2639
    'trash',  # Fish line 2658
    '_fish_from_source',  # Fish line 2682
)


def register_packages_hardware_abbreviations(registry: AbbreviationRegistry):
    abbr(registry, 'apts', 'apt search')  # Fish line 1184
    abbr(registry, 'apti', 'sudo apt install')  # Fish line 1185
    abbr(registry, 'aptu', 'sudo apt update')  # Fish line 1186
    abbr(registry, 'aptug', 'sudo apt upgrade')  # Fish line 1187
    abbr(registry, 'aptl', 'apt list --installed')  # Fish line 1189
    abbr(registry, 'aptlu', 'apt list --upgradable')  # Fish line 1190
    abbr(registry, 'aptcm', 'apt-cache madison')  # Fish line 1192
    abbr(registry, 'dpkgL', 'dpkg -L')  # Fish line 1194
    abbr(registry, 'dpkgS', 'dpkg -S')  # Fish line 1195
    abbr(registry, 'watch', '$WATCH_COMMAND')  # Fish line 1248
    abbr(registry, 'watch_last', fish_abbreviation('_expand_watch_last'))  # Fish line 1255
    abbr(registry, 'wa', '$WATCH_COMMAND')  # Fish line 1257
    abbr(registry, 'wag', '$WATCH_COMMAND --no-title -- grc --colour=on')  # Fish line 1259
    abbr(registry, 'wak', '$WATCH_COMMAND --no-title -- grc --colour=on kubectl get --show-kind')  # Fish line 1264
    abbr(registry, 'wad', '$WATCH_COMMAND --no-title -- grc --colour=on kubectl describe --show-kind')  # Fish line 1265
    abbr(registry, 'wakp', '$WATCH_COMMAND --no-title -- grc --colour=on kubectl get --show-kind pods')  # Fish line 1266
    abbr(registry, 'wah', '$WATCH_COMMAND --no-title -- http --pretty=colors')  # Fish line 1267
    abbr(registry, 'wahv', '$WATCH_COMMAND --no-title -- http --pretty=colors --verbose')  # Fish line 1268
    abbr(registry, 'wal', '$WATCH_COMMAND --no-title -- grc --colour=on ls')  # Fish line 1269
    abbr(registry, 'wat', '$WATCH_COMMAND --no-title -- grc --colour=on tree')  # Fish line 1270
    abbr(registry, 'wc', 'wordcount')  # Fish line 1283
    abbr(registry, 'pyqi', "| yq eval 'select(documentIndex == 1) | .status'")  # Fish line 1293
    abbr(registry, 'pyqp', '| yq -P')  # Fish line 1294
    abbr(registry, '_reminders_docker_binfmts', 'docker run --privileged --rm tonistiigi/binfmt')  # Fish line 1325
    abbr(registry, 'npmi', 'npm_install')  # Fish line 2059
    abbr(registry, 'npminit', 'npm init -y')  # Fish line 2060
    abbr(registry, 'npml', 'npm list')  # Fish line 2061
    abbr(registry, 'npmr', 'npm run')  # Fish line 2062
    abbr(registry, 'npmt', 'npm test')  # Fish line 2063
    abbr(registry, 'npma', 'npm audit')  # Fish line 2064
    abbr(registry, 'npmv', 'npm version')  # Fish line 2065
    abbr(registry, 'npms', 'npm start')  # Fish line 2066
    abbr(registry, 'npmo', 'npm outdated')  # Fish line 2067
    abbr(registry, 'npmun', 'npm uninstall')  # Fish line 2068
    abbr(registry, 'npmup', 'npm update')  # Fish line 2069
    abbr(registry, 'npxr', 'npx run')  # Fish line 2071
    abbr(registry, 'ts', 'tree-sitter')  # Fish line 2080
    abbr(registry, 'tsg', 'tree-sitter generate')  # Fish line 2081
    abbr(registry, 'tsb', 'tree-sitter build')  # Fish line 2082
    abbr(registry, 'tsp', 'tree-sitter parse')  # Fish line 2083
    abbr(registry, 'tst', 'tree-sitter test')  # Fish line 2084
    abbr(registry, 'tsq', 'tree-sitter query')  # Fish line 2085
    abbr(registry, 'tsh', 'tree-sitter highlight')  # Fish line 2086
    abbr(registry, 'tsplayground', 'tree-sitter playground')  # Fish line 2087
    abbr(registry, 'bm', 'bitmaths')  # Fish line 2137
    abbr(registry, 'man', 'gman')  # Fish line 2187
    abbr(registry, 'man_commands_1', '$XONSH_MAN_COMMAND 1')  # Fish line 2189
    abbr(registry, 'man_syscalls_2', '$XONSH_MAN_COMMAND 2')  # Fish line 2190
    abbr(registry, 'man_c_stdlib_3', '$XONSH_MAN_COMMAND 3')  # Fish line 2191
    abbr(registry, 'man_kernel_interfaces_4', '$XONSH_MAN_COMMAND 4')  # Fish line 2192
    abbr(registry, 'man_file_formats_5', '$XONSH_MAN_COMMAND 5')  # Fish line 2193
    abbr(registry, 'man_misc_7', '$XONSH_MAN_COMMAND 7')  # Fish line 2194
    abbr(registry, 'man_system_8', '$XONSH_MAN_COMMAND 8')  # Fish line 2195
    abbr(registry, 'man_kernel_dev_9', '$XONSH_MAN_COMMAND 9')  # Fish line 2196
    abbr(registry, re.compile('manlist[0-9]'), fish_abbreviation('manlistX'))  # Fish line 2198
    abbr(registry, 'man1', '$XONSH_MAN_COMMAND 1')  # Fish line 2203
    abbr(registry, 'man2', '$XONSH_MAN_COMMAND 2')  # Fish line 2204
    abbr(registry, 'man3', '$XONSH_MAN_COMMAND 3')  # Fish line 2205
    abbr(registry, 'man4', '$XONSH_MAN_COMMAND 4')  # Fish line 2206
    abbr(registry, 'man5', '$XONSH_MAN_COMMAND 5')  # Fish line 2207
    abbr(registry, 'man6', '$XONSH_MAN_COMMAND 6')  # Fish line 2208
    abbr(registry, 'man7', '$XONSH_MAN_COMMAND 7')  # Fish line 2209
    abbr(registry, 'man8', '$XONSH_MAN_COMMAND 8')  # Fish line 2210
    abbr(registry, 'man9', '$XONSH_MAN_COMMAND 9')  # Fish line 2211
    abbr(registry, 'mana', '$XONSH_MAN_COMMAND --all --regex')  # Fish line 2214
    abbr(registry, 'mank', 'apropos')  # Fish line 2215
    abbr(registry, 'manf', 'whatis')  # Fish line 2216
    abbr(registry, '-K', '--global-apropos', position="anywhere", commands=(MAN_COMMAND,))  # Fish line 2221
    abbr(registry, '-k', '--apropos', position="anywhere", commands=(MAN_COMMAND,))  # Fish line 2222
    abbr(registry, '-w', '--where', position="anywhere", commands=(MAN_COMMAND,))  # Fish line 2224
    abbr(registry, '-a', '--all', position="anywhere", commands=(MAN_COMMAND,))  # Fish line 2225
    abbr(registry, 'manK', '$XONSH_MAN_COMMAND -K')  # Fish line 2233
    abbr(registry, 'manw', '$XONSH_MAN_COMMAND --where -K')  # Fish line 2234
    abbr(registry, 'mgr', '$XONSH_MAN_COMMAND -K')  # Fish line 2237
    abbr(registry, 'mgrw', '$XONSH_MAN_COMMAND --where -K')  # Fish line 2238
    abbr(registry, 'manbash', '$XONSH_MAN_COMMAND $HOME/repos/github/g0t4/bash/doc/bash.1')  # Fish line 2242
    abbr(registry, 'mbash', '$XONSH_MAN_COMMAND $HOME/repos/github/g0t4/bash/doc/bash.1')  # Fish line 2244
    abbr(registry, 'mitm', 'mitmproxy')  # Fish line 2260
    abbr(registry, 'mitml', 'mitmproxy --mode=local')  # Fish line 2261
    abbr(registry, 'mitmw', 'mitmweb')  # Fish line 2263
    abbr(registry, 'mitmwl', 'mitmweb --mode=local')  # Fish line 2264
    abbr(registry, 'mitmd', 'mitmdump --mode=local')  # Fish line 2266
    abbr(registry, 'mitmdl', 'mitmdump --mode=local')  # Fish line 2267
    abbr(registry, 'mitmr', 'mitmproxy --no-server --rfile')  # Fish line 2270
    abbr(registry, 'mitm_pgrep', 'pgrep -ilf mitmproxy | rg_grep -v "\\--no-server" || true')  # Fish line 2275
    abbr(registry, 'mitm_kill', 'pgrep -ilf mitmproxy | rg_grep -v "\\--no-server" | awk \'{print $1}\' | xargs sudo kill -9 || true')  # Fish line 2276
    abbr(registry, 'mitmlc', "mitmproxy --mode=local:'Visual Studio Code.app'")  # Fish line 2279
    abbr(registry, 'mitmlci', "mitmproxy --mode=local:'Visual Studio Code - Insiders.app'")  # Fish line 2280
    abbr(registry, 'mitmlcurl', "mitmproxy --mode=local:'curl'")  # Fish line 2281
    abbr(registry, 'mitms', 'mitmproxy --scripts')  # Fish line 2283
    abbr(registry, 'mitmsave', 'mitmproxy --save-stream-file')  # Fish line 2284
    abbr(registry, 'lr', 'luarocks')  # Fish line 2470
    abbr(registry, 'lrll', 'luarocks list --local')  # Fish line 2472
    abbr(registry, 'lrl1', 'luarocks list --lua-version=5.1 --local')  # Fish line 2473
    abbr(registry, 'lrl4', 'luarocks list --lua-version=5.4 --local')  # Fish line 2474
    abbr(registry, 'lrl5', 'luarocks list --lua-version=5.5 --local')  # Fish line 2475
    abbr(registry, 'lri1', 'luarocks install --lua-version=5.1 --local')  # Fish line 2479
    abbr(registry, 'lri4', 'luarocks install --lua-version=5.4 --local')  # Fish line 2480
    abbr(registry, 'lri5', 'luarocks install --lua-version=5.5 --local')  # Fish line 2481
    abbr(registry, 'lrrm1', 'luarocks remove --lua-version=5.1 --local')  # Fish line 2483
    abbr(registry, 'lrrm4', 'luarocks remove --lua-version=5.4 --local')  # Fish line 2484
    abbr(registry, 'lrrm5', 'luarocks remove --lua-version=5.5 --local')  # Fish line 2485
    abbr(registry, 'lrs1', 'luarocks search --lua-version=5.1')  # Fish line 2487
    abbr(registry, 'lrs4', 'luarocks search --lua-version=5.4')  # Fish line 2488
    abbr(registry, 'lrs5', 'luarocks search --lua-version=5.5')  # Fish line 2489
    abbr(registry, 'lrshow1', 'luarocks show --lua-version=5.1')  # Fish line 2491
    abbr(registry, 'lrshow4', 'luarocks show --lua-version=5.4')  # Fish line 2492
    abbr(registry, 'lrshow5', 'luarocks show --lua-version=5.5')  # Fish line 2493
    abbr(registry, 'pm', 'pacman')  # Fish line 2502
    abbr(registry, 'pmss', "sudo pacman -Ss '^%'", cursor_marker="%")  # Fish line 2505
    abbr(registry, 'pm_search', "sudo pacman -Ss '^%'", cursor_marker="%")  # Fish line 2506
    abbr(registry, 'pmsi', 'pacman -Si')  # Fish line 2508
    abbr(registry, 'pm_info', 'pacman -Si')  # Fish line 2509
    abbr(registry, 'pms', 'sudo pacman --noconfirm -S')  # Fish line 2511
    abbr(registry, 'pm_install', 'sudo pacman --noconfirm -S')  # Fish line 2512
    abbr(registry, 'pmsu', 'sudo pacman -Syu')  # Fish line 2513
    abbr(registry, 'pm_update', 'sudo pacman -Syu')  # Fish line 2514
    abbr(registry, 'pmr', 'sudo pacman -R --recursive')  # Fish line 2517
    abbr(registry, 'pm_uninstall', 'sudo pacman -R --recursive')  # Fish line 2518
    abbr(registry, 'pmq', 'pacman -Q')  # Fish line 2521
    abbr(registry, 'pm_listinstalled', 'pacman -Q')  # Fish line 2522
    abbr(registry, 'pmqi', 'pacman -Qi')  # Fish line 2523
    abbr(registry, 'pmqs', 'pacman -Qs')  # Fish line 2525
    abbr(registry, 'pmqg', "pacman -Q | rg_grep -i '%'", cursor_marker="%")  # Fish line 2526
    abbr(registry, 'pmqgs', "pacman -Q | rg_grep -i '^%'", cursor_marker="%")  # Fish line 2527
    abbr(registry, 'pmql', 'pacman -Ql')  # Fish line 2529
    abbr(registry, 'pmqlt', 'pacman -Qlq % | treeify_with_icons ', cursor_marker="%")  # Fish line 2531
    abbr(registry, 'pm_listinstalledpkgfiles', 'pacman -Qlq % | treeify', cursor_marker="%")  # Fish line 2542
    abbr(registry, 'pmqo', 'pacman -Qo')  # Fish line 2544
    abbr(registry, 'pm_whoownsfile', 'pacman -Qo')  # Fish line 2545
    abbr(registry, 'pmqe', 'pacman -Q --explicit')  # Fish line 2550
    abbr(registry, 'pmqd', 'pacman -Q --deps')  # Fish line 2551
    abbr(registry, 'pm_list_explicit_installs', 'pacman -Q --explicit')  # Fish line 2552
    abbr(registry, 'pm_list_implicit_installs_aka_deps', 'pacman -Q --deps')  # Fish line 2553
    abbr(registry, 'pm_list_upgrades', 'pacman -Q --upgrades')  # Fish line 2559
    abbr(registry, 'pmf', 'pacman -F')  # Fish line 2562
    abbr(registry, 'pmfl', 'pacman -Fl')  # Fish line 2567
    abbr(registry, 'pmflt', 'pacman -Flq % | treeify', cursor_marker="%")  # Fish line 2568
    abbr(registry, 'pm_listremotepkgfiles', 'pacman -Flq % | treeify', cursor_marker="%")  # Fish line 2569
    abbr(registry, 'pmfy', 'sudo pacman -Fy')  # Fish line 2570
    abbr(registry, 'pmtree_list_installed_pkgs_that_use', 'pactree --reverse --color')  # Fish line 2575
    abbr(registry, 'pmtree_list_all_pkgs_used_by', 'pactree --sync --color')  # Fish line 2577
    abbr(registry, 'pmtree_list_all_pkgs_that_use', 'pactree --sync --reverse --color')  # Fish line 2578
    abbr(registry, re.compile('^d(\\d+)$'), fish_abbreviation('__pactree_depth'), position="anywhere", commands=('pactree',))  # Fish line 2580
    abbr(registry, 'prm', 'sudo pacman -R')  # Fish line 2588
    abbr(registry, 'pum', 'sudo pacman -U')  # Fish line 2590
    abbr(registry, 'nv', 'nvidia-%', cursor_marker="%")  # Fish line 2599
    abbr(registry, 'ns', 'nvidia-smi')  # Fish line 2605
    abbr(registry, 'nsl', 'nvidia-smi -L')  # Fish line 2606
    abbr(registry, 'nst', 'nvidia-smi -q -d temperature | bat -l yml')  # Fish line 2607
    abbr(registry, 'nsu', 'nvidia-smi -q -d utilization | bat -l yml')  # Fish line 2608
    abbr(registry, 'nstw', '\\$WATCH_COMMAND nvidia-smi -q -d temperature')  # Fish line 2609
    abbr(registry, 'nsuw', '\\$WATCH_COMMAND nvidia-smi -q -d utilization')  # Fish line 2610
    abbr(registry, 'nsm', 'nvidia-smi -q -d memory | bat -l yml')  # Fish line 2611
    abbr(registry, 'nsmw', '\\$WATCH_COMMAND nvidia-smi -q -d memory')  # Fish line 2612
    abbr(registry, 'nsp', 'nvidia-smi -q -d power | bat -l yml')  # Fish line 2613
    abbr(registry, 'nspm', '\\$WATCH_COMMAND -n 1 nvidia-smi -q -d power,memory,utilization')  # Fish line 2614
    abbr(registry, 'nsf', 'nvidia-smi -q -d clock | bat -l yml')  # Fish line 2615
    abbr(registry, 'nsdmon', 'nvidia-smi dmon')  # Fish line 2618
    abbr(registry, 'nspmon', 'nvidia-smi pmon')  # Fish line 2619
    abbr(registry, 'nswatch', '\\$WATCH_COMMAND -n 1 nvidia-smi')  # Fish line 2620
    abbr(registry, 'nspids', 'nvidia-smi --query-compute-apps=pid,process_name,used_memory --format=csv')  # Fish line 2623
    abbr(registry, 'nstopo', 'nvidia-smi topo -m')  # Fish line 2624
    abbr(registry, 'nsnvlink', 'nvidia-smi nvlink -s')  # Fish line 2625
    abbr(registry, 'nsgpu', 'nvidia-smi --query-gpu=gpu_name,gpu_bus_id,vbios_version --format=csv')  # Fish line 2626
    abbr(registry, 'nsall', 'nvidia-smi --query-gpu=timestamp,name,pci.bus_id,driver_version,pstate,pcie.link.gen.max,pcie.link.gen.current,temperature.gpu,utilization.gpu,utilization.memory,memory.total,memory.free,memory.used --format=csv')  # Fish line 2627
    abbr(registry, 'fuc', 'fish_update_completions')  # Fish line 2680
    abbr(registry, 'fish_from_source', fish_abbreviation('_fish_from_source'))  # Fish line 2697
    abbr(registry, 'lscpue', 'lscpu -e')  # Fish line 2703
    abbr(registry, 'lscpuon', 'lscpu -e --online')  # Fish line 2704
    abbr(registry, 'lscpuoff', 'lscpu -e --offline')  # Fish line 2705
    abbr(registry, 'lspcit', 'lspci -tv')  # Fish line 2708
    abbr(registry, 'lspcik', 'lspci -k')  # Fish line 2709
    abbr(registry, 'lspciu', 'lspci -k -d ::00xx')  # Fish line 2713
    abbr(registry, 'lspcii', 'lspci -k -d ::01xx')  # Fish line 2714
    abbr(registry, 'lspcin', 'lspci -k -d ::02xx')  # Fish line 2715
    abbr(registry, 'lspcig', 'lspci -k -d ::03xx')  # Fish line 2716
    abbr(registry, 'lshw', 'sudo lshw')  # Fish line 2721
    abbr(registry, 'lshws', 'sudo lshw -sanitize')  # Fish line 2722
    abbr(registry, 'lshwb', 'sudo lshw -businfo')  # Fish line 2723
    abbr(registry, 'lshwcd', 'sudo lshw -class display')  # Fish line 2724
    abbr(registry, 'lshwcn', 'sudo lshw -class network')  # Fish line 2725
    abbr(registry, 'lshwcs', 'sudo lshw -class storage')  # Fish line 2726
    abbr(registry, 'lsmodg', "sudo lsmod | rg_grep -i '%'", cursor_marker="%")  # Fish line 2729
    abbr(registry, 'lsmem', 'lsmem --output-all')  # Fish line 2732
    abbr(registry, 'lsusb', platform_abbreviation('system_profiler SPUSBDataType', 'lsusb -tv'))  # Fish line 2738
    abbr(registry, 'lsusbv', 'lsusb -v')  # Fish line 2739
    abbr(registry, 'dmesgg', "sudo dmesg | rg_grep -i '%'", cursor_marker="%")  # Fish line 2742
    abbr(registry, 'lspci', 'system_profiler SPPCIDataType')  # Fish line 2751
    abbr(registry, 'lscpu', 'sysctl -n machdep.cpu.brand_string; sysctl -n hw.physicalcpu; sysctl -n hw.logicalcpu')  # Fish line 2752
    abbr(registry, 'lsblk', 'diskutil list')  # Fish line 2753
    abbr(registry, 'dmidecode', 'system_profiler SPHardwareDataType')  # Fish line 2754
    abbr(registry, 'inxi', 'system_profiler SPHardwareDataType; system_profiler SPSoftwareDataType')  # Fish line 2755
    abbr(registry, 'hwinfo', 'system_profiler SPHardwareDataType')  # Fish line 2756
    abbr(registry, 'free', 'vm_stat')  # Fish line 2757
    abbr(registry, 'dmesg', 'log show --predicate \'eventMessage contains "kernel"\' --info --debug --last 1m')  # Fish line 2758
    abbr(registry, 'lsblk_fs', 'lsblk --fs')  # Fish line 2761
    abbr(registry, 'lsblk_nvme', 'lsblk --nvme')  # Fish line 2762
    abbr(registry, 'lsblk_scsi', 'lsblk --scsi')  # Fish line 2763
    abbr(registry, 'lsblk_virtio', 'lsblk --virtio')  # Fish line 2764
    abbr(registry, 'lsblk_topology', 'lsblk --topology')  # Fish line 2766
    abbr(registry, 'fdisk_ls', 'sudo fdisk -l')  # Fish line 2768
    abbr(registry, 'fdisk_details', 'sudo fdisk -lx')  # Fish line 2769
    abbr(registry, 'findmnt_fstab', 'findmnt --fstab')  # Fish line 2771
    abbr(registry, 'findmnt_verify', 'findmnt --verify --verbose')  # Fish line 2772
