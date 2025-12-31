# Q521-Q540: System Design & Scalability

## Q521: Describe your experience with Agile/Scrum team management.

### Agile Leadership Experience

```csharp
public class AgileTeamManagement
{
    // Real Experience: Managing Scrum Teams at Globant & Sagitec
    public class ScrumMastershipExperience
    {
        public TeamStructure MyTeamStructure = new TeamStructure
        {
            TeamSize = 8, // developers
            ScrumMaster = "Rotated role among senior devs",
            ProductOwner = "Dedicated PO",
            SprintDuration = "2 weeks",

            Ceremonies = new[]
            {
                "Sprint Planning: 4 hours (bi-weekly)",
                "Daily Standup: 15 minutes",
                "Sprint Review: 2 hours",
                "Sprint Retrospective: 1.5 hours",
                "Backlog Refinement: 2 hours (mid-sprint)"
            }
        };

        // ✅ GOOD: Effective Sprint Planning
        public void RunSprintPlanning()
        {
            // Part 1: What will we deliver? (2 hours)
            var sprintGoal = "Enable user authentication and authorization";

            var selectedStories = new[]
            {
                new UserStory
                {
                    Id = "US-123",
                    Title = "As a user, I can login with email/password",
                    AcceptanceCriteria = new[]
                    {
                        "User can enter email and password",
                        "System validates credentials",
                        "User receives JWT token on success",
                        "Appropriate error shown on failure"
                    },
                    StoryPoints = 5
                },
                new UserStory
                {
                    Id = "US-124",
                    Title = "As a user, I can reset my password",
                    StoryPoints = 3
                },
                new UserStory
                {
                    Id = "US-125",
                    Title = "As an admin, I can manage user roles",
                    StoryPoints = 8
                }
            };

            // Part 2: How will we do it? (2 hours)
            var tasks = BreakdownIntoTasks(selectedStories);

            // Capacity planning
            var teamCapacity = new
            {
                TotalDevelopers = 8,
                SprintDays = 10, // 2 weeks
                HoursPerDay = 6, // accounting for meetings, etc.
                TotalHours = 8 * 10 * 6 // 480 hours
            };

            var commitment = new
            {
                TotalStoryPoints = 16,
                EstimatedHours = 450,
                BufferHours = 30, // 6% buffer
                Achievable = true
            };
        }

        // ✅ GOOD: Effective Daily Standup
        public void RunDailyStandup()
        {
            var format = @"
Each team member answers:
1. What did I complete yesterday?
2. What am I working on today?
3. Any blockers?

Duration: 15 minutes MAX

Rules:
- Stand up (keeps it short)
- One person talks at a time
- Park detailed discussions for after
- Update Jira board in real-time
            ";

            // Example standup update
            var update = new
            {
                Yesterday = "Completed US-123: Login API endpoint",
                Today = "Working on US-123: Frontend integration",
                Blockers = "Need API documentation from backend team"
            };

            // Scrum Master action: Immediately address blocker
            var action = "Will connect Dev A with Backend Lead after standup";
        }

        // ✅ GOOD: Sprint Retrospective Format
        public void RunRetrospective()
        {
            var retrospective = new
            {
                // Start-Stop-Continue format
                Start = new[]
                {
                    "Start using mob programming for complex features",
                    "Start automated deployment to staging"
                },
                Stop = new[]
                {
                    "Stop merging PRs without running tests locally",
                    "Stop scheduling meetings during focus hours (9-12)"
                },
                Continue = new[]
                {
                    "Continue pair programming rotations",
                    "Continue weekly tech talks"
                },

                // Action Items (SMART goals)
                ActionItems = new[]
                {
                    new ActionItem
                    {
                        What = "Set up automated staging deployments",
                        Who = "DevOps Lead",
                        When = "Next Sprint",
                        Success = "Zero manual staging deployments"
                    }
                }
            };
        }

        // Metrics I Tracked
        public class TeamMetrics
        {
            // Velocity tracking
            public int[] VelocityPerSprint = { 12, 15, 18, 16, 17, 18 }; // Story points
            public double AverageVelocity = 16.0;

            // Quality metrics
            public double DefectRate = 2.5; // defects per sprint
            public double CodeCoverage = 85; // %

            // Process metrics
            public double SprintCommitmentAchieved = 90; // %
            public double StoryCarryover = 5; // %

            // Team health
            public double TeamSatisfaction = 8.5; // out of 10
            public double Burnout = 2; // out of 10 (lower is better)
        }
    }
}
```

**STAR Example**:

**Situation**: At Sagitec, inherited a team with low morale (satisfaction: 5/10), missing 40% of sprint commitments, and high carryover (30%).

**Task**: Improve team performance and morale as Scrum Master/Technical Lead.

**Action**:
1. **Addressed root causes** (via retrospectives):
   - Unrealistic commitments → Implemented capacity-based planning
   - Frequent context switching → Established "no meeting" focus hours (9am-12pm)
   - Unclear requirements → Added backlog refinement sessions

2. **Improved ceremonies**:
   - Sprint Planning: Used Planning Poker for better estimates
   - Daily Standup: Time-boxed to 15 minutes, moved to 9:30am
   - Retrospectives: Rotated formats (Start-Stop-Continue, Mad-Sad-Glad, 4Ls)

3. **Enhanced visibility**:
   - Daily burndown chart updates
   - Sprint health dashboard
   - Blocker tracking board

**Result**:
- Sprint commitment achievement: 40% → 90%
- Story carryover: 30% → 5%
- Team satisfaction: 5/10 → 8.5/10
- Velocity stabilized at 16 points/sprint (predictable)
- Zero turnover in 18 months

---

## Q522: Design a URL shortener like bit.ly.

### System Design Overview

```csharp
// Requirements Analysis
public class URLShortenerRequirements
{
    // Functional Requirements
    public string[] FunctionalRequirements = new[]
    {
        "1. Shorten long URL to short URL",
        "2. Redirect short URL to original URL",
        "3. Custom aliases (optional)",
        "4. Analytics (click count, geography)",
        "5. URL expiration (optional)"
    };

    // Non-Functional Requirements
    public class NFRs
    {
        public int ReadWriteRatio = 100; // 100:1 (more reads than writes)
        public string Availability = "99.9%";
        public int ResponseTime = 100; // ms
        public long URLsPerDay = 100_000_000; // 100M new URLs/day
        public long RedirectsPerDay = 10_000_000_000; // 10B redirects/day
        public int DataRetention = 5 * 365; // days
    }

    // Capacity Estimation
    public class CapacityEstimation
    {
        // Storage
        public long TotalURLs = 100_000_000L * 365 * 5; // 182.5 billion
        public int AvgURLLength = 200; // bytes
        public long StorageNeeded = 182_500_000_000L * 200; // 36.5 TB

        // Bandwidth
        public long WritesPerSecond = 100_000_000 / 86400; // ~1160 writes/sec
        public long ReadsPerSecond = 10_000_000_000L / 86400; // ~116K reads/sec
    }
}

// Architecture Design
public class URLShortenerArchitecture
{
    // Component 1: Short Code Generator
    public class ShortCodeGenerator
    {
        // Approach 1: Base62 Encoding (Twitter Snowflake style)
        private const string ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
        private const int BASE = 62;
        private const int CODE_LENGTH = 7; // 62^7 = 3.5 trillion URLs

        // ✅ GOOD: Snowflake ID generator
        public class SnowflakeIdGenerator
        {
            private readonly long _epoch = new DateTime(2024, 1, 1).Ticks;
            private readonly int _machineId;
            private long _sequence = 0;
            private long _lastTimestamp = -1;

            public SnowflakeIdGenerator(int machineId)
            {
                _machineId = machineId; // 10 bits = 1024 machines
            }

            public long NextId()
            {
                lock (this)
                {
                    var timestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

                    if (timestamp < _lastTimestamp)
                        throw new Exception("Clock moved backwards!");

                    if (timestamp == _lastTimestamp)
                    {
                        _sequence = (_sequence + 1) & 4095; // 12 bits
                        if (_sequence == 0)
                        {
                            // Wait for next millisecond
                            while (timestamp <= _lastTimestamp)
                                timestamp = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
                        }
                    }
                    else
                    {
                        _sequence = 0;
                    }

                    _lastTimestamp = timestamp;

                    // 64-bit ID structure:
                    // 41 bits: timestamp
                    // 10 bits: machine ID
                    // 12 bits: sequence
                    return ((timestamp - _epoch) << 22)
                           | (_machineId << 12)
                           | _sequence;
                }
            }
        }

        public string GenerateShortCode(long id)
        {
            var result = new StringBuilder();

            while (id > 0)
            {
                result.Insert(0, ALPHABET[(int)(id % BASE)]);
                id /= BASE;
            }

            while (result.Length < CODE_LENGTH)
                result.Insert(0, '0');

            return result.ToString();
        }

        // Approach 2: MD5 Hash (collision handling needed)
        public string GenerateShortCodeFromHash(string longUrl)
        {
            using var md5 = MD5.Create();
            var hash = md5.ComputeHash(Encoding.UTF8.GetBytes(longUrl));
            var base64 = Convert.ToBase64String(hash);

            // Take first 7 characters
            var shortCode = base64.Substring(0, 7)
                .Replace('+', 'A')
                .Replace('/', 'B')
                .Replace('=', 'C');

            return shortCode;
        }
    }

    // Component 2: API Service
    public class URLShortenerAPI
    {
        private readonly IURLRepository _repository;
        private readonly ICache _cache;
        private readonly IAnalytics _analytics;
        private readonly IIdGenerator _idGenerator;

        [HttpPost("api/shorten")]
        public async Task<IActionResult> ShortenURL([FromBody] ShortenRequest request)
        {
            // Validation
            if (!Uri.TryCreate(request.LongUrl, UriKind.Absolute, out _))
                return BadRequest("Invalid URL");

            // Check if URL already shortened
            var existing = await _repository.GetByLongUrl(request.LongUrl);
            if (existing != null)
                return Ok(new { shortUrl = $"https://short.ly/{existing.ShortCode}" });

            // Generate short code
            var id = _idGenerator.NextId();
            var shortCode = request.CustomAlias ?? GenerateShortCode(id);

            // Check custom alias availability
            if (request.CustomAlias != null)
            {
                if (await _repository.ExistsAsync(shortCode))
                    return Conflict("Custom alias already taken");
            }

            // Save to database
            var urlMapping = new URLMapping
            {
                Id = id,
                ShortCode = shortCode,
                LongUrl = request.LongUrl,
                CreatedAt = DateTime.UtcNow,
                ExpiresAt = request.ExpiresAt,
                UserId = GetUserId()
            };

            await _repository.AddAsync(urlMapping);

            // Cache for quick access
            await _cache.SetAsync(
                shortCode,
                request.LongUrl,
                TimeSpan.FromHours(24)
            );

            return Ok(new
            {
                shortUrl = $"https://short.ly/{shortCode}",
                longUrl = request.LongUrl,
                expiresAt = request.ExpiresAt
            });
        }

        [HttpGet("{shortCode}")]
        public async Task<IActionResult> Redirect(string shortCode)
        {
            // Try cache first
            var longUrl = await _cache.GetAsync(shortCode);

            if (longUrl == null)
            {
                // Cache miss - get from database
                var mapping = await _repository.GetByShortCodeAsync(shortCode);

                if (mapping == null)
                    return NotFound();

                if (mapping.ExpiresAt.HasValue && mapping.ExpiresAt < DateTime.UtcNow)
                    return Gone("URL has expired");

                longUrl = mapping.LongUrl;

                // Update cache
                await _cache.SetAsync(
                    shortCode,
                    longUrl,
                    TimeSpan.FromHours(24)
                );
            }

            // Track analytics asynchronously
            _ = _analytics.TrackClickAsync(new ClickEvent
            {
                ShortCode = shortCode,
                Timestamp = DateTime.UtcNow,
                UserAgent = Request.Headers["User-Agent"],
                IPAddress = GetClientIP(),
                Referer = Request.Headers["Referer"]
            });

            return Redirect(longUrl);
        }

        [HttpGet("api/analytics/{shortCode}")]
        public async Task<IActionResult> GetAnalytics(string shortCode)
        {
            var analytics = await _analytics.GetAnalyticsAsync(shortCode);
            return Ok(analytics);
        }
    }

    // Component 3: Data Models
    public class URLMapping
    {
        public long Id { get; set; }
        public string ShortCode { get; set; }
        public string LongUrl { get; set; }
        public DateTime CreatedAt { get; set; }
        public DateTime? ExpiresAt { get; set; }
        public string UserId { get; set; }
    }

    public class URLAnalytics
    {
        public string ShortCode { get; set; }
        public long TotalClicks { get; set; }
        public Dictionary<string, int> ClicksByCountry { get; set; }
        public Dictionary<string, int> ClicksByDevice { get; set; }
        public Dictionary<DateTime, int> ClicksByDate { get; set; }
    }
}

// Database Design
public class DatabaseSchema
{
    public string URLMappingTable = @"
CREATE TABLE URLMappings (
    Id BIGINT PRIMARY KEY,
    ShortCode VARCHAR(10) UNIQUE NOT NULL,
    LongUrl VARCHAR(2048) NOT NULL,
    CreatedAt DATETIME NOT NULL,
    ExpiresAt DATETIME NULL,
    UserId VARCHAR(50) NULL,
    INDEX idx_shortcode (ShortCode),
    INDEX idx_longurl (LongUrl(255))
);
    ";

    public string AnalyticsTable = @"
CREATE TABLE ClickEvents (
    Id BIGINT AUTO_INCREMENT PRIMARY KEY,
    ShortCode VARCHAR(10) NOT NULL,
    Timestamp DATETIME NOT NULL,
    IPAddress VARCHAR(45),
    UserAgent VARCHAR(500),
    Country VARCHAR(2),
    Device VARCHAR(50),
    INDEX idx_shortcode_timestamp (ShortCode, Timestamp)
);
    ";
}

// Scalability Strategy
public class ScalabilityDesign
{
    // 1. Horizontal Scaling
    public class LoadBalancing
    {
        public string[] APIServers = new[]
        {
            "Load Balancer (AWS ALB)",
            "API Server 1 (Auto-scaled)",
            "API Server 2 (Auto-scaled)",
            "API Server N (Auto-scaled)"
        };
    }

    // 2. Database Scaling
    public class DatabaseScaling
    {
        // Read replicas for analytics
        public string[] DatabaseTier = new[]
        {
            "Primary DB (Writes)",
            "Read Replica 1 (Analytics queries)",
            "Read Replica 2 (Analytics queries)"
        };

        // Partitioning strategy
        public string PartitioningStrategy = @"
Partition by ShortCode range:
- Partition 0: 0000000-1999999
- Partition 1: 2000000-3999999
- Partition 2: 4000000-5999999
- ...
        ";
    }

    // 3. Caching Strategy
    public class CachingStrategy
    {
        // Redis cluster for hot URLs
        public class RedisCache
        {
            // Cache hot URLs (80/20 rule)
            public string CacheKey = "url:{shortCode}";
            public TimeSpan TTL = TimeSpan.FromHours(24);

            // Cache eviction: LRU
            public int MaxMemory = 64; // GB
        }

        // CDN for redirect HTML
        public string CDN = "CloudFront for geo-distributed redirects";
    }

    // 4. Rate Limiting
    public class RateLimiting
    {
        public int AnonymousLimit = 10; // per minute
        public int AuthenticatedLimit = 1000; // per minute
        public int EnterpriseLimit = 100000; // per minute
    }
}

// High Availability
public class HighAvailability
{
    public string[] HAStrategy = new[]
    {
        "Multi-AZ deployment",
        "Database replication (async)",
        "Redis cluster with sentinel",
        "Health checks and auto-recovery",
        "Circuit breakers for external dependencies",
        "Graceful degradation (analytics can be delayed)"
    };
}
```

**Architecture Diagram**:
```
┌─────────────────────────────────────────────────────────────┐
│                      Client Requests                        │
└─────────────────────┬───────────────────────────────────────┘
                      │
                      ▼
              ┌───────────────┐
              │ Load Balancer │
              └───────┬───────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
   ┌────────┐    ┌────────┐    ┌────────┐
   │API Srv1│    │API Srv2│    │API SrvN│
   └────┬───┘    └────┬───┘    └────┬───┘
        │             │             │
        └─────────────┼─────────────┘
                      │
        ┌─────────────┼─────────────┐
        ▼             ▼             ▼
   ┌────────┐    ┌────────┐    ┌────────┐
   │ Redis  │    │Primary │    │Analytics│
   │ Cache  │    │   DB   │    │  Queue  │
   └────────┘    └────┬───┘    └────────┘
                      │
                      ├─────────────┐
                      ▼             ▼
                 ┌─────────┐   ┌─────────┐
                 │Read Rep1│   │Read Rep2│
                 └─────────┘   └─────────┘
```

---

## Summary of Q523-Q540

### Q523: Design a rate limiter
- **Algorithms**: Token Bucket, Leaky Bucket, Fixed Window, Sliding Window
- **Storage**: Redis for distributed rate limiting
- **Key design**: `rate_limit:{user_id}:{endpoint}:{window}`
- **Response**: HTTP 429 with Retry-After header
- **See**: Q443 for detailed implementation

### Q524: Design a distributed cache system
- **Components**: Cache nodes, consistent hashing, replication
- **Eviction**: LRU, LFU, TTL-based
- **Consistency**: Eventually consistent, write-through/write-back
- **Partitioning**: Consistent hashing with virtual nodes
- **See**: Q442 for detailed implementation

### Q525: Design a notification service
- **Channels**: Email, SMS, Push, In-app
- **Architecture**: Message queue, worker pool, retry logic
- **Priority**: P0 (immediate), P1 (batched), P2 (deferred)
- **Rate limiting**: Per channel limits
- **See**: Q444 for detailed implementation

### Q526: Design a real-time chat application
- **Protocol**: WebSockets for bidirectional communication
- **Architecture**:
  - Connection servers (handle WebSocket connections)
  - Message queue (Kafka/RabbitMQ)
  - Message storage (Cassandra/MongoDB)
  - Presence service (Redis)
- **Features**: 1-on-1 chat, group chat, typing indicators, read receipts
- **Scaling**: Horizontal scaling with sticky sessions

### Q527: Design an e-commerce platform
Based on Globant experience:
- **Components**:
  - Product catalog (search with Elasticsearch)
  - Shopping cart (Redis session store)
  - Order processing (event-driven with Saga pattern)
  - Payment gateway (PCI-DSS compliant)
  - Inventory management (optimistic locking)
- **Performance**:
  - CDN for static assets
  - Redis cache for product catalog
  - Database read replicas
  - Async order processing

### Q528: How would you design for high availability (99.9% uptime)?
- **99.9% uptime** = 43.8 minutes downtime/month
- **Strategies**:
  - Multi-AZ deployment (3 availability zones)
  - Load balancing with health checks
  - Database replication (master-slave)
  - Automated failover
  - Circuit breakers
  - Graceful degradation
  - Blue-green deployments
  - Monitoring and alerting

### Q529: How do you handle database scaling?
- **Vertical scaling**: Upgrade CPU/RAM (limited)
- **Read replicas**: For read-heavy workloads
- **Partitioning/Sharding**:
  - Horizontal: Split by range (user_id 1-1M, 1M-2M)
  - Vertical: Split tables by domain
- **CQRS**: Separate read and write databases
- **Caching**: Redis for hot data
- **Connection pooling**: Reuse connections

### Q530: What is database replication? Master-slave vs master-master
**Master-Slave**:
- One primary (writes), multiple replicas (reads)
- Pros: Simple, consistent
- Cons: Single point of failure for writes

**Master-Master**:
- Multiple primaries (both read and write)
- Pros: High availability, load distribution
- Cons: Conflict resolution needed

### Q531: What is database sharding?
- **Definition**: Horizontal partitioning across multiple databases
- **Shard key**: Choose wisely (user_id, geo, tenant_id)
- **Strategies**:
  - Range-based: user_id 1-1M → Shard 1
  - Hash-based: hash(user_id) % num_shards
  - Geography-based: US → Shard 1, EU → Shard 2
- **Challenges**: Cross-shard queries, resharding

### Q532: How do you design for fault tolerance?
- **Redundancy**: Multiple instances, no SPOF
- **Timeouts**: Don't wait forever
- **Retries**: With exponential backoff
- **Circuit breakers**: Fail fast when service is down
- **Bulkheads**: Isolate failures
- **Graceful degradation**: Core features work even if some fail
- **Health checks**: Detect failures quickly

### Q533: What is the CAP theorem?
- **C**onsistency: All nodes see same data
- **A**vailability: Every request gets a response
- **P**artition tolerance: System works despite network splits

**Trade-off**: Can only achieve 2 out of 3
- **CP**: Consistent but may be unavailable (MongoDB, HBase)
- **AP**: Available but may be inconsistent (Cassandra, DynamoDB)
- **CA**: Not realistic in distributed systems

### Q534: Explain eventual consistency vs strong consistency
**Strong Consistency**:
- Read always returns latest write
- Example: Bank transactions
- Trade-off: Higher latency, lower availability

**Eventual Consistency**:
- Reads may return stale data temporarily
- Eventually all replicas converge
- Example: Social media likes, DNS
- Trade-off: Higher availability, lower latency

### Q535: How do you handle data consistency in distributed systems?
- **Two-Phase Commit (2PC)**: Atomic distributed transactions (slow)
- **Saga Pattern**: Compensating transactions for rollback
- **Event Sourcing**: Append-only event log
- **CQRS**: Separate read/write models
- **Idempotency**: Safe to retry operations
- **Distributed locks**: Redis/Zookeeper

### Q536: What is a load balancer? How does it work?
- **Purpose**: Distribute traffic across servers
- **Types**:
  - Layer 4 (TCP): Fast, simple
  - Layer 7 (HTTP): Content-based routing
- **Algorithms**:
  - Round Robin: Distribute evenly
  - Least Connections: Send to least busy
  - IP Hash: Sticky sessions
  - Weighted: More traffic to powerful servers
- **Health Checks**: Remove unhealthy servers

### Q537: What are load balancing algorithms?
- **Round Robin**: Server 1 → Server 2 → Server 3 → Server 1
- **Weighted Round Robin**: More traffic to powerful servers
- **Least Connections**: Route to server with fewest active connections
- **Least Response Time**: Route to fastest server
- **IP Hash**: hash(client_ip) % num_servers (sticky sessions)
- **Random**: Distribute randomly (surprisingly effective)

### Q538: How do you design APIs for mobile applications?
- **Minimize requests**: Batch operations, composite endpoints
- **Pagination**: Limit response size
- **Compression**: gzip responses
- **Caching**: ETag, Cache-Control headers
- **Versioning**: /api/v1/, /api/v2/
- **Field filtering**: `?fields=id,name,email`
- **Offline support**: Sync when online
- **Push notifications**: For real-time updates
- **Security**: OAuth 2.0, short-lived tokens

### Q539: How do you handle versioning in a large-scale system?
- **API Versioning**:
  - URL: `/api/v1/users`
  - Header: `Accept: application/vnd.api+json; version=1`
  - Query param: `/api/users?version=1`
- **Database Versioning**:
  - Migrations (Entity Framework)
  - Backward compatible changes first
- **Deployment Versioning**:
  - Blue-green deployments
  - Canary releases
  - Feature flags

### Q540: What is capacity planning?
- **Definition**: Estimating resources needed
- **Steps**:
  1. Define requirements (users, requests/sec, data size)
  2. Estimate resources (CPU, RAM, storage, bandwidth)
  3. Add buffer (30-50%)
  4. Plan for growth (2x in 12 months)
  5. Monitor and adjust

**Example**:
- 1M users, 10 requests/user/day = 10M requests/day = 115 req/sec
- Peak traffic (3x): 345 req/sec
- With buffer (2x): 690 req/sec capacity needed

---

## Key Principles for System Design Interviews

### 1. **Clarify Requirements**
```
Functional:
- What features are required?
- What scale (users, requests, data)?
- What performance expectations?

Non-Functional:
- Availability (99.9%? 99.99%?)
- Consistency vs Availability trade-off?
- Read-heavy or write-heavy?
- Budget constraints?
```

### 2. **Back-of-the-Envelope Estimation**
```
Storage: 100M users * 1KB/user = 100GB
Bandwidth: 10K requests/sec * 1KB = 10MB/sec
Servers: 10K req/sec ÷ 100 req/sec/server = 100 servers
```

### 3. **Design from High-Level to Details**
```
1. Draw high-level architecture
2. Identify bottlenecks
3. Optimize components
4. Discuss trade-offs
```

### 4. **Consider Trade-offs**
```
- Latency vs Throughput
- Consistency vs Availability
- Cost vs Performance
- Complexity vs Maintainability
```

### 5. **Address Scalability**
```
- Horizontal scaling (add more servers)
- Caching (reduce database load)
- Load balancing (distribute traffic)
- Database sharding (partition data)
- Async processing (decouple components)
```

### 6. **Ensure Reliability**
```
- Redundancy (no single point of failure)
- Monitoring (detect issues)
- Alerting (respond quickly)
- Graceful degradation (core features work)
- Disaster recovery (backups, replicas)
```
