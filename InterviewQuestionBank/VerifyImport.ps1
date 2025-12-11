# PowerShell script to verify imported questions
$dbPath = "app.db"

Write-Host "=== Question Import Verification ===" -ForegroundColor Cyan
Write-Host ""

# Install SQLite if not available
if (-not (Get-Command sqlite3 -ErrorAction SilentlyContinue)) {
    Write-Host "SQLite command not found. Using .NET to query database..." -ForegroundColor Yellow

    # Query using dotnet
    dotnet run --configuration Release -- --verify-import
} else {
    # Query using sqlite3
    Write-Host "Categories:" -ForegroundColor Green
    sqlite3 $dbPath "SELECT Id, Name, COUNT(*) as QuestionCount FROM Categories LEFT JOIN Questions ON Categories.Id = Questions.CategoryId GROUP BY Categories.Id, Categories.Name ORDER BY Categories.Id;"

    Write-Host ""
    Write-Host "Total Questions:" -ForegroundColor Green
    sqlite3 $dbPath "SELECT COUNT(*) FROM Questions;"

    Write-Host ""
    Write-Host "Questions by Difficulty:" -ForegroundColor Green
    sqlite3 $dbPath "SELECT Difficulty, COUNT(*) as Count FROM Questions GROUP BY Difficulty;"

    Write-Host ""
    Write-Host "Question Number Range:" -ForegroundColor Green
    sqlite3 $dbPath "SELECT MIN(QuestionNumber) as Min, MAX(QuestionNumber) as Max FROM Questions;"
}
