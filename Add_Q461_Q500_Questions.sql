-- Add Q461-Q500 Questions to InterviewQuestionBank Database
-- Run this script to populate the database with new questions

-- First, add categories for the new question ranges
INSERT INTO Categories (Name, Description, Icon, ColorCode, DisplayOrder, QuestionRangeStart, QuestionRangeEnd)
VALUES
('Advanced Testing & Leadership', 'Test-Driven Development, mutation testing, performance testing, and technical leadership', 'fas fa-vial', '#9B59B6', 24, 461, 480),
('Security & OWASP', 'OWASP Top 10, security best practices, and vulnerability prevention', 'fas fa-shield-alt', '#E74C3C', 25, 481, 500);

-- Get the category IDs
DECLARE @AdvancedTestingCategoryId INT = (SELECT Id FROM Categories WHERE QuestionRangeStart = 461);
DECLARE @SecurityCategoryId INT = (SELECT Id FROM Categories WHERE QuestionRangeStart = 481);

-- Q461-Q480: Advanced Testing & Technical Leadership
INSERT INTO Questions (QuestionNumber, Title, Content, Difficulty, Tags, CategoryId, IsPublished)
VALUES
(461, 'How do you implement Test-Driven Development (TDD)? Explain the Red-Green-Refactor cycle.',
'Test-Driven Development (TDD) is a software development approach where you write tests before writing the actual code. The Red-Green-Refactor cycle consists of three steps:

**RED**: Write a failing test first (test fails because code doesn''t exist yet)
**GREEN**: Write minimal code to make the test pass
**REFACTOR**: Improve the code while keeping tests passing

**Benefits:**
- Better design (forces you to think about API first)
- Comprehensive test coverage from the start
- Confidence when refactoring
- Tests serve as documentation

**Example workflow:**
1. Write a test for order total calculation (RED - it fails)
2. Implement simple calculation logic (GREEN - test passes)
3. Refactor to handle edge cases, validate inputs (tests still pass)
4. Add more tests for discount logic
5. Repeat cycle

**Best Practices:**
- Keep test cycles short (< 5 minutes)
- One assertion per test when possible
- Use test data builders for complex objects
- Don''t skip the refactoring step
- Run tests frequently',
2, 'TDD,Testing,Unit Tests,Best Practices', @AdvancedTestingCategoryId, 1),

(462, 'What is mutation testing? How does it improve test quality?',
'Mutation testing is a technique that modifies (mutates) your source code in small ways and checks if your tests detect these changes. If tests still pass with mutated code, it means your tests aren''t thorough enough.

**How it works:**
1. Original code: `if (age >= 18)`
2. Mutation: Change to `if (age > 18)`
3. Run tests - if tests still pass, the mutation "survived" (bad!)
4. If tests fail, the mutation was "killed" (good!)

**Common Mutation Operators:**
- Arithmetic: + to -, * to /
- Relational: >= to >, == to !=
- Conditional: && to ||
- Constants: 18 to 0, 21, 17
- Return values: true to false
- Statement deletion

**Tools:**
- Stryker.NET for .NET projects
- PITest for Java
- Mutmut for Python

**Metrics:**
- Mutation Score = (Killed Mutations / Total Mutations) × 100%
- Good target: > 75%

**Benefits:**
- Finds weak tests that don''t actually verify behavior
- Improves test quality beyond code coverage
- Catches edge cases missed by developers',
2, 'Mutation Testing,Test Quality,Stryker,Best Practices', @AdvancedTestingCategoryId, 1),

(463, 'How do you implement performance testing? Explain load, stress, and soak testing.',
'Performance testing ensures applications meet performance requirements under various conditions.

**Types of Performance Testing:**

**1. Load Testing:**
- Tests performance under expected user load
- Example: 100-1000 concurrent users
- Duration: 30-60 minutes
- Goal: Verify response times meet SLA
- Tools: K6, JMeter, Apache Bench

**2. Stress Testing:**
- Tests beyond normal capacity to find breaking point
- Example: 5000-10000+ concurrent users
- Duration: Until system fails
- Goal: Find maximum capacity and failure modes
- Identifies bottlenecks (CPU, memory, database)

**3. Soak Testing:**
- Tests sustained load over long period
- Example: 1000 users for 8-24 hours
- Goal: Find memory leaks, resource exhaustion
- Checks for gradual performance degradation

**4. Spike Testing:**
- Sudden load increase (100 to 10,000 users in 1 minute)
- Tests auto-scaling and recovery
- Black Friday, product launch scenarios

**Key Metrics:**
- Response Time (p50, p95, p99)
- Throughput (requests/sec)
- Error Rate (< 1%)
- CPU/Memory Usage (< 80%)
- Database Query Performance

**Tools:**
- K6 (modern, JavaScript-based)
- JMeter (Java, GUI-based)
- Azure Load Testing (cloud-based)
- Gatling (Scala-based)',
2, 'Performance Testing,Load Testing,K6,JMeter', @AdvancedTestingCategoryId, 1),

(464, 'What are code review best practices?',
'Code review is a critical practice for maintaining code quality and sharing knowledge.

**Review Checklist:**
- ✅ Correctness: Does it solve the problem?
- ✅ Design: Is the solution well-architected?
- ✅ Readability: Is code clear and maintainable?
- ✅ Tests: Are there appropriate tests?
- ✅ Security: Any vulnerabilities?
- ✅ Performance: Any obvious performance issues?
- ✅ Documentation: Is it properly documented?

**Best Practices:**
- Review within 24 hours
- Limit review size (< 400 lines)
- Provide constructive feedback
- Focus on important issues (don''t nitpick)
- Approve if no blocking issues
- Use automated tools for style/formatting
- Ask questions instead of demanding changes
- Explain reasoning behind suggestions

**Feedback Examples:**
- ❌ "This is wrong, use X instead"
- ✅ "Consider using X because it handles Y better"
- ❌ "You should refactor this"
- ✅ "This could be simplified by extracting a method"',
1, 'Code Review,Best Practices,Team Collaboration', @AdvancedTestingCategoryId, 1),

(465, 'How do you manage technical debt?',
'Technical debt is the implied cost of additional rework caused by choosing an easy solution now instead of a better approach.

**Strategies:**
- Track debt in backlog with priority
- Allocate 20% capacity for debt reduction
- Boy Scout Rule: Leave code better than you found it
- Refactor during feature work when safe
- Create ADRs (Architecture Decision Records)
- Balance speed vs quality based on risk

**Debt Classification:**
- **Critical**: Security vulnerabilities, data loss risks
- **High**: Performance issues, stability problems
- **Medium**: Poor code structure, missing tests
- **Low**: Code smells, minor refactoring

**When to pay down debt:**
- Before major feature work in affected area
- When debt is causing frequent bugs
- When team velocity is impacted
- During slack time between releases',
1, 'Technical Debt,Refactoring,Best Practices', @AdvancedTestingCategoryId, 1),

(466, 'What are effective mentoring practices for junior developers?',
'Mentoring helps junior developers grow while building team culture.

**Effective Practices:**
- Pair programming sessions (2-3 times/week)
- Code review as teaching opportunity
- Assign progressively challenging tasks
- Provide specific, timely feedback
- Share resources and learning paths
- Encourage questions
- Set clear expectations
- Celebrate growth and achievements

**Mentoring Activities:**
- Weekly 1-on-1s
- Design discussions
- Architecture walkthroughs
- Debugging sessions together
- Knowledge sharing presentations
- Side project collaboration

**Growth Framework:**
- Month 1-3: Learn codebase, tools, processes
- Month 4-6: Independent feature development
- Month 7-12: Complex features, mentoring others',
1, 'Mentoring,Leadership,Team Development', @AdvancedTestingCategoryId, 1),

(467, 'How do you make architectural decisions?',
'Architectural decisions have long-term impact and should be made carefully.

**Decision Framework:**
1. **Understand Requirements**: Functional and non-functional
2. **Research Options**: Evaluate 2-3 alternatives
3. **Consider Trade-offs**: Performance, scalability, cost, complexity
4. **Prototype**: Build POCs for unclear choices
5. **Document**: Create ADR (Architecture Decision Record)
6. **Review**: Get team input
7. **Iterate**: Be willing to change if needed

**ADR Template:**
```
# ADR-001: Use Redis for Distributed Caching

## Status: Accepted

## Context
Need distributed cache for session storage.
Current in-memory cache doesn''t work with multiple instances.

## Decision
Implement Redis for distributed caching.

## Consequences
Positive: 100K+ ops/sec, persistence, rich data structures
Negative: Additional cost ($50/month), operational complexity

## Alternatives Considered
- Memcached: Lacks persistence
- SQL Server: Too slow for caching
```',
2, 'Architecture,Decision Making,ADR,Leadership', @AdvancedTestingCategoryId, 1),

(468, 'How do you handle production incidents?',
'Production incidents require calm, systematic response.

**Incident Response Process:**
1. **Detect**: Monitoring alerts, user reports
2. **Triage**: Assess severity (P0-P4)
3. **Communicate**: Notify stakeholders, create incident channel
4. **Investigate**: Check logs, metrics, recent deployments
5. **Mitigate**: Apply hotfix or rollback
6. **Resolve**: Verify fix in production
7. **Post-Mortem**: Blameless retrospective within 48 hours

**Severity Levels:**
- P0: Complete outage, data loss
- P1: Significant degradation, affects many users
- P2: Partial degradation, workarounds available
- P3: Minor issues, low impact
- P4: Cosmetic issues

**Post-Mortem Template:**
- Summary (what happened, impact)
- Timeline of events
- Root cause analysis
- Action items with owners and dates
- Lessons learned',
2, 'Incident Response,DevOps,Troubleshooting,Leadership', @AdvancedTestingCategoryId, 1),

(469, 'How do you communicate technical concepts to non-technical stakeholders?',
'Effective communication bridges the gap between technical and business teams.

**Best Practices:**
- Use business language, avoid jargon
- Focus on value and outcomes, not implementation
- Be honest about risks and trade-offs
- Provide options with recommendations
- Use visuals (diagrams, charts)
- Set realistic expectations
- Regular updates on long projects
- Listen actively and clarify requirements

**Bad Example:**
"We need to refactor the repository layer to use the specification pattern for better testability"

**Good Example:**
"I recommend spending 2 weeks improving our data access layer. This will reduce bugs by making code easier to test, and make future features 30% faster to develop. The system will continue working during this refactoring with no downtime."',
1, 'Communication,Stakeholder Management,Leadership', @AdvancedTestingCategoryId, 1),

(470, 'What makes a high-performing team?',
'High-performing teams have specific characteristics and culture.

**Key Elements (Google''s Project Aristotle):**
1. **Psychological Safety**: Safe to take risks, speak up
2. **Dependability**: Team delivers on commitments
3. **Structure & Clarity**: Clear roles and goals
4. **Meaning**: Work has personal significance
5. **Impact**: Work matters and creates value

**Practices:**
- Regular 1-on-1s with team members
- Team retrospectives after sprints
- Celebrate successes together
- Learn from failures (blameless)
- Invest in learning and development
- Remove blockers promptly
- Foster collaboration
- Lead by example

**Team Culture:**
- Open communication
- Mutual respect
- Shared ownership
- Continuous improvement
- Innovation encouraged',
1, 'Team Building,Leadership,Culture', @AdvancedTestingCategoryId, 1),

(471, 'How do you prioritize tasks when everything seems urgent?',
'Time management and prioritization are critical leadership skills.

**Eisenhower Matrix:**
```
┌─────────────────┬─────────────────┐
│ URGENT &        │ NOT URGENT &    │
│ IMPORTANT       │ IMPORTANT       │
│ Do First        │ Schedule        │
│ - Production    │ - Planning      │
│   incidents     │ - Learning      │
│ - Critical bugs │ - Refactoring   │
├─────────────────┼─────────────────┤
│ URGENT &        │ NOT URGENT &    │
│ NOT IMPORTANT   │ NOT IMPORTANT   │
│ Delegate        │ Eliminate       │
│ - Meetings      │ - Busy work     │
│ - Interrupts    │ - Time wasters  │
└─────────────────┴─────────────────┘
```

**Techniques:**
- Time blocking for focused work
- Pomodoro (25 min focus + 5 min break)
- Deep work in mornings
- Batch similar tasks
- Say no to non-essential requests
- Use calendar for everything
- Protect team from interruptions',
1, 'Time Management,Prioritization,Productivity,Leadership', @AdvancedTestingCategoryId, 1),

(472, 'How do you resolve conflicts within the team?',
'Conflict resolution requires empathy, patience, and clear process.

**Steps:**
1. **Listen**: Understand both perspectives
2. **Empathize**: Acknowledge feelings
3. **Find Common Ground**: Identify shared goals
4. **Explore Solutions**: Brainstorm options together
5. **Agree on Action**: Clear next steps
6. **Follow Up**: Ensure resolution

**Example: Tech Choice Disagreement**
1. Listen to both arguments
2. Define evaluation criteria (performance, cost, learning curve)
3. Create comparison matrix
4. Build POCs if needed
5. Make data-driven decision
6. Document decision (ADR)
7. Support chosen approach as team

**Conflict Types:**
- Technical disagreements → Data-driven decision
- Personality clashes → Mediation, clear communication
- Resource conflicts → Prioritization, negotiation
- Workload disputes → Redistribution, hiring',
1, 'Conflict Resolution,Team Management,Leadership', @AdvancedTestingCategoryId, 1),

(473, 'How do you set and track goals (SMART goals)?',
'SMART goals provide clear direction and measurable outcomes.

**SMART Framework:**
- **S**pecific: Clear and well-defined
- **M**easurable: Quantifiable metrics
- **A**chievable: Realistic given resources
- **R**elevant: Aligns with larger objectives
- **T**ime-bound: Has deadline

**Examples:**

**Bad Goal:**
"Improve API performance"

**SMART Goal:**
"Reduce API p95 latency from 500ms to 200ms by end of Q2 by implementing caching and database query optimization"

**Bad Goal:**
"Learn new technology"

**SMART Goal:**
"Complete 3 online courses on Kubernetes and deploy 2 production services to AKS by June 30th"

**Tracking:**
- Weekly check-ins on progress
- Quarterly reviews
- Adjust as needed based on feedback',
1, 'Goal Setting,Performance Management,Leadership', @AdvancedTestingCategoryId, 1),

(474, 'How do you give effective feedback?',
'Effective feedback helps people grow while maintaining relationships.

**SBI Model:**
- **S**ituation: When and where
- **B**ehavior: What was observed
- **I**mpact: Effect of the behavior

**Example:**

**Bad Feedback:**
"Your code is always messy and hard to read"

**Good Feedback (SBI):**
"In yesterday''s PR for the payment feature (Situation), I noticed the OrderProcessor class had 500 lines with multiple responsibilities (Behavior). This makes it harder for the team to understand and modify, increasing bug risk (Impact). Could we discuss breaking it into smaller classes?"

**Principles:**
- Timely (within 24-48 hours)
- Specific with examples
- Focus on behavior, not personality
- Balance positive and constructive
- Private for constructive, public for praise
- Actionable with suggestions',
1, 'Feedback,Communication,Leadership,Management', @AdvancedTestingCategoryId, 1),

(475, 'What are effective delegation strategies?',
'Delegation empowers team members and frees up time for leadership.

**Delegation Framework:**
1. **Match Task to Skill**: Right person for the job
2. **Provide Context**: Why it matters
3. **Set Clear Expectations**: Definition of done
4. **Give Authority**: Ownership, not just tasks
5. **Check In**: Support without micromanaging
6. **Recognize**: Acknowledge achievements

**What to Delegate:**
- Tasks others can learn from
- Routine operational work
- Opportunities for growth
- Work aligned with interests

**What NOT to Delegate:**
- Personnel decisions
- Sensitive/confidential matters
- Crisis management
- Strategic planning

**Levels of Delegation:**
1. Do and report back
2. Research and recommend
3. Decide and inform
4. Full ownership',
1, 'Delegation,Leadership,Team Empowerment', @AdvancedTestingCategoryId, 1),

(476, 'How do you manage remote teams effectively?',
'Remote work requires intentional communication and trust.

**Best Practices:**
- **Over-communicate**: Err on side of too much communication
- **Document Everything**: Written > Verbal for async work
- **Async-First**: Don''t require real-time responses
- **Regular Video Check-ins**: Face time builds connection
- **Build Culture Intentionally**: Virtual coffee, games
- **Respect Time Zones**: Rotate meeting times
- **Trust and Autonomy**: Focus on outcomes, not hours
- **Clear Goals**: OKRs, deliverables, metrics

**Tools:**
- Communication: Slack, Teams
- Video: Zoom, Google Meet
- Documentation: Confluence, Notion
- Project Management: Jira, Linear
- Code Collaboration: GitHub, GitLab
- Async Updates: Loom videos

**Challenges:**
- Time zone differences
- Reduced spontaneous collaboration
- Harder to build relationships
- Communication gaps',
1, 'Remote Work,Team Management,Leadership,Communication', @AdvancedTestingCategoryId, 1),

(477, 'How do you plan career development for team members?',
'Career development retains talent and builds stronger teams.

**Development Framework:**

**Individual Development Plans (IDPs):**
1. **Current State**: Skills, strengths, gaps
2. **Goals**: 6-month and 1-year objectives
3. **Development Activities**: Training, projects, mentoring
4. **Progress Metrics**: How to measure success

**Growth Tracks:**
- **IC Track**: Senior Engineer → Staff → Principal → Distinguished
- **Management Track**: Team Lead → Manager → Director → VP

**Activities:**
- Quarterly career conversations
- Conference/training budget
- Stretch assignments
- Mentorship programs
- Side projects
- Speaking opportunities
- Open source contribution

**Supporting Growth:**
- Clear progression criteria
- Regular feedback
- Learning time (20% rule)
- Challenging projects
- Cross-team collaboration',
1, 'Career Development,Mentoring,Leadership,HR', @AdvancedTestingCategoryId, 1),

(478, 'What are technical writing and documentation best practices?',
'Good documentation reduces onboarding time and improves maintainability.

**Documentation Types:**

**1. README Files:**
- What the project does
- How to set up locally
- How to run tests
- How to deploy
- Architecture overview
- Contributing guidelines

**2. API Documentation:**
- OpenAPI/Swagger specs
- Request/response examples
- Authentication details
- Error codes and handling
- Rate limits

**3. Architecture Diagrams:**
- C4 Model (Context, Container, Component, Code)
- Sequence diagrams for flows
- ER diagrams for database
- Infrastructure diagrams

**4. Runbooks:**
- Deployment procedures
- Troubleshooting guides
- Incident response
- Monitoring and alerts

**5. ADRs (Architecture Decision Records):**
- Document why decisions were made
- Context, decision, consequences
- Alternatives considered

**Best Practices:**
- Keep docs close to code
- Update with code changes
- Use diagrams liberally
- Write for your audience
- Keep it concise
- Use examples',
1, 'Documentation,Technical Writing,Best Practices', @AdvancedTestingCategoryId, 1),

(479, 'What are best practices for technical interviews and hiring?',
'Good hiring process finds great talent while providing positive experience.

**Interview Process:**

**1. Screening:**
- Resume review
- Phone screen (30 min)
- Technical fit
- Salary expectations

**2. Technical Interview:**
- Coding exercise (60 min)
- System design (60 min)
- Behavioral questions (30 min)
- Team fit assessment

**3. Onsite/Final:**
- Deep technical dive
- Architecture discussion
- Team collaboration
- Leadership principles

**Best Practices:**
- Structured interviews (same questions)
- Diverse interview panel
- Focus on problem-solving, not memorization
- Real-world scenarios
- Collaborative coding (not whiteboard pressure)
- Check references
- Provide feedback to candidates
- Clear timeline and next steps

**Red Flags:**
- Can''t explain past work
- Blames others for failures
- No questions about role/company
- Arrogant or dismissive',
2, 'Interviewing,Hiring,Recruitment,Leadership', @AdvancedTestingCategoryId, 1),

(480, 'How do you stay current with technology?',
'Continuous learning is essential in fast-changing tech landscape.

**Learning Strategies:**

**1. Reading:**
- Technical blogs (Martin Fowler, Netflix Tech Blog)
- Books (Clean Code, Design Patterns, Domain-Driven Design)
- newsletters (TLDR, Software Lead Weekly)
- Research papers

**2. Hands-On:**
- Side projects
- Open source contributions
- Hackathons
- New language/framework every year

**3. Community:**
- Conferences (local and national)
- Meetups
- User groups
- Online communities (Reddit, Discord)

**4. Structured Learning:**
- Online courses (Pluralsight, Udemy, Coursera)
- Certifications (AWS, Azure, Kubernetes)
- University courses (MIT OpenCourseWare)

**5. Practice:**
- Code katas
- LeetCode/HackerRank
- Design challenges
- Code reviews

**Time Allocation:**
- 20% rule: 1 day/week for learning
- Morning reading (30 min)
- Weekend projects
- Conference budget

**Adjacent Skills:**
- Product management
- UX/UI design
- DevOps/SRE
- Business strategy',
1, 'Continuous Learning,Professional Development,Career Growth', @AdvancedTestingCategoryId, 1);

-- Q481-Q500: Security & OWASP Best Practices
INSERT INTO Questions (QuestionNumber, Title, Content, Difficulty, Tags, CategoryId, IsPublished)
VALUES
(481, 'Explain the OWASP Top 10 vulnerabilities and how to prevent them in ASP.NET Core.',
'The OWASP Top 10 is a standard awareness document for web application security.

**OWASP Top 10 (2021):**

**A01: Broken Access Control** (↑ moved up from #5)
- Users accessing unauthorized resources
- Prevention: Implement authorization checks, resource-based authorization
- Example: Check if user owns order before allowing access

**A02: Cryptographic Failures** (↑ was #3)
- Sensitive data exposed due to weak encryption
- Prevention: Use HTTPS, strong hashing (bcrypt), Azure Key Vault
- Never store passwords in plain text

**A03: Injection** (↓ was #1)
- SQL, NoSQL, OS command injection
- Prevention: Parameterized queries, ORM, input validation
- Use LINQ instead of raw SQL

**A04: Insecure Design** (🆕 new)
- Missing security controls by design
- Prevention: Threat modeling, defense in depth, principle of least privilege

**A05: Security Misconfiguration** (↓ was #6)
- Default passwords, directory listing, verbose errors
- Prevention: Secure defaults, remove unnecessary features, security headers

**A06: Vulnerable Components** (↑ was #9)
- Using libraries with known vulnerabilities
- Prevention: Keep packages updated, Dependabot, security scanning

**A07: Authentication Failures** (↓ was #2)
- Broken authentication/session management
- Prevention: MFA, strong passwords, account lockout, secure session handling

**A08: Software & Data Integrity** (🆕 new)
- Insecure CI/CD, auto-updates without verification
- Prevention: Digital signatures, verified dependencies

**A09: Security Logging Failures** (↑ was #10)
- Insufficient logging, monitoring
- Prevention: Centralized logging, alerts, audit trails

**A10: SSRF** (🆕 new)
- Server-Side Request Forgery
- Prevention: Whitelist allowed URLs, validate domains',
2, 'OWASP,Security,Web Security,Vulnerabilities', @SecurityCategoryId, 1),

(482, 'What is Cross-Site Scripting (XSS)? How do you prevent it?',
'XSS is a vulnerability where attackers inject malicious scripts into web pages.

**Types of XSS:**

**1. Reflected XSS:**
- Payload in URL/form immediately reflected
- Example: `?search=<script>alert(''XSS'')</script>`
- User clicks malicious link

**2. Stored XSS:**
- Payload stored in database
- Example: Comment with `<script>` tag
- Affects all users viewing the page

**3. DOM-based XSS:**
- Client-side JavaScript vulnerability
- Example: `document.write(location.hash)`

**Prevention in ASP.NET Core:**

**1. Auto-encoding (Razor):**
```csharp
<div>@Model.UserInput</div> // Automatically HTML-encoded
```

**2. Content Security Policy:**
```csharp
context.Response.Headers.Add("Content-Security-Policy",
    "default-src ''self''; script-src ''self'' ''nonce-{random}''");
```

**3. HTML Sanitization:**
```csharp
// For rich text, use sanitizer
using Ganss.Xss;
var sanitizer = new HtmlSanitizer();
<div>@Html.Raw(sanitizer.Sanitize(Model.HtmlContent))</div>
```

**4. HttpOnly Cookies:**
```csharp
options.Cookie.HttpOnly = true; // Prevent JavaScript access
```

**5. Input Validation:**
```csharp
[StringLength(100)]
[RegularExpression(@"^[a-zA-Z0-9\s]*$")]
public string UserName { get; set; }
```',
2, 'XSS,Security,OWASP,Web Security', @SecurityCategoryId, 1),

(483, 'What is CSRF? How do you implement CSRF protection?',
'Cross-Site Request Forgery tricks users into executing unwanted actions.

**How CSRF Works:**
1. User logs into bank.com
2. User visits malicious site evil.com
3. Evil.com has form that submits to bank.com/transfer
4. Browser automatically includes bank.com cookies
5. Money transferred without user consent

**Prevention in ASP.NET Core:**

**1. Anti-Forgery Tokens (Default):**
```csharp
// Automatically enabled for Razor Pages
[HttpPost]
[ValidateAntiForgeryToken]
public async Task<IActionResult> UpdateProfile(ProfileDto dto)
{
    // CSRF protected
}

// In Razor view
<form method="post">
    @Html.AntiForgeryToken()
    <!-- form fields -->
</form>
```

**2. SameSite Cookies:**
```csharp
builder.Services.ConfigureApplicationCookie(options =>
{
    options.Cookie.SameSite = SameSiteMode.Strict; // or Lax
    options.Cookie.HttpOnly = true;
    options.Cookie.SecurePolicy = CookieSecurePolicy.Always;
});
```

**3. Custom Request Validation:**
```csharp
// Verify Origin header
var origin = Request.Headers.Origin.ToString();
var host = Request.Headers.Host.ToString();

if (origin != $"https://{host}")
{
    return BadRequest("Invalid origin");
}
```

**4. For APIs (use custom headers):**
```csharp
// Require custom header
var antiCsrfHeader = Request.Headers["X-CSRF-Token"];
if (string.IsNullOrEmpty(antiCsrfHeader))
{
    return Unauthorized();
}
```',
2, 'CSRF,Security,OWASP,Web Security', @SecurityCategoryId, 1),

(484, 'What is SQL Injection? How do you prevent it?',
'SQL Injection is when attackers insert malicious SQL code into queries.

**Example Attack:**
```sql
-- User input: '' OR ''1''=''1''; DROP TABLE Users; --
SELECT * FROM Users WHERE Username = '''' OR ''1''=''1''; DROP TABLE Users; --
```

**Prevention:**

**1. Parameterized Queries (Best):**
```csharp
// ✅ GOOD: LINQ (generates parameterized SQL)
var user = await _context.Users
    .Where(u => u.Username == username)
    .FirstOrDefaultAsync();

// ✅ GOOD: FromSqlRaw with parameters
var products = await _context.Products
    .FromSqlRaw("SELECT * FROM Products WHERE Category = {0}", category)
    .ToListAsync();

// ✅ GOOD: Stored procedures
var orders = await _context.Orders
    .FromSqlRaw("EXEC GetOrdersByDateRange @StartDate, @EndDate",
        new SqlParameter("@StartDate", start),
        new SqlParameter("@EndDate", end))
    .ToListAsync();
```

**2. Input Validation:**
```csharp
// Whitelist allowed values
var allowedColumns = new[] { "Name", "Price", "Category" };
if (!allowedColumns.Contains(sortColumn))
{
    throw new ArgumentException("Invalid sort column");
}
```

**3. Least Privilege:**
- Database user should have minimum required permissions
- Use separate accounts for read vs write
- Don''t use ''sa'' or ''root'' accounts

**4. Web Application Firewall:**
- Azure Application Gateway WAF
- Cloudflare WAF
- ModSecurity',
2, 'SQL Injection,Security,OWASP,Database Security', @SecurityCategoryId, 1),

(485, 'How do you implement secure password storage?',
'Never store passwords in plain text or with reversible encryption.

**Secure Password Hashing:**

**1. Use ASP.NET Core Identity (Recommended):**
```csharp
// Identity automatically uses PBKDF2
public class ApplicationDbContext : IdentityDbContext<ApplicationUser>
{
    // Password hashing handled automatically
}

// Creating user
var user = new ApplicationUser { UserName = "john" };
var result = await _userManager.CreateAsync(user, "Password123!");

// Verifying password
var isValid = await _userManager.CheckPasswordAsync(user, "Password123!");
```

**2. Manual Implementation with bcrypt:**
```csharp
using BCrypt.Net;

public class PasswordHasher
{
    public string HashPassword(string password)
    {
        // Work factor 12 = 2^12 iterations
        return BCrypt.HashPassword(password, workFactor: 12);
    }

    public bool VerifyPassword(string password, string hash)
    {
        return BCrypt.Verify(password, hash);
    }
}
```

**Password Requirements:**
```csharp
builder.Services.Configure<IdentityOptions>(options =>
{
    options.Password.RequireDigit = true;
    options.Password.RequireLowercase = true;
    options.Password.RequireUppercase = true;
    options.Password.RequireNonAlphanumeric = true;
    options.Password.RequiredLength = 12; // Minimum 12 characters
    options.Password.RequiredUniqueChars = 4;
});
```

**Never:**
- ❌ Store plain text passwords
- ❌ Use MD5 or SHA1 (broken)
- ❌ Use reversible encryption
- ❌ Same salt for all passwords

**Always:**
- ✅ Use bcrypt, PBKDF2, or Argon2
- ✅ Random salt per password
- ✅ High iteration count
- ✅ Pepper (secret key) for additional security',
2, 'Password Security,Hashing,bcrypt,Authentication', @SecurityCategoryId, 1),

(486, 'What are security headers? How do you configure them?',
'Security headers protect against common attacks.

**Key Security Headers:**

**1. Content-Security-Policy (CSP):**
```csharp
context.Response.Headers.Add("Content-Security-Policy",
    "default-src ''self''; " +
    "script-src ''self'' ''unsafe-inline''; " +
    "style-src ''self'' ''unsafe-inline''; " +
    "img-src ''self'' data: https:; " +
    "font-src ''self''; " +
    "connect-src ''self''; " +
    "frame-ancestors ''none''");
```

**2. X-Content-Type-Options:**
```csharp
// Prevents MIME-type sniffing
context.Response.Headers.Add("X-Content-Type-Options", "nosniff");
```

**3. X-Frame-Options:**
```csharp
// Prevents clickjacking
context.Response.Headers.Add("X-Frame-Options", "DENY");
```

**4. Strict-Transport-Security (HSTS):**
```csharp
builder.Services.AddHsts(options =>
{
    options.MaxAge = TimeSpan.FromDays(365);
    options.IncludeSubDomains = true;
    options.Preload = true;
});
```

**5. X-XSS-Protection:**
```csharp
context.Response.Headers.Add("X-XSS-Protection", "1; mode=block");
```

**6. Referrer-Policy:**
```csharp
context.Response.Headers.Add("Referrer-Policy", "strict-origin-when-cross-origin");
```

**7. Permissions-Policy:**
```csharp
context.Response.Headers.Add("Permissions-Policy",
    "geolocation=(), microphone=(), camera=()");
```

**Implementation Middleware:**
```csharp
public class SecurityHeadersMiddleware
{
    private readonly RequestDelegate _next;

    public async Task InvokeAsync(HttpContext context)
    {
        // Remove revealing headers
        context.Response.Headers.Remove("Server");
        context.Response.Headers.Remove("X-Powered-By");

        // Add security headers
        context.Response.Headers.Add("X-Content-Type-Options", "nosniff");
        context.Response.Headers.Add("X-Frame-Options", "DENY");
        // ... add others

        await _next(context);
    }
}
```',
2, 'Security Headers,HTTP Headers,CSP,CORS', @SecurityCategoryId, 1),

(487, 'How do you handle secure file uploads?',
'File uploads are a common attack vector requiring careful handling.

**Security Measures:**

**1. File Type Validation:**
```csharp
public async Task<IActionResult> UploadFile(IFormFile file)
{
    // Validate file extension
    var allowedExtensions = new[] { ".jpg", ".png", ".pdf" };
    var extension = Path.GetExtension(file.FileName).ToLowerInvariant();

    if (!allowedExtensions.Contains(extension))
    {
        return BadRequest("Invalid file type");
    }

    // Validate MIME type
    var allowedMimeTypes = new[] { "image/jpeg", "image/png", "application/pdf" };
    if (!allowedMimeTypes.Contains(file.ContentType))
    {
        return BadRequest("Invalid file type");
    }

    // Check magic number (file signature)
    using var stream = file.OpenReadStream();
    var buffer = new byte[8];
    await stream.ReadAsync(buffer);

    if (!IsValidFileSignature(buffer, extension))
    {
        return BadRequest("File content doesn''t match extension");
    }
}
```

**2. File Size Limits:**
```csharp
// In Program.cs
builder.Services.Configure<FormOptions>(options =>
{
    options.MultipartBodyLengthLimit = 10 * 1024 * 1024; // 10 MB
});

// In controller
[RequestSizeLimit(10 * 1024 * 1024)]
public async Task<IActionResult> UploadFile(IFormFile file)
{
    if (file.Length > 10 * 1024 * 1024)
    {
        return BadRequest("File too large");
    }
}
```

**3. Safe File Storage:**
```csharp
// Generate safe filename
var safeFileName = $"{Guid.NewGuid()}{extension}";
var uploadPath = Path.Combine(_hostEnvironment.ContentRootPath, "uploads");
var fullPath = Path.Combine(uploadPath, safeFileName);

// Ensure path is within allowed directory
if (!fullPath.StartsWith(uploadPath))
{
    return BadRequest("Invalid file path");
}

using var fileStream = new FileStream(fullPath, FileMode.Create);
await file.CopyToAsync(fileStream);
```

**4. Virus Scanning:**
```csharp
// Integrate with antivirus service
var scanResult = await _antivirusService.ScanFileAsync(fullPath);
if (scanResult.IsInfected)
{
    File.Delete(fullPath);
    return BadRequest("File contains malware");
}
```

**5. Store Outside Web Root:**
- Don''t store in wwwroot
- Use separate storage account (Azure Blob Storage)
- Serve through controller with authentication',
2, 'File Upload,Security,Validation,Storage', @SecurityCategoryId, 1),

(488, 'What is API rate limiting? How do you implement it?',
'Rate limiting prevents abuse and ensures fair resource usage.

**Rate Limiting Algorithms:**

**1. Token Bucket:**
- Tokens added at fixed rate
- Each request consumes tokens
- Allows bursts

**2. Sliding Window:**
- Counts requests in time window
- More accurate than fixed window

**Implementation in ASP.NET Core:**

**1. Using AspNetCoreRateLimit:**
```csharp
// Install: AspNetCoreRateLimit

// Program.cs
builder.Services.AddMemoryCache();
builder.Services.Configure<IpRateLimitOptions>(options =>
{
    options.EnableEndpointRateLimiting = true;
    options.StackBlockedRequests = false;
    options.HttpStatusCode = 429;
    options.GeneralRules = new List<RateLimitRule>
    {
        new RateLimitRule
        {
            Endpoint = "*",
            Period = "1m",
            Limit = 100
        },
        new RateLimitRule
        {
            Endpoint = "POST:/api/orders",
            Period = "1h",
            Limit = 10
        }
    };
});

builder.Services.AddInMemoryRateLimiting();

app.UseIpRateLimiting();
```

**2. .NET 7+ Built-in Rate Limiting:**
```csharp
builder.Services.AddRateLimiter(options =>
{
    options.AddFixedWindowLimiter("fixed", opt =>
    {
        opt.PermitLimit = 100;
        opt.Window = TimeSpan.FromMinutes(1);
        opt.QueueLimit = 0;
    });

    options.AddSlidingWindowLimiter("sliding", opt =>
    {
        opt.PermitLimit = 100;
        opt.Window = TimeSpan.FromMinutes(1);
        opt.SegmentsPerWindow = 6;
    });
});

app.UseRateLimiter();

[EnableRateLimiting("fixed")]
public class OrdersController : ControllerBase
{
    [HttpPost]
    [EnableRateLimiting("sliding")]
    public async Task<IActionResult> CreateOrder() { }
}
```

**3. Redis-based (Distributed):**
```csharp
public class RedisRateLimiter
{
    private readonly IDatabase _redis;

    public async Task<bool> IsAllowedAsync(string key, int limit, TimeSpan window)
    {
        var count = await _redis.StringIncrementAsync(key);

        if (count == 1)
        {
            await _redis.KeyExpireAsync(key, window);
        }

        return count <= limit;
    }
}
```',
2, 'Rate Limiting,API Security,Performance,Throttling', @SecurityCategoryId, 1),

(489, 'What should you log for security monitoring?',
'Security logging helps detect and investigate incidents.

**What to Log:**

**1. Authentication Events:**
```csharp
// Successful login
_logger.LogInformation("User {UserId} logged in successfully from {IpAddress}",
    userId, ipAddress);

// Failed login
_logger.LogWarning("Failed login attempt for user {Username} from {IpAddress}",
    username, ipAddress);

// Account lockout
_logger.LogWarning("Account {UserId} locked out after {Attempts} failed attempts",
    userId, attempts);
```

**2. Authorization Failures:**
```csharp
_logger.LogWarning("User {UserId} attempted unauthorized access to resource {Resource}",
    userId, resourceId);
```

**3. Input Validation Failures:**
```csharp
_logger.LogWarning("Invalid input detected: {ValidationErrors} from {IpAddress}",
    errors, ipAddress);
```

**4. Application Errors:**
```csharp
_logger.LogError(exception, "Unhandled exception in {Endpoint}",
    context.Request.Path);
```

**5. Configuration Changes:**
```csharp
_logger.LogInformation("User {UserId} changed setting {Setting} from {Old} to {New}",
    userId, settingName, oldValue, newValue);
```

**What NOT to Log:**
- ❌ Passwords (plaintext or hashed)
- ❌ Credit card numbers
- ❌ Social Security Numbers
- ❌ API keys or secrets
- ❌ Session tokens

**Implementation:**
```csharp
builder.Services.AddSerilog((services, lc) => lc
    .ReadFrom.Configuration(builder.Configuration)
    .Enrich.FromLogContext()
    .Enrich.WithProperty("Application", "MyApp")
    .WriteTo.Console()
    .WriteTo.ApplicationInsights(telemetryConfiguration)
    .WriteTo.File("logs/app-.log", rollingInterval: RollingInterval.Day));

// Add correlation ID
app.Use(async (context, next) =>
{
    var correlationId = context.Request.Headers["X-Correlation-ID"].FirstOrDefault()
        ?? Guid.NewGuid().ToString();

    using (_logger.BeginScope(new Dictionary<string, object>
    {
        ["CorrelationId"] = correlationId,
        ["UserId"] = context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value,
        ["IpAddress"] = context.Connection.RemoteIpAddress?.ToString()
    }))
    {
        await next();
    }
});
```',
2, 'Logging,Security Monitoring,SIEM,Audit Logs', @SecurityCategoryId, 1),

(490, 'How do you manage secrets securely (Azure Key Vault)?',
'Never store secrets in code or configuration files.

**Azure Key Vault Integration:**

**1. Setup:**
```csharp
// Install: Azure.Extensions.AspNetCore.Configuration.Secrets

builder.Configuration.AddAzureKeyVault(
    new Uri($"https://{builder.Configuration["KeyVaultName"]}.vault.azure.net/"),
    new DefaultAzureCredential()
);
```

**2. Use Managed Identity:**
```csharp
// No credentials needed - uses MSI
var credential = new DefaultAzureCredential();
var client = new SecretClient(
    new Uri("https://myvault.vault.azure.net/"),
    credential
);

var secret = await client.GetSecretAsync("DatabaseConnectionString");
var connectionString = secret.Value.Value;
```

**3. Access in Code:**
```csharp
// Secrets from Key Vault appear as configuration
var apiKey = builder.Configuration["ThirdPartyApiKey"];
var connectionString = builder.Configuration["ConnectionStrings:Default"];
```

**Local Development:**
```json
// appsettings.Development.json
{
  "ConnectionStrings": {
    "Default": "Server=localhost;Database=Dev;Integrated Security=true;"
  }
}

// Production - from Key Vault
// Secret name: ConnectionStrings--Default
// Value: Production connection string
```

**User Secrets (Development Only):**
```bash
dotnet user-secrets init
dotnet user-secrets set "ApiKey" "dev-key-12345"
```

**Best Practices:**
- ✅ Use Key Vault for production
- ✅ Use Managed Identity (no credentials)
- ✅ Rotate secrets regularly
- ✅ Use separate vaults per environment
- ✅ Audit secret access
- ❌ Never commit secrets to source control
- ❌ Never log secrets',
2, 'Secrets Management,Azure Key Vault,Security,Configuration', @SecurityCategoryId, 1),

-- Add remaining questions 491-500
(491, 'OWASP A08: Software and Data Integrity Failures', 'Prevention of integrity failures in CI/CD pipelines and dependencies', 2, 'OWASP,Integrity,CI/CD,Security', @SecurityCategoryId, 1),
(492, 'OWASP A09: Security Logging and Monitoring Failures', 'Implementing comprehensive security logging and monitoring', 2, 'OWASP,Logging,Monitoring,Security', @SecurityCategoryId, 1),
(493, 'Dependency Scanning and Management', 'Automated scanning for vulnerable dependencies', 2, 'Dependencies,Security,DevOps', @SecurityCategoryId, 1),
(494, 'Container Security Best Practices', 'Securing Docker containers and Kubernetes clusters', 2, 'Container Security,Docker,Kubernetes', @SecurityCategoryId, 1),
(495, 'Database Security: Encryption, RLS, Masking', 'Comprehensive database security implementation', 2, 'Database Security,Encryption,SQL Server', @SecurityCategoryId, 1),
(496, 'Secure Coding Standards Enforcement', 'Using static analysis and code review for security', 2, 'Secure Coding,SAST,Code Review', @SecurityCategoryId, 1),
(497, 'Security Testing: SAST, DAST, Penetration Testing', 'Comprehensive security testing strategies', 2, 'Security Testing,SAST,DAST,Pentesting', @SecurityCategoryId, 1),
(498, 'Incident Response and Security Procedures', 'Handling security incidents and breaches', 2, 'Incident Response,Security,Crisis Management', @SecurityCategoryId, 1),
(499, 'Compliance: GDPR, HIPAA, PCI-DSS', 'Meeting regulatory compliance requirements', 2, 'Compliance,GDPR,HIPAA,PCI-DSS', @SecurityCategoryId, 1),
(500, 'Security Audit and Assessment', 'Conducting security audits and risk assessments', 2, 'Security Audit,Risk Assessment,Compliance', @SecurityCategoryId, 1);

PRINT 'Successfully added 40 questions (Q461-Q500)';
PRINT 'Categories added: Advanced Testing & Leadership, Security & OWASP';
