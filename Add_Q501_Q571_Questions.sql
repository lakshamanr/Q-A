-- Add Q501-Q571 Questions to InterviewQuestionBank Database
-- This adds the remaining behavioral and system design questions

-- Add categories for Q501-Q571
INSERT INTO Categories (Name, Description, Icon, ColorCode, DisplayOrder, QuestionRangeStart, QuestionRangeEnd)
VALUES
('Leadership & Team Management', 'Technical leadership, team management, and soft skills for senior engineers', 'fas fa-users', '#3498DB', 26, 501, 520),
('System Design & Scalability', 'Large-scale system design, scalability patterns, and architecture', 'fas fa-project-diagram', '#2ECC71', 27, 521, 540),
('Behavioral Questions - Core', 'Essential behavioral interview questions using STAR format', 'fas fa-comments', '#E67E22', 28, 541, 560),
('Behavioral Questions - Advanced', 'Advanced career topics and final interview preparation', 'fas fa-star', '#F39C12', 29, 561, 571);

-- Get category IDs
DECLARE @LeadershipCategoryId INT = (SELECT Id FROM Categories WHERE QuestionRangeStart = 501);
DECLARE @SystemDesignCategoryId INT = (SELECT Id FROM Categories WHERE QuestionRangeStart = 521);
DECLARE @BehavioralCoreCategoryId INT = (SELECT Id FROM Categories WHERE QuestionRangeStart = 541);
DECLARE @BehavioralAdvancedCategoryId INT = (SELECT Id FROM Categories WHERE QuestionRangeStart = 561);

-- Q501-Q520: Leadership & Team Management
INSERT INTO Questions (QuestionNumber, Title, Content, Difficulty, Tags, CategoryId, IsPublished)
VALUES
(501, 'Describe a time when you had to make a difficult technical decision.',
'Use the STAR format to explain a difficult technical decision you made. Include the decision-making framework, data analysis, stakeholder involvement, and outcome with metrics. Example: Choosing between microservices migration vs implementing caching - analyzed costs, risks, and benefits, created ADR (Architecture Decision Record), got stakeholder buy-in, achieved 45% performance improvement.',
2, 'Leadership,Decision Making,STAR,Architecture', @LeadershipCategoryId, 1),

(502, 'How do you prioritize tasks when everything is urgent?',
'Explain prioritization frameworks like the Eisenhower Matrix (Urgent vs Important). Describe how you use impact vs effort analysis, communicate with stakeholders about trade-offs, and manage expectations. Include examples of handling production incidents (P0), security patches (P1), CEO demos (P2), and technical debt (P3).',
2, 'Leadership,Time Management,Prioritization', @LeadershipCategoryId, 1),

(503, 'How do you handle disagreements with stakeholders?',
'Describe collaborative resolution approach: active listening, data-driven presentations, finding common ground, and proposing alternatives. Example: Product owner wanting to skip code reviews - presented data on bug costs, proposed lightweight reviews, achieved compromise with time-boxed reviews.',
2, 'Leadership,Communication,Stakeholder Management', @LeadershipCategoryId, 1),

(504, 'How do you ensure code quality in your team?',
'Explain multi-layered quality strategy: automated quality gates (linting, tests, SonarQube), code review process with checklists, team coding standards, knowledge sharing (tech talks, pair programming), and metrics tracking (coverage, defect density, review time). Include results like 70% bug reduction.',
2, 'Leadership,Code Quality,Best Practices', @LeadershipCategoryId, 1),

(505, 'What is your code review process?',
'Detail comprehensive process: PR preparation (self-review, description, tests), reviewer guidelines (check architecture, logic, security), constructive feedback (SBI model), approval criteria (all tests pass, coverage threshold, critical comments resolved). Include SLA (4-hour first review, 24-hour approval) and impact metrics.',
2, 'Code Review,Team Collaboration,Best Practices', @LeadershipCategoryId, 1),

(506, 'How do you handle underperforming team members?',
'Explain approach: identify root cause (skill gap, personal issues, unclear expectations), private 1-on-1 conversations, create improvement plan with specific goals, provide mentorship (pair programming, training), track progress weekly. Example: Junior dev struggling with async programming improved from 50% to 90% efficiency in 2 months.',
1, 'Leadership,Management,Mentoring', @LeadershipCategoryId, 1),

(507, 'How do you motivate your team?',
'Describe motivation strategies: recognition (public praise for good work), growth opportunities (challenging projects, learning budget), autonomy (let team make technical decisions), purpose (connect work to business impact), work-life balance (flexible hours, no overtime culture). Example: Innovation Fridays (20% time) increased morale by 35%.',
1, 'Leadership,Team Building,Motivation', @LeadershipCategoryId, 1),

(508, 'Describe your experience with remote team management.',
'Explain remote work practices: daily standups, async updates (Slack), documentation (everything written down), timezone management (core hours overlap), team building (virtual coffee chats). Tools: Zoom, Miro, GitHub, Jira. Example: Managed distributed team across 3 time zones with 95% delivery rate.',
1, 'Remote Work,Team Management,Communication', @LeadershipCategoryId, 1),

(509, 'How do you conduct technical interviews?',
'Detail interview process: phone screen (30 min, experience and basics), technical assessment (live coding or take-home), system design (45 min), cultural fit (team interview). Focus on problem-solving approach over memorized solutions. Example question: Design a rate limiter to assess architecture thinking.',
2, 'Interviewing,Hiring,Recruitment', @LeadershipCategoryId, 1),

(510, 'What questions do you ask when interviewing candidates?',
'List effective interview questions: Technical (explain a challenging bug you debugged, how do you ensure code quality, design a URL shortener), Behavioral (disagreement with team member using STAR, time you failed and learned), Culture (ideal team environment, how you handle feedback). Assess both skills and cultural fit.',
1, 'Interviewing,Recruitment,Behavioral Questions', @LeadershipCategoryId, 1),

(511, 'How do you onboard new team members?',
'Explain structured onboarding: Week 1 (setup, codebase tour, pair programming), Week 2 (small bug fixes, code reviews), Week 3 (first feature with mentorship), Month 1 (regular 1-on-1s, buddy system). Documentation: setup guide, architecture docs, team practices. Result: New hires productive 50% faster.',
1, 'Onboarding,Team Management,Mentoring', @LeadershipCategoryId, 1),

(512, 'How do you handle scope creep?',
'Describe prevention and management: define scope clearly (written requirements, acceptance criteria), change control process (new features through approval), communicate impact ("Adding X delays delivery by Y days"), offer alternatives ("Phase 2 approach"). Example: Feature requests mid-sprint moved to backlog, maintained 90% on-time delivery.',
1, 'Project Management,Scope Management,Communication', @LeadershipCategoryId, 1),

(513, 'How do you manage technical debt?',
'Explain strategy: track debt in backlog with priority, reserve 20% of sprint capacity for debt reduction, prioritize high-impact/high-risk debt first, prevent new debt (code reviews, quality gates), make visible (dashboard showing trends). Example: Dedicated 1 sprint per quarter reduced build time from 15 min to 5 min.',
2, 'Technical Debt,Refactoring,Team Management', @LeadershipCategoryId, 1),

(514, 'How do you balance technical excellence with business deadlines?',
'Explain pragmatic approach: make trade-offs (MVP now, polish later), identify non-negotiables (security, data integrity), flexible areas (performance optimization, UI polish), document trade-offs (ADRs), communicate clearly ("Ship in 2 weeks with X limitations"). Example: E-commerce feature shipped MVP in 2 weeks, optimized over next month.',
2, 'Leadership,Project Management,Decision Making', @LeadershipCategoryId, 1),

(515, 'Describe a project where you improved team productivity by 40%.',
'Use STAR format: Situation (team spending 4 hours/day on manual deployments at Sagitec), Task (automate deployment process), Action (implemented CI/CD with Azure DevOps, automated testing, one-click deployments), Result (deployment time from 4 hours to 30 minutes - 87% reduction, team productivity increased 40%).',
2, 'STAR,Leadership,Productivity,CI/CD', @LeadershipCategoryId, 1),

(516, 'How do you handle production incidents and post-mortems?',
'Explain incident response: assess severity (P0-P4), assemble response team, communicate to stakeholders, identify root cause, apply fix or rollback, verify resolution. Post-mortem (blameless): timeline of events, root cause analysis (5 Whys), what went well/didn''t, action items with owners. Example: Database outage resolved in 2 hours, implemented monitoring to prevent recurrence.',
2, 'Incident Response,DevOps,Leadership', @LeadershipCategoryId, 1),

(517, 'What is your approach to knowledge sharing?',
'Describe practices: weekly tech talks (30-min presentations by team members), documentation (Confluence wiki, ADRs, runbooks), pair programming (rotate pairs weekly), code reviews (teaching moments), brown bag sessions (lunch & learn), internal blog (share lessons learned). Result: Team learned 5 new technologies in 6 months.',
1, 'Knowledge Sharing,Team Culture,Documentation', @LeadershipCategoryId, 1),

(518, 'How do you stay updated with technology?',
'List learning activities: reading (Hacker News, dev.to, Microsoft docs), courses (Pluralsight, Udemy, Microsoft Learn), conferences (NDC, .NET Conf), podcasts (.NET Rocks, Hanselminutes), practice (side projects, open source), community (user groups, Stack Overflow). Dedicate 5 hours/week for learning.',
1, 'Continuous Learning,Professional Development', @LeadershipCategoryId, 1),

(519, 'How do you make architectural decisions?',
'Explain process: gather requirements (functional and non-functional - scale, performance, cost), research 2-3 options, create comparison matrix (pros/cons, costs, risks), prototype if needed, consult team, document decision (ADR). Example: Choosing between monolith and microservices - evaluated team size, complexity, scale - chose modular monolith with migration path.',
2, 'Architecture,Decision Making,ADR,Leadership', @LeadershipCategoryId, 1),

(520, 'How do you communicate technical concepts to non-technical stakeholders?',
'Describe techniques: use analogies ("API is like restaurant menu"), visual aids (diagrams, flowcharts), focus on business impact ("reduces cost by 30%" vs technical details), avoid jargon, tell stories (real-world examples). Example: Explaining microservices using "restaurant kitchen" analogy - each station independent - stakeholder understood scalability benefits.',
1, 'Communication,Stakeholder Management,Leadership', @LeadershipCategoryId, 1);

-- Q521-Q540: System Design & Scalability
INSERT INTO Questions (QuestionNumber, Title, Content, Difficulty, Tags, CategoryId, IsPublished)
VALUES
(521, 'Describe your experience with Agile/Scrum team management.',
'Explain Agile practices: team structure (8 developers, 2-week sprints), ceremonies (Sprint Planning - 4 hours, Daily Standup - 15 min, Sprint Review - 2 hours, Retrospective - 1.5 hours), metrics tracking (velocity, burndown, team satisfaction). STAR example: Inherited struggling team (40% sprint success) - implemented capacity-based planning, focus hours, improved ceremonies - achieved 90% success rate, team satisfaction 5/10 to 8.5/10.',
2, 'Agile,Scrum,Team Management,Leadership', @SystemDesignCategoryId, 1),

(522, 'Design a URL shortener like bit.ly.',
'System design covering: requirements (100M URLs/day, 10B redirects/day, 100:1 read/write ratio), capacity estimation (182.5B URLs over 5 years = 36.5TB storage), architecture (Snowflake ID generation, Base62 encoding for 7-char codes), components (API service, Redis cache, SQL database with sharding), scalability (load balancer, auto-scaling, CDN), analytics (click tracking, geography). Key: 62^7 = 3.5 trillion possible URLs.',
3, 'System Design,Scalability,Architecture,Distributed Systems', @SystemDesignCategoryId, 1),

(523, 'Design a rate limiter.',
'Algorithms: Token Bucket (allows bursts), Leaky Bucket (smooth rate), Fixed Window (simple but has edge case), Sliding Window (most accurate). Implementation: Redis for distributed state, key design (rate_limit:user_id:endpoint:window), response (HTTP 429 with Retry-After header). Example: 100 requests/minute per user, use Redis INCR with expiration, sliding window for accuracy.',
3, 'System Design,Rate Limiting,Redis,Distributed Systems', @SystemDesignCategoryId, 1),

(524, 'Design a distributed cache system.',
'Components: cache nodes with consistent hashing for distribution, replication for availability, LRU/LFU eviction policies. Partitioning: consistent hashing with virtual nodes (minimize redistribution on node failure). Write strategies: cache-aside (lazy loading), write-through (always consistent), write-back (better performance). Example: Redis cluster with 3 master nodes, 3 replicas, consistent hashing, TTL-based expiration.',
3, 'System Design,Caching,Redis,Distributed Systems', @SystemDesignCategoryId, 1),

(525, 'Design a notification service.',
'Multi-channel architecture: Email (SendGrid/SES), SMS (Twilio), Push (FCM/APNS), In-app. Components: message queue (Kafka/RabbitMQ) for reliability, worker pool for processing, retry logic with exponential backoff, priority handling (P0 immediate, P1 batched, P2 deferred). Rate limiting: per channel (email: 100/hour, SMS: 10/hour). Dead letter queue for failed messages.',
3, 'System Design,Messaging,Distributed Systems', @SystemDesignCategoryId, 1),

(526, 'Design a real-time chat application.',
'Protocol: WebSockets for bidirectional communication. Architecture: connection servers (handle WebSocket connections with sticky sessions), message queue (Kafka for message persistence), message storage (Cassandra for scalability), presence service (Redis for online status). Features: 1-on-1 chat, group chat (up to 100 members), typing indicators (ephemeral), read receipts (stored), message history (last 30 days). Scaling: horizontal scaling with sticky sessions, sharding by chat_id.',
3, 'System Design,WebSockets,Real-time,Distributed Systems', @SystemDesignCategoryId, 1),

(527, 'Design an e-commerce platform (based on Globant experience).',
'Components: Product catalog (Elasticsearch for search, Redis cache for hot products), Shopping cart (Redis session store with 24-hour TTL), Order processing (event-driven with Saga pattern for distributed transactions), Payment gateway (PCI-DSS compliant with tokenization), Inventory management (optimistic locking for concurrency). Performance: CDN for static assets, database read replicas, async order processing. Result: Scaled to 10M+ daily transactions, 45% performance improvement.',
3, 'System Design,E-commerce,Microservices,Event-Driven', @SystemDesignCategoryId, 1),

(528, 'How would you design for high availability (99.9% uptime)?',
'99.9% = 43.8 minutes downtime/month. Strategies: multi-AZ deployment (3 availability zones), load balancing with health checks (remove unhealthy instances), database replication (master-slave with automated failover), circuit breakers (fail fast when dependencies down), graceful degradation (core features work even if some fail), blue-green deployments (zero downtime), monitoring and alerting (detect failures quickly). Example: Auto-scaling groups across 3 AZs, RDS with multi-AZ, Route 53 health checks.',
2, 'System Design,High Availability,Reliability,Architecture', @SystemDesignCategoryId, 1),

(529, 'How do you handle database scaling?',
'Strategies: vertical scaling (limited - upgrade CPU/RAM), read replicas (for read-heavy workloads, eventual consistency), sharding (horizontal partitioning by user_id or geography), CQRS (separate read/write databases), caching (Redis for hot data, reduce DB load), connection pooling (reuse connections, limit concurrent connections). Example: Primary DB for writes, 2 read replicas for analytics, Redis cache for product catalog, sharding users by ID range.',
2, 'Database,Scaling,Architecture,Performance', @SystemDesignCategoryId, 1),

(530, 'What is database replication? Master-slave vs master-master.',
'Master-Slave: One primary (handles writes), multiple replicas (handle reads only). Pros: simple, consistent writes. Cons: single point of failure for writes, read replicas may lag. Master-Master: Multiple primaries (both read and write). Pros: high availability, load distribution, no single point of failure. Cons: conflict resolution needed (last-write-wins, custom logic), more complex. Example: Use master-slave for most apps, master-master for global distributed systems.',
2, 'Database,Replication,High Availability', @SystemDesignCategoryId, 1),

(531, 'What is database sharding?',
'Horizontal partitioning across multiple databases. Shard key selection critical (user_id, geography, tenant_id). Strategies: Range-based (user_id 1-1M → Shard1, 1M-2M → Shard2), Hash-based (hash(user_id) % num_shards), Geography-based (US → Shard1, EU → Shard2). Challenges: cross-shard queries (avoid or aggregate at app layer), resharding (double writes during migration), hotspots (uneven distribution). Example: Instagram shards by user_id, 4000+ shards.',
2, 'Database,Sharding,Scalability,Distributed Systems', @SystemDesignCategoryId, 1),

(532, 'How do you design for fault tolerance?',
'Principles: redundancy (multiple instances, no SPOF), timeouts (don''t wait forever, 30s max), retries with exponential backoff (handle transient failures), circuit breakers (fail fast when service down after 5 failures), bulkheads (isolate failures, separate thread pools), graceful degradation (core features work even if some fail), health checks (detect failures in < 30s), chaos engineering (Netflix Chaos Monkey). Example: 3 app servers across 2 AZs, circuit breaker on payment gateway, fallback to queue for non-critical operations.',
2, 'System Design,Fault Tolerance,Reliability,Resilience', @SystemDesignCategoryId, 1),

(533, 'What is the CAP theorem?',
'Consistency (all nodes see same data), Availability (every request gets response), Partition tolerance (system works despite network failures). Theorem: Can only achieve 2 out of 3 in distributed systems. Trade-offs: CP (MongoDB, HBase) - consistent but may be unavailable during partition; AP (Cassandra, DynamoDB) - available but may serve stale data; CA - not realistic in distributed systems (network partitions happen). Choose based on requirements: banking (CP), social media (AP).',
2, 'Distributed Systems,CAP Theorem,Architecture', @SystemDesignCategoryId, 1),

(534, 'Explain eventual consistency vs strong consistency.',
'Strong Consistency: Reads always return latest write (linearizability). Pros: simpler reasoning, no stale data. Cons: higher latency, lower availability. Use cases: banking transactions, inventory management. Eventual Consistency: Reads may return stale data temporarily, all replicas converge eventually. Pros: higher availability, lower latency. Cons: complexity handling conflicts. Use cases: social media likes, DNS updates, shopping cart. Example: Amazon S3 uses eventual consistency for better availability.',
2, 'Distributed Systems,Consistency,Architecture', @SystemDesignCategoryId, 1),

(535, 'How do you handle data consistency in distributed systems?',
'Patterns: Two-Phase Commit (2PC) - atomic transactions across nodes (slow, blocking); Saga Pattern - compensating transactions for rollback (eventual consistency); Event Sourcing - append-only event log (rebuild state from events); CQRS - separate read/write models (optimize each independently); Idempotency - safe to retry (use idempotency keys); Distributed locks (Redis/Zookeeper for coordination). Example: Order processing uses Saga pattern - reserve inventory, charge payment, fulfill order (with compensation if payment fails).',
3, 'Distributed Systems,Consistency,Transactions,Architecture', @SystemDesignCategoryId, 1),

(536, 'What is a load balancer? How does it work?',
'Distributes traffic across multiple servers. Types: Layer 4 (TCP/UDP, fast, IP-based), Layer 7 (HTTP, content-based routing, sticky sessions). Algorithms: Round Robin (even distribution), Least Connections (route to least busy), IP Hash (sticky sessions via hash), Weighted (send more to powerful servers), Least Response Time (route to fastest). Health checks: remove unhealthy servers automatically. Examples: AWS ALB (Layer 7), NLB (Layer 4), nginx, HAProxy.',
2, 'Load Balancing,Scalability,Infrastructure', @SystemDesignCategoryId, 1),

(537, 'What are load balancing algorithms?',
'Round Robin: Request goes to next server in order (Server1 → Server2 → Server3 → Server1). Weighted Round Robin: More requests to powerful servers (weight=2 gets 2x traffic). Least Connections: Route to server with fewest active connections (best for long-lived connections). Least Response Time: Route to fastest server (requires health check monitoring). IP Hash: hash(client_ip) % num_servers (sticky sessions, same client always to same server). Random: Surprisingly effective, simple implementation.',
1, 'Load Balancing,Algorithms,Infrastructure', @SystemDesignCategoryId, 1),

(538, 'How do you design APIs for mobile applications?',
'Mobile-specific considerations: minimize requests (batch operations, composite endpoints /api/dashboard aggregates data), pagination (limit response size to 20-50 items), compression (gzip responses, save bandwidth), caching (ETag, Cache-Control headers, reduce redundant data), versioning (/api/v1/ for breaking changes), field filtering (?fields=id,name,email for efficiency), offline support (sync when online, conflict resolution), push notifications (real-time updates without polling). Security: OAuth 2.0, short-lived tokens (15 min), refresh tokens.',
2, 'API Design,Mobile,REST,Performance', @SystemDesignCategoryId, 1),

(539, 'How do you handle versioning in a large-scale system?',
'API Versioning: URL (/api/v1/users, /api/v2/users), Header (Accept: application/vnd.api+json;version=1), Query param (/api/users?v=1). Database Versioning: migrations (Entity Framework, Flyway), backward compatible changes first (add column, keep old), data migration scripts. Deployment Versioning: blue-green (instant switch), canary (gradual rollout to 5%, 25%, 50%, 100%), feature flags (toggle features without deployment). Best practice: Support N and N-1 versions, deprecation notices 6 months before removal.',
2, 'Versioning,API Design,Deployment,Architecture', @SystemDesignCategoryId, 1),

(540, 'What is capacity planning? How do you estimate system requirements?',
'Process: Define requirements (1M users, 10 req/user/day = 10M requests/day = 115 req/sec), estimate resources (peak 3x = 345 req/sec, with buffer 2x = 690 req/sec capacity), calculate storage (user data + transactions + media + 30% overhead), bandwidth (inbound + outbound traffic), servers needed (690 req/sec ÷ 100 req/sec/server = 7 servers), add HA (2x across 2 AZs = 14 servers). Example: URL shortener - 100M URLs/day, 10B redirects/day, 36.5TB storage, 116K reads/sec, 116 servers.',
2, 'Capacity Planning,System Design,Architecture,Scalability', @SystemDesignCategoryId, 1);

-- Q541-Q560: Behavioral Questions - Core
INSERT INTO Questions (QuestionNumber, Title, Content, Difficulty, Tags, CategoryId, IsPublished)
VALUES
(541, 'How do you estimate system requirements (storage, bandwidth, compute)?',
'Framework: Business requirements (10M DAU, 20 req/user/day), request load (200M req/day = 2,315 avg req/sec, peak 3x = 6,945 req/sec, with buffer = 10,417 req/sec target), storage (users 50GB + posts 4.5TB + media 36.5PB with 30% overhead), bandwidth (inbound uploads + outbound downloads in MB/s), compute (690 req/sec ÷ 100/server = 7 servers, with HA across 3 AZs = 21 servers), cost estimation (EC2, S3, RDS, bandwidth). Use back-of-envelope calculations for interviews.',
2, 'Capacity Planning,System Design,Estimation', @BehavioralCoreCategoryId, 1),

(542, 'Tell me about yourself and your experience.',
'Structure: Elevator pitch (2 min) covering name, role (Technical Lead, 10+ years .NET), recent impact (at Globant: 45% platform improvement, 50% API reduction, 10M+ transactions/day), key expertise (C#, .NET Core, Azure, microservices), leadership (high-performing teams, mentoring), and why this opportunity (align with specific role). Focus on quantified achievements and relevance to position. Keep concise, engaging, professional.',
1, 'STAR,Self Introduction,Interview Prep', @BehavioralCoreCategoryId, 1),

(543, 'Why are you looking for a new opportunity?',
'Professional response focusing on: technical growth (excited about cutting-edge tech, solving complex scalability), impact (want to work on products serving millions), leadership (ready for more strategic technical leadership), culture (specific aspect like innovation, learning, work-life balance). Avoid negatives about current role. Example: "Looking for challenges with distributed systems at scale, this role''s focus on microservices aligns perfectly with my interests." Keep positive, forward-looking.',
1, 'Interview Prep,Career Motivation,Behavioral', @BehavioralCoreCategoryId, 1),

(544, 'What are your greatest strengths?',
'Use structure: Strength + Example + Impact. Example 1: Complex problem-solving - At Globant, platform had 2.5s response times, profiled with Application Insights, identified N+1 queries, implemented Redis caching, optimized EF queries, added indexes - reduced response time 50% (2.5s → 1.25s). Example 2: Technical leadership - At Sagitec, team missing 40% sprint commitments, implemented capacity planning, focus hours, improved CI/CD - sprint success 40% → 90%, team satisfaction 5/10 → 8.5/10. Quantify results.',
1, 'STAR,Strengths,Interview Prep,Behavioral', @BehavioralCoreCategoryId, 1),

(545, 'What are your areas for improvement?',
'Show self-awareness + action: Area (public speaking to large audiences), context (comfortable with small groups, nervous with 50+ people), why it matters (crucial for senior leadership), what I''m doing (joined Toastmasters 6 months ago, given 8 speeches; volunteered for company all-hands presentation; watching TED talks), progress (recently presented to 200+ attendees, received positive feedback). Avoid clichés ("I''m a perfectionist"). Show genuine weakness with concrete improvement plan.',
1, 'Self Improvement,Behavioral,Interview Prep', @BehavioralCoreCategoryId, 1),

(546, 'Describe a challenging project you worked on.',
'STAR format: Situation (Globant e-commerce platform, 2M users, 2.5s response, frequent outages, 95% no tests, 6-hour manual deployments), Task (migrate to microservices, 40% performance improvement, 99.9% uptime, continuous deployment, zero downtime), Action (18-month plan: evaluated Strangler Fig pattern, identified bounded contexts, Azure setup, migrated services incrementally, implemented caching, database optimization), Result (45% responsiveness improvement, 50% API reduction, 99.95% uptime, 30-min deployments, 82% test coverage, $2M additional revenue).',
2, 'STAR,Project Experience,Leadership,Achievement', @BehavioralCoreCategoryId, 1),

(547, 'Tell me about a time you failed. What did you learn?',
'STAR honesty: Situation (early career, deploying new feature before holiday weekend), Task (rolling out on time), Action (skipped staging testing to meet deadline), Result (production bug affected 10K users, spent weekend fixing). Learning: Never skip testing even under pressure, implemented mandatory staging deployment, created pre-deployment checklist, now advocate "done means tested". Show growth, accountability, no excuses. Demonstrates maturity and learning from mistakes.',
1, 'STAR,Failure,Learning,Growth,Behavioral', @BehavioralCoreCategoryId, 1),

(548, 'Describe a conflict with a team member and how you resolved it.',
'STAR conflict resolution: Situation (senior dev disagreed with microservices decision, preferred monolith), Task (resolve without damaging relationship), Action (listened to concerns - performance overhead, complexity; presented data - scalability needs, team growth; created comparison matrix; prototyped both approaches), Result (data showed microservices right fit, dev became advocate for approach, maintained strong relationship). Show empathy, data-driven decision-making, collaborative problem-solving.',
1, 'STAR,Conflict Resolution,Teamwork,Leadership', @BehavioralCoreCategoryId, 1),

(549, 'Tell me about a time you had to work under pressure.',
'STAR under pressure: Situation (production database outage during peak hours, thousands of users affected), Task (restore service ASAP), Action (assembled incident response team, analyzed logs/metrics, identified root cause - connection pool exhaustion, implemented immediate fix - increased pool size, communicated updates every 30 min to stakeholders, conducted blameless post-mortem), Result (service restored in 2 hours, implemented monitoring alerts to prevent recurrence, zero similar incidents since). Show calm, systematic approach.',
2, 'STAR,Pressure,Incident Response,Leadership', @BehavioralCoreCategoryId, 1),

(550, 'Describe a situation where you had to learn a new technology quickly.',
'STAR rapid learning: Situation (client needed Azure Cosmos DB integration in 2 weeks), Task (learn Cosmos DB and implement solution), Action (Microsoft Learn modules - 20 hours study, built POC for hands-on learning, consulted Azure architects, pair programmed with experienced dev), Result (delivered on time, became team''s Cosmos DB expert, solution handled 1M documents with 99.99% SLA). Show proactive learning, resourcefulness, practical application.',
1, 'STAR,Learning,Adaptation,Growth', @BehavioralCoreCategoryId, 1),

(551, 'Tell me about a time you disagreed with your manager.',
'STAR respectful disagreement: Situation (manager wanted to skip code reviews for urgent feature), Task (balance speed with quality), Action (presented data on bugs from unreviewed code costing 10x more to fix, proposed lightweight alternative - time-boxed 30-min reviews, offered pair programming instead), Result (manager agreed to lightweight reviews, feature shipped on time with zero bugs). Show respect for authority while advocating for best practices with data.',
1, 'STAR,Manager Relationship,Communication,Leadership', @BehavioralCoreCategoryId, 1),

(552, 'Describe a time you had to convince stakeholders about a technical decision.',
'STAR stakeholder management: Situation (needed to invest 2 months in technical debt before new features), Task (get stakeholder buy-in for delay), Action (created cost analysis - current velocity 32 points/sprint vs future 45 points, showed risk - increasing bugs, slower delivery; presented ROI - 2 months investment → 40% faster delivery permanently, quarterly savings $50K), Result (got approval, completed refactoring, delivered 40% faster in next 6 months, reduced bugs 75%). Show business value translation.',
2, 'STAR,Stakeholder Management,Technical Debt,ROI', @BehavioralCoreCategoryId, 1),

(553, 'Tell me about a time you improved a process.',
'STAR process improvement: Situation (code reviews taking 5-7 days, blocking releases), Task (speed up review process without sacrificing quality), Action (set SLA - 4-hour first review, 24-hour approval; created review rotation schedule; limited PR size to < 400 lines; automated checklist; review metrics dashboard), Result (review time reduced from 5-7 days to 6 hours average, PR quality improved, released features 40% faster). Show systematic approach, metrics-driven.',
2, 'STAR,Process Improvement,Efficiency,Leadership', @BehavioralCoreCategoryId, 1),

(554, 'Describe a time you had to deal with ambiguity.',
'STAR handling ambiguity: Situation (new feature request with vague requirements), Task (deliver feature despite unclear scope), Action (asked clarifying questions - 5 Ws, created user stories with acceptance criteria, built quick mockup for feedback, iterative development with weekly demos to gather input), Result (delivered feature that exceeded expectations, clarified requirements through iteration). Show comfort with uncertainty, structured approach to reducing ambiguity.',
1, 'STAR,Ambiguity,Problem Solving,Requirements', @BehavioralCoreCategoryId, 1),

(555, 'Tell me about your biggest accomplishment.',
'STAR major achievement: Situation (Globant e-commerce platform modernization, legacy monolith serving 2M users), Task (migrate to microservices, improve 40% performance, achieve 99.9% uptime), Action (18-month project with Strangler Fig pattern, team of 8, implemented Azure cloud, Redis caching, Saga pattern for orders, automated CI/CD), Result (45% performance improvement, 99.95% uptime exceeded target, $2M additional revenue, 20% conversion rate increase, 82% test coverage). Reference Q546 for full details.',
2, 'STAR,Achievement,Leadership,Impact', @BehavioralCoreCategoryId, 1),

(556, 'Describe a time you mentored someone.',
'STAR mentoring: Situation (junior dev struggling with async programming, 50% efficiency), Task (help them become proficient), Action (weekly 1-on-1 mentoring sessions, pair programming on async features, code review with detailed feedback on await/async patterns, shared Pluralsight courses, created async programming guide), Result (developer improved from 50% to 90% efficiency in 2 months, promoted to mid-level developer, now mentoring others). Show investment in people, structured approach, measurable impact.',
1, 'STAR,Mentoring,Leadership,Team Development', @BehavioralCoreCategoryId, 1),

(557, 'Tell me about a time you received critical feedback.',
'STAR accepting feedback: Situation (manager said I was too hands-on, not delegating enough), Task (improve delegation skills), Action (consciously stepped back from coding, assigned features to team members with ownership, focused on mentoring and code reviews instead of implementation, tracked team growth and velocity), Result (team delivered 40% more features per sprint, team members grew faster, I had more time for strategic work). Show openness to feedback, action on criticism, positive outcome.',
1, 'STAR,Feedback,Growth,Leadership,Self Improvement', @BehavioralCoreCategoryId, 1),

(558, 'Describe a time you had to meet a tight deadline.',
'STAR tight deadline: Situation (Black Friday feature needed in 2 weeks vs 6 weeks estimated), Task (deliver core functionality on time), Action (negotiated MVP scope with stakeholders - essential features only, increased team capacity by 2 developers, daily progress reviews, deferred nice-to-have features to next sprint), Result (delivered MVP on time, handled Black Friday traffic successfully, enhanced features added in following sprint). Show pragmatism, negotiation, delivery focus.',
2, 'STAR,Deadline,Pressure,Project Management', @BehavioralCoreCategoryId, 1),

(559, 'Tell me about a time you went above and beyond.',
'STAR extra effort: Situation (production incident at 2am, critical payment processing bug affecting transactions), Task (fix critical bug preventing revenue loss), Action (debugged and fixed issue in 3 hours, created runbook for future incidents, implemented monitoring to prevent recurrence, conducted training session for team on payment processing), Result (prevented future incidents, saved company $50K/month in failed transactions, improved team knowledge). Show initiative, ownership, long-term thinking.',
2, 'STAR,Initiative,Ownership,Leadership', @BehavioralCoreCategoryId, 1),

(560, 'Describe a time you had to make a decision with incomplete information.',
'STAR incomplete info: Situation (needed to choose database - SQL vs NoSQL - without complete requirements), Task (make best decision with available info), Action (identified known requirements vs unknowns, evaluated both options against known requirements, chose SQL as safer default - easier to migrate from if needed, documented decision and assumptions in ADR with conditions that would trigger reassessment), Result (SQL was right choice, requirements clarified later confirmed this). Show risk management, documentation, adaptability.',
1, 'STAR,Decision Making,Ambiguity,Risk Management', @BehavioralCoreCategoryId, 1);

-- Q561-Q571: Behavioral Questions - Advanced
INSERT INTO Questions (QuestionNumber, Title, Content, Difficulty, Tags, CategoryId, IsPublished)
VALUES
(561, 'Tell me about a time you simplified a complex problem.',
'STAR simplification: Situation (order processing system with 2,500-line method, 8 levels of nesting, 15% test coverage, frequent bugs, 2-3 days to add payment methods), Task (simplify for maintainability and testability), Action (refactored using Strategy Pattern for payment processors, Pipeline Pattern for validation/enrichment, extracted validators with single responsibility, implemented dependency injection), Result (2,500 lines → 150 lines, complexity 47 → 5, test coverage 15% → 92%, time to add payment method 2-3 days → 2 hours, bugs 8/month → 1/month). Shows technical excellence.',
2, 'STAR,Problem Solving,Refactoring,Design Patterns', @BehavioralAdvancedCategoryId, 1),

(562, 'What motivates you in your work?',
'Authentic motivation: (1) Solving complex problems - satisfaction of taking messy code and creating elegant solutions (e.g., 2,500-line method refactor), seeing 40% productivity improvement; (2) Building and growing teams - watching junior developers grow and start mentoring others; (3) Delivering real impact - work that matters to users, knowing customers had better experience (e.g., $2M additional revenue). Ultimately: continuous learning, solving hard problems, helping others grow, delivering meaningful business value.',
1, 'Motivation,Career Goals,Passion,Values', @BehavioralAdvancedCategoryId, 1),

(563, 'Where do you see yourself in 5 years?',
'Career vision: Near-term (1-2 years) - deep expertise in cloud-native architectures, leading 15-20 engineers, mentoring technical leads, open-source contributions; Mid-term (3-4 years) - Principal Engineer or Engineering Manager, defining technical strategy across products, speaking at conferences, building high-performing culture; Long-term (5+ years) - VP of Engineering or Chief Architect, shaping company-wide technical direction, scaling engineering organizations, industry thought leadership. This role at [Company] is perfect next step offering [specific growth opportunities].',
1, 'Career Goals,Leadership,Growth,Vision', @BehavioralAdvancedCategoryId, 1),

(564, 'Why do you want to work for our company?',
'Company-specific response template: (1) Technical challenges - solving [specific challenge] at massive scale, impressed by [specific technology/blog post]; (2) Product impact - product serves [X million] users, mission to [company mission] aligns with my values; (3) Engineering culture - commitment to [testing/documentation], investment in [learning/innovation], open-source contributions to [projects]; (4) Growth opportunities - work with [technology] at scale, lead [type of projects]; (5) People - talked to [names], impressed by track record of [achievement]. Show research, genuine interest, alignment with role.',
1, 'Interview Prep,Company Research,Motivation', @BehavioralAdvancedCategoryId, 1),

(565, 'What is your ideal work environment?',
'Work environment preferences: (1) Collaborative but focused - balance between collaboration and deep work, "no meeting" blocks, open communication with respect for focus time; (2) Learning culture - continuous learning valued, conferences/courses budget, tech talks, mentorship opportunities; (3) High standards with psychological safety - high bar for quality, safe to fail and learn, constructive reviews, blameless post-mortems; (4) Autonomy with accountability - trust to make decisions, ownership of outcomes, clear goals, freedom to innovate; (5) Work-life balance - flexible hours, remote/hybrid, sustainable pace, respect for personal time; (6) Diverse and inclusive - different perspectives valued, merit-based, equitable growth.',
1, 'Work Culture,Values,Work-Life Balance', @BehavioralAdvancedCategoryId, 1),

(566, 'Tell me about a time you worked on a cross-functional team.',
'STAR cross-functional: Situation (Globant checkout flow project with Engineering 8 devs, Product 2 PMs, Design 3 UX, Marketing 2 analysts, Customer Support 1 lead), Task (coordinate technical delivery, translate requirements, align stakeholders, deliver on time with quality), Action (weekly sync all stakeholders 1 hour, daily engineering standup, bi-weekly demos, shared Slack channel, joint workshop for requirements, iterative development with UX testing), Result (delivered on time - 12 weeks, 30% checkout conversion increase, 25% cart abandonment reduction, all stakeholders satisfied NPS 9/10, zero scope creep). Shows collaboration, communication, delivery.',
2, 'STAR,Cross-Functional,Collaboration,Leadership', @BehavioralAdvancedCategoryId, 1),

(567, 'Describe how you handle technical debt.',
'Technical debt strategy: (1) Identify and track - create backlog items with impact/effort/risk scores; (2) Prioritize - matrix of (impact × risk) / effort, high-impact low-effort first; (3) Allocate capacity - 20% of each sprint for debt, quarterly dedicated debt sprint; (4) Prevent new debt - code review checklist, definition of done includes tests/documentation, SonarQube quality gates; (5) Communicate impact - show velocity improvement, bug reduction, feature delivery speed to stakeholders. STAR example: Sagitec debt slowed velocity 25→18 points, bug rate 3→12/month - created inventory 45 items, allocated 20% capacity, dedicated Q2 sprint - velocity 18→28 points, bugs 12→3/month, debt 45→12 days (73% reduction).',
2, 'Technical Debt,Process,Leadership,Metrics', @BehavioralAdvancedCategoryId, 1),

(568, 'What are you passionate about in technology?',
'Technology passions: (1) Cloud-native architectures - designing resilient, scalable, cost-effective systems, serverless event-driven processing 1M events/day < $50/month; (2) Performance optimization - satisfaction of making systems faster, reducing 2.5s → 1.4s like solving puzzle; (3) Developer experience - making developers'' lives better through CI/CD automation, great documentation, local environments that work; (4) System design and architecture - big-picture thinking, trade-offs between consistency and availability, scalability patterns; (5) Mentorship and knowledge sharing - technology most impactful when shared. Stay current: side projects, architecture blogs, courses, conferences.',
1, 'Passion,Technology,Learning,Growth', @BehavioralAdvancedCategoryId, 1),

(569, 'How do you handle work-life balance?',
'Work-life balance approach: (1) Boundaries - work 7am-4pm, no email/Slack after 6pm except emergencies, weekends sacred for family, communicate boundaries clearly; (2) Efficiency during work - focus time 9am-12pm no meetings, batch meetings 1pm-4pm, Pomodoro for complex tasks, delegate effectively; (3) Sustainable pace - avoid overtime culture (sign of poor planning), plan 80% capacity not 100%, take breaks, use all vacation days; (4) Energy management - exercise 3x/week before work, 7-8 hours sleep, healthy eating, hobbies outside tech; (5) Team culture - lead by example, respect team time, realistic sprint planning. Emergency handling: on-call rotation, runbooks, monitoring, post-mortems to prevent recurrence. Result: high performance 10+ years without burnout, low team turnover.',
1, 'Work-Life Balance,Health,Sustainability,Leadership', @BehavioralAdvancedCategoryId, 1),

(570, 'What questions do you have for us?',
'Smart interview questions: Technical (current architecture evolution, biggest technical challenges, technical debt balance, deployment pipeline frequency, monitoring/observability tools, code quality practices); Team (team structure and collaboration, sprint/development cycle, knowledge sharing and documentation, mentorship opportunities); Culture (engineering culture description, work-life balance, professional development support, what you enjoy most working here); Growth (career path for role, performance evaluation and feedback, opportunities for different technologies); Impact (role contribution to company mission, success in first 6 months, biggest challenges for company/team); For hiring manager (leadership style, team growth support, exciting plans this year); Meta (next steps in process, clarify any concerns about my background). Ask 3-5 questions tailored to interviewer.',
1, 'Interview Prep,Questions,Engagement', @BehavioralAdvancedCategoryId, 1),

(571, 'What are your salary expectations? (Salary negotiation)',
'Negotiation approach: Research first (Glassdoor, Levels.fyi, PayScale for market rates). Initial response if asked early: "More focused on right fit and growth opportunity, sure we can agree on fair compensation if mutual fit. Can you share budget range for role?" When must give number: "Based on research for [role] with [X years] in [market], seen ranges $[low]-$[high]. Given my experience with [specific skills/achievements like 45% performance improvements, Azure architecture], I''d expect $[target] range. Open to discussing full package including benefits, equity, bonus." Know your worth: base + bonus + equity + benefits. Total comp: Base $150K + Bonus 15% ($22.5K) + RSUs $40K/year + Benefits $15K = $227.5K total. Have range: minimum acceptable (floor), target (market rate), ideal (reach). Get it in writing. Be willing to walk if can''t meet minimum. Never reveal current salary. Focus on value you bring, not what you need.',
1, 'Salary,Negotiation,Compensation,Career', @BehavioralAdvancedCategoryId, 1);

PRINT 'Successfully added 71 questions (Q501-Q571)';
PRINT 'Categories added: Leadership & Team Management, System Design & Scalability, Behavioral Questions (Core & Advanced)';
PRINT 'Total interview question bank: 571 questions complete!';
