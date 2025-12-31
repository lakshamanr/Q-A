# Question Import Guide

This guide will help you import all 111 new questions (Q461-Q571) into your InterviewQuestionBank database.

## 📋 Prerequisites

- ✅ SQL Server or SQLite database (InterviewQuestionBank)
- ✅ ASP.NET Core application built successfully
- ✅ PowerShell (for Windows) or bash (for Linux/Mac)
- ✅ All markdown files in the Q-A folder

---

## 🔄 Two Import Methods

You can choose either method:

### Method 1: SQL Scripts (Direct Database Insert) - RECOMMENDED
Import via SQL scripts - faster and more reliable for bulk operations.

### Method 2: PowerShell Script (Markdown Parser)
Import by parsing markdown files - useful if you make changes to markdown content.

---

## 📊 Method 1: SQL Scripts (RECOMMENDED)

### Step 1: Execute SQL Scripts

You have **2 SQL scripts** to run in order:

#### Script 1: Add Q461-Q500 (40 questions)

**File**: `Add_Q461_Q500_Questions.sql`

**Using SQL Server Management Studio (SSMS)**:
```sql
-- 1. Open SSMS and connect to your database
-- 2. File → Open → File → Select Add_Q461_Q500_Questions.sql
-- 3. Make sure you're connected to the correct database
USE InterviewQuestionBank;
GO

-- 4. Execute the script (F5 or Execute button)
-- 5. Check output for: "Successfully added 40 questions (Q461-Q500)"
```

**Using Command Line (sqlcmd)**:
```bash
# Windows
sqlcmd -S localhost -d InterviewQuestionBank -i Add_Q461_Q500_Questions.sql

# With authentication
sqlcmd -S localhost -U sa -P YourPassword -d InterviewQuestionBank -i Add_Q461_Q500_Questions.sql
```

**Using SQLite (if using SQLite)**:
```bash
# Navigate to Q-A folder
cd c:\Users\lakshaman.rokade\source\repos\Q-A

# Run the script
sqlite3 InterviewQuestionBank/app.db < Add_Q461_Q500_Questions.sql
```

#### Script 2: Add Q501-Q571 (71 questions)

**File**: `Add_Q501_Q571_Questions.sql`

**Using SSMS**:
```sql
-- 1. File → Open → File → Select Add_Q501_Q571_Questions.sql
-- 2. Execute (F5)
-- 3. Check output for: "Successfully added 71 questions (Q501-Q571)"
```

**Using Command Line**:
```bash
# SQL Server
sqlcmd -S localhost -d InterviewQuestionBank -i Add_Q501_Q571_Questions.sql

# SQLite
sqlite3 InterviewQuestionBank/app.db < Add_Q501_Q571_Questions.sql
```

### Step 2: Verify Import

**Using SSMS**:
```sql
-- Check total questions
SELECT COUNT(*) AS TotalQuestions FROM Questions;
-- Expected: 571 (if all questions imported)

-- Check by category
SELECT
    c.Name AS Category,
    COUNT(q.Id) AS QuestionCount,
    MIN(q.QuestionNumber) AS FirstQuestion,
    MAX(q.QuestionNumber) AS LastQuestion
FROM Categories c
LEFT JOIN Questions q ON c.Id = q.CategoryId
GROUP BY c.Name
ORDER BY MIN(q.QuestionNumber);

-- Check specifically for new questions
SELECT
    QuestionNumber,
    Title,
    Difficulty
FROM Questions
WHERE QuestionNumber BETWEEN 461 AND 571
ORDER BY QuestionNumber;

-- Count new questions
SELECT COUNT(*) AS NewQuestions
FROM Questions
WHERE QuestionNumber BETWEEN 461 AND 571;
-- Expected: 111
```

**Using PowerShell**:
```powershell
# Navigate to project folder
cd c:\Users\lakshaman.rokade\source\repos\Q-A\InterviewQuestionBank

# Run verification
dotnet run --configuration Release -- --verify-import

# List all questions and find gaps
dotnet run --configuration Release -- --list-questions
```

---

## 🔄 Method 2: PowerShell Script (Markdown Parser)

### Step 1: First Create Categories via SQL

Before running the PowerShell import, you **MUST** create the categories first:

```sql
-- Run ONLY the category creation part from Add_Q501_Q571_Questions.sql

INSERT INTO Categories (Name, Description, Icon, ColorCode, DisplayOrder, QuestionRangeStart, QuestionRangeEnd)
VALUES
('Advanced Testing & Leadership', 'Test-Driven Development, mutation testing, performance testing, and technical leadership', 'fas fa-vial', '#9B59B6', 24, 461, 480),
('Security & OWASP', 'OWASP Top 10, security best practices, and vulnerability prevention', 'fas fa-shield-alt', '#E74C3C', 25, 481, 500),
('Leadership & Team Management', 'Technical leadership, team management, and soft skills for senior engineers', 'fas fa-users', '#3498DB', 26, 501, 520),
('System Design & Scalability', 'Large-scale system design, scalability patterns, and architecture', 'fas fa-project-diagram', '#2ECC71', 27, 521, 540),
('Behavioral Questions - Core', 'Essential behavioral interview questions using STAR format', 'fas fa-comments', '#E67E22', 28, 541, 560),
('Behavioral Questions - Advanced', 'Advanced career topics and final interview preparation', 'fas fa-star', '#F39C12', 29, 561, 571);
```

### Step 2: Run PowerShell Import Script

**Using PowerShell**:
```powershell
# Navigate to project folder
cd c:\Users\lakshaman.rokade\source\repos\Q-A\InterviewQuestionBank

# Run the import script
.\ImportAllQuestions.ps1
```

**Expected Output**:
```
========================================
  Interview Question Bank Import Tool
========================================

[1/5] Stopping running processes...
  ✓ No running processes found

[2/5] Cleaning build artifacts...
  ✓ Removed bin folder
  ✓ Removed obj folder

[3/5] Building project...
  ✓ Build successful

[4/5] Importing questions from markdown files...

Processing file: c:\Users\lakshaman.rokade\source\repos\Q-A\Q461_Q480_Advanced_Testing_Leadership.md
Parsed 20 questions from Q461_Q480_Advanced_Testing_Leadership.md
Import completed: 20 imported, 0 skipped, 0 errors

Processing file: c:\Users\lakshaman.rokade\source\repos\Q-A\Q481_Q500_Security_OWASP.md
Parsed 20 questions from Q481_Q500_Security_OWASP.md
Import completed: 20 imported, 0 skipped, 0 errors

Processing file: c:\Users\lakshaman.rokade\source\repos\Q-A\Q501_Q520_Leadership_Team_Management.md
Parsed 20 questions from Q501_Q520_Leadership_Team_Management.md
Import completed: 20 imported, 0 skipped, 0 errors

Processing file: c:\Users\lakshaman.rokade\source\repos\Q-A\Q521_Q540_System_Design_Scalability.md
Parsed 20 questions from Q521_Q540_System_Design_Scalability.md
Import completed: 20 imported, 0 skipped, 0 errors

Processing file: c:\Users\lakshaman.rokade\source\repos\Q-A\Q541_Q560_Behavioral_Questions.md
Parsed 20 questions from Q541_Q560_Behavioral_Questions.md
Import completed: 20 imported, 0 skipped, 0 errors

Processing file: c:\Users\lakshaman.rokade\source\repos\Q-A\Q561_Q571_Final_Behavioral_Questions.md
Parsed 11 questions from Q561_Q571_Final_Behavioral_Questions.md
Import completed: 11 imported, 0 skipped, 0 errors

  ✓ Import completed successfully

[5/5] Verifying imported questions...

=== Question Import Verification ===

Total Questions: 571

Questions by Category:
  C# Fundamentals: 50 questions
  ASP.NET MVC: 40 questions
  Azure Cloud: 45 questions
  ...
  Advanced Testing & Leadership: 20 questions
  Security & OWASP: 20 questions
  Leadership & Team Management: 20 questions
  System Design & Scalability: 20 questions
  Behavioral Questions - Core: 20 questions
  Behavioral Questions - Advanced: 11 questions

Questions by Difficulty:
  Beginner: 150 questions
  Intermediate: 320 questions
  Advanced: 101 questions

Question Number Range: Q1 - Q571

========================================
  Import Process Complete!
========================================

Next steps:
1. Review the verification results above
2. Run the web application: dotnet run
3. Open browser: https://localhost:5001
```

---

## ❗ Troubleshooting

### Issue 1: "Category with ID X not found"

**Problem**: Categories don't exist in database.

**Solution**:
```sql
-- Run the category creation from SQL scripts first
-- See Step 1 above
```

### Issue 2: "Questions already exist, skipping"

**Problem**: Questions are already in the database (duplicate prevention).

**Solution**:
```sql
-- Check existing questions
SELECT QuestionNumber, Title FROM Questions
WHERE QuestionNumber BETWEEN 461 AND 571
ORDER BY QuestionNumber;

-- If you want to re-import (delete first)
DELETE FROM Questions WHERE QuestionNumber BETWEEN 461 AND 571;
-- Then re-run import
```

### Issue 3: "Build failed"

**Problem**: Project won't compile.

**Solution**:
```powershell
# Clean and rebuild
dotnet clean
dotnet build

# Or close Visual Studio and try again
# Sometimes VS locks files
```

### Issue 4: "File not found: *.md"

**Problem**: Markdown files not in correct location.

**Solution**:
```powershell
# Verify files exist
Get-ChildItem c:\Users\lakshaman.rokade\source\repos\Q-A\Q*_*.md

# Should show:
# Q461_Q480_Advanced_Testing_Leadership.md
# Q481_Q500_Security_OWASP.md
# Q501_Q520_Leadership_Team_Management.md
# Q521_Q540_System_Design_Scalability.md
# Q541_Q560_Behavioral_Questions.md
# Q561_Q571_Final_Behavioral_Questions.md
```

### Issue 5: PowerShell Execution Policy

**Problem**: "Script cannot be executed because execution policy is disabled"

**Solution**:
```powershell
# Check current policy
Get-ExecutionPolicy

# Set to allow scripts (run as Administrator)
Set-ExecutionPolicy RemoteSigned -Scope CurrentUser

# Or run script with bypass
PowerShell -ExecutionPolicy Bypass -File .\ImportAllQuestions.ps1
```

---

## ✅ Verification Checklist

After import, verify:

- [ ] **Total questions**: 571 (run `SELECT COUNT(*) FROM Questions`)
- [ ] **New questions**: 111 (Q461-Q571)
- [ ] **Categories exist**: 29 categories total
- [ ] **No gaps**: All questions from Q1-Q571 present
- [ ] **Difficulty levels**: Beginner (1), Intermediate (2), Advanced (3)
- [ ] **Tags populated**: Each question has comma-separated tags
- [ ] **Content present**: Each question has Title and Content

**Run verification query**:
```sql
-- Complete verification
WITH QuestionStats AS (
    SELECT
        COUNT(*) AS TotalQuestions,
        MIN(QuestionNumber) AS MinQ,
        MAX(QuestionNumber) AS MaxQ,
        COUNT(DISTINCT CategoryId) AS TotalCategories
    FROM Questions
)
SELECT
    *,
    (MaxQ - MinQ + 1) AS ExpectedQuestions,
    (MaxQ - MinQ + 1) - TotalQuestions AS MissingQuestions
FROM QuestionStats;
```

---

## 🚀 Running the Application

After successful import:

```powershell
# Navigate to project folder
cd c:\Users\lakshaman.rokade\source\repos\Q-A\InterviewQuestionBank

# Run the application
dotnet run

# Or with hot reload
dotnet watch run

# Open browser
start https://localhost:5001
```

**Verify in UI**:
1. Navigate to Questions page
2. Filter by category "Leadership & Team Management"
3. Check that Q501-Q520 appear
4. Filter by category "System Design & Scalability"
5. Check that Q521-Q540 appear
6. Filter by difficulty "Advanced"
7. Search for "STAR format"

---

## 📊 Summary of New Questions

| Question Range | Count | Category | Topic |
|----------------|-------|----------|-------|
| Q461-Q480 | 20 | Advanced Testing & Leadership | TDD, Mutation Testing, Performance Testing, Leadership |
| Q481-Q500 | 20 | Security & OWASP | OWASP Top 10, XSS, CSRF, SQL Injection, Password Security |
| Q501-Q520 | 20 | Leadership & Team Management | Decisions, Prioritization, Team Management, Code Quality |
| Q521-Q540 | 20 | System Design & Scalability | URL Shortener, Rate Limiter, E-commerce, CAP Theorem |
| Q541-Q560 | 20 | Behavioral Questions - Core | STAR Format, Strengths, Failures, Conflicts |
| Q561-Q571 | 11 | Behavioral Questions - Advanced | Simplification, Motivation, Career Goals, Salary |
| **TOTAL** | **111** | **6 Categories** | **Complete Interview Prep** |

---

## 🎯 Next Steps

1. ✅ **Execute SQL scripts** (Add_Q461_Q500_Questions.sql, Add_Q501_Q571_Questions.sql)
2. ✅ **Verify import** (check question counts)
3. ✅ **Run application** (dotnet run)
4. ✅ **Test in browser** (search, filter, navigate)
5. ✅ **Start practicing** (review STAR format examples)

---

## 📝 Additional Commands

```powershell
# List all questions with gaps analysis
dotnet run -- --list-questions

# Re-verify import after changes
dotnet run -- --verify-import

# Check database schema
dotnet ef dbcontext info

# Create new migration (if schema changed)
dotnet ef migrations add AddNewQuestions

# Update database with migrations
dotnet ef database update
```

---

**Good luck with your interview preparation! 🚀**

All 571 questions are ready to help you ace your interviews!
