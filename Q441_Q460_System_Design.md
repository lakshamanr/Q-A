# Interview Questions 441-460: System Design & Scalability

## Q441: How would you design a URL shortening service like bit.ly? Discuss the architecture, database design, and handling high throughput.

### Complete System Design for URL Shortener

#### **Architecture Overview**

```
┌─────────────┐
│   Client    │
└──────┬──────┘
       │
       ▼
┌─────────────────────────────────────────┐
│         Load Balancer (ALB/NLB)         │
└──────┬──────────────────────┬───────────┘
       │                      │
       ▼                      ▼
┌─────────────┐      ┌─────────────┐
│  API Server │      │  API Server │  (Auto-scaling)
└──────┬──────┘      └──────┬──────┘
       │                    │
       ├────────────────────┤
       │                    │
       ▼                    ▼
┌─────────────────────────────────┐
│      Redis Cache (Read)         │
│  - Most accessed URLs           │
│  - TTL: 24 hours                │
└─────────────┬───────────────────┘
              │ Cache Miss
              ▼
┌─────────────────────────────────┐
│   Primary Database (Write)      │
│   - PostgreSQL/MySQL            │
│   - Sharded by hash(shortCode)  │
└─────────────┬───────────────────┘
              │
              ▼
┌─────────────────────────────────┐
│   Read Replicas (3-5 nodes)     │
└─────────────────────────────────┘
```

#### **Database Schema Design**

```sql
-- ✅ URLs Table - Optimized for high throughput
CREATE TABLE urls (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    short_code VARCHAR(10) NOT NULL UNIQUE,
    long_url VARCHAR(2048) NOT NULL,
    user_id BIGINT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    expires_at TIMESTAMP NULL,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,

    INDEX idx_short_code (short_code),
    INDEX idx_user_id (user_id),
    INDEX idx_created_at (created_at)
) ENGINE=InnoDB
  ROW_FORMAT=COMPRESSED
  KEY_BLOCK_SIZE=8;

-- Analytics Table (Separate for write optimization)
CREATE TABLE url_clicks (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    short_code VARCHAR(10) NOT NULL,
    clicked_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    ip_address VARCHAR(45),
    user_agent TEXT,
    referer VARCHAR(255),
    country_code VARCHAR(2),

    INDEX idx_short_code_time (short_code, clicked_at),
    INDEX idx_clicked_at (clicked_at)
) ENGINE=InnoDB
  PARTITION BY RANGE (UNIX_TIMESTAMP(clicked_at)) (
    PARTITION p_2024_01 VALUES LESS THAN (UNIX_TIMESTAMP('2024-02-01')),
    PARTITION p_2024_02 VALUES LESS THAN (UNIX_TIMESTAMP('2024-03-01')),
    -- Monthly partitions for easy archival
    PARTITION p_future VALUES LESS THAN MAXVALUE
);

-- Users Table (Optional for authenticated users)
CREATE TABLE users (
    id BIGINT PRIMARY KEY AUTO_INCREMENT,
    email VARCHAR(255) NOT NULL UNIQUE,
    api_key VARCHAR(64) UNIQUE,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,

    INDEX idx_email (email),
    INDEX idx_api_key (api_key)
);
```

#### **Short Code Generation Strategies**

**Strategy 1: Base62 Encoding (Recommended)**

```csharp
public class Base62ShortCodeGenerator : IShortCodeGenerator
{
    private const string ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    private const int BASE = 62;
    private const int SHORT_CODE_LENGTH = 7; // 62^7 = 3.5 trillion URLs

    private readonly IDistributedIdGenerator _idGenerator; // Snowflake ID

    public string GenerateShortCode(long id)
    {
        var result = new StringBuilder();
        var number = id;

        while (number > 0)
        {
            result.Insert(0, ALPHABET[(int)(number % BASE)]);
            number /= BASE;
        }

        // Pad to ensure consistent length
        while (result.Length < SHORT_CODE_LENGTH)
        {
            result.Insert(0, ALPHABET[0]);
        }

        return result.ToString();
    }

    public long DecodeShortCode(string shortCode)
    {
        long result = 0;
        foreach (char c in shortCode)
        {
            result = result * BASE + ALPHABET.IndexOf(c);
        }
        return result;
    }
}

// Snowflake-style Distributed ID Generator
public class SnowflakeIdGenerator : IDistributedIdGenerator
{
    private const long EPOCH = 1640995200000L; // 2022-01-01
    private const int WORKER_ID_BITS = 10;
    private const int SEQUENCE_BITS = 12;

    private readonly long _workerId;
    private long _sequence = 0L;
    private long _lastTimestamp = -1L;
    private readonly object _lock = new();

    public SnowflakeIdGenerator(long workerId)
    {
        if (workerId < 0 || workerId >= (1 << WORKER_ID_BITS))
            throw new ArgumentException("Worker ID out of range");

        _workerId = workerId;
    }

    public long NextId()
    {
        lock (_lock)
        {
            var timestamp = GetCurrentTimestamp();

            if (timestamp < _lastTimestamp)
                throw new InvalidOperationException("Clock moved backwards");

            if (timestamp == _lastTimestamp)
            {
                _sequence = (_sequence + 1) & ((1 << SEQUENCE_BITS) - 1);
                if (_sequence == 0)
                {
                    timestamp = WaitNextMillis(_lastTimestamp);
                }
            }
            else
            {
                _sequence = 0;
            }

            _lastTimestamp = timestamp;

            return ((timestamp - EPOCH) << (WORKER_ID_BITS + SEQUENCE_BITS))
                   | (_workerId << SEQUENCE_BITS)
                   | _sequence;
        }
    }

    private long GetCurrentTimestamp() => DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

    private long WaitNextMillis(long lastTimestamp)
    {
        var timestamp = GetCurrentTimestamp();
        while (timestamp <= lastTimestamp)
        {
            timestamp = GetCurrentTimestamp();
        }
        return timestamp;
    }
}
```

**Strategy 2: Random String with Collision Handling (Alternative)**

```csharp
public class RandomShortCodeGenerator : IShortCodeGenerator
{
    private const string ALPHABET = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz";
    private const int SHORT_CODE_LENGTH = 7;
    private readonly IUrlRepository _repository;

    public async Task<string> GenerateUniqueShortCodeAsync()
    {
        const int MAX_RETRIES = 5;

        for (int attempt = 0; attempt < MAX_RETRIES; attempt++)
        {
            var shortCode = GenerateRandomCode();

            // Check for collision
            if (!await _repository.ShortCodeExistsAsync(shortCode))
            {
                return shortCode;
            }
        }

        throw new InvalidOperationException("Failed to generate unique short code");
    }

    private string GenerateRandomCode()
    {
        var random = RandomNumberGenerator.Create();
        var bytes = new byte[SHORT_CODE_LENGTH];
        random.GetBytes(bytes);

        return new string(bytes.Select(b => ALPHABET[b % ALPHABET.Length]).ToArray());
    }
}
```

#### **API Implementation with High Throughput**

```csharp
// Domain Model
public class Url
{
    public long Id { get; private set; }
    public string ShortCode { get; private set; }
    public string LongUrl { get; private set; }
    public long? UserId { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? ExpiresAt { get; private set; }
    public bool IsActive { get; private set; }

    public static Url Create(string longUrl, string shortCode, long? userId = null, DateTime? expiresAt = null)
    {
        if (string.IsNullOrEmpty(longUrl) || !Uri.IsWellFormedUriString(longUrl, UriKind.Absolute))
            throw new ArgumentException("Invalid URL");

        return new Url
        {
            LongUrl = longUrl,
            ShortCode = shortCode,
            UserId = userId,
            CreatedAt = DateTime.UtcNow,
            ExpiresAt = expiresAt,
            IsActive = true
        };
    }
}

// Repository with Caching
public class UrlRepository : IUrlRepository
{
    private readonly AppDbContext _context;
    private readonly IDistributedCache _cache;
    private readonly ILogger<UrlRepository> _logger;

    private const string CACHE_KEY_PREFIX = "url:";
    private const int CACHE_EXPIRATION_HOURS = 24;

    public async Task<string> CreateShortUrlAsync(CreateUrlRequest request)
    {
        // Generate short code
        var id = _idGenerator.NextId();
        var shortCode = _shortCodeGenerator.GenerateShortCode(id);

        var url = Url.Create(request.LongUrl, shortCode, request.UserId, request.ExpiresAt);

        await _context.Urls.AddAsync(url);
        await _context.SaveChangesAsync();

        // Pre-warm cache
        await CacheUrlAsync(shortCode, url.LongUrl);

        return shortCode;
    }

    public async Task<string?> GetLongUrlAsync(string shortCode)
    {
        // Check cache first
        var cacheKey = $"{CACHE_KEY_PREFIX}{shortCode}";
        var cachedUrl = await _cache.GetStringAsync(cacheKey);

        if (cachedUrl != null)
        {
            _logger.LogDebug("Cache hit for {ShortCode}", shortCode);
            return cachedUrl;
        }

        // Query database (read replica)
        var url = await _context.Urls
            .AsNoTracking()
            .Where(u => u.ShortCode == shortCode && u.IsActive)
            .Where(u => u.ExpiresAt == null || u.ExpiresAt > DateTime.UtcNow)
            .Select(u => u.LongUrl)
            .FirstOrDefaultAsync();

        if (url != null)
        {
            // Cache the result
            await CacheUrlAsync(shortCode, url);
        }

        return url;
    }

    private async Task CacheUrlAsync(string shortCode, string longUrl)
    {
        var cacheKey = $"{CACHE_KEY_PREFIX}{shortCode}";
        var options = new DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(CACHE_EXPIRATION_HOURS)
        };

        await _cache.SetStringAsync(cacheKey, longUrl, options);
    }
}

// API Controller
[ApiController]
[Route("api/[controller]")]
public class UrlController : ControllerBase
{
    private readonly IUrlRepository _repository;
    private readonly IUrlAnalyticsService _analytics;
    private readonly ILogger<UrlController> _logger;

    // POST /api/url/shorten
    [HttpPost("shorten")]
    [ProducesResponseType(typeof(ShortenUrlResponse), StatusCodes.Status201Created)]
    [ProducesResponseType(StatusCodes.Status400BadRequest)]
    public async Task<IActionResult> ShortenUrl([FromBody] CreateUrlRequest request)
    {
        try
        {
            var shortCode = await _repository.CreateShortUrlAsync(request);
            var shortUrl = $"{Request.Scheme}://{Request.Host}/{shortCode}";

            return CreatedAtAction(
                nameof(RedirectToLongUrl),
                new { shortCode },
                new ShortenUrlResponse { ShortUrl = shortUrl, ShortCode = shortCode }
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to shorten URL");
            return BadRequest(new { error = "Failed to create short URL" });
        }
    }

    // GET /{shortCode}
    [HttpGet("{shortCode}")]
    public async Task<IActionResult> RedirectToLongUrl(string shortCode)
    {
        var longUrl = await _repository.GetLongUrlAsync(shortCode);

        if (longUrl == null)
        {
            return NotFound();
        }

        // Track analytics asynchronously (fire and forget)
        _ = _analytics.TrackClickAsync(shortCode, HttpContext);

        return Redirect(longUrl);
    }
}

// Analytics Service (Write to Queue for Async Processing)
public class UrlAnalyticsService : IUrlAnalyticsService
{
    private readonly IMessageQueue _messageQueue;
    private readonly IHttpContextAccessor _httpContextAccessor;

    public async Task TrackClickAsync(string shortCode, HttpContext context)
    {
        var clickEvent = new UrlClickEvent
        {
            ShortCode = shortCode,
            ClickedAt = DateTime.UtcNow,
            IpAddress = context.Connection.RemoteIpAddress?.ToString(),
            UserAgent = context.Request.Headers.UserAgent.ToString(),
            Referer = context.Request.Headers.Referer.ToString()
        };

        // Publish to message queue (RabbitMQ/Kafka)
        await _messageQueue.PublishAsync("url.clicks", clickEvent);
    }
}

// Background Worker to Process Analytics
public class AnalyticsProcessor : BackgroundService
{
    private readonly IMessageQueue _messageQueue;
    private readonly IServiceProvider _serviceProvider;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await _messageQueue.SubscribeAsync<UrlClickEvent>("url.clicks", async clickEvent =>
        {
            using var scope = _serviceProvider.CreateScope();
            var context = scope.ServiceProvider.GetRequiredService<AppDbContext>();

            // Batch insert for performance
            var click = new UrlClick
            {
                ShortCode = clickEvent.ShortCode,
                ClickedAt = clickEvent.ClickedAt,
                IpAddress = clickEvent.IpAddress,
                UserAgent = clickEvent.UserAgent,
                Referer = clickEvent.Referer
            };

            await context.UrlClicks.AddAsync(click);
            await context.SaveChangesAsync();
        }, stoppingToken);
    }
}
```

#### **Scaling Strategy**

**Horizontal Scaling**:
```yaml
# Kubernetes Deployment
apiVersion: apps/v1
kind: Deployment
metadata:
  name: url-shortener-api
spec:
  replicas: 10
  strategy:
    type: RollingUpdate
  selector:
    matchLabels:
      app: url-shortener
  template:
    metadata:
      labels:
        app: url-shortener
    spec:
      containers:
      - name: api
        image: url-shortener:latest
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        env:
        - name: WORKER_ID
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
---
apiVersion: autoscaling/v2
kind: HorizontalPodAutoscaler
metadata:
  name: url-shortener-hpa
spec:
  scaleTargetRef:
    apiVersion: apps/v1
    kind: Deployment
    name: url-shortener-api
  minReplicas: 10
  maxReplicas: 100
  metrics:
  - type: Resource
    resource:
      name: cpu
      target:
        type: Utilization
        averageUtilization: 70
```

**Database Sharding Strategy**:
```csharp
public class ShardedUrlRepository : IUrlRepository
{
    private readonly IList<AppDbContext> _shards;

    private int GetShardIndex(string shortCode)
    {
        // Hash-based sharding
        var hash = shortCode.GetHashCode();
        return Math.Abs(hash) % _shards.Count;
    }

    public async Task<string?> GetLongUrlAsync(string shortCode)
    {
        var shardIndex = GetShardIndex(shortCode);
        var context = _shards[shardIndex];

        return await context.Urls
            .AsNoTracking()
            .Where(u => u.ShortCode == shortCode)
            .Select(u => u.LongUrl)
            .FirstOrDefaultAsync();
    }
}
```

#### **Performance Characteristics**

| Operation | Latency | Throughput |
|-----------|---------|------------|
| Create Short URL | 5-10ms | 10,000 writes/sec per instance |
| Redirect (Cache Hit) | 1-2ms | 100,000 reads/sec per instance |
| Redirect (Cache Miss) | 10-20ms | 10,000 reads/sec per instance |
| Analytics Write | <1ms (async) | 500,000 events/sec |

#### **✅ Best Practices**

1. **Use Base62 encoding with distributed ID generator** (Snowflake)
2. **Implement aggressive caching** with Redis for read-heavy workload
3. **Separate read and write paths** (CQRS pattern)
4. **Use message queues** for analytics to avoid blocking redirects
5. **Partition analytics table** by time for easy archival
6. **Pre-warm cache** on URL creation
7. **Use database read replicas** for redirect queries
8. **Implement rate limiting** per user/IP
9. **Monitor cache hit ratio** (target: >90%)
10. **Use connection pooling** and async I/O throughout

#### **❌ Common Mistakes**

1. **Synchronous analytics writes** - blocks redirect response
2. **No caching layer** - database becomes bottleneck
3. **Random collision checking** - wasted database queries
4. **No URL validation** - allows malicious URLs
5. **Storing full user agent strings** - wastes space
6. **No expiration mechanism** - infinite data growth
7. **Single database** - SPOF and scalability limit
8. **No rate limiting** - vulnerable to abuse

---

## Q442: Design a distributed cache system. How would you handle cache invalidation, consistency, and high availability?

### Complete Distributed Cache System Design

#### **Architecture Overview**

```
┌────────────────────────────────────────────────────────────┐
│                    Application Layer                       │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐       │
│  │  API Node 1 │  │  API Node 2 │  │  API Node N │       │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘       │
└─────────┼─────────────────┼─────────────────┼──────────────┘
          │                 │                 │
          ▼                 ▼                 ▼
┌─────────────────────────────────────────────────────────────┐
│            Distributed Cache Client Library                  │
│  - Consistent Hashing                                        │
│  - Connection Pooling                                        │
│  - Circuit Breaker                                           │
│  - Retry Logic                                               │
└────────┬─────────────┬──────────────┬─────────────┬─────────┘
         │             │              │             │
    ┌────▼───┐    ┌───▼────┐    ┌────▼───┐    ┌───▼────┐
    │ Redis  │    │ Redis  │    │ Redis  │    │ Redis  │
    │ Master │    │ Master │    │ Master │    │ Master │
    │ Shard 1│    │ Shard 2│    │ Shard 3│    │ Shard N│
    └────┬───┘    └───┬────┘    └────┬───┘    └───┬────┘
         │            │              │             │
    ┌────▼───┐    ┌──▼─────┐   ┌────▼───┐    ┌───▼────┐
    │ Redis  │    │ Redis  │   │ Redis  │    │ Redis  │
    │Replica │    │Replica │   │Replica │    │Replica │
    └────────┘    └────────┘   └────────┘    └────────┘

┌─────────────────────────────────────────────────────────────┐
│           Redis Sentinel (High Availability)                 │
│  - Master/Replica Monitoring                                 │
│  - Automatic Failover                                        │
│  - Configuration Provider                                    │
└─────────────────────────────────────────────────────────────┘
```

#### **Distributed Cache Client Implementation**

```csharp
// Consistent Hashing for Shard Distribution
public class ConsistentHashRing
{
    private const int VIRTUAL_NODES = 150; // Per physical node
    private readonly SortedDictionary<uint, string> _ring = new();
    private readonly List<string> _physicalNodes = new();

    public void AddNode(string nodeId)
    {
        _physicalNodes.Add(nodeId);

        for (int i = 0; i < VIRTUAL_NODES; i++)
        {
            var virtualKey = $"{nodeId}:{i}";
            var hash = ComputeHash(virtualKey);
            _ring[hash] = nodeId;
        }
    }

    public void RemoveNode(string nodeId)
    {
        _physicalNodes.Remove(nodeId);

        for (int i = 0; i < VIRTUAL_NODES; i++)
        {
            var virtualKey = $"{nodeId}:{i}";
            var hash = ComputeHash(virtualKey);
            _ring.Remove(hash);
        }
    }

    public string GetNode(string key)
    {
        if (_ring.Count == 0)
            throw new InvalidOperationException("No nodes available");

        var hash = ComputeHash(key);

        // Find first node >= hash
        foreach (var kvp in _ring)
        {
            if (kvp.Key >= hash)
                return kvp.Value;
        }

        // Wrap around to first node
        return _ring.First().Value;
    }

    private uint ComputeHash(string key)
    {
        using var md5 = MD5.Create();
        var hashBytes = md5.ComputeHash(Encoding.UTF8.GetBytes(key));
        return BitConverter.ToUInt32(hashBytes, 0);
    }
}

// Distributed Cache Client with Connection Pooling
public class DistributedCacheClient : IDistributedCacheClient
{
    private readonly ConsistentHashRing _hashRing;
    private readonly ConcurrentDictionary<string, ConnectionMultiplexer> _connections;
    private readonly CacheConfiguration _config;
    private readonly ILogger<DistributedCacheClient> _logger;

    public DistributedCacheClient(CacheConfiguration config, ILogger<DistributedCacheClient> logger)
    {
        _config = config;
        _logger = logger;
        _hashRing = new ConsistentHashRing();
        _connections = new ConcurrentDictionary<string, ConnectionMultiplexer>();

        InitializeNodes();
    }

    private void InitializeNodes()
    {
        foreach (var node in _config.Nodes)
        {
            _hashRing.AddNode(node.Id);

            var connection = ConnectionMultiplexer.Connect(new ConfigurationOptions
            {
                EndPoints = { node.Endpoint },
                ConnectTimeout = 5000,
                SyncTimeout = 5000,
                AbortOnConnectFail = false,
                ConnectRetry = 3,
                KeepAlive = 60
            });

            _connections[node.Id] = connection;
        }
    }

    public async Task<T?> GetAsync<T>(string key)
    {
        var nodeId = _hashRing.GetNode(key);
        var db = GetDatabase(nodeId);

        try
        {
            var value = await db.StringGetAsync(key);

            if (value.IsNullOrEmpty)
                return default;

            return JsonSerializer.Deserialize<T>(value!);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to get key {Key} from node {NodeId}", key, nodeId);
            throw;
        }
    }

    public async Task<bool> SetAsync<T>(string key, T value, TimeSpan? expiration = null)
    {
        var nodeId = _hashRing.GetNode(key);
        var db = GetDatabase(nodeId);

        try
        {
            var json = JsonSerializer.Serialize(value);
            return await db.StringSetAsync(key, json, expiration);
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to set key {Key} on node {NodeId}", key, nodeId);
            throw;
        }
    }

    public async Task<bool> DeleteAsync(string key)
    {
        var nodeId = _hashRing.GetNode(key);
        var db = GetDatabase(nodeId);

        return await db.KeyDeleteAsync(key);
    }

    private IDatabase GetDatabase(string nodeId)
    {
        if (!_connections.TryGetValue(nodeId, out var connection))
            throw new InvalidOperationException($"No connection for node {nodeId}");

        return connection.GetDatabase();
    }
}
```

#### **Cache Invalidation Strategies**

**1. Time-Based Expiration (TTL)**

```csharp
public class CacheService : ICacheService
{
    private readonly IDistributedCacheClient _cache;

    // Simple TTL
    public async Task SetUserAsync(User user)
    {
        var key = $"user:{user.Id}";
        await _cache.SetAsync(key, user, TimeSpan.FromMinutes(30));
    }

    // Sliding Expiration (Redis doesn't support natively, manual implementation)
    public async Task<User?> GetUserWithSlidingExpirationAsync(string userId)
    {
        var key = $"user:{userId}";
        var user = await _cache.GetAsync<User>(key);

        if (user != null)
        {
            // Refresh TTL on access
            await _cache.SetAsync(key, user, TimeSpan.FromMinutes(30));
        }

        return user;
    }
}
```

**2. Write-Through Cache**

```csharp
public class WriteThoughCacheRepository : IUserRepository
{
    private readonly IDistributedCacheClient _cache;
    private readonly AppDbContext _context;

    public async Task<User> UpdateUserAsync(User user)
    {
        // Update database first
        _context.Users.Update(user);
        await _context.SaveChangesAsync();

        // Update cache
        var key = $"user:{user.Id}";
        await _cache.SetAsync(key, user, TimeSpan.FromMinutes(30));

        return user;
    }

    public async Task<User?> GetUserAsync(string userId)
    {
        var key = $"user:{userId}";

        // Try cache first
        var user = await _cache.GetAsync<User>(key);
        if (user != null)
            return user;

        // Cache miss - load from database
        user = await _context.Users.FindAsync(userId);

        if (user != null)
        {
            // Populate cache
            await _cache.SetAsync(key, user, TimeSpan.FromMinutes(30));
        }

        return user;
    }
}
```

**3. Cache-Aside Pattern (Lazy Loading)**

```csharp
public class CacheAsideRepository : IProductRepository
{
    private readonly IDistributedCacheClient _cache;
    private readonly AppDbContext _context;

    public async Task<Product?> GetProductAsync(string productId)
    {
        var key = $"product:{productId}";

        // Check cache
        var product = await _cache.GetAsync<Product>(key);
        if (product != null)
            return product;

        // Load from database
        product = await _context.Products
            .Include(p => p.Category)
            .FirstOrDefaultAsync(p => p.Id == productId);

        if (product != null)
        {
            // Cache for future requests
            await _cache.SetAsync(key, product, TimeSpan.FromHours(1));
        }

        return product;
    }

    public async Task UpdateProductAsync(Product product)
    {
        // Update database
        _context.Products.Update(product);
        await _context.SaveChangesAsync();

        // Invalidate cache (lazy reload on next access)
        var key = $"product:{product.Id}";
        await _cache.DeleteAsync(key);
    }
}
```

**4. Event-Driven Invalidation**

```csharp
// Domain Event
public record ProductUpdatedEvent(string ProductId, DateTime UpdatedAt);

// Event Handler
public class ProductCacheInvalidationHandler : INotificationHandler<ProductUpdatedEvent>
{
    private readonly IDistributedCacheClient _cache;
    private readonly IMessageBus _messageBus;

    public async Task Handle(ProductUpdatedEvent notification, CancellationToken cancellationToken)
    {
        // Invalidate cache locally
        var key = $"product:{notification.ProductId}";
        await _cache.DeleteAsync(key);

        // Publish invalidation message to all instances
        await _messageBus.PublishAsync(new CacheInvalidationMessage
        {
            Key = key,
            Timestamp = notification.UpdatedAt
        });
    }
}

// Cache Invalidation Listener (in each API instance)
public class CacheInvalidationListener : BackgroundService
{
    private readonly IMessageBus _messageBus;
    private readonly IDistributedCacheClient _cache;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await _messageBus.SubscribeAsync<CacheInvalidationMessage>(
            "cache.invalidation",
            async message =>
            {
                await _cache.DeleteAsync(message.Key);
            },
            stoppingToken
        );
    }
}
```

**5. Pub/Sub Invalidation Pattern (Redis)**

```csharp
public class RedisPubSubCacheInvalidation
{
    private readonly ConnectionMultiplexer _redis;
    private readonly ISubscriber _subscriber;

    public RedisPubSubCacheInvalidation(ConnectionMultiplexer redis)
    {
        _redis = redis;
        _subscriber = _redis.GetSubscriber();

        // Subscribe to invalidation channel
        _subscriber.Subscribe("cache:invalidate", async (channel, message) =>
        {
            await HandleInvalidationAsync(message);
        });
    }

    public async Task InvalidateAsync(string key)
    {
        // Delete from cache
        var db = _redis.GetDatabase();
        await db.KeyDeleteAsync(key);

        // Publish invalidation message
        await _subscriber.PublishAsync("cache:invalidate", key);
    }

    private async Task HandleInvalidationAsync(string key)
    {
        var db = _redis.GetDatabase();
        await db.KeyDeleteAsync(key);
    }
}
```

#### **Consistency Patterns**

**1. Strong Consistency (Distributed Lock)**

```csharp
public class StronglyConsistentCache
{
    private readonly IDistributedCacheClient _cache;
    private readonly IDistributedLockManager _lockManager;

    public async Task<T> GetOrComputeAsync<T>(
        string key,
        Func<Task<T>> factory,
        TimeSpan expiration)
    {
        // Try to get from cache
        var value = await _cache.GetAsync<T>(key);
        if (value != null)
            return value;

        // Acquire distributed lock to prevent cache stampede
        var lockKey = $"lock:{key}";
        await using var lockHandle = await _lockManager.AcquireLockAsync(lockKey, TimeSpan.FromSeconds(30));

        if (lockHandle == null)
        {
            // Failed to acquire lock, wait and retry
            await Task.Delay(100);
            return await GetOrComputeAsync(key, factory, expiration);
        }

        // Double-check cache (another thread might have populated it)
        value = await _cache.GetAsync<T>(key);
        if (value != null)
            return value;

        // Compute value
        value = await factory();

        // Store in cache
        await _cache.SetAsync(key, value, expiration);

        return value;
    }
}

// Distributed Lock using Redis
public class RedisDistributedLock : IDistributedLockManager
{
    private readonly IDatabase _redis;

    public async Task<IAsyncDisposable?> AcquireLockAsync(string key, TimeSpan timeout)
    {
        var token = Guid.NewGuid().ToString();
        var expiry = timeout;

        // Try to acquire lock with SET NX EX
        var acquired = await _redis.StringSetAsync(
            key,
            token,
            expiry,
            When.NotExists
        );

        if (!acquired)
            return null;

        return new RedisLock(_redis, key, token);
    }

    private class RedisLock : IAsyncDisposable
    {
        private readonly IDatabase _redis;
        private readonly string _key;
        private readonly string _token;

        public RedisLock(IDatabase redis, string key, string token)
        {
            _redis = redis;
            _key = key;
            _token = token;
        }

        public async ValueTask DisposeAsync()
        {
            // Release lock only if we still own it (using Lua script)
            const string script = @"
                if redis.call('get', KEYS[1]) == ARGV[1] then
                    return redis.call('del', KEYS[1])
                else
                    return 0
                end
            ";

            await _redis.ScriptEvaluateAsync(script, new RedisKey[] { _key }, new RedisValue[] { _token });
        }
    }
}
```

**2. Eventual Consistency (Async Replication)**

```csharp
public class EventuallyConsistentCache
{
    private readonly IDistributedCacheClient _primaryCache;
    private readonly IDistributedCacheClient _secondaryCache;
    private readonly IMessageBus _messageBus;

    public async Task SetAsync<T>(string key, T value, TimeSpan expiration)
    {
        // Write to primary cache immediately
        await _primaryCache.SetAsync(key, value, expiration);

        // Async replication to secondary
        _ = Task.Run(async () =>
        {
            try
            {
                await _secondaryCache.SetAsync(key, value, expiration);
            }
            catch (Exception ex)
            {
                // Log but don't fail
                // Could also publish to dead-letter queue for retry
            }
        });
    }

    public async Task<T?> GetAsync<T>(string key)
    {
        // Try primary first
        try
        {
            var value = await _primaryCache.GetAsync<T>(key);
            if (value != null)
                return value;
        }
        catch
        {
            // Fallback to secondary
        }

        // Fallback to secondary cache
        return await _secondaryCache.GetAsync<T>(key);
    }
}
```

#### **High Availability Setup**

**Redis Sentinel Configuration**:

```csharp
public class RedisSentinelCacheClient
{
    private ConnectionMultiplexer _connection;
    private readonly string _serviceName;

    public RedisSentinelCacheClient(string serviceName, params string[] sentinelEndpoints)
    {
        _serviceName = serviceName;

        var options = new ConfigurationOptions
        {
            CommandMap = CommandMap.Sentinel,
            ServiceName = serviceName,
            AbortOnConnectFail = false,
            TieBreaker = "",
            AllowAdmin = true
        };

        foreach (var endpoint in sentinelEndpoints)
        {
            options.EndPoints.Add(endpoint);
        }

        _connection = ConnectionMultiplexer.Connect(options);

        // Subscribe to failover events
        _connection.ConnectionRestored += OnConnectionRestored;
        _connection.ConnectionFailed += OnConnectionFailed;
    }

    private void OnConnectionRestored(object? sender, ConnectionFailedEventArgs e)
    {
        // Log restoration
        // Potentially refresh configuration
    }

    private void OnConnectionFailed(object? sender, ConnectionFailedEventArgs e)
    {
        // Log failure
        // Sentinel will handle automatic failover
    }

    public IDatabase GetDatabase() => _connection.GetDatabase();
}
```

**Redis Cluster Configuration** (Alternative to Sentinel):

```csharp
public class RedisClusterClient
{
    private readonly ConnectionMultiplexer _connection;

    public RedisClusterClient(params string[] clusterEndpoints)
    {
        var options = new ConfigurationOptions
        {
            AbortOnConnectFail = false,
            ConnectRetry = 3,
            ConnectTimeout = 5000
        };

        foreach (var endpoint in clusterEndpoints)
        {
            options.EndPoints.Add(endpoint);
        }

        _connection = ConnectionMultiplexer.Connect(options);
    }

    public IDatabase GetDatabase() => _connection.GetDatabase();
}
```

#### **Performance Optimizations**

**1. Pipeline Batching**

```csharp
public class BatchedCacheClient
{
    private readonly IDatabase _redis;

    public async Task<Dictionary<string, T?>> GetManyAsync<T>(IEnumerable<string> keys)
    {
        var batch = _redis.CreateBatch();
        var tasks = new Dictionary<string, Task<RedisValue>>();

        foreach (var key in keys)
        {
            tasks[key] = batch.StringGetAsync(key);
        }

        batch.Execute();

        var result = new Dictionary<string, T?>();
        foreach (var (key, task) in tasks)
        {
            var value = await task;
            result[key] = value.IsNullOrEmpty
                ? default
                : JsonSerializer.Deserialize<T>(value!);
        }

        return result;
    }
}
```

**2. Connection Multiplexing**

```csharp
// ✅ Correct - Single connection shared across application
public class CacheClientFactory
{
    private static readonly Lazy<ConnectionMultiplexer> _lazyConnection = new(() =>
    {
        return ConnectionMultiplexer.Connect("localhost:6379");
    });

    public static IDatabase GetDatabase() => _lazyConnection.Value.GetDatabase();
}
```

#### **Monitoring and Observability**

```csharp
public class ObservableCacheClient : IDistributedCacheClient
{
    private readonly IDistributedCacheClient _inner;
    private readonly IMetrics _metrics;

    public async Task<T?> GetAsync<T>(string key)
    {
        var sw = Stopwatch.StartNew();
        try
        {
            var result = await _inner.GetAsync<T>(key);

            _metrics.RecordCacheOperation("get", result != null ? "hit" : "miss", sw.Elapsed);

            return result;
        }
        catch (Exception ex)
        {
            _metrics.RecordCacheOperation("get", "error", sw.Elapsed);
            throw;
        }
    }
}
```

#### **✅ Best Practices**

1. **Use consistent hashing** for even data distribution
2. **Implement circuit breakers** for fault tolerance
3. **Monitor cache hit ratio** (target: >80%)
4. **Use connection pooling** and multiplexing
5. **Set appropriate TTLs** based on data volatility
6. **Implement cache warming** for critical data
7. **Use Redis Sentinel or Cluster** for HA
8. **Batch operations** when possible (MGET/MSET)
9. **Implement distributed locks** to prevent cache stampede
10. **Use pub/sub for cache invalidation** across instances

#### **❌ Common Mistakes**

1. **Creating new connections per request** - connection overhead
2. **No TTL on cached items** - memory leaks
3. **Synchronous cache operations** - blocks threads
4. **No fallback mechanism** - single point of failure
5. **Storing large objects** - network overhead
6. **No cache warming** - cold start issues
7. **Ignoring cache stampede** - database overload on cache miss
8. **No monitoring** - blind to performance issues

---

## Q443: Design a rate limiting system for an API. Discuss different algorithms (token bucket, leaky bucket, sliding window) and their implementation.

### Rate Limiting Algorithms and Implementation

#### **1. Token Bucket Algorithm**

**Concept**: Tokens are added to a bucket at a fixed rate. Each request consumes a token. If no tokens available, request is rejected.

```csharp
public class TokenBucketRateLimiter : IRateLimiter
{
    private readonly int _bucketCapacity;
    private readonly int _tokensPerInterval;
    private readonly TimeSpan _interval;
    private readonly ConcurrentDictionary<string, TokenBucket> _buckets = new();

    public TokenBucketRateLimiter(int bucketCapacity, int tokensPerInterval, TimeSpan interval)
    {
        _bucketCapacity = bucketCapacity;
        _tokensPerInterval = tokensPerInterval;
        _interval = interval;
    }

    public async Task<RateLimitResult> CheckRateLimitAsync(string clientId, int cost = 1)
    {
        var bucket = _buckets.GetOrAdd(clientId, _ => new TokenBucket(_bucketCapacity, _tokensPerInterval, _interval));

        return bucket.TryConsume(cost);
    }

    private class TokenBucket
    {
        private readonly int _capacity;
        private readonly int _tokensPerInterval;
        private readonly TimeSpan _interval;
        private double _tokens;
        private DateTime _lastRefill;
        private readonly object _lock = new();

        public TokenBucket(int capacity, int tokensPerInterval, TimeSpan interval)
        {
            _capacity = capacity;
            _tokensPerInterval = tokensPerInterval;
            _interval = interval;
            _tokens = capacity;
            _lastRefill = DateTime.UtcNow;
        }

        public RateLimitResult TryConsume(int tokens)
        {
            lock (_lock)
            {
                Refill();

                if (_tokens >= tokens)
                {
                    _tokens -= tokens;
                    return new RateLimitResult
                    {
                        IsAllowed = true,
                        RemainingTokens = (int)_tokens,
                        RetryAfter = null
                    };
                }

                var timeToRefill = _interval - (DateTime.UtcNow - _lastRefill);
                return new RateLimitResult
                {
                    IsAllowed = false,
                    RemainingTokens = 0,
                    RetryAfter = timeToRefill > TimeSpan.Zero ? timeToRefill : _interval
                };
            }
        }

        private void Refill()
        {
            var now = DateTime.UtcNow;
            var elapsed = now - _lastRefill;

            if (elapsed >= _interval)
            {
                var intervalsElapsed = elapsed.TotalMilliseconds / _interval.TotalMilliseconds;
                var tokensToAdd = intervalsElapsed * _tokensPerInterval;

                _tokens = Math.Min(_capacity, _tokens + tokensToAdd);
                _lastRefill = now;
            }
        }
    }
}

// Usage Example
var rateLimiter = new TokenBucketRateLimiter(
    bucketCapacity: 100,        // Max 100 tokens
    tokensPerInterval: 10,      // Refill 10 tokens
    interval: TimeSpan.FromSeconds(1)  // Every 1 second
);

var result = await rateLimiter.CheckRateLimitAsync("user123");
// Allows burst of 100 requests, then sustains 10 req/sec
```

**Redis-Based Token Bucket**:

```csharp
public class RedisTokenBucketRateLimiter : IRateLimiter
{
    private readonly IDatabase _redis;
    private readonly int _capacity;
    private readonly int _tokensPerInterval;
    private readonly TimeSpan _interval;

    public async Task<RateLimitResult> CheckRateLimitAsync(string clientId, int cost = 1)
    {
        var key = $"ratelimit:token:{clientId}";
        var now = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();

        // Lua script for atomic token bucket operation
        const string script = @"
            local key = KEYS[1]
            local capacity = tonumber(ARGV[1])
            local tokens_per_interval = tonumber(ARGV[2])
            local interval_ms = tonumber(ARGV[3])
            local cost = tonumber(ARGV[4])
            local now = tonumber(ARGV[5])

            local bucket = redis.call('HMGET', key, 'tokens', 'last_refill')
            local tokens = tonumber(bucket[1]) or capacity
            local last_refill = tonumber(bucket[2]) or now

            -- Calculate refill
            local elapsed = now - last_refill
            if elapsed >= interval_ms then
                local intervals = math.floor(elapsed / interval_ms)
                tokens = math.min(capacity, tokens + (intervals * tokens_per_interval))
                last_refill = now
            end

            -- Try to consume
            if tokens >= cost then
                tokens = tokens - cost
                redis.call('HMSET', key, 'tokens', tokens, 'last_refill', last_refill)
                redis.call('PEXPIRE', key, interval_ms * 2)
                return {1, tokens, 0}
            else
                local retry_after = interval_ms - (now - last_refill)
                return {0, 0, retry_after}
            end
        ";

        var result = (RedisValue[])await _redis.ScriptEvaluateAsync(
            script,
            new RedisKey[] { key },
            new RedisValue[]
            {
                _capacity,
                _tokensPerInterval,
                (long)_interval.TotalMilliseconds,
                cost,
                now
            }
        );

        return new RateLimitResult
        {
            IsAllowed = (int)result[0] == 1,
            RemainingTokens = (int)result[1],
            RetryAfter = result[2] > 0 ? TimeSpan.FromMilliseconds((long)result[2]) : null
        };
    }
}
```

#### **2. Leaky Bucket Algorithm**

**Concept**: Requests are processed at a constant rate, like water dripping from a leaky bucket.

```csharp
public class LeakyBucketRateLimiter : IRateLimiter
{
    private readonly int _bucketCapacity;
    private readonly int _leakRate; // Requests per second
    private readonly ConcurrentDictionary<string, LeakyBucket> _buckets = new();

    public LeakyBucketRateLimiter(int bucketCapacity, int leakRate)
    {
        _bucketCapacity = bucketCapacity;
        _leakRate = leakRate;
    }

    public async Task<RateLimitResult> CheckRateLimitAsync(string clientId, int cost = 1)
    {
        var bucket = _buckets.GetOrAdd(clientId, _ => new LeakyBucket(_bucketCapacity, _leakRate));

        return bucket.TryAdd(cost);
    }

    private class LeakyBucket
    {
        private readonly int _capacity;
        private readonly double _leakRatePerMs;
        private double _water; // Current water level
        private DateTime _lastLeak;
        private readonly object _lock = new();

        public LeakyBucket(int capacity, int leakRatePerSecond)
        {
            _capacity = capacity;
            _leakRatePerMs = leakRatePerSecond / 1000.0;
            _water = 0;
            _lastLeak = DateTime.UtcNow;
        }

        public RateLimitResult TryAdd(int amount)
        {
            lock (_lock)
            {
                Leak();

                if (_water + amount <= _capacity)
                {
                    _water += amount;
                    return new RateLimitResult
                    {
                        IsAllowed = true,
                        RemainingTokens = (int)(_capacity - _water),
                        RetryAfter = null
                    };
                }

                // Calculate when bucket will have space
                var overflow = (_water + amount) - _capacity;
                var retryAfterMs = overflow / _leakRatePerMs;

                return new RateLimitResult
                {
                    IsAllowed = false,
                    RemainingTokens = 0,
                    RetryAfter = TimeSpan.FromMilliseconds(retryAfterMs)
                };
            }
        }

        private void Leak()
        {
            var now = DateTime.UtcNow;
            var elapsed = (now - _lastLeak).TotalMilliseconds;

            var leaked = elapsed * _leakRatePerMs;
            _water = Math.Max(0, _water - leaked);
            _lastLeak = now;
        }
    }
}

// Usage
var rateLimiter = new LeakyBucketRateLimiter(
    bucketCapacity: 100,    // Max 100 pending requests
    leakRate: 10            // Process 10 req/sec
);
// Smooths out traffic bursts
```

#### **3. Sliding Window Log Algorithm**

**Concept**: Keeps a log of timestamps for each request. Counts requests in the last window.

```csharp
public class SlidingWindowLogRateLimiter : IRateLimiter
{
    private readonly IDatabase _redis;
    private readonly int _maxRequests;
    private readonly TimeSpan _window;

    public SlidingWindowLogRateLimiter(IDatabase redis, int maxRequests, TimeSpan window)
    {
        _redis = redis;
        _maxRequests = maxRequests;
        _window = window;
    }

    public async Task<RateLimitResult> CheckRateLimitAsync(string clientId, int cost = 1)
    {
        var key = $"ratelimit:sliding:{clientId}";
        var now = DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
        var windowStart = now - (long)_window.TotalMilliseconds;

        // Lua script for atomic sliding window operation
        const string script = @"
            local key = KEYS[1]
            local now = tonumber(ARGV[1])
            local window_start = tonumber(ARGV[2])
            local max_requests = tonumber(ARGV[3])
            local window_ms = tonumber(ARGV[4])

            -- Remove old entries
            redis.call('ZREMRANGEBYSCORE', key, 0, window_start)

            -- Count current requests
            local current_requests = redis.call('ZCARD', key)

            if current_requests < max_requests then
                -- Add new request
                redis.call('ZADD', key, now, now)
                redis.call('PEXPIRE', key, window_ms)
                return {1, max_requests - current_requests - 1, 0}
            else
                -- Get oldest request timestamp
                local oldest = redis.call('ZRANGE', key, 0, 0, 'WITHSCORES')
                local retry_after = tonumber(oldest[2]) + window_ms - now
                return {0, 0, retry_after}
            end
        ";

        var result = (RedisValue[])await _redis.ScriptEvaluateAsync(
            script,
            new RedisKey[] { key },
            new RedisValue[] { now, windowStart, _maxRequests, (long)_window.TotalMilliseconds }
        );

        return new RateLimitResult
        {
            IsAllowed = (int)result[0] == 1,
            RemainingTokens = (int)result[1],
            RetryAfter = result[2] > 0 ? TimeSpan.FromMilliseconds((long)result[2]) : null
        };
    }
}

// Usage
var rateLimiter = new SlidingWindowLogRateLimiter(
    redis,
    maxRequests: 100,                  // Max 100 requests
    window: TimeSpan.FromMinutes(1)    // Per 1 minute
);
// Most accurate but memory intensive (stores all timestamps)
```

#### **4. Sliding Window Counter Algorithm**

**Concept**: Hybrid approach combining fixed window counters with weighted sliding window.

```csharp
public class SlidingWindowCounterRateLimiter : IRateLimiter
{
    private readonly IDatabase _redis;
    private readonly int _maxRequests;
    private readonly TimeSpan _window;

    public async Task<RateLimitResult> CheckRateLimitAsync(string clientId, int cost = 1)
    {
        var now = DateTime.UtcNow;
        var currentWindow = GetWindowKey(now);
        var previousWindow = GetWindowKey(now - _window);

        var currentKey = $"ratelimit:swc:{clientId}:{currentWindow}";
        var previousKey = $"ratelimit:swc:{clientId}:{previousWindow}";

        // Get counts from both windows
        var transaction = _redis.CreateTransaction();
        var currentCountTask = transaction.StringGetAsync(currentKey);
        var previousCountTask = transaction.StringGetAsync(previousKey);

        await transaction.ExecuteAsync();

        var currentCount = (long)(await currentCountTask).GetValueOrDefault();
        var previousCount = (long)(await previousCountTask).GetValueOrDefault();

        // Calculate weighted count
        var windowProgress = (now.Ticks % _window.Ticks) / (double)_window.Ticks;
        var weightedCount = (previousCount * (1 - windowProgress)) + currentCount;

        if (weightedCount < _maxRequests)
        {
            // Increment current window counter
            await _redis.StringIncrementAsync(currentKey);
            await _redis.KeyExpireAsync(currentKey, _window * 2);

            return new RateLimitResult
            {
                IsAllowed = true,
                RemainingTokens = (int)(_maxRequests - weightedCount - 1),
                RetryAfter = null
            };
        }

        return new RateLimitResult
        {
            IsAllowed = false,
            RemainingTokens = 0,
            RetryAfter = TimeSpan.FromTicks((long)((1 - windowProgress) * _window.Ticks))
        };
    }

    private long GetWindowKey(DateTime time)
    {
        return time.Ticks / _window.Ticks;
    }
}

// Usage
var rateLimiter = new SlidingWindowCounterRateLimiter(
    redis,
    maxRequests: 100,
    window: TimeSpan.FromMinutes(1)
);
// Good balance between accuracy and memory efficiency
```

#### **Rate Limiting Middleware**

```csharp
public class RateLimitingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly IRateLimiterFactory _rateLimiterFactory;
    private readonly ILogger<RateLimitingMiddleware> _logger;

    public RateLimitingMiddleware(
        RequestDelegate next,
        IRateLimiterFactory rateLimiterFactory,
        ILogger<RateLimitingMiddleware> logger)
    {
        _next = next;
        _rateLimiterFactory = rateLimiterFactory;
        _logger = logger;
    }

    public async Task InvokeAsync(HttpContext context)
    {
        var endpoint = context.GetEndpoint();
        var rateLimitPolicy = endpoint?.Metadata.GetMetadata<RateLimitAttribute>();

        if (rateLimitPolicy == null)
        {
            await _next(context);
            return;
        }

        var clientId = GetClientId(context);
        var rateLimiter = _rateLimiterFactory.GetRateLimiter(rateLimitPolicy.Policy);

        var result = await rateLimiter.CheckRateLimitAsync(clientId);

        // Add rate limit headers
        context.Response.Headers.Add("X-RateLimit-Limit", rateLimitPolicy.MaxRequests.ToString());
        context.Response.Headers.Add("X-RateLimit-Remaining", result.RemainingTokens.ToString());

        if (!result.IsAllowed)
        {
            context.Response.StatusCode = StatusCodes.Status429TooManyRequests;

            if (result.RetryAfter.HasValue)
            {
                context.Response.Headers.Add("Retry-After", ((int)result.RetryAfter.Value.TotalSeconds).ToString());
            }

            await context.Response.WriteAsJsonAsync(new
            {
                error = "Rate limit exceeded",
                message = $"Too many requests. Please try again later.",
                retryAfter = result.RetryAfter
            });

            return;
        }

        await _next(context);
    }

    private string GetClientId(HttpContext context)
    {
        // Try to get user ID from authentication
        var userId = context.User?.FindFirst(ClaimTypes.NameIdentifier)?.Value;
        if (!string.IsNullOrEmpty(userId))
            return $"user:{userId}";

        // Fall back to IP address
        var ipAddress = context.Connection.RemoteIpAddress?.ToString();
        return $"ip:{ipAddress}";
    }
}

// Attribute for declarative rate limiting
[AttributeUsage(AttributeTargets.Class | AttributeTargets.Method)]
public class RateLimitAttribute : Attribute
{
    public string Policy { get; set; }
    public int MaxRequests { get; set; }
    public TimeSpan Window { get; set; }

    public RateLimitAttribute(string policy, int maxRequests, int windowSeconds)
    {
        Policy = policy;
        MaxRequests = maxRequests;
        Window = TimeSpan.FromSeconds(windowSeconds);
    }
}

// Controller Usage
[ApiController]
[Route("api/[controller]")]
public class OrdersController : ControllerBase
{
    [HttpPost]
    [RateLimit("create-order", maxRequests: 10, windowSeconds: 60)]
    public async Task<IActionResult> CreateOrder([FromBody] CreateOrderRequest request)
    {
        // Max 10 orders per minute per user
        return Ok();
    }

    [HttpGet]
    [RateLimit("list-orders", maxRequests: 100, windowSeconds: 60)]
    public async Task<IActionResult> ListOrders()
    {
        // Max 100 list requests per minute
        return Ok();
    }
}
```

#### **Distributed Rate Limiting with Redis**

```csharp
public class DistributedRateLimiter
{
    private readonly IConnectionMultiplexer _redis;
    private readonly RateLimitConfiguration _config;

    public async Task<RateLimitResult> CheckAsync(string clientId, string resource)
    {
        var db = _redis.GetDatabase();
        var policy = _config.GetPolicy(resource);

        switch (policy.Algorithm)
        {
            case RateLimitAlgorithm.TokenBucket:
                return await CheckTokenBucketAsync(db, clientId, policy);

            case RateLimitAlgorithm.SlidingWindow:
                return await CheckSlidingWindowAsync(db, clientId, policy);

            default:
                throw new NotSupportedException($"Algorithm {policy.Algorithm} not supported");
        }
    }

    private async Task<RateLimitResult> CheckTokenBucketAsync(
        IDatabase db,
        string clientId,
        RateLimitPolicy policy)
    {
        // Implementation as shown earlier
        throw new NotImplementedException();
    }
}
```

#### **Algorithm Comparison**

| Algorithm | Accuracy | Memory Usage | Burst Handling | Complexity |
|-----------|----------|--------------|----------------|------------|
| **Token Bucket** | High | Low (2 values) | Excellent (allows burst) | Low |
| **Leaky Bucket** | High | Low (2 values) | Poor (smooth rate) | Low |
| **Sliding Window Log** | Highest | High (all timestamps) | Excellent | Medium |
| **Sliding Window Counter** | Good | Medium (2 counters) | Good | Low |
| **Fixed Window** | Low (boundary issues) | Lowest (1 counter) | Poor | Lowest |

#### **Performance Characteristics**

| Operation | Latency (Redis) | Throughput |
|-----------|-----------------|------------|
| Token Bucket check | 1-2ms | 50,000 ops/sec |
| Sliding Window Log | 2-5ms | 20,000 ops/sec |
| Sliding Window Counter | 1-3ms | 40,000 ops/sec |

#### **✅ Best Practices**

1. **Use Token Bucket for API rate limiting** - allows bursts, fair
2. **Use Sliding Window for strict limits** - most accurate
3. **Implement in middleware/gateway** - centralized enforcement
4. **Return proper HTTP 429 status** with Retry-After header
5. **Use Redis for distributed systems** - consistent across instances
6. **Implement tiered limits** (per user, per IP, global)
7. **Monitor rate limit hits** - adjust limits based on data
8. **Use Lua scripts in Redis** - atomic operations
9. **Add circuit breakers** - fallback if Redis unavailable
10. **Provide clear error messages** - help users understand limits

#### **❌ Common Mistakes**

1. **In-memory rate limiting in distributed systems** - inconsistent across instances
2. **No Retry-After header** - poor client experience
3. **Fixed window algorithm** - allows double traffic at boundaries
4. **No monitoring** - can't tune limits appropriately
5. **Synchronous Redis calls** - blocks request thread
6. **Same limit for all endpoints** - some need different limits
7. **No fallback** - service down if Redis unavailable
8. **Counting before validation** - wasted quota on invalid requests

---

## Q444: How would you design a notification system that supports multiple channels (email, SMS, push notifications)? Discuss prioritization, retry logic, and delivery guarantees.

### Comprehensive Multi-Channel Notification System

#### **System Architecture**

```
┌──────────────────────────────────────────────────────────┐
│              Application Layer                            │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐                  │
│  │  Order  │  │  User   │  │ Payment │                  │
│  │ Service │  │ Service │  │ Service │                  │
│  └────┬────┘  └────┬────┘  └────┬────┘                  │
└───────┼────────────┼────────────┼───────────────────────┘
        │            │            │
        └────────────┼────────────┘
                     ▼
        ┌────────────────────────┐
        │  Notification Service  │
        │  - Validation          │
        │  - Template Resolution │
        │  - Channel Selection   │
        └───────────┬────────────┘
                    │
                    ▼
        ┌───────────────────────────┐
        │   Message Queue           │
        │   (RabbitMQ/Kafka)        │
        │   - Priority Queues       │
        │   - Dead Letter Queue     │
        └───┬───────┬───────┬───────┘
            │       │       │
    ┌───────▼──┐ ┌──▼──────▼──┐ ┌──▼──────┐
    │  Email   │ │  SMS Worker │ │  Push   │
    │  Worker  │ │   Worker    │ │  Worker │
    └────┬─────┘ └──────┬──────┘ └────┬────┘
         │              │              │
    ┌────▼─────┐   ┌───▼────┐    ┌────▼─────┐
    │ SendGrid │   │ Twilio │    │ Firebase │
    │   SMTP   │   │  SMS   │    │   FCM    │
    └──────────┘   └────────┘    └──────────┘

┌──────────────────────────────────────────────────────────┐
│          Notification Status Database                     │
│  - Delivery Status                                        │
│  - Retry Attempts                                         │
│  - Audit Log                                              │
└──────────────────────────────────────────────────────────┘
```

#### **Domain Models**

```csharp
// Notification Entity
public class Notification
{
    public Guid Id { get; private set; }
    public Guid UserId { get; private set; }
    public NotificationType Type { get; private set; }
    public NotificationPriority Priority { get; private set; }
    public List<NotificationChannel> Channels { get; private set; }
    public Dictionary<string, object> TemplateData { get; private set; }
    public NotificationStatus Status { get; private set; }
    public DateTime CreatedAt { get; private set; }
    public DateTime? ScheduledFor { get; private set; }
    public int RetryCount { get; private set; }
    public int MaxRetries { get; private set; }

    public static Notification Create(
        Guid userId,
        NotificationType type,
        NotificationPriority priority,
        List<NotificationChannel> channels,
        Dictionary<string, object> templateData,
        DateTime? scheduledFor = null)
    {
        return new Notification
        {
            Id = Guid.NewGuid(),
            UserId = userId,
            Type = type,
            Priority = priority,
            Channels = channels,
            TemplateData = templateData,
            Status = NotificationStatus.Pending,
            CreatedAt = DateTime.UtcNow,
            ScheduledFor = scheduledFor,
            RetryCount = 0,
            MaxRetries = GetMaxRetriesByPriority(priority)
        };
    }

    private static int GetMaxRetriesByPriority(NotificationPriority priority)
    {
        return priority switch
        {
            NotificationPriority.Critical => 5,
            NotificationPriority.High => 3,
            NotificationPriority.Normal => 2,
            NotificationPriority.Low => 1,
            _ => 0
        };
    }

    public void MarkAsSent(NotificationChannel channel)
    {
        Status = NotificationStatus.Sent;
    }

    public void MarkAsFailed(string reason)
    {
        RetryCount++;
        Status = RetryCount >= MaxRetries
            ? NotificationStatus.Failed
            : NotificationStatus.PendingRetry;
    }
}

public enum NotificationType
{
    OrderConfirmation,
    PaymentReceipt,
    ShippingUpdate,
    PasswordReset,
    SecurityAlert,
    MarketingCampaign
}

public enum NotificationPriority
{
    Low = 0,
    Normal = 1,
    High = 2,
    Critical = 3
}

public enum NotificationChannel
{
    Email,
    SMS,
    Push,
    WebSocket
}

public enum NotificationStatus
{
    Pending,
    Processing,
    Sent,
    PendingRetry,
    Failed
}

// Channel-Specific Message
public record EmailMessage(
    string To,
    string Subject,
    string HtmlBody,
    string? PlainTextBody,
    List<EmailAttachment>? Attachments);

public record SmsMessage(
    string PhoneNumber,
    string Body);

public record PushMessage(
    string DeviceToken,
    string Title,
    string Body,
    Dictionary<string, object>? Data,
    string? ImageUrl);
```

#### **Notification Service**

```csharp
public class NotificationService : INotificationService
{
    private readonly IMessageQueue _messageQueue;
    private readonly INotificationRepository _repository;
    private readonly ITemplateEngine _templateEngine;
    private readonly IUserPreferencesService _userPreferences;
    private readonly ILogger<NotificationService> _logger;

    public async Task<Guid> SendNotificationAsync(SendNotificationRequest request)
    {
        // Get user preferences
        var preferences = await _userPreferences.GetPreferencesAsync(request.UserId);

        // Determine channels based on notification type and user preferences
        var channels = DetermineChannels(request.Type, preferences, request.Priority);

        if (!channels.Any())
        {
            _logger.LogWarning("No channels available for user {UserId}", request.UserId);
            return Guid.Empty;
        }

        // Create notification
        var notification = Notification.Create(
            request.UserId,
            request.Type,
            request.Priority,
            channels,
            request.TemplateData,
            request.ScheduledFor
        );

        await _repository.AddAsync(notification);

        // Enqueue to appropriate priority queue
        await EnqueueNotificationAsync(notification);

        return notification.Id;
    }

    private List<NotificationChannel> DetermineChannels(
        NotificationType type,
        UserNotificationPreferences preferences,
        NotificationPriority priority)
    {
        var channels = new List<NotificationChannel>();

        // Critical notifications override preferences
        if (priority == NotificationPriority.Critical)
        {
            channels.Add(NotificationChannel.Email);
            channels.Add(NotificationChannel.SMS);
            channels.Add(NotificationChannel.Push);
            return channels;
        }

        // Check user preferences for each channel
        if (preferences.EmailEnabled && preferences.EmailTypes.Contains(type))
            channels.Add(NotificationChannel.Email);

        if (preferences.SmsEnabled && preferences.SmsTypes.Contains(type))
            channels.Add(NotificationChannel.SMS);

        if (preferences.PushEnabled && preferences.PushTypes.Contains(type))
            channels.Add(NotificationChannel.Push);

        return channels;
    }

    private async Task EnqueueNotificationAsync(Notification notification)
    {
        var queueName = GetQueueName(notification.Priority);
        var message = new NotificationMessage
        {
            NotificationId = notification.Id,
            UserId = notification.UserId,
            Type = notification.Type,
            Channels = notification.Channels,
            TemplateData = notification.TemplateData,
            Priority = notification.Priority
        };

        await _messageQueue.PublishAsync(queueName, message, new PublishOptions
        {
            Priority = (byte)notification.Priority,
            DeliveryMode = DeliveryMode.Persistent,
            Expiration = GetMessageExpiration(notification.Priority)
        });
    }

    private string GetQueueName(NotificationPriority priority)
    {
        return priority switch
        {
            NotificationPriority.Critical => "notifications.critical",
            NotificationPriority.High => "notifications.high",
            NotificationPriority.Normal => "notifications.normal",
            NotificationPriority.Low => "notifications.low",
            _ => "notifications.normal"
        };
    }

    private TimeSpan GetMessageExpiration(NotificationPriority priority)
    {
        return priority switch
        {
            NotificationPriority.Critical => TimeSpan.FromHours(24),
            NotificationPriority.High => TimeSpan.FromHours(12),
            NotificationPriority.Normal => TimeSpan.FromHours(6),
            NotificationPriority.Low => TimeSpan.FromHours(1),
            _ => TimeSpan.FromHours(6)
        };
    }
}
```

#### **Channel Workers**

**Email Worker**:

```csharp
public class EmailNotificationWorker : BackgroundService
{
    private readonly IMessageQueue _messageQueue;
    private readonly IEmailProvider _emailProvider;
    private readonly ITemplateEngine _templateEngine;
    private readonly INotificationRepository _repository;
    private readonly ILogger<EmailNotificationWorker> _logger;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await _messageQueue.SubscribeAsync<NotificationMessage>(
            "notifications.*",  // Subscribe to all priority queues
            async (message) =>
            {
                await ProcessEmailNotificationAsync(message, stoppingToken);
            },
            stoppingToken
        );
    }

    private async Task ProcessEmailNotificationAsync(
        NotificationMessage message,
        CancellationToken cancellationToken)
    {
        if (!message.Channels.Contains(NotificationChannel.Email))
            return;

        try
        {
            var notification = await _repository.GetByIdAsync(message.NotificationId);
            notification.Status = NotificationStatus.Processing;
            await _repository.UpdateAsync(notification);

            // Render template
            var template = await _templateEngine.GetTemplateAsync(message.Type, NotificationChannel.Email);
            var renderedEmail = await _templateEngine.RenderAsync(template, message.TemplateData);

            var emailMessage = new EmailMessage(
                To: message.TemplateData["email"].ToString()!,
                Subject: renderedEmail.Subject,
                HtmlBody: renderedEmail.HtmlBody,
                PlainTextBody: renderedEmail.PlainTextBody,
                Attachments: renderedEmail.Attachments
            );

            // Send email with retry logic
            await SendEmailWithRetryAsync(emailMessage, notification, cancellationToken);

            notification.MarkAsSent(NotificationChannel.Email);
            await _repository.UpdateAsync(notification);

            _logger.LogInformation(
                "Email notification {NotificationId} sent successfully",
                notification.Id
            );
        }
        catch (Exception ex)
        {
            _logger.LogError(ex, "Failed to send email notification {NotificationId}", message.NotificationId);
            await HandleFailureAsync(message, ex.Message);
        }
    }

    private async Task SendEmailWithRetryAsync(
        EmailMessage email,
        Notification notification,
        CancellationToken cancellationToken)
    {
        var retryPolicy = Policy
            .Handle<EmailProviderException>()
            .Or<HttpRequestException>()
            .WaitAndRetryAsync(
                notification.MaxRetries,
                retryAttempt => TimeSpan.FromSeconds(Math.Pow(2, retryAttempt)), // Exponential backoff
                onRetry: (exception, timeSpan, retryCount, context) =>
                {
                    _logger.LogWarning(
                        "Retry {RetryCount} for notification {NotificationId} after {Delay}ms",
                        retryCount,
                        notification.Id,
                        timeSpan.TotalMilliseconds
                    );
                }
            );

        await retryPolicy.ExecuteAsync(async () =>
        {
            await _emailProvider.SendAsync(email, cancellationToken);
        });
    }

    private async Task HandleFailureAsync(NotificationMessage message, string reason)
    {
        var notification = await _repository.GetByIdAsync(message.NotificationId);
        notification.MarkAsFailed(reason);
        await _repository.UpdateAsync(notification);

        if (notification.RetryCount < notification.MaxRetries)
        {
            // Requeue for retry with exponential backoff
            var delay = TimeSpan.FromMinutes(Math.Pow(2, notification.RetryCount));
            await _messageQueue.PublishDelayedAsync(
                GetQueueName(notification.Priority),
                message,
                delay
            );
        }
        else
        {
            // Move to dead letter queue for manual investigation
            await _messageQueue.PublishAsync("notifications.failed", message);

            // Trigger alert for failed critical notifications
            if (notification.Priority == NotificationPriority.Critical)
            {
                await TriggerFailureAlertAsync(notification);
            }
        }
    }

    private async Task TriggerFailureAlertAsync(Notification notification)
    {
        // Send alert to operations team
        _logger.LogCritical(
            "Critical notification {NotificationId} failed after {RetryCount} attempts",
            notification.Id,
            notification.RetryCount
        );
    }
}
```

**SMS Worker**:

```csharp
public class SmsNotificationWorker : BackgroundService
{
    private readonly IMessageQueue _messageQueue;
    private readonly ISmsProvider _smsProvider;
    private readonly ITemplateEngine _templateEngine;
    private readonly INotificationRepository _repository;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await _messageQueue.SubscribeAsync<NotificationMessage>(
            "notifications.*",
            async (message) =>
            {
                await ProcessSmsNotificationAsync(message, stoppingToken);
            },
            stoppingToken
        );
    }

    private async Task ProcessSmsNotificationAsync(
        NotificationMessage message,
        CancellationToken cancellationToken)
    {
        if (!message.Channels.Contains(NotificationChannel.SMS))
            return;

        try
        {
            var notification = await _repository.GetByIdAsync(message.NotificationId);

            // Render template
            var template = await _templateEngine.GetTemplateAsync(message.Type, NotificationChannel.SMS);
            var renderedSms = await _templateEngine.RenderAsync(template, message.TemplateData);

            var smsMessage = new SmsMessage(
                PhoneNumber: message.TemplateData["phoneNumber"].ToString()!,
                Body: renderedSms.Body
            );

            // Send SMS with rate limiting (Twilio limits)
            await _smsProvider.SendAsync(smsMessage, cancellationToken);

            notification.MarkAsSent(NotificationChannel.SMS);
            await _repository.UpdateAsync(notification);
        }
        catch (Exception ex)
        {
            await HandleFailureAsync(message, ex.Message);
        }
    }
}
```

**Push Notification Worker**:

```csharp
public class PushNotificationWorker : BackgroundService
{
    private readonly IMessageQueue _messageQueue;
    private readonly IPushNotificationProvider _pushProvider; // Firebase FCM
    private readonly ITemplateEngine _templateEngine;
    private readonly INotificationRepository _repository;
    private readonly IDeviceTokenRepository _deviceTokenRepository;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        await _messageQueue.SubscribeAsync<NotificationMessage>(
            "notifications.*",
            async (message) =>
            {
                await ProcessPushNotificationAsync(message, stoppingToken);
            },
            stoppingToken
        );
    }

    private async Task ProcessPushNotificationAsync(
        NotificationMessage message,
        CancellationToken cancellationToken)
    {
        if (!message.Channels.Contains(NotificationChannel.Push))
            return;

        try
        {
            // Get all device tokens for user
            var deviceTokens = await _deviceTokenRepository.GetActiveTokensAsync(message.UserId);

            if (!deviceTokens.Any())
            {
                _logger.LogWarning("No device tokens found for user {UserId}", message.UserId);
                return;
            }

            var template = await _templateEngine.GetTemplateAsync(message.Type, NotificationChannel.Push);
            var renderedPush = await _templateEngine.RenderAsync(template, message.TemplateData);

            // Send to all devices (multi-device support)
            var tasks = deviceTokens.Select(async token =>
            {
                var pushMessage = new PushMessage(
                    DeviceToken: token.Token,
                    Title: renderedPush.Title,
                    Body: renderedPush.Body,
                    Data: message.TemplateData,
                    ImageUrl: renderedPush.ImageUrl
                );

                try
                {
                    await _pushProvider.SendAsync(pushMessage, cancellationToken);
                }
                catch (InvalidDeviceTokenException)
                {
                    // Mark token as invalid for cleanup
                    await _deviceTokenRepository.MarkAsInvalidAsync(token.Id);
                }
            });

            await Task.WhenAll(tasks);

            var notification = await _repository.GetByIdAsync(message.NotificationId);
            notification.MarkAsSent(NotificationChannel.Push);
            await _repository.UpdateAsync(notification);
        }
        catch (Exception ex)
        {
            await HandleFailureAsync(message, ex.Message);
        }
    }
}
```

#### **Template Engine**

```csharp
public class NotificationTemplateEngine : ITemplateEngine
{
    private readonly ITemplateRepository _templateRepository;
    private readonly IRazorViewEngine _razorEngine;
    private readonly IDistributedCache _cache;

    public async Task<RenderedTemplate> RenderAsync(
        NotificationTemplate template,
        Dictionary<string, object> data)
    {
        // Compile template (cached)
        var compiledTemplate = await GetCompiledTemplateAsync(template);

        // Render with data
        var result = await compiledTemplate.RenderAsync(data);

        return result;
    }

    private async Task<ICompiledTemplate> GetCompiledTemplateAsync(NotificationTemplate template)
    {
        var cacheKey = $"template:{template.Id}:{template.Version}";

        var cached = await _cache.GetStringAsync(cacheKey);
        if (cached != null)
        {
            return JsonSerializer.Deserialize<CompiledTemplate>(cached)!;
        }

        var compiled = CompileTemplate(template);
        await _cache.SetStringAsync(cacheKey, JsonSerializer.Serialize(compiled), new DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(24)
        });

        return compiled;
    }
}
```

#### **Delivery Guarantees**

**At-Least-Once Delivery**:

```csharp
public class AtLeastOnceMessageQueue : IMessageQueue
{
    private readonly IModel _channel;

    public async Task SubscribeAsync<T>(
        string queueName,
        Func<T, Task> handler,
        CancellationToken cancellationToken)
    {
        var consumer = new AsyncEventingBasicConsumer(_channel);

        consumer.Received += async (model, ea) =>
        {
            try
            {
                var message = JsonSerializer.Deserialize<T>(ea.Body.ToArray())!;

                // Process message
                await handler(message);

                // Acknowledge only after successful processing
                _channel.BasicAck(ea.DeliveryTag, multiple: false);
            }
            catch (Exception ex)
            {
                // Negative acknowledge - requeue for retry
                _channel.BasicNack(ea.DeliveryTag, multiple: false, requeue: true);
            }
        };

        _channel.BasicConsume(queue: queueName, autoAck: false, consumer: consumer);
    }
}
```

**Idempotency**:

```csharp
public class IdempotentNotificationHandler
{
    private readonly IDistributedCache _cache;

    public async Task<bool> TryProcessAsync(Guid notificationId, Func<Task> handler)
    {
        var lockKey = $"notification:lock:{notificationId}";
        var processedKey = $"notification:processed:{notificationId}";

        // Check if already processed
        var processed = await _cache.GetStringAsync(processedKey);
        if (processed != null)
        {
            return false; // Already processed
        }

        // Acquire distributed lock
        var lockAcquired = await _cache.StringSetAsync(
            lockKey,
            "1",
            TimeSpan.FromMinutes(5),
            When.NotExists
        );

        if (!lockAcquired)
        {
            return false; // Another instance is processing
        }

        try
        {
            await handler();

            // Mark as processed
            await _cache.SetStringAsync(processedKey, "1", new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromDays(7)
            });

            return true;
        }
        finally
        {
            await _cache.KeyDeleteAsync(lockKey);
        }
    }
}
```

#### **Priority Queue Configuration (RabbitMQ)**

```csharp
public class PriorityQueueConfiguration
{
    public static void ConfigureQueues(IModel channel)
    {
        var queueArgs = new Dictionary<string, object>
        {
            { "x-max-priority", 3 }, // 0=Low, 1=Normal, 2=High, 3=Critical
            { "x-message-ttl", 86400000 }, // 24 hours
            { "x-dead-letter-exchange", "notifications.dlx" }
        };

        channel.QueueDeclare(
            queue: "notifications.critical",
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: queueArgs
        );

        channel.QueueDeclare(
            queue: "notifications.high",
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: queueArgs
        );

        channel.QueueDeclare(
            queue: "notifications.normal",
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: queueArgs
        );

        channel.QueueDeclare(
            queue: "notifications.low",
            durable: true,
            exclusive: false,
            autoDelete: false,
            arguments: queueArgs
        );

        // Dead Letter Queue
        channel.QueueDeclare(
            queue: "notifications.failed",
            durable: true,
            exclusive: false,
            autoDelete: false
        );
    }
}
```

#### **Monitoring and Observability**

```csharp
public class NotificationMetrics
{
    private readonly IMetricsCollector _metrics;

    public void RecordNotificationSent(NotificationType type, NotificationChannel channel, TimeSpan duration)
    {
        _metrics.Increment("notifications.sent", new Dictionary<string, string>
        {
            { "type", type.ToString() },
            { "channel", channel.ToString() }
        });

        _metrics.RecordHistogram("notifications.duration", duration.TotalMilliseconds, new Dictionary<string, string>
        {
            { "type", type.ToString() },
            { "channel", channel.ToString() }
        });
    }

    public void RecordNotificationFailed(NotificationType type, NotificationChannel channel, string reason)
    {
        _metrics.Increment("notifications.failed", new Dictionary<string, string>
        {
            { "type", type.ToString() },
            { "channel", channel.ToString() },
            { "reason", reason }
        });
    }
}
```

#### **✅ Best Practices**

1. **Use priority queues** for urgent notifications
2. **Implement idempotency** to handle duplicates
3. **Respect user preferences** (allow opt-out)
4. **Use exponential backoff** for retries
5. **Template caching** for performance
6. **Multi-device support** for push notifications
7. **Dead letter queues** for failed messages
8. **Rate limiting** to avoid provider throttling
9. **Comprehensive monitoring** (delivery rate, latency)
10. **A/B testing** for templates

#### **❌ Common Mistakes**

1. **No retry logic** - transient failures cause lost notifications
2. **Synchronous sending** - blocks application
3. **No user preferences** - spam users
4. **Hard-coded templates** - difficult to update
5. **No monitoring** - blind to failures
6. **Same priority for all** - important notifications delayed
7. **No idempotency** - duplicate notifications
8. **Missing unsubscribe** - regulatory compliance issues

---

## Q445-Q460: System Design Topics Summary

### Q445: Design a real-time chat system (WebSocket, message persistence, read receipts)

**Key Components**:
- WebSocket server with connection pooling
- Message broker (Redis Pub/Sub or RabbitMQ)
- Message persistence (Cassandra for horizontal scaling)
- Presence service (online/offline status)
- Read receipts with eventual consistency
- Message delivery acknowledgments

**Challenges**:
- Handling millions of concurrent connections
- Message ordering guarantees
- Offline message delivery
- Typing indicators
- File/image sharing
- End-to-end encryption

**Technologies**: SignalR, Socket.IO, Cassandra, Redis, WebRTC (for voice/video)

---

### Q446: Design a search system like Elasticsearch (indexing, ranking, autocomplete)

**Core Features**:
- Inverted index for full-text search
- TF-IDF and BM25 ranking algorithms
- Trie data structure for autocomplete
- Fuzzy matching for typo tolerance
- Faceted search and filtering
- Distributed sharding

**Optimizations**:
- Index caching (hot data in memory)
- Query result caching
- Incremental indexing
- Stemming and lemmatization
- Stop word removal

**Technologies**: Elasticsearch, Apache Solr, Lucene, Azure Cognitive Search

---

### Q447: Design a file storage system like Dropbox/Google Drive

**Architecture**:
- Chunking and deduplication (block-level)
- Metadata service (file structure, versions)
- Sync service (delta sync algorithm)
- Conflict resolution (operational transformation)
- CDN for fast downloads

**Features**:
- File versioning
- Sharing and permissions
- Real-time collaboration
- Offline access
- Compression

**Technologies**: S3, Azure Blob Storage, Reed-Solomon erasure coding, WebSocket

---

### Q448: Design a recommendation system (collaborative filtering, content-based)

**Algorithms**:
- Collaborative filtering (user-user, item-item)
- Matrix factorization (SVD, ALS)
- Content-based filtering (TF-IDF, embeddings)
- Hybrid models
- Deep learning (neural collaborative filtering)

**Architecture**:
- Offline batch processing (model training)
- Online serving (real-time predictions)
- A/B testing framework
- Feature store

**Challenges**:
- Cold start problem
- Scalability (billions of users/items)
- Real-time updates

**Technologies**: Apache Spark, TensorFlow, PyTorch, Redis (for caching)

---

### Q449: Design a payment processing system (transactions, fraud detection, reconciliation)

**Components**:
- Payment gateway integration (Stripe, PayPal)
- Transaction state machine
- Idempotency keys
- Double-entry bookkeeping
- Fraud detection (rule engine, ML models)
- Reconciliation service

**Guarantees**:
- Exactly-once processing
- ACID transactions
- PCI DSS compliance
- Audit logging

**Technologies**: PostgreSQL, Event Sourcing, Saga pattern, Apache Kafka

---

### Q450: Design a video streaming platform (transcoding, CDN, adaptive bitrate)

**Architecture**:
- Video upload and transcoding pipeline
- CDN for content delivery
- Adaptive bitrate streaming (HLS, DASH)
- DRM for content protection
- Recommendation engine
- Analytics (watch time, engagement)

**Optimizations**:
- Multi-bitrate encoding
- Thumbnail generation
- Preloading and prefetching
- Edge caching

**Technologies**: FFmpeg, AWS MediaConvert, CloudFront, HLS, MPEG-DASH

---

### Q451: Design a job scheduling system (cron jobs, dependencies, retries)

**Features**:
- Job definition (schedule, dependencies)
- DAG execution engine
- Distributed task queue
- Retry with exponential backoff
- Job monitoring and alerting

**Patterns**:
- Leader election (for scheduler)
- Idempotent job execution
- Dead letter queue for failures

**Technologies**: Apache Airflow, Hangfire, Quartz.NET, Temporal, Celery

---

### Q452: Design a metrics monitoring system (time-series data, alerting)

**Components**:
- Time-series database (InfluxDB, Prometheus)
- Metric ingestion pipeline
- Aggregation and downsampling
- Query engine for dashboards
- Alerting rules engine
- Anomaly detection

**Optimizations**:
- Compression (delta encoding)
- Retention policies
- Pre-aggregation

**Technologies**: Prometheus, Grafana, InfluxDB, TimescaleDB, Datadog

---

### Q453: Design a content delivery network (CDN)

**Components**:
- Edge servers (distributed globally)
- Origin server
- Cache invalidation
- Load balancing
- SSL/TLS termination
- DDoS protection

**Caching Strategies**:
- Cache-Control headers
- Stale-while-revalidate
- Purge API

**Technologies**: CloudFlare, AWS CloudFront, Akamai, Varnish

---

### Q454: Design an A/B testing platform

**Features**:
- Experiment configuration
- User bucketing (consistent hashing)
- Metric tracking
- Statistical significance calculation
- Multi-variant testing

**Challenges**:
- Sample size calculation
- Avoiding biases
- Interaction effects

**Technologies**: Optimizely, LaunchDarkly, custom feature flags

---

### Q455: Design a ride-sharing system like Uber

**Core Services**:
- Rider service
- Driver service
- Matching service (proximity algorithm)
- Routing service (shortest path, ETA)
- Pricing service (surge pricing)
- Payment service

**Data Structures**:
- Geohashing for location indexing
- QuadTree for spatial queries

**Technologies**: Redis Geospatial, Google Maps API, WebSocket

---

### Q456: Design a social media feed (Twitter timeline, Facebook news feed)

**Approaches**:
- **Fan-out-on-write**: Pre-compute feeds (fast reads, slow writes)
- **Fan-out-on-read**: Compute on demand (slow reads, fast writes)
- **Hybrid**: Fan-out for regular users, on-read for celebrities

**Ranking**:
- Edge Rank algorithm
- Machine learning models
- Engagement signals

**Technologies**: Redis (for feed cache), Cassandra, Kafka

---

### Q457: Design a distributed locking service

**Algorithms**:
- Redlock (Redis-based)
- Zookeeper for coordination
- Etcd for distributed locks

**Requirements**:
- Mutual exclusion
- Deadlock-free
- Fault tolerance
- Fairness

**Use Cases**: Leader election, resource allocation

---

### Q458: Design an autocomplete/typeahead system

**Data Structures**:
- Trie (prefix tree)
- Ternary search tree

**Optimizations**:
- Caching popular prefixes
- Prefix frequency scoring
- Personalized suggestions

**Technologies**: Elasticsearch, Redis (sorted sets), Apache Solr

---

### Q459: Design a distributed task queue

**Components**:
- Queue (RabbitMQ, Kafka)
- Workers (horizontal scaling)
- Task scheduler
- Result backend
- Retry and dead letter queues

**Patterns**:
- At-least-once delivery
- Idempotent task handlers
- Priority queues

**Technologies**: Celery, Hangfire, AWS SQS, RabbitMQ

---

### Q460: Design a log aggregation and search system (ELK stack)

**Architecture**:
- Log shippers (Filebeat, Fluentd)
- Log aggregation (Logstash)
- Storage (Elasticsearch)
- Visualization (Kibana)
- Alerting (ElastAlert)

**Features**:
- Real-time indexing
- Full-text search
- Log parsing and enrichment
- Retention policies

**Optimizations**:
- Index lifecycle management
- Hot-warm-cold architecture

**Technologies**: ELK (Elasticsearch, Logstash, Kibana), Grafana Loki, Splunk

---

## Summary

This section (Q441-Q460) covers comprehensive **system design and scalability** topics essential for senior software engineers and architects. Key themes include:

1. **Distributed Systems**: Cache systems, rate limiting, notifications
2. **Real-Time Systems**: Chat, streaming, monitoring
3. **Data-Intensive Systems**: Search, recommendations, analytics
4. **Infrastructure**: CDN, job scheduling, distributed locks
5. **Best Practices**: Retry logic, idempotency, monitoring, fault tolerance

Each question emphasizes practical implementation with C# examples, architectural diagrams, algorithm comparisons, and performance characteristics. The focus is on production-ready solutions that scale to millions of users.
