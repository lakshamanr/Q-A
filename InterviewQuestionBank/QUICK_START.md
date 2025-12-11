# Quick Start Guide - Interview Question Bank

## Current Status

✅ **89 questions imported successfully**
⚠️ **Need to re-import after fixing regex pattern for Azure/DevOps questions**

## How to Complete the Import

### Step 1: Stop the Running Process
The previous import is still running. You need to:
- Press `Ctrl+C` in the terminal, OR
- Close the terminal window

### Step 2: Rebuild and Re-import
```bash
cd "c:\Users\lakshaman.rokade\source\repos\Q-A\InterviewQuestionBank"

# Rebuild with the fixed regex pattern
dotnet build

# Re-run import (will skip existing 89 questions and add the missing ones)
dotnet run --import-questions

# Verify all questions imported
dotnet run --verify-import
```

Expected result: **~120-140 total questions** across all 7 categories.

## Using the Application

### Run the Web App
```bash
dotnet run
```

Then open your browser to: **https://localhost:5001**

### Features Available

1. **Browse Questions**
   - View all questions with search and filters
   - Filter by category or difficulty
   - Pagination (15 questions per page)

2. **View Question Details**
   - Full markdown rendering with syntax highlighting
   - View count tracking
   - Previous/Next navigation

3. **User Features** (after login/register)
   - ⭐ Favorite questions
   - ✓ Mark questions as completed
   - 📊 Track your progress
   - 📝 Add personal notes

### Test Accounts
To create a test account:
1. Click "Register" in the top right
2. Enter email and password
3. Confirm registration (for development, confirmation is required)

## CLI Commands

### Import Questions
```bash
dotnet run --import-questions
```
Imports all markdown files from the parent directory.

### Verify Import
```bash
dotnet run --verify-import
```
Shows statistics: total questions, breakdown by category and difficulty.

### Run Web App
```bash
dotnet run
```
Starts the web application on https://localhost:5001

## What Was Fixed

**Problem**: Azure and DevOps markdown files use bold headers (`## **Q100:**`) which weren't being parsed.

**Solution**: Updated regex pattern to handle both plain and bold formats:
```csharp
// Now matches both:
// ## Q21: Title         (plain)
// ## **Q100:** Title    (bold)
var pattern = @"##\s+\*{0,2}Q(\d+):\*{0,2}\s+(.+?)";
```

## Database Location

The SQLite database is located at:
```
c:\Users\lakshaman.rokade\source\repos\Q-A\InterviewQuestionBank\app.db
```

You can browse it with tools like:
- DB Browser for SQLite
- SQLiteStudio
- VS Code SQLite extension

## Project Structure

```
InterviewQuestionBank/
├── Controllers/
│   ├── HomeController.cs          # Landing page with categories
│   └── QuestionsController.cs     # Question browsing and CRUD
├── Data/
│   └── ApplicationDbContext.cs    # EF Core context with seeded categories
├── Models/
│   ├── Category.cs                # 7 categories (C#, MVC, Azure, etc.)
│   ├── Question.cs                # Main question model
│   ├── UserFavorite.cs            # User favorites tracking
│   └── UserProgress.cs            # User progress tracking
├── Services/
│   └── QuestionImportService.cs   # Import from markdown files ⭐ UPDATED
├── Views/
│   ├── Home/Index.cshtml          # Landing page with hero and categories
│   ├── Questions/
│   │   ├── Index.cshtml           # Browse all questions
│   │   ├── Details.cshtml         # View question with markdown
│   │   ├── MyFavorites.cshtml     # User favorites list
│   │   └── MyProgress.cshtml      # User progress dashboard
│   └── Shared/_Layout.cshtml      # Navigation and layout
├── app.db                         # SQLite database (89 questions)
├── Program.cs                     # Startup with CLI commands ⭐ UPDATED
└── IMPORT_STATUS.md              # Detailed import report
```

## Markdown Files Being Imported

Located in parent directory (`Q-A/`):
- Q21_Q25_C#.md ✅
- Q26_Q30_C#.md ✅
- Q31_Q34_C#.md ✅
- Q35_Q43_async_C#.md ✅
- Q44_Q50_C#.md ✅
- Q51_Q60_mvc_batch.md ✅
- Q61_Q70_mvc_batch.md ✅
- Q71_Q80_mvc_batch.md ✅
- Q81_Q90_mvc_batch.md ✅
- Q91_Q99_DotNet_Advanced.md ✅
- Q100_Q115_Azure_Cloud.md ⏳ (needs re-import with fix)
- Q108-Q115_Azure.md ⏳ (needs re-import with fix)
- Q111_Q120_continuation.md ⏳ (needs re-import with fix)
- Q113_Q120_final.md ⏳ (needs re-import with fix)
- Q121_Q140_DevOps_Microservices.md ⏳ (needs re-import with fix)
- Q125_Q140_complete.md ⏳ (needs re-import with fix)
- Q141_Q171_Microservices_Advanced.md ✅
- Q172_Q200_SQL_Database.md ✅

## Categories

1. **C# Fundamentals** (Q21-Q50) - Purple 🟣
2. **ASP.NET MVC** (Q51-Q90) - Green 🟢
3. **Advanced .NET** (Q91-Q99) - Red 🔴
4. **Azure Cloud** (Q100-Q120) - Blue 🔵
5. **DevOps & Microservices** (Q121-Q140) - Purple 🟣
6. **Advanced Microservices** (Q141-Q171) - Orange 🟠
7. **SQL Server & Database** (Q172-Q200) - Cyan 🔵

## Troubleshooting

### Process Lock Error
If you see "file is locked by: InterviewQuestionBank.exe":
1. Close all terminal windows running the app
2. Or use Task Manager to end the process
3. Then rebuild with `dotnet build`

### Missing Questions After Import
Run verification: `dotnet run --verify-import`
Check the logs for specific file parsing errors.

### Database Issues
If you need to reset the database:
```bash
# Delete the database
rm app.db

# Recreate from migrations
dotnet ef database update
```

This will recreate the database with seeded categories, but you'll need to re-import questions.

## Next Steps

1. ✅ Stop the running process (Ctrl+C or close terminal)
2. ✅ Run `dotnet build` to compile the fixed regex
3. ✅ Run `dotnet run --import-questions` to import missing questions
4. ✅ Run `dotnet run --verify-import` to confirm all categories have questions
5. ✅ Run `dotnet run` to test the web application
6. ✅ Register a user account and test favorites/progress features

---

**Ready to continue!** Just stop the running process and follow the steps above.
