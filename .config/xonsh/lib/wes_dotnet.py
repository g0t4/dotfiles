"""generated from Fish"""

from __future__ import annotations

import re
import os
import platform

from xonsh.built_ins import XSH
from wes_abbreviations import abbr
from wes_fish_migration import (
    wrap_fish_functions,
    abbr_from_fish_function,
    platform_abbreviation,
    unsupported_abbreviation,
)


def register_wes_dotnet():
    fish_funcs = (
        'dotnet_get_version_tag',
        'dotnet_version',
        'get_image_url',
        'dotnet_shell',
        'diff_dotnet',
        'dnd_all',
        'dnd_tools',
    )
    wrap_fish_functions(XSH.aliases, fish_funcs)
    abbr('dotnet_versions', 'skopeo --override-os linux inspect docker://mcr.microsoft.com/dotnet/sdk | jq ".RepoTags | .[]" -r')
    abbr('dotnet_versions_major_only', 'skopeo --override-os linux inspect docker://mcr.microsoft.com/dotnet/sdk | jq ".RepoTags | .[]" -r | grep -o "\\d\\.\\d" | sort | uniq')
    abbr('dotnet_versions_major_only_nightly', 'skopeo --override-os linux inspect docker://mcr.microsoft.com/dotnet/nightly/sdk | jq ".RepoTags | .[]" -r | grep -o "\\d\\.\\d" | sort | uniq')
    abbr('dn2', 'dotnet_version 2.1')
    abbr('dn3', 'dotnet_version 3.1')
    abbr('dn4', 'dotnet_version 4.0')
    abbr('dn5', 'dotnet_version 5.0')
    abbr('dn6', 'dotnet_version 6.0')
    abbr('dn7', 'dotnet_version 7.0')
    abbr('dn8', 'dotnet_version 8.0')
    abbr('dn9', 'dotnet_version 9.0')
    abbr('dn10', 'dotnet_version 10.0')
    abbr('dn11', 'dotnet_version 11.0')
    abbr('dns2', 'dotnet_shell 2.1')
    abbr('dns3', 'dotnet_shell 3.1')
    abbr('dns4', 'dotnet_shell 4.0')
    abbr('dns5', 'dotnet_shell 5.0')
    abbr('dns6', 'dotnet_shell 6.0')
    abbr('dns7', 'dotnet_shell 7.0')
    abbr('dns8', 'dotnet_shell 8.0')
    abbr('dns9', 'dotnet_shell 9.0')
    abbr('dns10', 'dotnet_shell 10.0')
    abbr('dns11', 'dotnet_shell 11.0')
    abbr('dnd3', 'diff_dotnet 2.1 3.1')
    abbr('dnd5', 'diff_dotnet 3.1 5.0')
    abbr('dnd6', 'diff_dotnet 5.0 6.0')
    abbr('dnd7', 'diff_dotnet 6.0 7.0')
    abbr('dnd8', 'diff_dotnet 7.0 8.0')
    abbr('dnd9', 'diff_dotnet 8.0 9.0')
    abbr('dnd10', 'diff_dotnet 9.0 10.0')
    abbr('dnd11', 'diff_dotnet 10.0 11.0')
    abbr('dnh', 'dotnet -h')
    abbr('dnhh', 'dotnet help help')
    abbr('dnd', 'dotnet --diagnostics')
    abbr('dnsdks', 'dotnet --list-sdks')
    abbr('dnsdkc', 'dotnet sdk check')
    abbr('dnrtms', 'dotnet --list-runtimes')
    abbr('dni', 'dotnet --info')
    abbr('dnres', 'dotnet restore')
    abbr('dnap', 'dotnet add package')
    abbr('dnar', 'dotnet add reference')
    abbr('dnha', 'dotnet help add')
    abbr('dna', 'dotnet remove')
    abbr('dnsln', 'dotnet sln')
    abbr('dnhsln', 'dotnet help sln')
    abbr('dnls', 'dotnet list -h')
    abbr('dnlsp', 'dotnet list package')
    abbr('dnlsr', 'dotnet list reference')
    abbr('dnstore', 'dotnet store')
    abbr('dnn', 'dotnet new')
    abbr('dnnls', 'dotnet new list')
    abbr('dnni', 'dotnet new install')
    abbr('dnnu', 'dotnet new uninstall')
    abbr('dnnup', 'dotnet new update')
    abbr('dnns', 'dotnet new search')
    abbr('dnnd', 'dotnet new details')
    abbr('dndc', 'dotnet dev-certs')
    abbr('dnfsi', 'dotnet fsi')
    abbr('dnsqlc', 'dotnet sql-cache')
    abbr('dnusec', 'dotnet user-secrets')
    abbr('dnc', 'dotnet clean')
    abbr('dnb', 'dotnet build')
    abbr('dnbs', 'dotnet build-server')
    abbr('dnmsb', 'dotnet msbuild')
    abbr('dnpa', 'dotnet pack')
    abbr('dnpu', 'dotnet publish')
    abbr('dnr', 'dotnet run')
    abbr('dnw', 'dotnet watch')
    abbr('dnt', 'dotnet tool -h')
    abbr('dnht', 'dotnet help tool')
    abbr('dntls', 'dotnet tool list')
    abbr('dnhtls', 'dotnet tool list')
    abbr('dntlsl', 'dotnet tool list --locaa')
    abbr('dntlsg', 'dotnet tool list --global')
    abbr('dnts', 'dotnet tool search')
    abbr('dntsd', 'dotnet tool search --detail')
    abbr('dnti', 'dotnet tool install')
    abbr('dntun', 'dotnet tool uninstall')
    abbr('dntup', 'dotnet tool update')
    abbr('dntr', 'dotnet tool run')
    abbr('dntres', 'dotnet tool restore')


