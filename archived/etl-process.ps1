# Usage: ./convert.ps1 MY_FILE.etl

param (
    [string]$etl
)

# Function to download a file if it doesn't exist
function Download-File {
    param (
        [string]$url,
        [string]$outputPath
    )

    if (-not (Test-Path $outputPath)) {
        Write-Host "Downloading $url..."
        Invoke-WebRequest -Uri $url -OutFile $outputPath
        Write-Host "Download completed."
    }
}

# # Function to download a file if it doesn't exist
# function Download-File {
#     param (
#         [string]$url,
#         [string]$outputPath
#     )
# 
#     if (-not (Test-Path $outputPath)) {
#         Write-Host "Downloading $url..."
#         $webClient = New-Object System.Net.WebClient
#         $webClient.DownloadFile($url, $outputPath)
#         Write-Host "Download completed."
#     }
# }

# Define URLs and temporary file paths
$gzipUrl = "https://recolic.net/setup/win/gzip_1.10.exe"
$etl2pcapngUrl = "https://recolic.net/setup/win/etl2pcapng_1.11.0.exe"
$tmpDirectory = $env:TEMP
$gzipExe = Join-Path $tmpDirectory "gzip_1.10.exe"
$etl2pcapngExe = Join-Path $tmpDirectory "etl2pcapng_1.11.0.exe"
$outputPcapng = Join-Path $tmpDirectory "output_temp.pcapng"
$outputCsv = Join-Path $tmpDirectory "output_temp.csv"

# Create temporary directory if it doesn't exist
if (-not (Test-Path $tmpDirectory)) {
    New-Item -ItemType Directory -Path $tmpDirectory | Out-Null
}

# Download gzip if it doesn't exist
Download-File -url $gzipUrl -outputPath $gzipExe

# Download etl2pcapng if it doesn't exist
Download-File -url $etl2pcapngUrl -outputPath $etl2pcapngExe

# Convert ETL to pcapng
& $etl2pcapngExe $etl $outputPcapng

##Disabled
## # Convert ETL to CSV using netsh
## netsh trace convert input=$etl output=$outputCsv dump=csv

# Compress the output files
Start-Process -FilePath $gzipExe -ArgumentList $outputPcapng -Wait
## Start-Process -FilePath $gzipExe -ArgumentList $outputCsv -Wait

