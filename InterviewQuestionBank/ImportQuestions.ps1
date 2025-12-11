# PowerShell Script to Import Questions from Markdown Files
# Run this after the database is created

Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Question Import Script" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host ""

# Connection string
$connectionString = "Data Source=app.db"

# Markdown files mapping
$markdownFiles = @{
    "../Q91_Q99_DotNet_Advanced.md" = @{ CategoryId = 3; StartQ = 91; EndQ = 99 }
    "../Q100_Q115_Azure_Cloud.md" = @{ CategoryId = 4; StartQ = 100; EndQ = 115 }
    "../Q172_Q200_SQL_Database.md" = @{ CategoryId = 7; StartQ = 172; EndQ = 200 }
    # Add more files as needed
}

Write-Host "This script will import questions from your markdown files." -ForegroundColor Yellow
Write-Host "Files to process:" -ForegroundColor Yellow
foreach ($file in $markdownFiles.Keys) {
    Write-Host "  - $file" -ForegroundColor Gray
}
Write-Host ""

$response = Read-Host "Do you want to continue? (Y/N)"
if ($response -ne "Y" -and $response -ne "y") {
    Write-Host "Import cancelled." -ForegroundColor Red
    exit
}

Write-Host ""
Write-Host "Starting import..." -ForegroundColor Green

# Function to parse markdown and extract questions
function Parse-MarkdownQuestions {
    param (
        [string]$FilePath,
        [int]$CategoryId
    )

    if (-not (Test-Path $FilePath)) {
        Write-Host "  [SKIP] File not found: $FilePath" -ForegroundColor Yellow
        return @()
    }

    $content = Get-Content $FilePath -Raw
    $questions = @()

    # Simple regex to find questions (## Q\d+:)
    $pattern = '##\s+Q(\d+):\s+(.+?)(?=\n##\s+Q\d+:|\Z)'
    $matches = [regex]::Matches($content, $pattern, [System.Text.RegularExpressions.RegexOptions]::Singleline)

    foreach ($match in $matches) {
        $questionNumber = [int]$match.Groups[1].Value
        $questionContent = $match.Groups[2].Value.Trim()

        # Extract title (first line)
        $lines = $questionContent -split "`n"
        $title = $lines[0].Trim()
        if ($title.Length > 500) {
            $title = $title.Substring(0, 497) + "..."
        }

        # Determine difficulty based on keywords
        $difficulty = 1 # Intermediate by default
        if ($questionContent -match "basic|fundamental|introduction|simple") {
            $difficulty = 0 # Beginner
        }
        elseif ($questionContent -match "advanced|complex|optimization|performance|architecture") {
            $difficulty = 2 # Advanced
        }

        $question = @{
            QuestionNumber = $questionNumber
            Title = $title
            Content = $questionContent
            CategoryId = $CategoryId
            Difficulty = $difficulty
        }

        $questions += $question
    }

    return $questions
}

# Import questions to database
$totalImported = 0

foreach ($file in $markdownFiles.Keys) {
    $fileInfo = $markdownFiles[$file]
    Write-Host "Processing: $file" -ForegroundColor Cyan

    $questions = Parse-MarkdownQuestions -FilePath $file -CategoryId $fileInfo.CategoryId

    if ($questions.Count -eq 0) {
        Write-Host "  [WARNING] No questions found in file" -ForegroundColor Yellow
        continue
    }

    Write-Host "  Found $($questions.Count) questions" -ForegroundColor Green

    # Generate SQL for bulk insert
    $insertStatements = @()
    foreach ($q in $questions) {
        $title = $q.Title -replace "'", "''"
        $content = $q.Content -replace "'", "''"

        $sql = @"
INSERT INTO Questions (QuestionNumber, Title, Content, CategoryId, Difficulty, IsPublished, CreatedDate, ViewCount)
VALUES ($($q.QuestionNumber), '$title', '$content', $($q.CategoryId), $($q.Difficulty), 1, datetime('now'), 0);
"@
        $insertStatements += $sql
    }

    # Write SQL to temporary file
    $tempSqlFile = "temp_import_$($fileInfo.CategoryId).sql"
    $insertStatements | Out-File -FilePath $tempSqlFile -Encoding UTF8

    Write-Host "  Created SQL file: $tempSqlFile" -ForegroundColor Gray
    Write-Host "  You can import this manually using SQLite tools" -ForegroundColor Gray

    $totalImported += $questions.Count
}

Write-Host ""
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Import Summary" -ForegroundColor Cyan
Write-Host "==================================" -ForegroundColor Cyan
Write-Host "Total questions prepared: $totalImported" -ForegroundColor Green
Write-Host ""
Write-Host "SQL files have been created. To import them:" -ForegroundColor Yellow
Write-Host "1. Download DB Browser for SQLite" -ForegroundColor White
Write-Host "2. Open app.db" -ForegroundColor White
Write-Host "3. Go to 'Execute SQL' tab" -ForegroundColor White
Write-Host "4. Load and execute the temp_import_*.sql files" -ForegroundColor White
Write-Host ""
Write-Host "OR use command line:" -ForegroundColor Yellow
Write-Host "  sqlite3 app.db < temp_import_3.sql" -ForegroundColor White
Write-Host ""
Write-Host "After import, run:" -ForegroundColor Green
Write-Host "  dotnet run" -ForegroundColor Cyan
Write-Host ""
Write-Host "Done!" -ForegroundColor Green
