[CmdletBinding()]
param(
    [string]$OutputDirectory
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($OutputDirectory)) {
    $scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Path
    $OutputDirectory = Join-Path $scriptDirectory '..\data\raw'
}

$datasets = @(
    @{
        Name = 'exploring_set.jsonl'
        GoogleDriveId = '1fiP48CP-rtLUJ6ARwYRsf1YxrAYWyhDU'
        Sha256 = '0f6a07e5c525f2c99779a4a06780729d843f0045379c98c41f81ebe4f1cf5d4e'
    },
    @{
        Name = 'training_set_human.jsonl'
        GoogleDriveId = '1ek82f0FswSozBEYdqwJ8eHEyoaUq8arg'
        Sha256 = 'c737fe5d8b40dc21a3c61657e42e5359942a6abdf6837f31ad1dcef696eb1054'
    },
    @{
        Name = 'training_set_aigc.jsonl'
        GoogleDriveId = '1ZR6FWmWGabMPTf8mszfG-8LXU75xBsHY'
        Sha256 = '288d6ec75512301dd5accaa22205204ce626d13b61753bc3e7ff005061108659'
    }
)

$resolvedOutput = [System.IO.Path]::GetFullPath($OutputDirectory)
[System.IO.Directory]::CreateDirectory($resolvedOutput) | Out-Null

foreach ($dataset in $datasets) {
    $destination = Join-Path $resolvedOutput $dataset.Name

    if (Test-Path -LiteralPath $destination) {
        $existingHash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
        if ($existingHash -eq $dataset.Sha256) {
            Write-Host "Verified existing file: $($dataset.Name)"
            continue
        }

        throw "Existing file failed SHA-256 validation: $destination"
    }

    $downloadUrl = "https://drive.usercontent.google.com/download?id=$($dataset.GoogleDriveId)&export=download&confirm=t"
    Write-Host "Downloading: $($dataset.Name)"
    Invoke-WebRequest -Uri $downloadUrl -OutFile $destination -UseBasicParsing -TimeoutSec 180

    $downloadedHash = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($downloadedHash -ne $dataset.Sha256) {
        throw "Downloaded file failed SHA-256 validation: $destination"
    }

    Write-Host "Downloaded and verified: $($dataset.Name)"
}
