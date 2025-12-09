# .NET Interview Mastery Website

A modern, responsive website for browsing and studying 570 .NET developer interview questions.

## 🚀 Features

- **Modern Design**: Clean, professional UI with smooth animations
- **Responsive**: Works perfectly on desktop, tablet, and mobile
- **Search & Filter**: Quickly find questions by keyword, section, or difficulty
- **Code Highlighting**: Syntax-highlighted code examples
- **Interactive**: Modal popups for detailed question viewing
- **Organized Sections**: Questions grouped by topic
- **Navigation**: Easy pagination and keyboard shortcuts

## 📁 File Structure

```
website/
├── index.html           # Main HTML file
├── styles.css           # All styling
├── script.js            # JavaScript functionality
├── questions-data.js    # Question database
└── README.md            # This file
```

## 🎯 Sections Covered

1. **Advanced .NET & ASP.NET Core** (Q91-Q99)
   - Dependency Injection
   - Middleware Pipeline
   - Authentication & Authorization
   - Async/Await Patterns

2. **Azure Cloud Services** (Q100-Q120)
   - Azure Service Bus
   - Event Hub & Event Grid
   - Redis Cache
   - Azure SQL Database

3. **DevOps & CI/CD** (Q121-Q130)
   - Azure DevOps
   - Docker & Kubernetes
   - CI/CD Pipelines

4. **Microservices Basics** (Q131-Q140)
   - Architecture Patterns
   - API Gateway
   - Service Discovery

5. **Advanced Microservices** (Q141-Q171)
   - CQRS & Event Sourcing
   - Saga Pattern
   - Circuit Breaker

6. **SQL Server & Database** (Q172-Q200)
   - SQL Joins & Indexes
   - Stored Procedures & Triggers
   - Query Optimization

## 🔧 How to Use

### Option 1: Direct File Opening
1. Open `index.html` in your web browser
2. Browse questions, search, and filter

### Option 2: Local Web Server (Recommended)
For better performance with code highlighting:

**Using Python:**
```bash
cd website
python -m http.server 8000
```
Then visit: http://localhost:8000

**Using Node.js:**
```bash
npm install -g http-server
http-server website -p 8000
```
Then visit: http://localhost:8000

**Using VS Code:**
- Install "Live Server" extension
- Right-click `index.html` → "Open with Live Server"

## ⌨️ Keyboard Shortcuts

When viewing a question:
- **Esc** - Close modal
- **← Left Arrow** - Previous question
- **→ Right Arrow** - Next question

## 🎨 Customization

### Change Color Scheme
Edit the CSS variables in `styles.css`:

```css
:root {
    --primary-color: #5B21B6;  /* Purple */
    --secondary-color: #7C3AED;
    /* Modify these to change the theme */
}
```

### Add More Questions
Add questions to `questions-data.js` following this structure:

```javascript
{
    number: 91,
    title: "Your question title",
    section: "dotnet-advanced",
    difficulty: "intermediate", // beginner, intermediate, or advanced
    content: `Your markdown content here`
}
```

## 📱 Responsive Breakpoints

- **Desktop**: > 1200px
- **Tablet**: 768px - 1200px
- **Mobile**: < 768px

## 🔗 Dependencies

- **Font Awesome 6.4.0** - Icons
- **Highlight.js 11.9.0** - Code syntax highlighting

Both loaded via CDN, no installation required.

## 🌟 Features in Detail

### Search Functionality
- Real-time search as you type
- Searches in question titles and content
- Debounced for performance

### Filtering
- Filter by section (topic)
- Filter by difficulty level
- Combine with search for precise results

### Code Examples
- Syntax highlighted C# and SQL
- Copy-friendly formatting
- Dark theme for better readability

### Pagination
- 10 questions per page
- Easy navigation between pages
- Scroll to top on page change

## 🐛 Troubleshooting

**Code highlighting not working?**
- Check internet connection (CDN dependencies)
- Try using a local web server instead of opening file directly

**Styles not loading?**
- Ensure all files are in the same directory
- Check browser console for errors

**Questions not displaying?**
- Verify `questions-data.js` is loaded
- Check browser console for JavaScript errors

## 📝 Adding Real Question Data

To populate with actual questions from your markdown files:

1. Parse the markdown files (Q91-Q200)
2. Extract questions and answers
3. Add them to `questions-data.js` array
4. Follow the existing structure

Example script structure:
```javascript
{
    number: 175,
    title: "What are database triggers?",
    section: "sql-database",
    difficulty: "advanced",
    content: `
### Full markdown content here
Including code examples, tables, etc.
    `
}
```

## 🚀 Deployment

### GitHub Pages
1. Push to GitHub repository
2. Enable GitHub Pages in Settings
3. Select main branch
4. Website will be available at: `https://username.github.io/repo-name/website/`

### Netlify
1. Drag and drop the `website` folder to Netlify
2. Or connect your GitHub repository
3. Auto-deploy on every commit

### Azure Static Web Apps
1. Upload via Azure Portal or CLI
2. Configure custom domain if needed

## 📄 License

This question bank is for educational purposes.

## 🤝 Contributing

To add or improve questions:
1. Edit `questions-data.js`
2. Follow the existing format
3. Test locally before committing

## 💡 Tips for Interview Preparation

1. **Study Section by Section**: Master one topic before moving to next
2. **Practice Coding**: Don't just read - implement the examples
3. **Understand, Don't Memorize**: Focus on concepts, not word-for-word answers
4. **Use Search**: Find related questions across sections
5. **Track Progress**: Mark questions you've mastered

## 📧 Support

For questions or issues, refer to the main documentation in the parent folder.

---

**Built with ❤️ for .NET Developers**

Good luck with your interviews! 🎯
