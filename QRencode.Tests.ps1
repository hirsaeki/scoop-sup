Describe 'qrencode-sup install hook' {
    BeforeAll {
        . (Join-Path $env:SCOOP_HOME 'lib/manifest.ps1')
        . (Join-Path $env:SCOOP_HOME 'lib/install.ps1')
        $manifest = Get-Content -Raw (Join-Path $PSScriptRoot 'bucket/qrencode-sup.json') | ConvertFrom-Json

        # Stand in for Scoop's Windows robocopy wrapper. An absent source must fail.
        function movedir($from, $to) {
            if (!(Test-Path -LiteralPath $from -PathType Container)) { throw "Missing fixture source: $from" }
            Get-ChildItem -LiteralPath $from | Move-Item -Destination $to -ErrorAction Stop
        }
    }

    It 'uses the Scoop hook architecture for <bitness>' -ForEach @(
        @{ bitness = '64bit'; root = 'mingw64'; keepLibgcc = $false }
        @{ bitness = '32bit'; root = 'mingw32'; keepLibgcc = $true }
    ) {
        $dir = Join-Path $TestDrive $bitness
        $src = Join-Path $dir $root
        $files = @(
            'bin/qrencode.exe', 'bin/libqrencode.dll', 'bin/libwinpthread-1.dll',
            'bin/libpng16-16.dll', 'bin/zlib1.dll', 'bin/libgcc_s_dw2-1.dll',
            'share/licenses/qrencode/COPYING', 'share/man/man1/qrencode.1.gz',
            'share/licenses/libgcc/COPYING.RUNTIME', 'share/licenses/libgcc/COPYING3',
            'bin/unneeded.exe'
        )
        foreach ($file in $files) {
            $path = Join-Path $src $file
            New-Item -ItemType Directory -Path (Split-Path $path) -Force | Out-Null
            Set-Content -LiteralPath $path -Value $bitness
        }

        Invoke-HookScript -HookType pre_install -Manifest $manifest -ProcessorArchitecture $bitness

        foreach ($file in $files[0..4] + $files[6..7]) {
            Get-Content -LiteralPath (Join-Path $dir $file) | Should -Be $bitness
        }
        foreach ($file in $files[5,8,9]) {
            (Test-Path -LiteralPath (Join-Path $dir $file) -PathType Leaf) | Should -Be $keepLibgcc
        }
        (Test-Path -LiteralPath (Join-Path $dir 'bin/unneeded.exe')) | Should -BeFalse
    }
}
