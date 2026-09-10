"""Generated .NET abbreviations."""

from __future__ import annotations

from wes_abbreviations import abbr


FISH_FUNCTIONS = (
    'dotnet_get_version_tag',  # Fish line 10
    'dotnet_version',  # Fish line 45
    'get_image_url',  # Fish line 56
    'dotnet_shell',  # Fish line 64
    'diff_dotnet',  # Fish line 78
    'dnd_all',  # Fish line 112
    'dnd_tools',  # Fish line 208
)


def register_dotnet_abbreviations():
    abbr('dotnet_versions', 'skopeo --override-os linux inspect docker://mcr.microsoft.com/dotnet/sdk | jq ".RepoTags | .[]" -r')  # Fish line 5
    abbr('dotnet_versions_major_only', 'skopeo --override-os linux inspect docker://mcr.microsoft.com/dotnet/sdk | jq ".RepoTags | .[]" -r | grep -o "\\d\\.\\d" | sort | uniq')  # Fish line 7
    abbr('dotnet_versions_major_only_nightly', 'skopeo --override-os linux inspect docker://mcr.microsoft.com/dotnet/nightly/sdk | jq ".RepoTags | .[]" -r | grep -o "\\d\\.\\d" | sort | uniq')  # Fish line 8
    abbr('dn2', 'dotnet_version 2.1')  # Fish line 21
    abbr('dn3', 'dotnet_version 3.1')  # Fish line 22
    abbr('dn4', 'dotnet_version 4.0')  # Fish line 23
    abbr('dn5', 'dotnet_version 5.0')  # Fish line 24
    abbr('dn6', 'dotnet_version 6.0')  # Fish line 25
    abbr('dn7', 'dotnet_version 7.0')  # Fish line 26
    abbr('dn8', 'dotnet_version 8.0')  # Fish line 27
    abbr('dn9', 'dotnet_version 9.0')  # Fish line 28
    abbr('dns2', 'dotnet_shell 2.1')  # Fish line 29
    abbr('dns3', 'dotnet_shell 3.1')  # Fish line 30
    abbr('dns4', 'dotnet_shell 4.0')  # Fish line 31
    abbr('dns5', 'dotnet_shell 5.0')  # Fish line 32
    abbr('dns6', 'dotnet_shell 6.0')  # Fish line 33
    abbr('dns7', 'dotnet_shell 7.0')  # Fish line 34
    abbr('dns8', 'dotnet_shell 8.0')  # Fish line 35
    abbr('dns9', 'dotnet_shell 9.0')  # Fish line 36
    abbr('dnd3', 'diff_dotnet 2.1 3.1')  # Fish line 104
    abbr('dnd5', 'diff_dotnet 3.1 5.0')  # Fish line 105
    abbr('dnd6', 'diff_dotnet 5.0 6.0')  # Fish line 107
    abbr('dnd7', 'diff_dotnet 6.0 7.0')  # Fish line 108
    abbr('dnd8', 'diff_dotnet 7.0 8.0')  # Fish line 109
    abbr('dnd9', 'diff_dotnet 8.0 9.0')  # Fish line 110
    abbr('dnh', 'dotnet -h')  # Fish line 228
    abbr('dnhh', 'dotnet help help')  # Fish line 230
    abbr('dnd', 'dotnet --diagnostics')  # Fish line 231
    abbr('dnsdks', 'dotnet --list-sdks')  # Fish line 232
    abbr('dnsdkc', 'dotnet sdk check')  # Fish line 233
    abbr('dnrtms', 'dotnet --list-runtimes')  # Fish line 234
    abbr('dni', 'dotnet --info')  # Fish line 235
    abbr('dnres', 'dotnet restore')  # Fish line 238
    abbr('dnap', 'dotnet add package')  # Fish line 239
    abbr('dnar', 'dotnet add reference')  # Fish line 240
    abbr('dnha', 'dotnet help add')  # Fish line 241
    abbr('dna', 'dotnet remove')  # Fish line 242
    abbr('dnsln', 'dotnet sln')  # Fish line 243
    abbr('dnhsln', 'dotnet help sln')  # Fish line 244
    abbr('dnls', 'dotnet list -h')  # Fish line 245
    abbr('dnlsp', 'dotnet list package')  # Fish line 246
    abbr('dnlsr', 'dotnet list reference')  # Fish line 247
    abbr('dnstore', 'dotnet store')  # Fish line 248
    abbr('dnn', 'dotnet new')  # Fish line 251
    abbr('dnnls', 'dotnet new list')  # Fish line 252
    abbr('dnni', 'dotnet new install')  # Fish line 253
    abbr('dnnu', 'dotnet new uninstall')  # Fish line 254
    abbr('dnnup', 'dotnet new update')  # Fish line 255
    abbr('dnns', 'dotnet new search')  # Fish line 256
    abbr('dnnd', 'dotnet new details')  # Fish line 257
    abbr('dndc', 'dotnet dev-certs')  # Fish line 266
    abbr('dnfsi', 'dotnet fsi')  # Fish line 267
    abbr('dnsqlc', 'dotnet sql-cache')  # Fish line 268
    abbr('dnusec', 'dotnet user-secrets')  # Fish line 269
    abbr('dnc', 'dotnet clean')  # Fish line 273
    abbr('dnb', 'dotnet build')  # Fish line 274
    abbr('dnbs', 'dotnet build-server')  # Fish line 275
    abbr('dnmsb', 'dotnet msbuild')  # Fish line 276
    abbr('dnpa', 'dotnet pack')  # Fish line 277
    abbr('dnpu', 'dotnet publish')  # Fish line 278
    abbr('dnr', 'dotnet run')  # Fish line 281
    abbr('dnw', 'dotnet watch')  # Fish line 283
    abbr('dnt', 'dotnet tool -h')  # Fish line 287
    abbr('dnht', 'dotnet help tool')  # Fish line 288
    abbr('dntls', 'dotnet tool list')  # Fish line 289
    abbr('dnhtls', 'dotnet tool list')  # Fish line 290
    abbr('dntlsl', 'dotnet tool list --local')  # Fish line 291
    abbr('dntlsg', 'dotnet tool list --global')  # Fish line 292
    abbr('dnts', 'dotnet tool search')  # Fish line 293
    abbr('dntsd', 'dotnet tool search --detail')  # Fish line 294
    abbr('dnti', 'dotnet tool install')  # Fish line 295
    abbr('dntun', 'dotnet tool uninstall')  # Fish line 296
    abbr('dntup', 'dotnet tool update')  # Fish line 297
    abbr('dntr', 'dotnet tool run')  # Fish line 298
    abbr('dntres', 'dotnet tool restore')  # Fish line 299
