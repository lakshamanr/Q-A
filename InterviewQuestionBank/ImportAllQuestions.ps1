# Complete Question Import Script
# This script stops running processes, rebuilds, and imports all questions

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Interview Question Bank Import Tool  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

$projectPath = "c:\Users\lakshaman.rokade\source\repos\Q-A\InterviewQuestionBank"
Set-Location $projectPath

# Step 1: Stop all running instances
Write-Host "[1/5] Stopping running processes..." -ForegroundColor Yellow
try {
    $processes = Get-Process | Where-Object { $_.ProcessName -eq "InterviewQuestionBank" }
    if ($processes) {
        foreach ($proc in $processes) {
            Write-Host "  - Stopping process $($proc.Id)..." -ForegroundColor Gray
            Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue
        }
        Start-Sleep -Seconds 2
        Write-Host "  ✓ Processes stopped" -ForegroundColor Green
    } else {
        Write-Host "  ✓ No running processes found" -ForegroundColor Green
    }
} catch {
    Write-Host "  ! Warning: $($_.Exception.Message)" -ForegroundColor Yellow
}

# Step 2: Clean build artifacts
Write-Host ""
Write-Host "[2/5] Cleaning build artifacts..." -ForegroundColor Yellow
try {
    if (Test-Path "bin") {
        Remove-Item -Path "bin" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Removed bin folder" -ForegroundColor Green
    }
    if (Test-Path "obj") {
        Remove-Item -Path "obj" -Recurse -Force -ErrorAction SilentlyContinue
        Write-Host "  ✓ Removed obj folder" -ForegroundColor Green
    }
} catch {
    Write-Host "  ! Warning: Could not clean all artifacts" -ForegroundColor Yellow
}

# Step 3: Build the project
Write-Host ""
Write-Host "[3/5] Building project..." -ForegroundColor Yellow
$buildOutput = dotnet build --configuration Release 2>&1
if ($LASTEXITCODE -eq 0) {
    Write-Host "  ✓ Build successful" -ForegroundColor Green
} else {
    Write-Host "  ✗ Build failed!" -ForegroundColor Red
    Write-Host $buildOutput
    Write-Host ""
    Write-Host "Please close Visual Studio and try again." -ForegroundColor Yellow
    exit 1
}

# Step 4: Run the import
Write-Host ""
Write-Host "[4/5] Importing questions from markdown files..." -ForegroundColor Yellow
Write-Host ""

dotnet run --configuration Release --no-build -- --import-questions

if ($LASTEXITCODE -eq 0) {
    Write-Host ""
    Write-Host "  ✓ Import completed successfully" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "  ✗ Import encountered errors" -ForegroundColor Red
    exit 1
}

# Step 5: Verify the import
Write-Host ""
Write-Host "[5/5] Verifying imported questions..." -ForegroundColor Yellow
Write-Host ""

dotnet run --configuration Release --no-build -- --verify-import

Write-Host ""
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "  Import Process Complete!  " -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "Next steps:" -ForegroundColor Yellow
Write-Host "1. Review the verification results above" -ForegroundColor White
Write-Host "2. Run the web application: dotnet run" -ForegroundColor White
Write-Host "3. Open browser: https://localhost:5001" -ForegroundColor White
Write-Host ""
