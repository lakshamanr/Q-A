# Interview Question Bank - ASP.NET Core MVC Application

## 🎯 Overview

A comprehensive ASP.NET Core MVC web application for managing and browsing 570+ .NET developer interview questions with:

- **User Authentication** (ASP.NET Core Identity)
- **SQL Server Database** (Entity Framework Core)
- **Admin Panel** for question management
- **User Features**: Favorites, Progress Tracking
- **Search & Filter** capabilities
- **Markdown Support** for rich content

## 📦 What's Included

### Models
- `Category` - Question categories/sections
- `Question` - Interview questions with markdown content
- `UserFavorite` - User's favorite questions
- `UserProgress` - Track completed questions

### Controllers
- `HomeController` - Landing page with categories
- `QuestionsController` - Browse, search, view questions
- `AccountController` - Login/Register (Identity scaffolded)

### Features
✅ User Registration & Login
✅ Browse Questions by Category
✅ Search & Filter Questions
✅ View Question Details (Markdown → HTML)
✅ Favorite Questions
✅ Track Progress
✅ Pagination
✅ Difficulty Levels (Beginner, Intermediate, Advanced)

## 🚀 Quick Start

### 1. Update Connection String

Edit `appsettings.json`:

```json
{
  "ConnectionStrings": {
    "DefaultConnection": "Server=(localdb)\\mssqllocaldb;Database=InterviewQuestionBank;Trusted_Connection=True;MultipleActiveResultSets=true"
  }
}
```

**Or use SQL Server:**
```json
"DefaultConnection": "Server=localhost;Database=InterviewQuestionBank;Trusted_Connection=True;TrustServerCertificate=True"
```

### 2. Create Database & Run Migrations

```bash
cd InterviewQuestionBank

# Create initial migration
dotnet ef migrations add InitialCreate

# Update database
dotnet ef database update
```

### 3. Run the Application

```bash
dotnet run
```

Visit: https://localhost:5001

## 📊 Database Schema

```
ApplicationDbContext
├── AspNetUsers (Identity)
├── AspNetRoles (Identity)
├── Categories
│   ├── Id (PK)
│   ├── Name
│   ├── Description
│   ├── Icon
│   ├── ColorCode
│   └── QuestionRangeStart/End
├── Questions
│   ├── Id (PK)
│   ├── QuestionNumber
│   ├── Title
│   ├── Content (Markdown)
│   ├── ContentHtml
│   ├── Difficulty (Enum)
│   ├── CategoryId (FK)
│   ├── ViewCount
│   └── IsPublished
├── UserFavorites
│   ├── Id (PK)
│   ├── UserId (FK)
│   ├── QuestionId (FK)
│   └── AddedDate
└── UserProgresses
    ├── Id (PK)
    ├── UserId (FK)
    ├── QuestionId (FK)
    ├── IsCompleted
    └── CompletedDate
```

## 📝 Seeding Questions from Markdown Files

### Option 1: Manual Import (SQL Script)

Create `SeedQuestions.sql`:

```sql
-- Insert question from markdown
INSERT INTO Questions (QuestionNumber, Title, Content, CategoryId, Difficulty, IsPublished, CreatedDate)
VALUES
(91, 'What is Dependency Injection in ASP.NET Core?',
'**Dependency Injection** is a design pattern...

### Example:
```csharp
builder.Services.AddScoped<IProductService, ProductService>();
```',
3, 1, 1, GETDATE());
```

### Option 2: Create Data Seeder Service

Create `Services/QuestionSeederService.cs`:

```csharp
public class QuestionSeederService
{
    private readonly ApplicationDbContext _context;

    public async Task SeedFromMarkdownAsync(string filePath, int categoryId)
    {
        var content = await File.ReadAllTextAsync(filePath);
        // Parse markdown and extract questions
        // Insert into database
    }
}
```

### Option 3: Use the Parser Script (Recommended)

I'll create a PowerShell script to parse all your markdown files:

```powershell
.\SeedQuestions.ps1
```

## 🔐 Default Admin Account

After first run, create admin account:

```bash
dotnet run -- seed-admin
```

Or manually register and assign role:

```sql
INSERT INTO AspNetRoles (Id, Name, NormalizedName)
VALUES (NEWID(), 'Admin', 'ADMIN');

-- Assign role to user
INSERT INTO AspNetUserRoles (UserId, RoleId)
VALUES ('user-id-here', 'role-id-here');
```

## 🎨 Customization

### Change Theme Colors

Edit `wwwroot/css/site.css`:

```css
:root {
    --primary-color: #5B21B6;
    --secondary-color: #7C3AED;
}
```

### Add More Categories

Update `ApplicationDbContext.OnModelCreating()`:

```csharp
builder.Entity<Category>().HasData(
    new Category {
        Id = 8,
        Name = "Design Patterns",
        Description = "Software Design Patterns",
        Icon = "fa-drafting-compass",
        ColorCode = "#F59E0B"
    }
);
```

## 📱 Features to Implement

Current features work out of the box. Additional features you can add:

- [ ] Admin Panel (CRUD for Questions)
- [ ] Export Questions to PDF
- [ ] Code Syntax Highlighting
- [ ] Question Comments/Discussion
- [ ] Study Plans/Roadmaps
- [ ] Question Difficulty Voting
- [ ] Interview Preparation Mode
- [ ] Mobile App (Xamarin/MAUI)

## 🔧 Troubleshooting

### Migration Issues

```bash
# Remove migrations
dotnet ef migrations remove

# Recreate
dotnet ef migrations add InitialCreate
dotnet ef database update
```

### Database Connection Issues

Check SQL Server is running:
```bash
# LocalDB
sqllocaldb start mssqllocaldb

# SQL Server
services.msc → SQL Server → Start
```

### Markdown Not Rendering

Ensure Markdig package is installed:
```bash
dotnet add package Markdig
```

## 📚 Your Markdown Files Structure

Your existing files:
```
Q-A/
├── Comprehensive_Interview_Answers.md
├── Q21_Q25_C#.md
├── Q26_Q30_C#.md
├── ...
├── Q91_Q99_DotNet_Advanced.md
├── Q100_Q115_Azure_Cloud.md
├── Q141_Q171_Microservices_Advanced.md
└── Q172_Q200_SQL_Database.md
```

## 🔄 Next Steps

1. ✅ **Run Migrations** - Create database
2. ✅ **Seed Categories** - Already configured
3. ⏳ **Import Questions** - Use seed script (I'll create this)
4. ⏳ **Test Application** - Register user, browse questions
5. ⏳ **Customize** - Adjust theme, add features

## 📖 API Endpoints

### Questions
- `GET /` - Home page with categories
- `GET /Questions` - Browse all questions
- `GET /Questions/Details/5` - View question #5
- `GET /Questions/Category/1` - Questions in category
- `POST /Questions/ToggleFavorite` - Add/remove favorite
- `POST /Questions/ToggleCompleted` - Mark completed
- `GET /Questions/MyFavorites` - User's favorites
- `GET /Questions/MyProgress` - User's progress

### Account (Identity)
- `GET /Identity/Account/Register` - Register page
- `GET /Identity/Account/Login` - Login page
- `GET /Identity/Account/Logout` - Logout

## 💡 Tips

1. **Use LocalDB for Development** - No SQL Server installation needed
2. **Seed Sample Data First** - Test with a few questions
3. **Enable Detailed Errors** - Set `ASPNETCORE_ENVIRONMENT=Development`
4. **Use EF Core Tools** - `dotnet ef` commands are helpful

## 🐛 Known Issues

- Large markdown files may take time to parse
- Code blocks need syntax highlighting library (add Highlight.js)
- Search is case-sensitive (can be improved)

## 📄 License

Educational/Personal Use

---

**Built with ASP.NET Core 9.0 + Entity Framework Core 9.0**

🎯 Ready for your 570 interview questions!
