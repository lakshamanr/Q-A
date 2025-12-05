# INTERVIEW ANSWERS - QUESTIONS 100 ONWARDS

---

## **Q100: What is the difference between Azure Service Bus and Azure Storage Queues?**

### **Answer:**

Azure Service Bus and Azure Storage Queues are both message queuing solutions in Azure, but they serve different purposes and have distinct features.

**Key Differences:**

| Feature | Azure Service Bus | Azure Storage Queues |
|---------|------------------|---------------------|
| **Message Size** | Up to 256 KB (standard), 100 MB (premium) | Up to 64 KB |
| **Ordering** | FIFO guarantee with sessions | Best-effort ordering only |
| **Duplicate Detection** | Built-in duplicate detection | No built-in duplicate detection |
| **Transactions** | Supports transactions | Limited transaction support |
| **TTL (Time-to-Live)** | Configurable, up to unlimited | Maximum 7 days |
| **Protocols** | AMQP, HTTP/HTTPS | HTTP/HTTPS only |
| **Delivery Model** | At-least-once, at-most-once | At-least-once only |
| **Topics/Subscriptions** | Yes (pub-sub pattern) | No (queues only) |
| **Dead-letter Queue** | Built-in dead-letter queue | No built-in DLQ |
| **Batching** | Send/receive batching | Limited batching |
| **Pricing** | Higher cost, more features | Lower cost, simpler |

**When to Use Azure Service Bus:**
- You need guaranteed FIFO ordering
- Messages larger than 64 KB
- Pub-sub pattern with topics and subscriptions
- Duplicate detection is required
- Enterprise messaging scenarios
- Complex routing and filtering

**When to Use Azure Storage Queues:**
- Simple queue requirements
- Cost-effective solution needed
- Message size under 64 KB
- High-volume, simple messaging
- Already using Azure Storage

**Example Implementation:**

```csharp
// Azure Service Bus - Sending a message
using Azure.Messaging.ServiceBus;

ServiceBusClient client = new ServiceBusClient(connectionString);
ServiceBusSender sender = client.CreateSender("myqueue");

ServiceBusMessage message = new ServiceBusMessage("Order #12345");
message.MessageId = Guid.NewGuid().ToString();
message.ContentType = "application/json";

await sender.SendMessageAsync(message);

// Azure Storage Queue - Sending a message
using Azure.Storage.Queues;

QueueClient queueClient = new QueueClient(connectionString, "myqueue");
await queueClient.CreateIfNotExistsAsync();
await queueClient.SendMessageAsync("Order #12345");
```

**Visual Representation:**

```
Azure Service Bus (Enterprise Messaging)
┌─────────────────────────────────────┐
│  Producer                           │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  Service Bus Namespace              │
│  ┌───────────────┐  ┌─────────────┐│
│  │ Queue         │  │ Topic       ││
│  │ (Point-to-    │  │ (Pub-Sub)   ││
│  │  Point)       │  │             ││
│  │ - Ordered     │  │ Subscription││
│  │ - Duplicate   │  │ Filtering   ││
│  │   Detection   │  │             ││
│  │ - Dead Letter │  │             ││
│  └───────────────┘  └─────────────┘│
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  Multiple Consumers                 │
└─────────────────────────────────────┘

Azure Storage Queue (Simple, Cost-Effective)
┌─────────────────────────────────────┐
│  Producer                           │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  Storage Account                    │
│  ┌───────────────────────────────┐ │
│  │ Queue (Simple FIFO)           │ │
│  │ - Best effort ordering        │ │
│  │ - HTTP/HTTPS only             │ │
│  │ - 7 days max TTL              │ │
│  │ - 64 KB max size              │ │
│  └───────────────────────────────┘ │
└────────┬────────────────────────────┘
         │
         ▼
┌─────────────────────────────────────┐
│  Single Consumer (typically)        │
└─────────────────────────────────────┘
```

**Real-World Example:**

At an e-commerce platform:
- **Use Service Bus**: For order processing where FIFO is critical, you need to process orders in exact sequence, and you want to publish order events to multiple subscribers (inventory, shipping, notifications)
- **Use Storage Queue**: For simple background jobs like sending welcome emails, resizing uploaded images, or cleaning up temporary files

---

## **Q101: Explain Azure Event Hub. When would you use it?**

### **Answer:**

Azure Event Hub is a big data streaming platform and event ingestion service capable of receiving and processing millions of events per second. It's part of Azure's messaging services but designed specifically for high-throughput, real-time data streaming scenarios.

**Key Features:**

1. **Massive Scale**: Can ingest millions of events per second
2. **Low Latency**: Real-time data streaming
3. **Event Retention**: Stores events for 1-90 days (configurable)
4. **Partitioning**: Multiple partitions for parallel processing
5. **Consumer Groups**: Multiple independent consumers can read the same stream
6. **Capture**: Automatically capture streaming data to Azure Blob or Data Lake
7. **Apache Kafka Compatible**: Can use Kafka clients with Event Hub

**Architecture Components:**

- **Event Producers**: Applications that send events to Event Hub
- **Partitions**: Ordered sequence of events (1-32 partitions)
- **Consumer Groups**: Independent views of the event stream
- **Throughput Units**: Pre-purchased capacity units
- **Event Receivers**: Applications that read events

**When to Use Azure Event Hub:**

✅ **Use Event Hub When:**
- Streaming large volumes of telemetry data (IoT devices)
- Real-time analytics and dashboards
- Log and telemetry aggregation
- Live game analytics
- User activity tracking
- Time-series data collection
- Transaction processing streams
- Clickstream analysis

❌ **Don't Use Event Hub When:**
- Low-volume messaging (use Service Bus)
- Request-response patterns
- Strict FIFO ordering required
- Need message sessions or transactions

**Comparison with Other Services:**

| Feature | Event Hub | Service Bus | Event Grid |
|---------|-----------|-------------|------------|
| **Purpose** | Big data streaming | Enterprise messaging | Event distribution |
| **Throughput** | Millions/sec | Thousands/sec | Millions/sec |
| **Retention** | 1-90 days | Minutes to days | Immediate delivery |
| **Use Case** | Telemetry, logs | Transactions, commands | Reactive programming |
| **Ordering** | Per-partition | Global with sessions | No guarantee |

**Example Implementation:**

```csharp
// Producer - Sending events to Event Hub
using Azure.Messaging.EventHubs;
using Azure.Messaging.EventHubs.Producer;

EventHubProducerClient producer = new EventHubProducerClient(
    connectionString,
    eventHubName
);

// Create a batch of events
EventDataBatch eventBatch = await producer.CreateBatchAsync();

// IoT sensor data
var sensorData = new
{
    DeviceId = "device-001",
    Temperature = 72.5,
    Humidity = 65.3,
    Timestamp = DateTime.UtcNow
};

EventData eventData = new EventData(
    JsonSerializer.SerializeToUtf8Bytes(sensorData)
);

// Add partition key for ordered processing
eventData.PartitionKey = "device-001";

if (!eventBatch.TryAdd(eventData))
{
    throw new Exception("Event is too large for the batch");
}

await producer.SendAsync(eventBatch);

// Consumer - Reading events from Event Hub
using Azure.Messaging.EventHubs.Consumer;

EventHubConsumerClient consumer = new EventHubConsumerClient(
    consumerGroup,
    connectionString,
    eventHubName
);

await foreach (PartitionEvent partitionEvent in consumer.ReadEventsAsync())
{
    string data = Encoding.UTF8.GetString(partitionEvent.Data.Body.ToArray());
    Console.WriteLine($"Event from partition {partitionEvent.Partition.PartitionId}: {data}");

    // Process the event
    ProcessSensorData(data);
}
```

**Real-World Example with Event Hub Capture:**

```csharp
// Configuration in Azure Portal or ARM template
// Event Hub Capture Configuration
{
    "capture": {
        "enabled": true,
        "encoding": "Avro",
        "intervalInSeconds": 300,
        "sizeLimitInBytes": 314572800,
        "destination": {
            "name": "EventHubArchive.AzureBlockBlob",
            "properties": {
                "storageAccountResourceId": "/subscriptions/.../storageAccounts/myaccount",
                "blobContainer": "eventhubcapture",
                "archiveNameFormat": "{Namespace}/{EventHub}/{PartitionId}/{Year}/{Month}/{Day}/{Hour}/{Minute}/{Second}"
            }
        }
    }
}
```

**Visual Architecture:**

```
IoT/Telemetry Scenario with Event Hub

┌─────────────┐  ┌─────────────┐  ┌─────────────┐
│IoT Device 1 │  │IoT Device 2 │  │IoT Device N │
│Temperature  │  │Humidity     │  │Pressure     │
│Sensor       │  │Sensor       │  │Sensor       │
└──────┬──────┘  └──────┬──────┘  └──────┬──────┘
       │                │                 │
       │ Millions of events per second    │
       └────────────────┼─────────────────┘
                        ▼
         ┌──────────────────────────────┐
         │   Azure Event Hub Namespace  │
         │  ┌────────────────────────┐  │
         │  │ Event Hub: SensorData  │  │
         │  │                        │  │
         │  │ Partition 0 [events]   │  │
         │  │ Partition 1 [events]   │  │
         │  │ Partition 2 [events]   │  │
         │  │ Partition 3 [events]   │  │
         │  │                        │  │
         │  │ Retention: 7 days      │  │
         │  └────────────────────────┘  │
         └───────┬──────────────┬───────┘
                 │              │
        ┌────────▼──────┐  ┌───▼─────────────┐
        │ Stream        │  │ Capture         │
        │ Analytics     │  │ (Archive to     │
        │ (Real-time    │  │  Blob Storage)  │
        │  Processing)  │  │                 │
        └────────┬──────┘  └───┬─────────────┘
                 │              │
        ┌────────▼──────┐  ┌───▼─────────────┐
        │ Power BI      │  │ Azure Data      │
        │ Dashboard     │  │ Lake / Synapse  │
        │ (Real-time)   │  │ (Batch Analysis)│
        └───────────────┘  └─────────────────┘
```

**Consumer Groups Example:**

```
Event Hub Stream
┌─────────────────────────────────────┐
│ [E1][E2][E3][E4][E5][E6][E7][E8]... │
└─────────────────────────────────────┘
          │         │         │
  ┌───────▼───┐ ┌───▼────┐ ┌──▼──────┐
  │Consumer   │ │Consumer│ │Consumer │
  │Group: CG1 │ │Group:  │ │Group:   │
  │           │ │CG2     │ │CG3      │
  │Real-time  │ │Archive │ │Analytics│
  │Alerts     │ │        │ │         │
  └───────────┘ └────────┘ └─────────┘
```

**Real-World Use Case Example:**

**Scenario**: E-commerce Platform Clickstream Analysis

```csharp
// User Activity Tracking
public class ClickStreamEvent
{
    public string UserId { get; set; }
    public string SessionId { get; set; }
    public string Page { get; set; }
    public string Action { get; set; } // View, Click, AddToCart, Purchase
    public Dictionary<string, object> Properties { get; set; }
    public DateTime Timestamp { get; set; }
}

// Sending clickstream events
public async Task TrackUserActivity(ClickStreamEvent clickEvent)
{
    var eventData = new EventData(
        JsonSerializer.SerializeToUtf8Bytes(clickEvent)
    );

    // Use UserId as partition key to keep user events ordered
    eventData.PartitionKey = clickEvent.UserId;

    await eventHubProducer.SendAsync(new[] { eventData });
}

// Processing for real-time recommendations
public async Task ProcessClickstream()
{
    await foreach (PartitionEvent evt in eventHubConsumer.ReadEventsAsync())
    {
        var clickEvent = JsonSerializer.Deserialize<ClickStreamEvent>(
            evt.Data.Body
        );

        // Real-time processing
        await UpdateUserProfile(clickEvent);
        await GenerateRecommendations(clickEvent.UserId);
        await DetectAnomalies(clickEvent);
    }
}
```

**Performance Characteristics:**

- **Throughput**: Up to 2 MB/sec per Throughput Unit (Standard), much higher for Premium/Dedicated
- **Ingestion Rate**: Millions of events per second
- **Latency**: Sub-second latency for event delivery
- **Retention**: 1 day (default) up to 90 days (configurable)

---

## **Q102: What is Event Grid? How does it differ from Event Hub?**

### **Answer:**

Azure Event Grid is a fully managed event routing service that enables event-driven, reactive programming. It uses a publish-subscribe model to uniformly deliver events from various sources to multiple handlers.

**Key Characteristics of Event Grid:**

1. **Event Routing Service**: Routes events from sources to handlers
2. **Serverless**: No infrastructure to manage
3. **Massive Scale**: 10 million events per second per region
4. **Low Latency**: Near real-time event delivery
5. **Pay-per-event**: Cost-effective for sporadic events
6. **Built-in Events**: Native integration with 20+ Azure services
7. **Custom Topics**: Create your own event sources
8. **Event Filtering**: Advanced filtering and routing

**Event Grid vs Event Hub - Key Differences:**

| Aspect | Event Grid | Event Hub |
|--------|-----------|-----------|
| **Purpose** | Event distribution/routing | Data streaming/ingestion |
| **Pattern** | Discrete events (things happened) | Stream of events (continuous) |
| **Delivery** | Push model (reactive) | Pull model (client reads) |
| **Retention** | No retention (immediate delivery) | 1-90 days retention |
| **Use Case** | React to state changes | Telemetry, logs, time-series |
| **Ordering** | No ordering guarantee | Ordered within partition |
| **Throughput** | 10M events/sec | Millions/sec |
| **Latency** | Sub-second | Sub-second |
| **Cost Model** | Per-event | Throughput units |
| **Event Size** | Up to 1 MB | Up to 1 MB (premium) |
| **Consumers** | Multiple, independent handlers | Consumer groups with checkpointing |

**When to Use Event Grid:**

✅ **Use Event Grid When:**
- Reacting to Azure resource changes (blob created, VM started)
- Building event-driven serverless applications
- Integration scenarios (connecting systems)
- Notification and alerting
- Webhooks and event handlers
- State change notifications
- Application integration

✅ **Use Event Hub When:**
- Processing telemetry streams
- Log aggregation
- Real-time analytics on continuous data
- Time-series data
- IoT device data
- Need to replay events
- Big data pipeline ingestion

**Event Grid Architecture:**

```
Event Grid - Event Distribution

Event Sources                Event Grid              Event Handlers
┌──────────────┐            ┌──────────┐            ┌──────────────┐
│ Azure Blob   │──events───▶│          │───route───▶│Azure Function│
│ Storage      │            │  Event   │            │              │
└──────────────┘            │  Grid    │            └──────────────┘
┌──────────────┐            │          │            ┌──────────────┐
│ Custom App   │──events───▶│  Topics  │───route───▶│Logic Apps    │
│              │            │    +     │            │              │
└──────────────┘            │ Filtering│            └──────────────┘
┌──────────────┐            │          │            ┌──────────────┐
│ Azure        │──events───▶│          │───route───▶│Webhook       │
│ Resources    │            │          │            │              │
└──────────────┘            └──────────┘            └──────────────┘

Events are immediately pushed to handlers (no storage)
```

**Example Implementation:**

```csharp
// Publishing custom events to Event Grid
using Azure.Messaging.EventGrid;

EventGridPublisherClient client = new EventGridPublisherClient(
    new Uri(topicEndpoint),
    new AzureKeyCredential(topicKey)
);

// Create custom event
var customEvent = new EventGridEvent(
    subject: "orders/order-12345",
    eventType: "OrderService.OrderPlaced",
    dataVersion: "1.0",
    data: new
    {
        OrderId = "order-12345",
        CustomerId = "customer-789",
        TotalAmount = 299.99,
        Items = new[] { "Product A", "Product B" }
    }
);

customEvent.Id = Guid.NewGuid().ToString();
customEvent.EventTime = DateTimeOffset.UtcNow;

// Send event
await client.SendEventAsync(customEvent);

// Receiving events in Azure Function
[FunctionName("OrderEventHandler")]
public static async Task Run(
    [EventGridTrigger] EventGridEvent eventGridEvent,
    ILogger log)
{
    log.LogInformation($"Event Type: {eventGridEvent.EventType}");
    log.LogInformation($"Event Subject: {eventGridEvent.Subject}");
    log.LogInformation($"Event Data: {eventGridEvent.Data}");

    if (eventGridEvent.EventType == "OrderService.OrderPlaced")
    {
        var orderData = JsonSerializer.Deserialize<OrderData>(
            eventGridEvent.Data.ToString()
        );

        // Process the order
        await SendOrderConfirmationEmail(orderData.CustomerId);
        await UpdateInventory(orderData.Items);
        await NotifyShipping(orderData.OrderId);
    }
}
```

**Event Filtering Example:**

```csharp
// Event Grid Subscription with Advanced Filtering
{
    "properties": {
        "destination": {
            "endpointType": "WebHook",
            "properties": {
                "endpointUrl": "https://myapp.azurewebsites.net/api/OrderHandler"
            }
        },
        "filter": {
            "includedEventTypes": [
                "OrderService.OrderPlaced",
                "OrderService.OrderShipped"
            ],
            "advancedFilters": [
                {
                    "operatorType": "NumberGreaterThan",
                    "key": "data.TotalAmount",
                    "value": 100
                },
                {
                    "operatorType": "StringContains",
                    "key": "data.Items",
                    "values": ["Premium"]
                }
            ],
            "subjectBeginsWith": "orders/",
            "subjectEndsWith": ""
        }
    }
}
```

**Built-in Azure Events Example:**

```csharp
// React to Blob Storage events
[FunctionName("BlobCreatedHandler")]
public static async Task HandleBlobCreated(
    [EventGridTrigger] EventGridEvent blobEvent,
    ILogger log)
{
    // Event from Azure Blob Storage
    // EventType: Microsoft.Storage.BlobCreated

    var blobUrl = blobEvent.Subject; // /blobServices/default/containers/images/blobs/photo.jpg
    var createdEvent = JsonSerializer.Deserialize<StorageBlobCreatedEventData>(
        blobEvent.Data.ToString()
    );

    log.LogInformation($"New blob created: {createdEvent.Url}");
    log.LogInformation($"Content Type: {createdEvent.ContentType}");
    log.LogInformation($"Size: {createdEvent.ContentLength} bytes");

    // Process the blob (e.g., create thumbnail, scan for viruses)
    if (createdEvent.ContentType.StartsWith("image/"))
    {
        await CreateThumbnail(createdEvent.Url);
        await ExtractMetadata(createdEvent.Url);
    }
}
```

**Real-World Scenario Comparison:**

**Scenario 1: E-commerce Order Processing**

```
Using Event Grid (Discrete events):
┌──────────────┐
│Order Service │
│ User places  │
│ an order     │
└──────┬───────┘
       │ Publishes "OrderPlaced" event
       ▼
┌──────────────┐
│  Event Grid  │ Routes to multiple handlers
└──┬─────┬─────┘
   │     │
   │     └─────▶ Inventory Service (Update stock)
   │
   ├───────────▶ Email Service (Send confirmation)
   │
   ├───────────▶ Shipping Service (Create shipment)
   │
   └───────────▶ Analytics Service (Track metrics)

Each handler processes independently and immediately
```

**Scenario 2: IoT Telemetry Processing**

```
Using Event Hub (Continuous stream):
┌──────────┐ ┌──────────┐ ┌──────────┐
│IoT Device│ │IoT Device│ │IoT Device│
│  (1000s) │ │  (1000s) │ │  (1000s) │
└────┬─────┘ └────┬─────┘ └────┬─────┘
     │            │            │
     │ Continuous stream of temperature readings
     └────────────┼────────────┘
                  ▼
         ┌────────────────┐
         │   Event Hub    │ Ingests millions of events
         │  Partitions    │ Stores for 7 days
         │  [data stream] │
         └────────┬───────┘
                  │
         ┌────────┴───────┐
         │                │
         ▼                ▼
    ┌─────────┐    ┌──────────────┐
    │ Stream  │    │ Batch        │
    │ Analytics│    │ Processing   │
    │(Real-time│    │(Historical   │
    │ alerts) │    │  analysis)   │
    └─────────┘    └──────────────┘

Continuous processing of data stream
```

**Decision Matrix:**

| Requirement | Use Event Grid | Use Event Hub |
|-------------|---------------|---------------|
| React to Azure resource changes | ✅ | ❌ |
| Process telemetry/IoT data | ❌ | ✅ |
| Event-driven architecture | ✅ | ❌ |
| Time-series analytics | ❌ | ✅ |
| Webhook integration | ✅ | ❌ |
| Need to replay events | ❌ | ✅ |
| Serverless event handling | ✅ | ⚠️ (can use) |
| Log aggregation | ❌ | ✅ |
| State change notifications | ✅ | ❌ |
| Continuous data streams | ❌ | ✅ |

**Combined Usage Example:**

```csharp
// Using both together in a complete solution
public class ComprehensiveEventingSolution
{
    // Event Hub: Ingest high-volume IoT telemetry
    public async Task ProcessIoTTelemetry()
    {
        // Millions of sensor readings per second
        await eventHub.SendAsync(sensorData);
    }

    // Event Grid: React to significant events
    public async Task PublishCriticalAlert()
    {
        // When Stream Analytics detects temperature > threshold
        await eventGrid.PublishEventAsync(new
        {
            EventType = "IoT.CriticalTemperatureAlert",
            Data = new { DeviceId = "device-123", Temperature = 95.5 }
        });

        // Event Grid immediately notifies:
        // - Azure Function (send SMS alert)
        // - Logic App (create incident ticket)
        // - Webhook (notify operations dashboard)
    }
}
```

---

## **Q103: Explain the pub-sub pattern in Azure.**

### **Answer:**

The Publish-Subscribe (Pub-Sub) pattern is a messaging pattern where senders (publishers) send messages without knowledge of who will receive them, and receivers (subscribers) receive messages without knowledge of who sent them. This decouples producers from consumers.

**Core Concepts:**

1. **Publisher**: Sends messages to a topic (not directly to subscribers)
2. **Topic**: Named channel/category for messages
3. **Subscription**: Filter-based consumer registration
4. **Subscriber**: Receives messages from subscriptions
5. **Message Filtering**: Subscribers can filter based on criteria

**Azure Services Supporting Pub-Sub:**

### **1. Azure Service Bus Topics and Subscriptions**

The primary pub-sub implementation in Azure for enterprise messaging.

**Architecture:**

```
Pub-Sub with Service Bus Topics

Publishers                   Topic                  Subscriptions              Subscribers
┌───────────┐               ┌─────┐               ┌──────────────┐          ┌────────────┐
│Publisher 1│──publish─────▶│     │──filter────────│Subscription 1│─────────▶│Subscriber 1│
│(Orders)   │               │     │               │(All Orders)  │          │(Warehouse) │
└───────────┘               │     │               └──────────────┘          └────────────┘
┌───────────┐               │Topic│               ┌──────────────┐          ┌────────────┐
│Publisher 2│──publish─────▶│     │──filter────────│Subscription 2│─────────▶│Subscriber 2│
│(Inventory)│               │     │               │(Premium Only)│          │(Analytics) │
└───────────┘               │     │               └──────────────┘          └────────────┘
                            │     │               ┌──────────────┐          ┌────────────┐
                            └─────┘──filter────────│Subscription 3│─────────▶│Subscriber 3│
                                                  │(Local Orders)│          │(Shipping)  │
                                                  └──────────────┘          └────────────┘
```

**Implementation Example:**

```csharp
// Creating Topic and Subscriptions
using Azure.Messaging.ServiceBus.Administration;

ServiceBusAdministrationClient adminClient = new ServiceBusAdministrationClient(connectionString);

// Create Topic
CreateTopicOptions topicOptions = new CreateTopicOptions("orders-topic")
{
    MaxSizeInMegabytes = 1024,
    DefaultMessageTimeToLive = TimeSpan.FromDays(7)
};
await adminClient.CreateTopicAsync(topicOptions);

// Create Subscriptions with Filters
// Subscription 1: All orders
CreateSubscriptionOptions allOrdersSub = new CreateSubscriptionOptions(
    "orders-topic",
    "all-orders-subscription"
);
await adminClient.CreateSubscriptionAsync(allOrdersSub);

// Subscription 2: Premium orders only
CreateSubscriptionOptions premiumSub = new CreateSubscriptionOptions(
    "orders-topic",
    "premium-orders-subscription"
);
CreateRuleOptions premiumRule = new CreateRuleOptions
{
    Filter = new SqlRuleFilter("Premium = 'true' AND TotalAmount > 100"),
    Name = "PremiumOrderFilter"
};
await adminClient.CreateSubscriptionAsync(premiumSub, premiumRule);

// Subscription 3: Orders for specific region
CreateSubscriptionOptions regionalSub = new CreateSubscriptionOptions(
    "orders-topic",
    "us-west-subscription"
);
CreateRuleOptions regionalRule = new CreateRuleOptions
{
    Filter = new CorrelationRuleFilter { Subject = "US-West" },
    Name = "RegionalFilter"
};
await adminClient.CreateSubscriptionAsync(regionalSub, regionalRule);

// PUBLISHER: Publishing messages to topic
using Azure.Messaging.ServiceBus;

ServiceBusClient client = new ServiceBusClient(connectionString);
ServiceBusSender sender = client.CreateSender("orders-topic");

// Create message with properties for filtering
ServiceBusMessage message = new ServiceBusMessage(JsonSerializer.Serialize(new
{
    OrderId = "ORD-12345",
    CustomerId = "CUST-789",
    TotalAmount = 299.99,
    Items = new[] { "Laptop", "Mouse" }
}));

// Set properties for filtering
message.ApplicationProperties["Premium"] = "true";
message.ApplicationProperties["TotalAmount"] = 299.99;
message.Subject = "US-West"; // Correlation filter
message.ContentType = "application/json";
message.MessageId = Guid.NewGuid().ToString();

await sender.SendMessageAsync(message);
Console.WriteLine("Message published to topic");

// SUBSCRIBER 1: Warehouse (All Orders)
ServiceBusProcessor allOrdersProcessor = client.CreateProcessor(
    "orders-topic",
    "all-orders-subscription"
);

allOrdersProcessor.ProcessMessageAsync += async args =>
{
    string body = args.Message.Body.ToString();
    Console.WriteLine($"[Warehouse] Received: {body}");

    // Process order for fulfillment
    await ProcessWarehouseOrder(body);

    // Complete the message
    await args.CompleteMessageAsync(args.Message);
};

allOrdersProcessor.ProcessErrorAsync += args =>
{
    Console.WriteLine($"Error: {args.Exception.Message}");
    return Task.CompletedTask;
};

await allOrdersProcessor.StartProcessingAsync();

// SUBSCRIBER 2: Analytics (Premium Orders Only)
ServiceBusProcessor premiumProcessor = client.CreateProcessor(
    "orders-topic",
    "premium-orders-subscription"
);

premiumProcessor.ProcessMessageAsync += async args =>
{
    string body = args.Message.Body.ToString();
    Console.WriteLine($"[Analytics] Received Premium Order: {body}");

    // Analyze premium customer behavior
    await AnalyzePremiumOrder(body);

    await args.CompleteMessageAsync(args.Message);
};

await premiumProcessor.StartProcessingAsync();

// SUBSCRIBER 3: Shipping (Regional Orders)
ServiceBusProcessor regionalProcessor = client.CreateProcessor(
    "orders-topic",
    "us-west-subscription"
);

regionalProcessor.ProcessMessageAsync += async args =>
{
    string body = args.Message.Body.ToString();
    Console.WriteLine($"[Shipping-US-West] Received: {body}");

    // Process shipping for US-West region
    await ProcessRegionalShipping(body, "US-West");

    await args.CompleteMessageAsync(args.Message);
};

await regionalProcessor.StartProcessingAsync();
```

**Filter Types:**

```csharp
// 1. SQL Filter (Most flexible)
SqlRuleFilter sqlFilter = new SqlRuleFilter(
    "TotalAmount > 100 AND (Category = 'Electronics' OR Category = 'Books')"
);

// 2. Correlation Filter (Better performance)
CorrelationRuleFilter correlationFilter = new CorrelationRuleFilter
{
    Subject = "OrderPlaced",
    Properties =
    {
        { "Region", "US-West" },
        { "Priority", "High" }
    }
};

// 3. True Filter (Accepts all messages)
TrueRuleFilter trueFilter = new TrueRuleFilter();

// 4. False Filter (Rejects all messages)
FalseRuleFilter falseFilter = new FalseRuleFilter();
```

### **2. Azure Event Grid Topics (Event-Driven Pub-Sub)**

```csharp
// Publishing to Event Grid Topic
using Azure.Messaging.EventGrid;

EventGridPublisherClient publisher = new EventGridPublisherClient(
    new Uri("https://mytopic.region.eventgrid.azure.net/api/events"),
    new AzureKeyCredential(topicKey)
);

// Publish event
var events = new List<EventGridEvent>
{
    new EventGridEvent(
        subject: "orders/new",
        eventType: "OrderCreated",
        dataVersion: "1.0",
        data: new
        {
            OrderId = "ORD-12345",
            Amount = 299.99
        }
    )
};

await publisher.SendEventsAsync(events);

// Multiple subscribers can register via Event Grid Subscriptions
// Each subscription can have different endpoints:
// - Azure Functions
// - Logic Apps
// - Webhooks
// - Event Hubs
// - Storage Queues
```

### **3. Redis Pub/Sub (Lightweight)**

```csharp
// Redis Pub/Sub (for simple scenarios)
using StackExchange.Redis;

ConnectionMultiplexer redis = ConnectionMultiplexer.Connect("localhost");
ISubscriber subscriber = redis.GetSubscriber();

// Publisher
await subscriber.PublishAsync("orders-channel", "New Order: ORD-12345");

// Subscriber 1
await subscriber.SubscribeAsync("orders-channel", (channel, message) =>
{
    Console.WriteLine($"[Service 1] Received: {message}");
});

// Subscriber 2
await subscriber.SubscribeAsync("orders-channel", (channel, message) =>
{
    Console.WriteLine($"[Service 2] Received: {message}");
});

// Pattern-based subscription
await subscriber.SubscribeAsync("orders-*", (channel, message) =>
{
    Console.WriteLine($"Pattern match on {channel}: {message}");
});
```

**Real-World Example: E-Commerce Order System**

```csharp
public class OrderPublisher
{
    private readonly ServiceBusSender _topicSender;

    public async Task PublishOrderEvent(Order order)
    {
        // Create comprehensive message
        var message = new ServiceBusMessage(JsonSerializer.Serialize(order))
        {
            MessageId = Guid.NewGuid().ToString(),
            Subject = $"Order.{order.Status}",
            ContentType = "application/json",
            CorrelationId = order.OrderId
        };

        // Add properties for filtering
        message.ApplicationProperties["OrderType"] = order.IsPremium ? "Premium" : "Standard";
        message.ApplicationProperties["TotalAmount"] = order.TotalAmount;
        message.ApplicationProperties["Region"] = order.ShippingAddress.Region;
        message.ApplicationProperties["Category"] = order.Category;
        message.ApplicationProperties["CustomerId"] = order.CustomerId;

        // Publish to topic
        await _topicSender.SendMessageAsync(message);

        Console.WriteLine($"Published order {order.OrderId} to topic");
    }
}

// Subscriber 1: Inventory Service (Interested in ALL orders)
public class InventoryService
{
    public async Task SubscribeToOrders()
    {
        var processor = client.CreateProcessor("orders-topic", "inventory-subscription");

        processor.ProcessMessageAsync += async args =>
        {
            var order = JsonSerializer.Deserialize<Order>(args.Message.Body);
            await UpdateInventory(order);
            await args.CompleteMessageAsync(args.Message);
        };

        await processor.StartProcessingAsync();
    }
}

// Subscriber 2: Email Service (Interested in orders > $100)
public class EmailService
{
    // Subscription filter: TotalAmount > 100
    public async Task SubscribeToHighValueOrders()
    {
        var processor = client.CreateProcessor("orders-topic", "email-subscription");

        processor.ProcessMessageAsync += async args =>
        {
            var order = JsonSerializer.Deserialize<Order>(args.Message.Body);
            await SendOrderConfirmationEmail(order);
            await args.CompleteMessageAsync(args.Message);
        };

        await processor.StartProcessingAsync();
    }
}

// Subscriber 3: Analytics Service (Interested in Premium orders only)
public class AnalyticsService
{
    // Subscription filter: OrderType = 'Premium'
    public async Task SubscribeToPremiumOrders()
    {
        var processor = client.CreateProcessor("orders-topic", "analytics-subscription");

        processor.ProcessMessageAsync += async args =>
        {
            var order = JsonSerializer.Deserialize<Order>(args.Message.Body);
            await TrackPremiumCustomerBehavior(order);
            await args.CompleteMessageAsync(args.Message);
        };

        await processor.StartProcessingAsync();
    }
}

// Subscriber 4: Shipping Service (Interested in specific regions)
public class ShippingService
{
    // Subscription filter: Region = 'US-West' OR Region = 'US-East'
    public async Task SubscribeToRegionalOrders()
    {
        var processor = client.CreateProcessor("orders-topic", "shipping-us-subscription");

        processor.ProcessMessageAsync += async args =>
        {
            var order = JsonSerializer.Deserialize<Order>(args.Message.Body);
            string region = args.Message.ApplicationProperties["Region"].ToString();
            await CreateShipment(order, region);
            await args.CompleteMessageAsync(args.Message);
        };

        await processor.StartProcessingAsync();
    }
}
```

**Benefits of Pub-Sub Pattern:**

1. **Loose Coupling**: Publishers and subscribers are independent
2. **Scalability**: Add/remove subscribers without affecting publishers
3. **Flexibility**: Subscribers can filter messages based on criteria
4. **Reliability**: Messages are delivered even if subscribers are temporarily down
5. **Multiple Consumers**: Same message can be processed by multiple services
6. **Maintainability**: Easy to add new functionality by adding subscribers

**Visual Comparison:**

```
Traditional Point-to-Point (Tightly Coupled):
┌──────────┐     ┌──────────┐
│ Service A│────▶│ Service B│
│          │     └──────────┘
│          │     ┌──────────┐
│          │────▶│ Service C│
│          │     └──────────┘
│          │     ┌──────────┐
│          │────▶│ Service D│
└──────────┘     └──────────┘

Service A must know about all consumers!

Pub-Sub (Loosely Coupled):
┌──────────┐     ┌───────┐     ┌──────────┐
│ Service A│────▶│ Topic │────▶│ Service B│
│(Publisher│     │       │     │(Subscriber│
│          │     │       │     └──────────┘
└──────────┘     │       │     ┌──────────┐
                 │       │────▶│ Service C│
                 │       │     │(Subscriber│
                 │       │     └──────────┘
                 │       │     ┌──────────┐
                 └───────┘────▶│ Service D│
                               │(Subscriber│
                               └──────────┘

Publisher doesn't know about subscribers!
```

**Best Practices:**

1. **Message Design**: Include all necessary data to avoid callback queries
2. **Idempotency**: Subscribers should handle duplicate messages gracefully
3. **Error Handling**: Use dead-letter queues for failed messages
4. **Monitoring**: Track message flow and subscription health
5. **Filter Optimization**: Use correlation filters for better performance than SQL filters
6. **Naming Conventions**: Use clear topic and subscription names
7. **TTL Configuration**: Set appropriate time-to-live for messages
8. **Retry Policies**: Configure exponential backoff for transient failures

---

## **Q104: What is Azure Redis Cache? How do you implement it?**

### **Answer:**

Azure Redis Cache (Azure Cache for Redis) is a fully managed, in-memory data store based on the open-source Redis software. It provides high-performance caching, session storage, and real-time analytics capabilities for applications.

**Key Features:**

1. **In-Memory Performance**: Sub-millisecond latency
2. **Distributed Cache**: Shared across multiple application instances
3. **Data Structures**: Strings, hashes, lists, sets, sorted sets, bitmaps, hyperloglogs
4. **Persistence Options**: RDB snapshots and AOF logs
5. **High Availability**: Built-in replication and failover
6. **Scaling**: Multiple tiers (Basic, Standard, Premium, Enterprise)
7. **Security**: VNet integration, SSL/TLS, Azure AD authentication
8. **Clustering**: Multi-shard deployments for horizontal scaling

**Service Tiers:**

| Tier | Features | Use Case |
|------|----------|----------|
| **Basic** | Single node, no SLA | Dev/Test |
| **Standard** | 2 nodes, 99.9% SLA, replication | Production |
| **Premium** | Clustering, persistence, VNet | Enterprise, high performance |
| **Enterprise** | Redis Enterprise features, 99.99% SLA | Mission-critical |

**Implementation in ASP.NET Core:**

```csharp
// 1. Install NuGet Package
// Microsoft.Extensions.Caching.StackExchangeRedis
// StackExchange.Redis

// 2. Configure in Program.cs / Startup.cs
using Microsoft.Extensions.Caching.Distributed;
using StackExchange.Redis;

public class Program
{
    public static void Main(string[] args)
    {
        var builder = WebApplication.CreateBuilder(args);

        // Add Redis Cache
        builder.Services.AddStackExchangeRedisCache(options =>
        {
            options.Configuration = builder.Configuration.GetConnectionString("RedisConnection");
            options.InstanceName = "MyApp_";
        });

        // Alternative: Configure with detailed options
        builder.Services.AddStackExchangeRedisCache(options =>
        {
            options.ConfigurationOptions = new ConfigurationOptions
            {
                EndPoints = { "mycache.redis.cache.windows.net:6380" },
                Password = "your-access-key",
                Ssl = true,
                AbortOnConnectFail = false,
                ConnectTimeout = 5000,
                SyncTimeout = 5000
            };
            options.InstanceName = "MyApp_";
        });

        builder.Services.AddControllers();
        var app = builder.Build();
        app.MapControllers();
        app.Run();
    }
}

// 3. appsettings.json Configuration
{
    "ConnectionStrings": {
        "RedisConnection": "mycache.redis.cache.windows.net:6380,password=your-access-key,ssl=True,abortConnect=False"
    }
}
```

**Basic Usage with IDistributedCache:**

```csharp
using Microsoft.Extensions.Caching.Distributed;
using System.Text.Json;

public class ProductService
{
    private readonly IDistributedCache _cache;
    private readonly IProductRepository _repository;

    public ProductService(IDistributedCache cache, IProductRepository repository)
    {
        _cache = cache;
        _repository = repository;
    }

    // Cache-Aside Pattern (Lazy Loading)
    public async Task<Product> GetProductByIdAsync(int productId)
    {
        string cacheKey = $"product_{productId}";

        // Try to get from cache
        string cachedProduct = await _cache.GetStringAsync(cacheKey);

        if (!string.IsNullOrEmpty(cachedProduct))
        {
            Console.WriteLine("Cache HIT");
            return JsonSerializer.Deserialize<Product>(cachedProduct);
        }

        Console.WriteLine("Cache MISS - Fetching from database");

        // Get from database
        var product = await _repository.GetByIdAsync(productId);

        if (product != null)
        {
            // Store in cache
            var cacheOptions = new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10),
                SlidingExpiration = TimeSpan.FromMinutes(2)
            };

            await _cache.SetStringAsync(
                cacheKey,
                JsonSerializer.Serialize(product),
                cacheOptions
            );
        }

        return product;
    }

    // Update cache when data changes
    public async Task UpdateProductAsync(Product product)
    {
        // Update database
        await _repository.UpdateAsync(product);

        // Update cache (Write-Through pattern)
        string cacheKey = $"product_{product.Id}";
        var cacheOptions = new DistributedCacheEntryOptions
        {
            AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10)
        };

        await _cache.SetStringAsync(
            cacheKey,
            JsonSerializer.Serialize(product),
            cacheOptions
        );
    }

    // Remove from cache
    public async Task DeleteProductAsync(int productId)
    {
        await _repository.DeleteAsync(productId);

        // Invalidate cache
        string cacheKey = $"product_{productId}";
        await _cache.RemoveAsync(cacheKey);
    }

    // Caching collections
    public async Task<List<Product>> GetAllProductsAsync()
    {
        string cacheKey = "products_all";

        string cachedProducts = await _cache.GetStringAsync(cacheKey);

        if (!string.IsNullOrEmpty(cachedProducts))
        {
            return JsonSerializer.Deserialize<List<Product>>(cachedProducts);
        }

        var products = await _repository.GetAllAsync();

        await _cache.SetStringAsync(
            cacheKey,
            JsonSerializer.Serialize(products),
            new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(5)
            }
        );

        return products;
    }
}
```

**Advanced Usage with StackExchange.Redis:**

```csharp
using StackExchange.Redis;

public class RedisCacheService
{
    private readonly IConnectionMultiplexer _redis;
    private readonly IDatabase _db;

    public RedisCacheService(IConnectionMultiplexer redis)
    {
        _redis = redis;
        _db = redis.GetDatabase();
    }

    // String Operations
    public async Task SetStringAsync(string key, string value, TimeSpan? expiry = null)
    {
        await _db.StringSetAsync(key, value, expiry);
    }

    public async Task<string> GetStringAsync(string key)
    {
        return await _db.StringGetAsync(key);
    }

    // Hash Operations (for complex objects)
    public async Task SetHashAsync<T>(string key, T obj) where T : class
    {
        var properties = typeof(T).GetProperties();
        var hashEntries = properties.Select(p =>
            new HashEntry(p.Name, p.GetValue(obj)?.ToString() ?? "")
        ).ToArray();

        await _db.HashSetAsync(key, hashEntries);
    }

    public async Task<T> GetHashAsync<T>(string key) where T : class, new()
    {
        var hashEntries = await _db.HashGetAllAsync(key);
        if (hashEntries.Length == 0) return null;

        var obj = new T();
        var properties = typeof(T).GetProperties();

        foreach (var property in properties)
        {
            var entry = hashEntries.FirstOrDefault(e => e.Name == property.Name);
            if (entry != default(HashEntry))
            {
                var value = Convert.ChangeType(entry.Value.ToString(), property.PropertyType);
                property.SetValue(obj, value);
            }
        }

        return obj;
    }

    // List Operations
    public async Task AddToListAsync(string key, string value)
    {
        await _db.ListRightPushAsync(key, value);
    }

    public async Task<string[]> GetListAsync(string key)
    {
        var values = await _db.ListRangeAsync(key);
        return values.Select(v => v.ToString()).ToArray();
    }

    // Set Operations
    public async Task AddToSetAsync(string key, string value)
    {
        await _db.SetAddAsync(key, value);
    }

    public async Task<bool> IsInSetAsync(string key, string value)
    {
        return await _db.SetContainsAsync(key, value);
    }

    // Sorted Set (Leaderboard example)
    public async Task AddToSortedSetAsync(string key, string member, double score)
    {
        await _db.SortedSetAddAsync(key, member, score);
    }

    public async Task<SortedSetEntry[]> GetTopFromSortedSetAsync(string key, int count)
    {
        return await _db.SortedSetRangeByRankWithScoresAsync(
            key,
            0,
            count - 1,
            Order.Descending
        );
    }

    // Cache with Sliding Expiration (using Lua script)
    public async Task<string> GetWithSlidingExpirationAsync(string key, TimeSpan slidingExpiration)
    {
        var value = await _db.StringGetAsync(key);

        if (!value.IsNullOrEmpty)
        {
            // Refresh expiration
            await _db.KeyExpireAsync(key, slidingExpiration);
        }

        return value;
    }

    // Pattern-based deletion (e.g., delete all user-related cache)
    public async Task DeleteByPatternAsync(string pattern)
    {
        var endpoints = _redis.GetEndPoints();
        var server = _redis.GetServer(endpoints.First());

        var keys = server.Keys(pattern: pattern);
        foreach (var key in keys)
        {
            await _db.KeyDeleteAsync(key);
        }
    }

    // Atomic increment (useful for counters, rate limiting)
    public async Task<long> IncrementAsync(string key, long value = 1)
    {
        return await _db.StringIncrementAsync(key, value);
    }

    // Check if key exists
    public async Task<bool> ExistsAsync(string key)
    {
        return await _db.KeyExistsAsync(key);
    }

    // Get remaining time to live
    public async Task<TimeSpan?> GetTimeToLiveAsync(string key)
    {
        return await _db.KeyTimeToLiveAsync(key);
    }
}
```

**Session State with Redis:**

```csharp
// Configure session with Redis
builder.Services.AddSession(options =>
{
    options.IdleTimeout = TimeSpan.FromMinutes(30);
    options.Cookie.HttpOnly = true;
    options.Cookie.IsEssential = true;
});

builder.Services.AddStackExchangeRedisCache(options =>
{
    options.Configuration = "your-redis-connection-string";
    options.InstanceName = "Session_";
});

// Usage in controller
public class ShoppingCartController : Controller
{
    public IActionResult AddToCart(int productId)
    {
        // Store in session (backed by Redis)
        var cart = HttpContext.Session.GetString("Cart");
        List<int> cartItems = string.IsNullOrEmpty(cart)
            ? new List<int>()
            : JsonSerializer.Deserialize<List<int>>(cart);

        cartItems.Add(productId);
        HttpContext.Session.SetString("Cart", JsonSerializer.Serialize(cartItems));

        return Ok();
    }

    public IActionResult GetCart()
    {
        var cart = HttpContext.Session.GetString("Cart");
        return Ok(cart);
    }
}
```

**Real-World Example: E-Commerce Product Catalog Cache:**

```csharp
public class ProductCacheManager
{
    private readonly IDatabase _cache;
    private readonly IProductRepository _repository;
    private const int CacheExpirationMinutes = 15;

    public async Task<Product> GetProductAsync(int productId)
    {
        string cacheKey = $"product:{productId}";

        // Try cache first
        var cachedProduct = await _cache.StringGetAsync(cacheKey);

        if (!cachedProduct.IsNullOrEmpty)
        {
            return JsonSerializer.Deserialize<Product>(cachedProduct);
        }

        // Cache miss - get from database
        var product = await _repository.GetByIdAsync(productId);

        if (product != null)
        {
            // Store in cache
            await _cache.StringSetAsync(
                cacheKey,
                JsonSerializer.Serialize(product),
                TimeSpan.FromMinutes(CacheExpirationMinutes)
            );
        }

        return product;
    }

    // Cache product search results
    public async Task<List<Product>> SearchProductsAsync(string searchTerm)
    {
        string cacheKey = $"search:{searchTerm.ToLower()}";

        var cached = await _cache.StringGetAsync(cacheKey);

        if (!cached.IsNullOrEmpty)
        {
            return JsonSerializer.Deserialize<List<Product>>(cached);
        }

        var results = await _repository.SearchAsync(searchTerm);

        await _cache.StringSetAsync(
            cacheKey,
            JsonSerializer.Serialize(results),
            TimeSpan.FromMinutes(5) // Shorter expiration for search results
        );

        return results;
    }

    // Leaderboard using Sorted Set
    public async Task UpdateProductPopularityAsync(int productId, int viewCount)
    {
        await _cache.SortedSetAddAsync(
            "popular_products",
            productId.ToString(),
            viewCount
        );
    }

    public async Task<List<int>> GetTopPopularProductsAsync(int count = 10)
    {
        var topProducts = await _cache.SortedSetRangeByRankAsync(
            "popular_products",
            0,
            count - 1,
            Order.Descending
        );

        return topProducts.Select(p => int.Parse(p)).ToList();
    }

    // Cache invalidation when product is updated
    public async Task InvalidateProductCacheAsync(int productId)
    {
        string cacheKey = $"product:{productId}";
        await _cache.KeyDeleteAsync(cacheKey);

        // Also invalidate related caches
        await _cache.KeyDeleteAsync("products:all");
        await _cache.KeyDeleteAsync($"category:{productId}");
    }
}
```

**Rate Limiting with Redis:**

```csharp
public class RateLimiter
{
    private readonly IDatabase _cache;

    public async Task<bool> IsRequestAllowedAsync(string userId, int maxRequests, TimeSpan timeWindow)
    {
        string key = $"rate_limit:{userId}";

        // Increment counter
        long requestCount = await _cache.StringIncrementAsync(key);

        // Set expiration on first request
        if (requestCount == 1)
        {
            await _cache.KeyExpireAsync(key, timeWindow);
        }

        return requestCount <= maxRequests;
    }
}

// Usage in middleware
public class RateLimitingMiddleware
{
    private readonly RequestDelegate _next;
    private readonly RateLimiter _rateLimiter;

    public async Task InvokeAsync(HttpContext context)
    {
        var userId = context.User.Identity.Name ?? context.Connection.RemoteIpAddress.ToString();

        // 100 requests per minute per user
        if (!await _rateLimiter.IsRequestAllowedAsync(
            userId,
            maxRequests: 100,
            timeWindow: TimeSpan.FromMinutes(1)))
        {
            context.Response.StatusCode = 429; // Too Many Requests
            await context.Response.WriteAsync("Rate limit exceeded");
            return;
        }

        await _next(context);
    }
}
```

**Visual Architecture:**

```
Redis Cache Architecture

Application Tier                Cache Tier               Data Tier
┌─────────────────┐           ┌──────────────┐        ┌──────────┐
│  Web App        │           │              │        │          │
│  Instance 1     │──read────▶│  Azure       │        │  Azure   │
│                 │◀──data────│  Cache for   │        │  SQL DB  │
└─────────────────┘           │  Redis       │        │          │
┌─────────────────┐           │              │        │          │
│  Web App        │──read────▶│  Standard    │        │          │
│  Instance 2     │◀──data────│  Tier        │        │          │
│                 │           │              │        │          │
└─────────────────┘           │  - Primary   │        │          │
┌─────────────────┐           │  - Replica   │        │          │
│  Web App        │──read────▶│              │        │          │
│  Instance 3     │◀──data────│  99.9% SLA   │        │          │
└─────────────────┘           └──────────────┘        └──────────┘
                                     ▲                      │
                                     │                      │
                              Cache Miss: Fetch from DB     │
                              Cache Hit: Return immediately │
                                     └──────────────────────┘
```

**Performance Improvements:**

```
Without Redis Cache:
Request → Database → Response
Latency: 50-200ms per request
Database load: High

With Redis Cache:
Request → Redis (Cache Hit) → Response
Latency: 1-5ms per request
Database load: Reduced by 80-95%

Cache Miss scenario:
Request → Redis (Miss) → Database → Cache Update → Response
First request: 50-200ms
Subsequent requests: 1-5ms
```

**Best Practices:**

1. **Key Naming**: Use consistent naming conventions (e.g., `{entity}:{id}`)
2. **Expiration**: Always set appropriate TTL to avoid stale data
3. **Serialization**: Use efficient serialization (JSON, MessagePack)
4. **Connection Management**: Reuse connections (singleton IConnectionMultiplexer)
5. **Error Handling**: Cache failures shouldn't crash the application
6. **Monitoring**: Track cache hit/miss ratio, memory usage
7. **Data Size**: Keep cached objects small (<100 KB ideal)
8. **Eviction Policy**: Configure appropriate eviction policy (allkeys-lru recommended)

---

## **Q105: Explain caching strategies: Cache-aside, Write-through, Write-behind.**

### **Answer:**

Caching strategies determine how and when data is loaded into and written from the cache. Choosing the right strategy depends on your application's read/write patterns, consistency requirements, and performance goals.

### **1. Cache-Aside (Lazy Loading)**

Also known as "Lazy Loading" or "Read-Through on Miss" - the application manages the cache explicitly.

**How it Works:**

```
Read Flow:
1. Application checks cache
2. If CACHE HIT → return data
3. If CACHE MISS → fetch from database
4. Store in cache
5. Return data

Write Flow:
1. Write to database
2. Invalidate (delete) cache entry
3. Next read will load fresh data
```

**Visual Representation:**

```
Cache-Aside Pattern

┌──────────────┐
│ Application  │
└───┬─────┬────┘
    │     │
    │ 1. Read Request
    ▼     │
┌────────┴─────┐
│   Cache      │
│              │
│ Hit? ──Yes──▶│──2. Return cached data
│  │           │
│  No          │
│  │           │
└──┼───────────┘
   │ 3. Cache Miss
   ▼
┌──────────────┐
│  Database    │
│              │
│ 4. Fetch data│
└──────┬───────┘
       │
       │ 5. Store in cache
       ▼ 6. Return data
┌──────────────┐
│ Application  │
└──────────────┘
```

**Implementation:**

```csharp
public class CacheAsideService
{
    private readonly IDistributedCache _cache;
    private readonly IDatabase _database;

    public async Task<Product> GetProductAsync(int productId)
    {
        string cacheKey = $"product:{productId}";

        // 1. Try to get from cache
        var cachedData = await _cache.GetStringAsync(cacheKey);

        if (!string.IsNullOrEmpty(cachedData))
        {
            // 2. Cache HIT
            Console.WriteLine("Cache HIT");
            return JsonSerializer.Deserialize<Product>(cachedData);
        }

        // 3. Cache MISS - Load from database
        Console.WriteLine("Cache MISS");
        var product = await _database.Products.FindAsync(productId);

        if (product != null)
        {
            // 4. Store in cache for future requests
            await _cache.SetStringAsync(
                cacheKey,
                JsonSerializer.Serialize(product),
                new DistributedCacheEntryOptions
                {
                    AbsoluteExpirationRelativeToNow = TimeSpan.FromMinutes(10)
                }
            );
        }

        // 5. Return data
        return product;
    }

    public async Task UpdateProductAsync(Product product)
    {
        // 1. Update database
        await _database.UpdateAsync(product);
        await _database.SaveChangesAsync();

        // 2. Invalidate cache (lazy loading will refresh on next read)
        string cacheKey = $"product:{product.Id}";
        await _cache.RemoveAsync(cacheKey);
    }
}
```

**Pros:**
✅ Simple to implement
✅ Only requested data is cached (efficient memory usage)
✅ Cache failures don't prevent data access
✅ Application has full control

**Cons:**
❌ Cache miss penalty (3 trips: check cache, read DB, write cache)
❌ Potential for stale data until cache expires
❌ Cache stampede risk (multiple simultaneous misses)

**Best For:**
- Read-heavy workloads
- Infrequently changing data
- When cache availability isn't critical

---

### **2. Write-Through Cache**

Data is written to both cache and database simultaneously. Cache is always synchronized with the database.

**How it Works:**

```
Write Flow:
1. Write to cache AND database (synchronously)
2. Confirm after both complete
3. Data is always in cache

Read Flow:
1. Read from cache (data always present)
2. If miss (rare), load from database
```

**Visual Representation:**

```
Write-Through Pattern

Write Operation:
┌──────────────┐
│ Application  │
└───┬──────────┘
    │ 1. Write Request
    ├─────────┬─────────┐
    ▼         ▼         │
┌────────┐ ┌────────┐  │
│ Cache  │ │Database│  │
│        │ │        │  │
│2.Write │ │2.Write │  │
└────┬───┘ └───┬────┘  │
     │         │        │
     └────┬────┘        │
          │3. Both complete
          ▼
    ┌──────────────┐
    │ Confirm      │
    └──────────────┘

Read Operation:
┌──────────────┐
│ Application  │
└───┬──────────┘
    │ 1. Read
    ▼
┌────────┐
│ Cache  │──2. Return data (always present)
└────────┘
```

**Implementation:**

```csharp
public class WriteThroughCacheService
{
    private readonly IDistributedCache _cache;
    private readonly IDatabase _database;

    public async Task<Product> GetProductAsync(int productId)
    {
        string cacheKey = $"product:{productId}";

        // Cache should always have the data
        var cachedData = await _cache.GetStringAsync(cacheKey);

        if (!string.IsNullOrEmpty(cachedData))
        {
            return JsonSerializer.Deserialize<Product>(cachedData);
        }

        // Rare cache miss (cache cleared, or first access)
        var product = await _database.Products.FindAsync(productId);

        if (product != null)
        {
            await _cache.SetStringAsync(
                cacheKey,
                JsonSerializer.Serialize(product),
                new DistributedCacheEntryOptions
                {
                    AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(24)
                }
            );
        }

        return product;
    }

    public async Task UpdateProductAsync(Product product)
    {
        string cacheKey = $"product:{product.Id}";

        // Write to BOTH cache and database
        var cacheTask = _cache.SetStringAsync(
            cacheKey,
            JsonSerializer.Serialize(product),
            new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(24)
            }
        );

        var dbTask = Task.Run(async () =>
        {
            _database.Update(product);
            await _database.SaveChangesAsync();
        });

        // Wait for both to complete
        await Task.WhenAll(cacheTask, dbTask);
    }

    public async Task CreateProductAsync(Product product)
    {
        // 1. Save to database first to get ID
        await _database.Products.AddAsync(product);
        await _database.SaveChangesAsync();

        // 2. Immediately cache it
        string cacheKey = $"product:{product.Id}";
        await _cache.SetStringAsync(
            cacheKey,
            JsonSerializer.Serialize(product),
            new DistributedCacheEntryOptions
            {
                AbsoluteExpirationRelativeToNow = TimeSpan.FromHours(24)
            }
        );
    }
}
```

**Pros:**
✅ Cache and database always in sync
✅ Read operations are always fast (cache always has data)
✅ No stale data issues
✅ Predictable performance

**Cons:**
❌ Write latency (must wait for both cache and database)
❌ Wasted cache space (everything is cached, even rarely-read data)
❌ Write operations are slower
❌ If cache write fails, need rollback strategy

**Best For:**
- Read-heavy workloads with occasional writes
- Strong consistency requirements
- Small, frequently-accessed datasets

---

### **3. Write-Behind (Write-Back) Cache**

Data is written to cache immediately, and database write is queued/deferred. Database is updated asynchronously.

**How it Works:**

```
Write Flow:
1. Write to cache immediately
2. Acknowledge write to application
3. Queue database write (async)
4. Batch writes to database periodically

Read Flow:
1. Read from cache (always has latest)
2. If miss, load from database
```

**Visual Representation:**

```
Write-Behind Pattern

Write Operation:
┌──────────────┐
│ Application  │
└───┬──────────┘
    │ 1. Write Request
    ▼
┌────────────┐
│   Cache    │ 2. Write immediately
│            │
│            │ 3. Return success (fast!)
└─────┬──────┘
      │ 4. Queue async write
      ▼
┌────────────┐
│Write Queue │
└─────┬──────┘
      │ 5. Batch writes (periodic)
      ▼
┌────────────┐
│  Database  │
└────────────┘

Read Operation:
┌──────────────┐
│ Application  │
└───┬──────────┘
    │ Read
    ▼
┌────────────┐
│   Cache    │──Return (has latest data)
└────────────┘
```

**Implementation:**

```csharp
public class WriteBehindCacheService
{
    private readonly IDistributedCache _cache;
    private readonly IDatabase _database;
    private readonly IBackgroundTaskQueue _writeQueue;

    public async Task<Product> GetProductAsync(int productId)
    {
        string cacheKey = $"product:{productId}";

        // Always read from cache first
        var cachedData = await _cache.GetStringAsync(cacheKey);

        if (!string.IsNullOrEmpty(cachedData))
        {
            return JsonSerializer.Deserialize<Product>(cachedData);
        }

        // Load from database if not in cache
        var product = await _database.Products.FindAsync(productId);

        if (product != null)
        {
            await _cache.SetStringAsync(
                cacheKey,
                JsonSerializer.Serialize(product)
            );
        }

        return product;
    }

    public async Task UpdateProductAsync(Product product)
    {
        string cacheKey = $"product:{product.Id}";

        // 1. Write to cache immediately (fast)
        await _cache.SetStringAsync(
            cacheKey,
            JsonSerializer.Serialize(product)
        );

        // 2. Queue the database write (async)
        _writeQueue.QueueBackgroundWorkItem(async token =>
        {
            try
            {
                _database.Update(product);
                await _database.SaveChangesAsync();
                Console.WriteLine($"Product {product.Id} persisted to database");
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error persisting product {product.Id}: {ex.Message}");
                // Implement retry logic or dead-letter queue
            }
        });

        // 3. Return immediately (application doesn't wait for database)
    }
}

// Background service to process queued writes
public class DatabaseWriterService : BackgroundService
{
    private readonly IBackgroundTaskQueue _taskQueue;
    private readonly IDatabase _database;
    private readonly List<object> _writeBuffer = new();
    private readonly SemaphoreSlim _semaphore = new(1);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            // Process writes every 5 seconds (batch)
            await Task.Delay(TimeSpan.FromSeconds(5), stoppingToken);

            await _semaphore.WaitAsync(stoppingToken);
            try
            {
                if (_writeBuffer.Any())
                {
                    // Batch write to database
                    await _database.BulkUpdateAsync(_writeBuffer);
                    await _database.SaveChangesAsync();

                    Console.WriteLine($"Batch wrote {_writeBuffer.Count} items to database");
                    _writeBuffer.Clear();
                }
            }
            finally
            {
                _semaphore.Release();
            }
        }
    }

    public async Task QueueWrite(object entity)
    {
        await _semaphore.WaitAsync();
        try
        {
            _writeBuffer.Add(entity);
        }
        finally
        {
            _semaphore.Release();
        }
    }
}
```

**Advanced Write-Behind with Change Tracking:**

```csharp
public class AdvancedWriteBehindCache
{
    private readonly IConnectionMultiplexer _redis;
    private readonly IDatabase _cache;
    private readonly IDatabase _database;

    public async Task UpdateProductAsync(Product product)
    {
        string cacheKey = $"product:{product.Id}";
        string dirtySetKey = "dirty_products";

        // 1. Update cache
        await _cache.StringSetAsync(
            cacheKey,
            JsonSerializer.Serialize(product)
        );

        // 2. Mark as dirty (needs database write)
        await _cache.SetAddAsync(dirtySetKey, product.Id.ToString());

        // Background job will flush dirty items periodically
    }

    // Background job that runs periodically
    public async Task FlushDirtyItemsAsync()
    {
        string dirtySetKey = "dirty_products";

        // Get all dirty product IDs
        var dirtyIds = await _cache.SetMembersAsync(dirtySetKey);

        if (!dirtyIds.Any())
            return;

        var products = new List<Product>();

        foreach (var id in dirtyIds)
        {
            string cacheKey = $"product:{id}";
            var cachedData = await _cache.StringGetAsync(cacheKey);

            if (!cachedData.IsNullOrEmpty)
            {
                products.Add(JsonSerializer.Deserialize<Product>(cachedData));
            }
        }

        // Batch write to database
        if (products.Any())
        {
            _database.Products.UpdateRange(products);
            await _database.SaveChangesAsync();

            // Clear dirty set
            await _cache.KeyDeleteAsync(dirtySetKey);

            Console.WriteLine($"Flushed {products.Count} products to database");
        }
    }
}

// Hosted service
public class CacheFlushService : BackgroundService
{
    private readonly AdvancedWriteBehindCache _cache;

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        while (!stoppingToken.IsCancellationRequested)
        {
            await Task.Delay(TimeSpan.FromSeconds(10), stoppingToken);
            await _cache.FlushDirtyItemsAsync();
        }
    }
}
```

**Pros:**
✅ Extremely fast writes (only cache latency)
✅ Reduced database load (batch writes)
✅ Better throughput for write-heavy workloads
✅ Can handle database temporary unavailability

**Cons:**
❌ Risk of data loss if cache fails before database write
❌ Complex implementation
❌ Eventual consistency (database lags behind cache)
❌ Need persistence/queue for reliability

**Best For:**
- Write-heavy workloads
- High-throughput scenarios
- When eventual consistency is acceptable
- Gaming leaderboards, counters, analytics

---

### **Comparison Table:**

| Aspect | Cache-Aside | Write-Through | Write-Behind |
|--------|-------------|---------------|--------------|
| **Write Speed** | Fast | Slow (dual write) | Fastest |
| **Read Speed** | Fast (on hit) | Fastest (always cached) | Fastest |
| **Consistency** | Eventual | Strong | Eventual |
| **Complexity** | Low | Medium | High |
| **Data Loss Risk** | Low | Low | Medium-High |
| **Database Load** | Low (writes direct) | Higher | Lowest (batched) |
| **Use Case** | General purpose | Read-heavy, consistency | Write-heavy |
| **Cache Miss** | Common | Rare | Rare |
| **Implementation** | Application | Application or Proxy | Background service needed |

---

### **Real-World Example: E-Commerce Scenarios**

```csharp
// Product Catalog: Cache-Aside (read-heavy, infrequent updates)
public class ProductCatalogService
{
    // Most reads, few writes - Cache-Aside is perfect
    public async Task<Product> GetProduct(int id)
    {
        return await CacheAsideGetAsync($"product:{id}",
            () => _db.Products.FindAsync(id));
    }
}

// Shopping Cart: Write-Through (need consistency)
public class ShoppingCartService
{
    // Critical data, must be consistent - Write-Through
    public async Task UpdateCart(Cart cart)
    {
        await Task.WhenAll(
            _cache.SetAsync($"cart:{cart.UserId}", cart),
            _db.SaveCartAsync(cart)
        );
    }
}

// Page Views/Analytics: Write-Behind (high write volume)
public class AnalyticsService
{
    // Millions of writes, eventual consistency OK - Write-Behind
    public async Task TrackPageView(string userId, string page)
    {
        await _cache.IncrementAsync($"views:{page}:{DateTime.UtcNow:yyyyMMdd}");
        _writeQueue.QueueDatabaseWrite(new PageView { UserId = userId, Page = page });
    }
}
```

---

## **Q106: What is Azure SQL Database? How does it differ from SQL Server on VM?**

### **Answer:**

Azure SQL Database is a fully managed Platform-as-a-Service (PaaS) relational database service in Azure, based on the latest stable version of Microsoft SQL Server. It provides a cloud-based alternative to traditional SQL Server installations.

**Key Features of Azure SQL Database:**

1. **Fully Managed**: Automated backups, patching, monitoring
2. **High Availability**: 99.99% SLA built-in
3. **Intelligent Performance**: Automatic tuning recommendations
4. **Scalability**: Scale up/down on-demand
5. **Security**: Advanced threat protection, encryption
6. **Global Distribution**: Geo-replication support
7. **Cost-Effective**: Pay only for what you use

### **Azure SQL Database vs SQL Server on VM:**

| Aspect | Azure SQL Database (PaaS) | SQL Server on Azure VM (IaaS) |
|--------|---------------------------|-------------------------------|
| **Management** | Fully managed by Microsoft | You manage OS, SQL Server |
| **Control** | Limited (PaaS restrictions) | Full control (sysadmin access) |
| **Patching** | Automatic | Manual (you schedule) |
| **Backups** | Automatic, built-in | Configure yourself |
| **High Availability** | Built-in (99.99% SLA) | Configure yourself (Always On, etc.) |
| **Scaling** | Elastic, on-demand | Requires downtime or manual setup |
| **Cost** | Lower (no VM costs) | Higher (VM + storage + license) |
| **SQL Features** | Most features (some limitations) | All SQL Server features |
| **Maintenance Window** | Managed by Azure | You control |
| **CLR Support** | Limited | Full support |
| **Linked Servers** | Not supported | Fully supported |
| **SQL Agent Jobs** | Elastic Jobs | Full SQL Agent |
| **File System Access** | No | Yes |
| **Pricing Model** | DTU or vCore | VM size + license |

**Deployment Options:**

```
Azure SQL Offerings:

1. Azure SQL Database (PaaS)
   ├─ Single Database (standalone)
   ├─ Elastic Pool (multiple DBs sharing resources)
   └─ Hyperscale (100TB+, fast scale)

2. Azure SQL Managed Instance (PaaS+)
   └─ Near 100% SQL Server compatibility
      (supports SQL Agent, CLR, linked servers)

3. SQL Server on Azure VMs (IaaS)
   └─ Full SQL Server on Windows/Linux VM
      (complete control, all features)
```

**Purchasing Models:**

### **1. DTU-Based Model (Database Transaction Units)**

```
DTU = CPU + Memory + I/O combined metric

Service Tiers:
┌─────────────┬───────────┬──────────────┬─────────────┐
│ Tier        │ DTUs      │ Max DB Size  │ Use Case    │
├─────────────┼───────────┼──────────────┼─────────────┤
│ Basic       │ 5         │ 2 GB         │ Dev/Test    │
│ Standard    │ 10-3000   │ 1 TB         │ Production  │
│ Premium     │ 125-4000  │ 4 TB         │ High perf   │
└─────────────┴───────────┴──────────────┴─────────────┘
```

### **2. vCore-Based Model (More flexible)**

```
Service Tiers:
┌──────────────┬─────────────┬──────────────┬─────────────┐
│ Tier         │ Compute     │ Max Size     │ Use Case    │
├──────────────┼─────────────┼──────────────┼─────────────┤
│ General      │ 2-80 vCores │ 4 TB         │ Most apps   │
│ Purpose      │             │              │             │
├──────────────┼─────────────┼──────────────┼─────────────┤
│ Business     │ 2-80 vCores │ 4 TB         │ High IOPS,  │
│ Critical     │             │              │ low latency │
├──────────────┼─────────────┼──────────────┼─────────────┤
│ Hyperscale   │ 2-80 vCores │ 100+ TB      │ Very large  │
│              │             │              │ databases   │
└──────────────┴─────────────┴──────────────┴─────────────┘
```

**Connection Example:**

```csharp
// Connection String
{
    "ConnectionStrings": {
        "DefaultConnection": "Server=tcp:myserver.database.windows.net,1433;Database=mydb;User ID=admin;Password=P@ssw0rd;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    }
}

// Using Entity Framework Core
public class ApplicationDbContext : DbContext
{
    public ApplicationDbContext(DbContextOptions<ApplicationDbContext> options)
        : base(options)
    {
    }

    public DbSet<Product> Products { get; set; }
    public DbSet<Order> Orders { get; set; }
}

// Startup/Program.cs
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection"),
        sqlOptions =>
        {
            sqlOptions.EnableRetryOnFailure(
                maxRetryCount: 5,
                maxRetryDelay: TimeSpan.FromSeconds(30),
                errorNumbersToAdd: null
            );
        }
    )
);
```

**Advanced Features:**

### **1. Geo-Replication (Disaster Recovery)**

```csharp
// Configure using Azure Portal, PowerShell, or Azure CLI
# Create geo-replica
az sql db replica create \
    --resource-group myResourceGroup \
    --server myPrimaryServer \
    --name myDatabase \
    --partner-resource-group mySecondaryRG \
    --partner-server mySecondaryServer \
    --service-objective S3

// Connection with failover groups
Server=tcp:myserver-failover-group.database.windows.net,1433;
Database=mydb;
User ID=admin;
Password=P@ssw0rd;
Encrypt=True;
```

**Visual Architecture:**

```
Azure SQL Database Deployment Options

┌─────────────────────────────────────────────────┐
│ Azure SQL Database (PaaS)                       │
│                                                 │
│ ┌─────────────────┐  ┌─────────────────┐      │
│ │ Single Database │  │ Elastic Pool    │      │
│ │                 │  │  ┌───┐ ┌───┐    │      │
│ │ Dedicated       │  │  │DB1│ │DB2│    │      │
│ │ Resources       │  │  └───┘ └───┘    │      │
│ └─────────────────┘  │  Shared Resources│      │
│                      └─────────────────┘      │
│                                                 │
│ + Automatic backups (7-35 days)                │
│ + Built-in high availability                   │
│ + Automatic patching                           │
│ + Query Performance Insights                   │
│ + Threat detection                             │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ Azure SQL Managed Instance (PaaS+)             │
│                                                 │
│ + Native Virtual Network support               │
│ + SQL Server Agent                             │
│ + CLR support                                  │
│ + Linked servers                               │
│ + Cross-database queries                       │
│ + Near 100% SQL Server compatibility           │
└─────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────┐
│ SQL Server on Azure VM (IaaS)                  │
│                                                 │
│ ┌─────────────────────────────┐                │
│ │ Windows/Linux VM            │                │
│ │  ├─ OS (you manage)         │                │
│ │  ├─ SQL Server (you manage) │                │
│ │  └─ All features available  │                │
│ └─────────────────────────────┘                │
│                                                 │
│ + Complete control                             │
│ + All SQL Server features                      │
│ + Custom configuration                         │
│ - You handle backups, HA, patching            │
└─────────────────────────────────────────────────┘
```

### **2. Automatic Tuning**

```csharp
// Automatic tuning recommendations via Azure Portal
// Or query using DMVs

// Check tuning recommendations
SELECT
    reason,
    state_transition_reason,
    create_time,
    last_refresh,
    score,
    CAST(details AS nvarchar(max)) AS details
FROM sys.dm_db_tuning_recommendations;

// Apply recommendation
ALTER DATABASE SCOPED CONFIGURATION
SET AUTOMATIC_TUNING (FORCE_LAST_GOOD_PLAN = ON);
```

### **3. Elastic Pools (Cost Optimization)**

```csharp
// Elastic Pool for multiple databases with variable load
/*
Use Case: SaaS application with 100 customer databases
- Each DB has unpredictable usage
- Not all DBs are active at same time
- Share resources across all databases for cost savings

Example:
- 100 databases
- Each needs up to 100 DTUs at peak
- But only 20% are active at any time
- Solution: Elastic Pool with 2000 DTUs
  Instead of: 100 x 100 = 10,000 DTUs
  You use: 2000 DTUs (80% cost savings!)
*/

// Create elastic pool (Azure CLI)
az sql elastic-pool create \
    --resource-group myResourceGroup \
    --server myserver \
    --name myElasticPool \
    --edition Standard \
    --dtu 1000 \
    --database-dtu-max 100 \
    --database-dtu-min 10
```

**Security Features:**

```csharp
// 1. Firewall Rules
# Allow specific IP
az sql server firewall-rule create \
    --resource-group myResourceGroup \
    --server myserver \
    --name AllowMyIP \
    --start-ip-address 203.0.113.0 \
    --end-ip-address 203.0.113.255

// 2. Always Encrypted (column-level encryption)
public class ApplicationDbContext : DbContext
{
    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        optionsBuilder.UseSqlServer(
            "Server=myserver.database.windows.net;Database=mydb;Column Encryption Setting=Enabled;...",
            options => options.EnableRetryOnFailure()
        );
    }
}

// 3. Dynamic Data Masking
CREATE TABLE Customers
(
    CustomerId INT PRIMARY KEY,
    Name NVARCHAR(100),
    Email NVARCHAR(100) MASKED WITH (FUNCTION = 'email()'),
    Phone NVARCHAR(20) MASKED WITH (FUNCTION = 'partial(0,"XXX-XXX-",4)'),
    CreditCard NVARCHAR(20) MASKED WITH (FUNCTION = 'default()')
);

// 4. Row-Level Security
CREATE SECURITY POLICY CustomerSecurityPolicy
ADD FILTER PREDICATE dbo.fn_securitypredicate(CustomerId)
ON dbo.Customers
WITH (STATE = ON);
```

**Backup and Restore:**

```csharp
// Automatic backups (no configuration needed)
/*
- Full backup: Weekly
- Differential backup: Every 12-24 hours
- Transaction log backup: Every 5-10 minutes
- Retention: 7-35 days (configurable)
- Long-term retention: Up to 10 years
*/

// Point-in-Time Restore (Azure CLI)
az sql db restore \
    --resource-group myResourceGroup \
    --server myserver \
    --name myRestoredDB \
    --source-database mySourceDB \
    --time "2024-12-04T10:30:00"

// Restore deleted database (within retention period)
az sql db restore \
    --resource-group myResourceGroup \
    --server myserver \
    --name myRestoredDB \
    --deleted-time "2024-12-04T09:00:00" \
    --source-database myDeletedDB
```

**Performance Monitoring:**

```csharp
// Query Performance Insights
// Available in Azure Portal

// Query Store (enabled by default)
SELECT
    qt.query_sql_text,
    q.query_id,
    rs.avg_duration,
    rs.avg_cpu_time,
    rs.count_executions
FROM sys.query_store_query q
JOIN sys.query_store_query_text qt ON q.query_text_id = qt.query_text_id
JOIN sys.query_store_plan p ON q.query_id = p.query_id
JOIN sys.query_store_runtime_stats rs ON p.plan_id = rs.plan_id
ORDER BY rs.avg_duration DESC;

// Intelligent Insights (automatic performance diagnostics)
// Detects:
// - Increased wait times
// - Excessive locking
// - Memory pressure
// - Query parameter sensitivity
```

**Real-World Decision Matrix:**

| Requirement | Choose SQL Database | Choose SQL MI | Choose SQL on VM |
|-------------|-------------------|---------------|-----------------|
| Lift-and-shift from on-premises | ❌ | ✅ | ✅ |
| Need SQL Agent | ❌ | ✅ | ✅ |
| Need linked servers | ❌ | ✅ | ✅ |
| Cross-database queries | ❌ | ✅ | ✅ |
| CLR assemblies | ❌ | ✅ | ✅ |
| Minimal management | ✅ | ⚠️ | ❌ |
| Cost optimization | ✅ | ⚠️ | ❌ |
| SaaS applications | ✅ | ⚠️ | ❌ |
| Elastic scaling | ✅ | ❌ | ❌ |
| Custom OS configuration | ❌ | ❌ | ✅ |

**Best Practices:**

1. **Use vCore model for predictable workloads**: More control over resources
2. **Enable automatic tuning**: Let Azure optimize your queries
3. **Implement retry logic**: Handle transient faults
4. **Use elastic pools for SaaS**: Significant cost savings
5. **Configure geo-replication for DR**: Business continuity
6. **Monitor with Query Performance Insights**: Identify slow queries
7. **Use connection pooling**: Reduce connection overhead
8. **Implement security best practices**: Firewall, encryption, threat detection

---

## **Q107: Explain elastic pools in Azure SQL Database.**

### **Answer:**

Azure SQL Database Elastic Pools are a cost-effective solution for managing and scaling multiple databases with varying and unpredictable usage patterns. They allow multiple databases to share a set of resources (DTUs or vCores) within a single pool.

**Core Concept:**

Instead of provisioning resources for each database individually (which can be wasteful when databases have different peak times), elastic pools allow resource sharing, resulting in significant cost savings.

**How Elastic Pools Work:**

```
Traditional Approach (WITHOUT Elastic Pool):
┌──────────┐ ┌──────────┐ ┌──────────┐ ┌──────────┐
│  DB1     │ │  DB2     │ │  DB3     │ │  DB4     │
│ 100 DTU  │ │ 100 DTU  │ │ 100 DTU  │ │ 100 DTU  │
│ Active   │ │ Idle     │ │ Idle     │ │ Active   │
└──────────┘ └──────────┘ └──────────┘ └──────────┘
Cost: 400 DTUs (100 x 4 databases)
Utilization: 50% (only 2 DBs active)
Wasted: 200 DTUs

Elastic Pool Approach:
┌────────────────────────────────────────────────┐
│         Elastic Pool (200 eDTUs)               │
│  ┌──────────┐ ┌──────────┐ ┌──────────┐      │
│  │  DB1     │ │  DB2     │ │  DB3     │      │
│  │ 100 eDTU │ │ 20 eDTU  │ │ 20 eDTU  │      │
│  │ Active   │ │ Idle     │ │ Idle     │      │
│  └──────────┘ └──────────┘ └──────────┘      │
│  ┌──────────┐                                  │
│  │  DB4     │  Shared Resource Pool           │
│  │ 60 eDTU  │  Databases share 200 eDTUs      │
│  │ Active   │  dynamically                    │
│  └──────────┘                                  │
└────────────────────────────────────────────────┘
Cost: 200 eDTUs (50% savings!)
Utilization: 90% (efficient usage)
```

**When to Use Elastic Pools:**

✅ **Perfect Use Cases:**
- **SaaS Applications**: Each customer has their own database
- **Multi-tenant architectures**: Hundreds of small databases
- **Development/Test environments**: Multiple team databases
- **Unpredictable workloads**: Databases with different peak times
- **Cost optimization**: When most databases are idle most of the time

❌ **Not Suitable For:**
- Single database with predictable high usage
- Databases requiring maximum performance 24/7
- Very large databases with consistent high resource needs
- Mixed workloads with vastly different requirements

**Elastic Pool Configuration:**

```csharp
// Creating Elastic Pool (Azure CLI)
az sql elastic-pool create \
    --resource-group MyResourceGroup \
    --server myserver \
    --name MyElasticPool \
    --edition Standard \
    --dtu 1000 \
    --database-dtu-max 100 \
    --database-dtu-min 10

// vCore-based elastic pool
az sql elastic-pool create \
    --resource-group MyResourceGroup \
    --server myserver \
    --name MyElasticPool \
    --edition GeneralPurpose \
    --family Gen5 \
    --capacity 4 \
    --db-max-capacity 2 \
    --db-min-capacity 0.25

// Add existing database to elastic pool
az sql db update \
    --resource-group MyResourceGroup \
    --server myserver \
    --name MyDatabase \
    --elastic-pool MyElasticPool
```

**C# Code Example - Multi-Tenant SaaS Application:**

```csharp
public class TenantDatabaseManager
{
    private readonly string _connectionString;

    public async Task<string> GetTenantConnectionString(string tenantId)
    {
        // All tenant databases are in the same elastic pool
        return $"Server=tcp:myserver.database.windows.net,1433;" +
               $"Database=Tenant_{tenantId};" +
               $"User ID=admin;Password=P@ssw0rd;" +
               $"Encrypt=True;Connection Timeout=30;";
    }

    public async Task ProvisionNewTenant(string tenantId)
    {
        // Create new database in elastic pool
        var connectionString = "Server=tcp:myserver.database.windows.net,1433;Database=master;...";

        using var connection = new SqlConnection(connectionString);
        await connection.OpenAsync();

        // Database automatically joins the elastic pool
        var createDbCommand = $@"
            CREATE DATABASE [Tenant_{tenantId}]
            ( SERVICE_OBJECTIVE = ELASTIC_POOL ( name = MyElasticPool ) )";

        using var command = new SqlCommand(createDbCommand, connection);
        await command.ExecuteNonQueryAsync();

        Console.WriteLine($"Tenant {tenantId} provisioned in elastic pool");
    }
}

// Multi-tenant data access
public class MultiTenantDbContextFactory
{
    private readonly TenantDatabaseManager _tenantManager;

    public async Task<ApplicationDbContext> CreateDbContext(string tenantId)
    {
        var connectionString = await _tenantManager.GetTenantConnectionString(tenantId);

        var optionsBuilder = new DbContextOptionsBuilder<ApplicationDbContext>();
        optionsBuilder.UseSqlServer(connectionString);

        return new ApplicationDbContext(optionsBuilder.Options);
    }
}

// Usage in API Controller
[ApiController]
[Route("api/{tenantId}/[controller]")]
public class ProductsController : ControllerBase
{
    private readonly MultiTenantDbContextFactory _dbFactory;

    public ProductsController(MultiTenantDbContextFactory dbFactory)
    {
        _dbFactory = dbFactory;
    }

    [HttpGet]
    public async Task<IActionResult> GetProducts(string tenantId)
    {
        // Each tenant accesses their own database from elastic pool
        using var dbContext = await _dbFactory.CreateDbContext(tenantId);
        var products = await dbContext.Products.ToListAsync();
        return Ok(products);
    }

    [HttpPost]
    public async Task<IActionResult> CreateProduct(string tenantId, Product product)
    {
        using var dbContext = await _dbFactory.CreateDbContext(tenantId);
        dbContext.Products.Add(product);
        await dbContext.SaveChangesAsync();
        return CreatedAtAction(nameof(GetProducts), new { tenantId }, product);
    }
}
```

**Pricing Tiers and Limits:**

### **DTU-based Model:**

| Pool Tier | eDTUs | Max Databases | Max Storage | Cost Efficiency |
|-----------|-------|---------------|-------------|-----------------|
| Basic | 50-1600 | 500 | 156 GB | Dev/Test |
| Standard | 50-3000 | 500 | 1 TB | Production |
| Premium | 125-4000 | 500 | 4 TB | High Performance |

### **vCore-based Model:**

| Pool Tier | vCores | Max Databases | Max Storage | Use Case |
|-----------|--------|---------------|-------------|----------|
| General Purpose | 2-80 | 500 | 4 TB | Most workloads |
| Business Critical | 2-80 | 500 | 4 TB | Low latency, high IOPS |
| Hyperscale | 2-80 | 25 | 100 TB | Very large databases |

**Monitoring and Management:**

```csharp
// Monitor elastic pool usage
// Query pool resource usage
SELECT
    start_time,
    end_time,
    avg_cpu_percent,
    avg_data_io_percent,
    avg_log_write_percent,
    avg_storage_percent
FROM sys.elastic_pool_resource_stats
WHERE elastic_pool_name = 'MyElasticPool'
ORDER BY start_time DESC;

// Monitor individual database usage within pool
SELECT
    database_name,
    start_time,
    end_time,
    avg_cpu_percent,
    avg_data_io_percent,
    avg_log_write_percent
FROM sys.resource_stats
WHERE database_name IN (
    SELECT name
    FROM sys.databases
    WHERE elastic_pool_name = 'MyElasticPool'
)
ORDER BY start_time DESC;
```

**Monitoring Dashboard (C#):**

```csharp
public class ElasticPoolMonitor
{
    private readonly SqlConnection _connection;

    public async Task<ElasticPoolMetrics> GetPoolMetricsAsync(string poolName)
    {
        var query = @"
            SELECT TOP 1
                avg_cpu_percent,
                avg_data_io_percent,
                avg_log_write_percent,
                avg_storage_percent,
                max_worker_percent,
                max_session_percent
            FROM sys.elastic_pool_resource_stats
            WHERE elastic_pool_name = @PoolName
            ORDER BY end_time DESC";

        using var command = new SqlCommand(query, _connection);
        command.Parameters.AddWithValue("@PoolName", poolName);

        using var reader = await command.ExecuteReaderAsync();
        if (await reader.ReadAsync())
        {
            return new ElasticPoolMetrics
            {
                CpuPercent = reader.GetDouble(0),
                DataIOPercent = reader.GetDouble(1),
                LogWritePercent = reader.GetDouble(2),
                StoragePercent = reader.GetDouble(3),
                WorkerPercent = reader.GetDouble(4),
                SessionPercent = reader.GetDouble(5)
            };
        }

        return null;
    }

    public async Task<List<DatabaseMetrics>> GetDatabaseMetricsAsync()
    {
        var query = @"
            SELECT
                database_name,
                avg_cpu_percent,
                avg_data_io_percent,
                avg_storage_percent
            FROM sys.resource_stats
            WHERE start_time >= DATEADD(hour, -1, GETUTCDATE())
            GROUP BY database_name
            ORDER BY avg_cpu_percent DESC";

        var metrics = new List<DatabaseMetrics>();

        using var command = new SqlCommand(query, _connection);
        using var reader = await command.ExecuteReaderAsync();

        while (await reader.ReadAsync())
        {
            metrics.Add(new DatabaseMetrics
            {
                DatabaseName = reader.GetString(0),
                CpuPercent = reader.GetDouble(1),
                DataIOPercent = reader.GetDouble(2),
                StoragePercent = reader.GetDouble(3)
            });
        }

        return metrics;
    }

    // Alert if pool is over-utilized
    public async Task CheckPoolHealthAsync(string poolName)
    {
        var metrics = await GetPoolMetricsAsync(poolName);

        if (metrics.CpuPercent > 80)
        {
            await SendAlert($"Elastic Pool {poolName} CPU usage: {metrics.CpuPercent}%");
            // Consider scaling up the pool
        }

        if (metrics.DataIOPercent > 80)
        {
            await SendAlert($"Elastic Pool {poolName} Data I/O: {metrics.DataIOPercent}%");
        }

        if (metrics.StoragePercent > 90)
        {
            await SendAlert($"Elastic Pool {poolName} Storage: {metrics.StoragePercent}%");
        }
    }
}
```

**Real-World Example: SaaS E-Commerce Platform**

```csharp
/*
Scenario:
- 500 small business customers
- Each customer gets their own database
- Most customers have < 10 orders/day
- Peak hours vary by time zone
- Black Friday: 100 customers very active, 400 idle

Without Elastic Pool:
500 databases × 100 DTU each = 50,000 DTUs
Cost: ~$23,000/month

With Elastic Pool:
1 Elastic Pool with 3,000 eDTUs
Cost: ~$2,000/month
Savings: ~$21,000/month (91% reduction!)
*/

public class SaaSCustomerService
{
    private readonly ElasticPoolManager _poolManager;

    // Onboard new customer
    public async Task OnboardCustomerAsync(Customer customer)
    {
        // Create database in elastic pool
        await _poolManager.CreateDatabaseAsync($"Customer_{customer.Id}");

        // Initialize schema
        using var dbContext = await GetCustomerDbContext(customer.Id);
        await dbContext.Database.MigrateAsync();

        Console.WriteLine($"Customer {customer.Name} onboarded to elastic pool");
    }

    // Handle peak loads automatically
    // Elastic pool distributes resources dynamically
    // Active databases get more eDTUs
    // Idle databases consume minimal resources
}
```

**Resource Limits Configuration:**

```csharp
// Per-database limits within elastic pool
public class ElasticPoolDatabaseConfig
{
    // DTU-based
    public int DatabaseDtuMin { get; set; } = 10;  // Minimum guaranteed per DB
    public int DatabaseDtuMax { get; set; } = 100; // Maximum allowed per DB

    // vCore-based
    public decimal DatabaseVCoreMin { get; set; } = 0.25m; // Min vCores
    public decimal DatabaseVCoreMax { get; set; } = 2m;    // Max vCores

    /*
    Example configuration:
    - Pool: 1000 eDTUs
    - DatabaseDtuMin: 10 (each DB gets at least 10 eDTUs)
    - DatabaseDtuMax: 200 (each DB can burst up to 200 eDTUs)
    - 50 databases in pool

    Guarantees: 50 × 10 = 500 eDTUs reserved
    Available for bursting: 500 eDTUs
    */
}
```

**Best Practices:**

1. **Right-size the pool**: Monitor usage and adjust eDTUs/vCores
2. **Set appropriate min/max per database**: Prevent resource starvation
3. **Group similar workloads**: Don't mix OLTP and analytics workloads
4. **Monitor regularly**: Use Azure Portal metrics and alerts
5. **Plan for growth**: Leave headroom for new databases
6. **Use automation**: Auto-scale based on metrics
7. **Test before migrating**: Validate performance with elastic pools
8. **Document tenant mapping**: Know which database belongs to which tenant

**Cost Optimization Strategy:**

```
Calculation Example:

Individual Databases:
- 100 databases
- Each needs 50-200 DTUs (varies throughout day)
- Peak planning: 100 × 200 = 20,000 DTUs
- Cost: ~$9,200/month

Elastic Pool Approach:
- Analysis shows only 30% of DBs peak simultaneously
- Required: 20,000 × 0.3 = 6,000 eDTUs
- Cost: ~$3,400/month
- Savings: $5,800/month (63% reduction)
```

---


---

## **Q111: What is Azure Blob Storage? Explain different blob types.**

### **Answer:**

Azure Blob Storage is Microsoft's object storage solution for the cloud, optimized for storing massive amounts of unstructured data such as text, binary data, images, videos, backups, and logs.

**Key Features:**

1. **Massive Scale**: Store petabytes of data
2. **Cost-Effective**: Tiered storage pricing
3. **Durable**: 99.999999999% (11 nines) durability
4. **Accessible**: REST API, SDKs, Azure Portal, Storage Explorer
5. **Secure**: Encryption at rest and in transit
6. **Integrated**: Works with Azure services (CDN, Media Services, etc.)

**Three Types of Blobs:**

### **1. Block Blobs (Most Common)**

**Purpose:** Optimized for uploading large amounts of data efficiently.

**Characteristics:**
- Made up of blocks (up to 50,000 blocks)
- Each block: up to 4000 MB
- Max size: ~190 TB
- Ideal for: text files, media files, documents, backups

```csharp
using Azure.Storage.Blobs;
using Azure.Storage.Blobs.Models;

// Upload file as Block Blob
string connectionString = "DefaultEndpointsProtocol=https;AccountName=...";
BlobServiceClient blobServiceClient = new BlobServiceClient(connectionString);

// Get container reference
BlobContainerClient containerClient = blobServiceClient.GetBlobContainerClient("documents");
await containerClient.CreateIfNotExistsAsync(PublicAccessType.None);

// Upload block blob
BlobClient blobClient = containerClient.GetBlobClient("report.pdf");

// Option 1: Upload from file
await blobClient.UploadAsync("C:\\reports\\report.pdf", overwrite: true);

// Option 2: Upload from stream
using var fileStream = File.OpenRead("C:\\reports\\report.pdf");
await blobClient.UploadAsync(fileStream, overwrite: true);

// Option 3: Upload large file in blocks (for files > 100MB)
using var largeFileStream = File.OpenRead("C:\\videos\\large-video.mp4");
await blobClient.UploadAsync(
    largeFileStream,
    new BlobUploadOptions
    {
        TransferOptions = new Azure.Storage.StorageTransferOptions
        {
            MaximumConcurrency = 8, // Parallel uploads
            MaximumTransferSize = 4 * 1024 * 1024 // 4MB blocks
        }
    }
);

Console.WriteLine($"Uploaded to: {blobClient.Uri}");

// Download block blob
BlobDownloadInfo download = await blobClient.DownloadAsync();
using (FileStream downloadFileStream = File.OpenWrite("C:\\downloads\\report.pdf"))
{
    await download.Content.CopyToAsync(downloadFileStream);
}

// Get blob metadata
BlobProperties properties = await blobClient.GetPropertiesAsync();
Console.WriteLine($"Size: {properties.ContentLength} bytes");
Console.WriteLine($"Content Type: {properties.ContentType}");
Console.WriteLine($"Last Modified: {properties.LastModified}");

// Set blob metadata
var metadata = new Dictionary<string, string>
{
    { "Department", "Finance" },
    { "Year", "2024" },
    { "Confidential", "true" }
};
await blobClient.SetMetadataAsync(metadata);

// List blobs with metadata
await foreach (BlobItem blobItem in containerClient.GetBlobsAsync(BlobTraits.Metadata))
{
    Console.WriteLine($"Blob: {blobItem.Name}");
    foreach (var tag in blobItem.Metadata)
    {
        Console.WriteLine($"  {tag.Key}: {tag.Value}");
    }
}
```

**Use Cases:**
- Document storage
- Media files (images, videos)
- Backups
- Log files
- Static website hosting

---

### **2. Append Blobs**

**Purpose:** Optimized for append operations (logging scenarios).

**Characteristics:**
- Made up of blocks optimized for append
- Can only append blocks (no update or delete blocks)
- Max size: ~195 GB
- Ideal for: logs, audit trails, streaming data

```csharp
// Create append blob for logging
BlobClient appendBlobClient = containerClient.GetBlobClient("application-log.txt");

// Create if doesn't exist
if (!await appendBlobClient.ExistsAsync())
{
    await appendBlobClient.GetAppendBlobClient().CreateAsync();
}

// Append log entries
var logEntries = new[]
{
    $"{DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} - Application started\n",
    $"{DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} - Processing order #12345\n",
    $"{DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} - Payment received\n"
};

foreach (var logEntry in logEntries)
{
    using var stream = new MemoryStream(Encoding.UTF8.GetBytes(logEntry));
    await appendBlobClient.GetAppendBlobClient().AppendBlockAsync(stream);
}

// Read entire log
var downloadResult = await appendBlobClient.DownloadContentAsync();
string logContent = downloadResult.Value.Content.ToString();
Console.WriteLine(logContent);
```

**Real-World Logging Example:**

```csharp
public class AzureBlobLogger : ILogger
{
    private readonly AppendBlobClient _logBlob;

    public AzureBlobLogger(BlobServiceClient blobService)
    {
        var container = blobService.GetBlobContainerClient("logs");
        container.CreateIfNotExists();

        var logFileName = $"app-log-{DateTime.UtcNow:yyyy-MM-dd}.txt";
        _logBlob = container.GetBlobClient(logFileName).GetAppendBlobClient();

        if (!_logBlob.Exists())
        {
            _logBlob.Create();
        }
    }

    public void LogInformation(string message)
    {
        var logEntry = $"[INFO] {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} - {message}\n";
        AppendLog(logEntry);
    }

    public void LogError(string message, Exception ex)
    {
        var logEntry = $"[ERROR] {DateTime.UtcNow:yyyy-MM-dd HH:mm:ss} - {message}\n" +
                      $"Exception: {ex.Message}\n" +
                      $"StackTrace: {ex.StackTrace}\n";
        AppendLog(logEntry);
    }

    private void AppendLog(string logEntry)
    {
        using var stream = new MemoryStream(Encoding.UTF8.GetBytes(logEntry));
        _logBlob.AppendBlock(stream);
    }
}
```

**Use Cases:**
- Application logs
- Audit trails
- Event streams
- Telemetry data

---

### **3. Page Blobs**

**Purpose:** Optimized for random read/write operations (VHD files).

**Characteristics:**
- Made up of 512-byte pages
- Max size: 8 TB
- Supports random access
- Ideal for: VHD/VHDX files, databases

```csharp
// Create page blob for VHD
PageBlobClient pageBlobClient = containerClient.GetPageBlobClient("disk.vhd");

// Create page blob (size must be multiple of 512)
long blobSize = 1024 * 1024 * 1024; // 1 GB
await pageBlobClient.CreateAsync(blobSize);

// Write pages (random access)
byte[] data = new byte[512];
// Fill data with content
Array.Fill(data, (byte)0xAB);

using var dataStream = new MemoryStream(data);
await pageBlobClient.UploadPagesAsync(dataStream, offset: 0);

// Write at different offset
using var dataStream2 = new MemoryStream(data);
await pageBlobClient.UploadPagesAsync(dataStream2, offset: 1024);

// Read specific pages
var range = new HttpRange(0, 512);
var response = await pageBlobClient.DownloadAsync(range);
```

**Use Cases:**
- Azure Virtual Machine disks (VHD/VHDX)
- SQL Server data files in Azure VMs
- Any scenario requiring random I/O

---

**Comparison Table:**

| Feature | Block Blob | Append Blob | Page Blob |
|---------|-----------|-------------|-----------|
| **Max Size** | ~190 TB | ~195 GB | 8 TB |
| **Operations** | Upload, download | Append only | Random read/write |
| **Block Size** | Variable | Fixed | 512 bytes (pages) |
| **Use Case** | General files | Logs, streams | VHDs, databases |
| **Performance** | Sequential | Append-optimized | Random I/O |
| **Cost** | Standard | Standard | Higher |

**Advanced Features:**

```csharp
// Blob Versioning
await blobClient.UploadAsync(stream, overwrite: true);
// Creates new version automatically

// Soft Delete (recover deleted blobs)
// Configure in portal: 7-365 days retention
BlobContainerClient containerClient = blobServiceClient.GetBlobContainerClient("documents");
await foreach (BlobItem blob in containerClient.GetBlobsAsync(BlobTraits.None,
    BlobStates.Deleted))
{
    Console.WriteLine($"Deleted blob: {blob.Name}");
    // Undelete
    await containerClient.GetBlobClient(blob.Name).UndeleteAsync();
}

// Blob Snapshots
var snapshot = await blobClient.CreateSnapshotAsync();
Console.WriteLine($"Snapshot created: {snapshot.Value.Snapshot}");

// Access specific snapshot
BlobClient snapshotClient = blobClient.WithSnapshot(snapshot.Value.Snapshot);
var snapshotContent = await snapshotClient.DownloadContentAsync();

// Blob Leasing (distributed locking)
BlobLeaseClient leaseClient = blobClient.GetBlobLeaseClient();
var lease = await leaseClient.AcquireAsync(TimeSpan.FromSeconds(60));

try
{
    // Perform operations with lease
    await blobClient.UploadAsync(stream, new BlobUploadOptions
    {
        Conditions = new BlobRequestConditions
        {
            LeaseId = lease.Value.LeaseId
        }
    });
}
finally
{
    await leaseClient.ReleaseAsync();
}

// Change Feed (track all changes)
BlobChangeFeedClient changeFeedClient = blobServiceClient.GetChangeFeedClient();
await foreach (BlobChangeFeedEvent changeFeedEvent in changeFeedClient.GetChangesAsync())
{
    Console.WriteLine($"Event: {changeFeedEvent.EventType}");
    Console.WriteLine($"Blob: {changeFeedEvent.Subject}");
    Console.WriteLine($"Time: {changeFeedEvent.EventTime}");
}
```

**Best Practices:**

1. **Choose the right blob type**: Block for general, Append for logs, Page for VHDs
2. **Use appropriate access tier**: Hot/Cool/Archive based on access patterns
3. **Enable soft delete**: Protect against accidental deletion
4. **Use SAS tokens**: Secure temporary access
5. **Implement retry logic**: Handle transient failures
6. **Use CDN for static content**: Improve global access speed
7. **Monitor costs**: Track storage and transactions
8. **Optimize uploads**: Use parallel uploads for large files

---

## **Q112: What are the different access tiers in Azure Storage?**

### **Answer:**

Azure Blob Storage offers different access tiers optimized for different usage patterns, allowing cost optimization based on how frequently data is accessed.

**The 4 Access Tiers:**

### **1. Hot Tier**

**Optimized for:** Frequently accessed data

**Characteristics:**
- Highest storage cost
- Lowest access cost
- Lowest latency
- Optimized for active data

**Pricing Example:**
- Storage: ~$0.018/GB/month
- Write operations: ~$0.05 per 10,000
- Read operations: ~$0.004 per 10,000

**Use Cases:**
- Active application data
- Frequently accessed files
- Data in active use
- Serving website content

```csharp
// Upload to Hot tier (default)
BlobClient blobClient = containerClient.GetBlobClient("active-document.pdf");
await blobClient.UploadAsync("document.pdf", new BlobUploadOptions
{
    AccessTier = AccessTier.Hot
});
```

---

### **2. Cool Tier**

**Optimized for:** Infrequently accessed data (stored for at least 30 days)

**Characteristics:**
- Lower storage cost than Hot
- Higher access cost than Hot
- Slightly higher latency
- 30-day minimum storage duration

**Pricing Example:**
- Storage: ~$0.01/GB/month (44% cheaper than Hot)
- Write operations: ~$0.10 per 10,000 (2x Hot)
- Read operations: ~$0.01 per 10,000 (2.5x Hot)
- Early deletion fee: If deleted before 30 days

**Use Cases:**
- Short-term backup
- Disaster recovery data
- Older data accessed occasionally
- Data kept for compliance (accessed rarely)

```csharp
// Upload to Cool tier
await blobClient.UploadAsync("backup.zip", new BlobUploadOptions
{
    AccessTier = AccessTier.Cool
});

// Change tier
await blobClient.SetAccessTierAsync(AccessTier.Cool);
```

---

### **3. Cold Tier**

**Optimized for:** Rarely accessed data (stored for at least 90 days)

**Characteristics:**
- Lower storage cost than Cool
- Higher access cost than Cool
- 90-day minimum storage duration
- Good balance for archival data

**Pricing Example:**
- Storage: ~$0.004/GB/month (78% cheaper than Hot)
- Access cost: Higher than Cool
- Early deletion fee: If deleted before 90 days

**Use Cases:**
- Long-term backups
- Compliance data (retained but rarely accessed)
- Old project files
- Historical records

```csharp
await blobClient.SetAccessTierAsync(AccessTier.Cold);
```

---

### **4. Archive Tier**

**Optimized for:** Rarely accessed data (stored for at least 180 days)

**Characteristics:**
- Lowest storage cost
- Highest access/rehydration cost
- Data is offline (must rehydrate to access)
- 180-day minimum storage duration
- Rehydration can take hours

**Pricing Example:**
- Storage: ~$0.00099/GB/month (95% cheaper than Hot!)
- Rehydration: ~$0.02/GB + access costs
- Early deletion fee: If deleted before 180 days

**Use Cases:**
- Long-term archival
- Regulatory compliance archives (7+ years)
- Historical data backups
- Data that may never be accessed

```csharp
// Archive a blob
await blobClient.SetAccessTierAsync(AccessTier.Archive);

// Rehydrate from Archive (takes 1-15 hours)
await blobClient.SetAccessTierAsync(
    AccessTier.Hot,
    rehydratePriority: RehydratePriority.High // or Standard
);

// Check rehydration status
var properties = await blobClient.GetPropertiesAsync();
if (properties.Value.ArchiveStatus == ArchiveStatus.RehydratePendingToHot)
{
    Console.WriteLine("Rehydration in progress...");
}
else if (properties.Value.AccessTier == AccessTier.Hot.ToString())
{
    Console.WriteLine("Rehydration complete!");
    // Now can access the data
}
```

---

**Tier Comparison Table:**

| Tier | Storage Cost | Access Cost | Latency | Min Duration | Use Case |
|------|-------------|-------------|---------|--------------|----------|
| **Hot** | Highest | Lowest | ms | None | Active data |
| **Cool** | Medium | Medium | ms | 30 days | Backups |
| **Cold** | Low | High | ms | 90 days | Long-term backups |
| **Archive** | Lowest | Highest | hours | 180 days | Archival |

**Cost Comparison (Monthly for 1TB):**

```
Scenario: 1 TB of data stored for 1 year

Hot Tier:
- Storage: 1000 GB × $0.018 × 12 months = $216
- Access: 100 reads × $0.004 = $0.40
- Total: ~$216/year

Cool Tier:
- Storage: 1000 GB × $0.01 × 12 months = $120
- Access: 100 reads × $0.01 = $1
- Total: ~$121/year (44% savings)

Cold Tier:
- Storage: 1000 GB × $0.004 × 12 months = $48
- Access: Limited reads
- Total: ~$50/year (77% savings)

Archive Tier:
- Storage: 1000 GB × $0.00099 × 12 months = $11.88
- Access: Almost never accessed
- Total: ~$12/year (94% savings!)
```

**Lifecycle Management (Automated Tiering):**

```csharp
// Configure lifecycle policy via Azure Portal or code
// Example policy (JSON):
{
    "rules": [
        {
            "name": "MoveOldBackupsToArchive",
            "enabled": true,
            "type": "Lifecycle",
            "definition": {
                "filters": {
                    "blobTypes": ["blockBlob"],
                    "prefixMatch": ["backups/"]
                },
                "actions": {
                    "baseBlob": {
                        "tierToCool": {
                            "daysAfterModificationGreaterThan": 30
                        },
                        "tierToArchive": {
                            "daysAfterModificationGreaterThan": 90
                        },
                        "delete": {
                            "daysAfterModificationGreaterThan": 2555 // 7 years
                        }
                    },
                    "snapshot": {
                        "delete": {
                            "daysAfterCreationGreaterThan": 90
                        }
                    }
                }
            }
        }
    ]
}

// Programmatic lifecycle management
using Azure.ResourceManager.Storage;
using Azure.ResourceManager.Storage.Models;

// Create lifecycle policy
var managementPolicyData = new ManagementPolicyData
{
    Policy = new ManagementPolicySchema
    {
        Rules =
        {
            new ManagementPolicyRule("ArchiveOldLogs")
            {
                Enabled = true,
                Type = RuleType.Lifecycle,
                Definition = new ManagementPolicyDefinition
                {
                    Filters = new ManagementPolicyFilter
                    {
                        BlobTypes = { "blockBlob" },
                        PrefixMatch = { "logs/" }
                    },
                    Actions = new ManagementPolicyAction
                    {
                        BaseBlob = new ManagementPolicyBaseBlob
                        {
                            TierToCool = new DateAfterModification { DaysAfterModificationGreaterThan = 30 },
                            TierToArchive = new DateAfterModification { DaysAfterModificationGreaterThan = 180 },
                            Delete = new DateAfterModification { DaysAfterModificationGreaterThan = 365 }
                        }
                    }
                }
            }
        }
    }
};
```

**Real-World Example: Document Management System:**

```csharp
public class DocumentStorageService
{
    private readonly BlobContainerClient _containerClient;

    public async Task UploadDocument(string fileName, Stream fileStream, DocumentType type)
    {
        BlobClient blobClient = _containerClient.GetBlobClient(fileName);

        // Choose tier based on document type
        AccessTier tier = type switch
        {
            DocumentType.ActiveProject => AccessTier.Hot,      // Accessed daily
            DocumentType.CompletedProject => AccessTier.Cool,  // Accessed monthly
            DocumentType.ArchivedProject => AccessTier.Archive, // Rarely accessed
            _ => AccessTier.Cool
        };

        await blobClient.UploadAsync(fileStream, new BlobUploadOptions
        {
            AccessTier = tier,
            Metadata = new Dictionary<string, string>
            {
                { "DocumentType", type.ToString() },
                { "UploadDate", DateTime.UtcNow.ToString("O") }
            }
        });
    }

    public async Task<Stream> DownloadDocument(string fileName)
    {
        BlobClient blobClient = _containerClient.GetBlobClient(fileName);

        // Check if archived
        var properties = await blobClient.GetPropertiesAsync();

        if (properties.Value.AccessTier == "Archive")
        {
            // Need to rehydrate first
            if (properties.Value.ArchiveStatus != ArchiveStatus.RehydratePendingToHot)
            {
                await blobClient.SetAccessTierAsync(AccessTier.Hot,
                    rehydratePriority: RehydratePriority.High);

                throw new InvalidOperationException(
                    "Document is archived. Rehydration started. Try again in a few hours.");
            }
        }

        var download = await blobClient.DownloadAsync();
        return download.Value.Content;
    }
}
```

**Decision Matrix:**

| Access Frequency | Retention Period | Recommended Tier |
|-----------------|------------------|------------------|
| Daily/Weekly | Any | Hot |
| Monthly | 30-90 days | Cool |
| Quarterly | 90-180 days | Cold |
| Yearly/Never | 180+ days | Archive |

**Best Practices:**

1. **Use lifecycle policies**: Automate tier transitions
2. **Monitor access patterns**: Adjust tiers based on actual usage
3. **Consider retrieval time**: Archive has hours of latency
4. **Account for minimum durations**: Early deletion incurs charges
5. **Blob-level tiering**: Different blobs in same container can have different tiers
6. **Cost analysis**: Calculate total cost (storage + access + operations)
7. **Archive rehydration planning**: Plan ahead for Archive data access

---

## **Q113: What is Azure Key Vault? How do you use it in applications?**

### **Answer:**

Azure Key Vault is a cloud service for securely storing and accessing secrets, keys, and certificates. It helps solve the problem of hardcoded credentials and sensitive data in application code.

**What Key Vault Stores:**

1. **Secrets**: Connection strings, passwords, API keys
2. **Keys**: Cryptographic keys for encryption/decryption
3. **Certificates**: SSL/TLS certificates

**Key Features:**

- Centralized secret management
- Access control with Azure AD
- Audit logging (who accessed what, when)
- Automatic secret rotation
- Integration with Azure services
- HSM-backed keys (Hardware Security Module)

**Implementation:**

```csharp
// Install: Azure.Security.KeyVault.Secrets, Azure.Identity

//appsettings.json
{
    "KeyVault": {
        "VaultUri": "https://myvault.vault.azure.net/"
    },
    "ConnectionStrings": {
        "DefaultConnection": "" // Empty - will load from Key Vault
    }
}

// Program.cs - Configure Key Vault
using Azure.Identity;
using Azure.Security.KeyVault.Secrets;
using Azure.Extensions.AspNetCore.Configuration.Secrets;

var builder = WebApplication.CreateBuilder(args);

// Add Key Vault to configuration
var keyVaultUri = builder.Configuration["KeyVault:VaultUri"];
if (!string.IsNullOrEmpty(keyVaultUri))
{
    var credential = new DefaultAzureCredential(); // Uses Managed Identity in Azure
    builder.Configuration.AddAzureKeyVault(
        new Uri(keyVaultUri),
        credential
    );
}

// Now secrets from Key Vault are available via IConfiguration
builder.Services.AddDbContext<ApplicationDbContext>(options =>
    options.UseSqlServer(
        builder.Configuration.GetConnectionString("DefaultConnection") // Loaded from Key Vault!
    )
);

// Using Secret Client directly
public class SecretService
{
    private readonly SecretClient _secretClient;

    public SecretService(IConfiguration configuration)
    {
        var vaultUri = configuration["KeyVault:VaultUri"];
        _secretClient = new SecretClient(
            new Uri(vaultUri),
            new DefaultAzureCredential()
        );
    }

    public async Task<string> GetSecretAsync(string secretName)
    {
        try
        {
            KeyVaultSecret secret = await _secretClient.GetSecretAsync(secretName);
            return secret.Value;
        }
        catch (Azure.RequestFailedException ex) when (ex.Status == 404)
        {
            throw new Exception($"Secret '{secretName}' not found in Key Vault");
        }
    }

    public async Task SetSecretAsync(string secretName, string secretValue)
    {
        await _secretClient.SetSecretAsync(secretName, secretValue);
    }

    // Get multiple secrets efficiently
    public async Task<Dictionary<string, string>> GetSecretsAsync(params string[] secretNames)
    {
        var tasks = secretNames.Select(async name =>
        {
            var secret = await _secretClient.GetSecretAsync(name);
            return new KeyValuePair<string, string>(name, secret.Value.Value);
        });

        var results = await Task.WhenAll(tasks);
        return results.ToDictionary(kvp => kvp.Key, kvp => kvp.Value);
    }
}
```

**Real-World Example:**

```csharp
public class PaymentService
{
    private readonly SecretClient _secretClient;

    public async Task ProcessPaymentAsync(decimal amount)
    {
        // Get payment gateway credentials from Key Vault
        var apiKey = await _secretClient.GetSecretAsync("PaymentGateway-ApiKey");
        var apiSecret = await _secretClient.GetSecretAsync("PaymentGateway-ApiSecret");

        // Use credentials securely
        var paymentGateway = new PaymentGatewayClient(apiKey.Value.Value, apiSecret.Value.Value);
        await paymentGateway.ChargeAsync(amount);

        // No hardcoded secrets in code!
    }
}
```

**Best Practices:**

1. Use Managed Identity (no credentials in code)
2. Enable soft delete and purge protection
3. Use RBAC for access control
4. Enable audit logging
5. Rotate secrets regularly
6. Use separate vaults for different environments

---

## **Q114: Explain managed identities in Azure.**

### **Answer:**

Managed Identities eliminate the need to manage credentials in code. Azure automatically handles the identity and credentials for Azure resources.

**Types:**

### **1. System-Assigned Managed Identity**

- Tied to a single Azure resource
- Created with the resource
- Deleted when resource is deleted

```csharp
// Enable in Azure Portal or CLI:
az vm identity assign --name myVM --resource-group myRG

// No credentials needed in code!
var credential = new DefaultAzureCredential();
var secretClient = new SecretClient(vaultUri, credential);

// Azure handles authentication automatically
var secret = await secretClient.GetSecretAsync("DatabasePassword");
```

### **2. User-Assigned Managed Identity**

- Standalone identity
- Can be assigned to multiple resources
- Lifecycle independent of resources

**How It Works:**

```
1. App requests token from Azure Instance Metadata Service
2. Azure validates identity
3. Returns access token
4. App uses token to access Key Vault/Storage/SQL
5. No secrets stored in application!
```

**Implementation:**

```csharp
// Works automatically in Azure with Managed Identity enabled
public class ManagedIdentityExample
{
    // Access Key Vault
    public async Task<string> GetSecretAsync()
    {
        var credential = new DefaultAzureCredential();
        var client = new SecretClient(new Uri("https://myvault.vault.azure.net/"), credential);
        var secret = await client.GetSecretAsync("MySecret");
        return secret.Value.Value;
    }

    // Access Blob Storage
    public async Task UploadFileAsync()
    {
        var credential = new DefaultAzureCredential();
        var blobClient = new BlobServiceClient(
            new Uri("https://mystorageaccount.blob.core.windows.net"),
            credential
        );

        var containerClient = blobClient.GetBlobContainerClient("documents");
        await containerClient.GetBlobClient("file.txt").UploadAsync("data.txt");
    }

    // Access SQL Database
    public async Task QueryDatabaseAsync()
    {
        var credential = new DefaultAzureCredential();
        var token = await credential.GetTokenAsync(
            new TokenRequestContext(new[] { "https://database.windows.net/.default" })
        );

        using var connection = new SqlConnection("Server=myserver.database.windows.net;Database=mydb;");
        connection.AccessToken = token.Token;
        await connection.OpenAsync();

        // Query database
    }
}
```

**Benefits:**

- No credentials in code or configuration
- Automatic rotation of credentials
- Simplified credential management
- Better security posture
- Works seamlessly in Azure

---

## **Q115: What is Azure API Management? What problems does it solve?**

### **Answer:**

Azure API Management (APIM) is a fully managed service that helps organizations publish, secure, transform, maintain, and monitor APIs.

**Problems It Solves:**

1. **API Security**: Authentication, authorization, rate limiting
2. **API Gateway**: Single entry point for all APIs
3. **API Versioning**: Manage multiple API versions
4. **Traffic Management**: Throttling, quotas, caching
5. **Analytics**: Usage metrics, monitoring
6. **Developer Portal**: Documentation, testing
7. **Transformation**: Request/response manipulation

**Architecture:**

```
External Clients → API Management Gateway → Backend APIs

Components:
1. Gateway: Accepts API calls, enforces policies
2. Azure Portal: Manage APIs, policies, users
3. Developer Portal: API documentation, testing
```

**Implementation:**

```csharp
// No code changes needed in backend APIs!
// All policies configured in APIM

// Example backend API (stays unchanged)
[ApiController]
[Route("api/products")]
public class ProductsController : ControllerBase
{
    [HttpGet]
    public IActionResult GetProducts()
    {
        return Ok(products);
    }
}
```

**APIM Policies (XML):**

```xml
<!-- Rate Limiting -->
<policies>
    <inbound>
        <rate-limit calls="100" renewal-period="60" />
        <quota calls="10000" renewal-period="604800" />
    </inbound>
</policies>

<!-- Authentication -->
<policies>
    <inbound>
        <validate-jwt header-name="Authorization">
            <issuer-signing-keys>
                <key>{{jwt-signing-key}}</key>
            </issuer-signing-keys>
        </validate-jwt>
    </inbound>
</policies>

<!-- Response Caching -->
<policies>
    <inbound>
        <cache-lookup vary-by-developer="false" vary-by-developer-groups="false" />
    </inbound>
    <outbound>
        <cache-store duration="3600" />
    </outbound>
</policies>
```

**Use Cases:**

- Microservices API gateway
- External API monetization
- Legacy API modernization
- Multi-channel API access
- Partner/customer API access

---

## **Q116: How do you implement rate limiting in API Management?**

### **Answer:**

Rate limiting in APIM controls the number of API calls to prevent abuse and ensure fair usage.

**Two Types:**

### **1. Rate Limit (Short-term)**

```xml
<policies>
    <inbound>
        <!-- 100 calls per 60 seconds per subscription key -->
        <rate-limit calls="100" renewal-period="60" />

        <!-- Per IP address -->
        <rate-limit-by-key calls="100" renewal-period="60"
            counter-key="@(context.Request.IpAddress)" />

        <!-- Per user -->
        <rate-limit-by-key calls="1000" renewal-period="60"
            counter-key="@(context.Request.Headers.GetValueOrDefault("user-id"))" />
    </inbound>
</policies>
```

### **2. Quota (Long-term)**

```xml
<policies>
    <inbound>
        <!-- 10,000 calls per week per subscription -->
        <quota calls="10000" renewal-period="604800" />

        <!-- Bandwidth quota -->
        <quota-by-key calls="10000" bandwidth="100000" renewal-period="604800"
            counter-key="@(context.Subscription.Id)" />
    </inbound>
</policies>
```

**Advanced Rate Limiting:**

```xml
<!-- Different limits for different tiers -->
<policies>
    <inbound>
        <choose>
            <when condition="@(context.Product.Name == "Premium")">
                <rate-limit calls="10000" renewal-period="60" />
            </when>
            <when condition="@(context.Product.Name == "Basic")">
                <rate-limit calls="100" renewal-period="60" />
            </when>
            <otherwise>
                <rate-limit calls="10" renewal-period="60" />
            </otherwise>
        </choose>
    </inbound>
</policies>
```

**Custom Error Response:**

```xml
<policies>
    <inbound>
        <rate-limit calls="100" renewal-period="60" />
    </inbound>
    <on-error>
        <choose>
            <when condition="@(context.LastError.Reason == "RateLimitExceeded")">
                <return-response>
                    <set-status code="429" reason="Too Many Requests" />
                    <set-header name="Retry-After" exists-action="override">
                        <value>60</value>
                    </set-header>
                    <set-body>@{
                        return new JObject(
                            new JProperty("error", "Rate limit exceeded"),
                            new JProperty("retry_after", 60)
                        ).ToString();
                    }</set-body>
                </return-response>
            </when>
        </choose>
    </on-error>
</policies>
```

---

## **Q117: Explain policies in Azure API Management.**

### **Answer:**

Policies are collections of statements that execute sequentially on request/response of an API.

**Policy Sections:**

```xml
<policies>
    <inbound>      <!-- Before forwarding to backend -->
    </inbound>
    <backend>      <!-- Before/after calling backend -->
    </backend>
    <outbound>     <!-- After receiving from backend -->
    </outbound>
    <on-error>     <!-- On error in any section -->
    </on-error>
</policies>
```

**Common Policies:**

### **1. Transformation Policies:**

```xml
<!-- Add/Modify Headers -->
<set-header name="X-Correlation-Id" exists-action="override">
    <value>@(Guid.NewGuid().ToString())</value>
</set-header>

<!-- Transform JSON -->
<set-body>@{
    var body = context.Request.Body.As<JObject>();
    body["timestamp"] = DateTime.UtcNow;
    return body.ToString();
}</set-body>

<!-- Convert XML to JSON -->
<xml-to-json kind="direct" apply="always" consider-accept-header="false" />
```

### **2. Security Policies:**

```xml
<!-- Validate JWT -->
<validate-jwt header-name="Authorization" failed-validation-httpcode="401">
    <openid-config url="https://login.microsoftonline.com/tenant/.well-known/openid-configuration" />
    <audiences>
        <audience>api://myapi</audience>
    </audiences>
    <required-claims>
        <claim name="roles" match="any">
            <value>Admin</value>
        </claim>
    </required-claims>
</validate-jwt>

<!-- IP Filtering -->
<ip-filter action="allow">
    <address>13.66.201.169</address>
    <address-range from="13.66.140.128" to="13.66.140.143" />
</ip-filter>
```

### **3. Caching Policies:**

```xml
<cache-lookup vary-by-developer="true" vary-by-developer-groups="true">
    <vary-by-header>Accept</vary-by-header>
    <vary-by-query-parameter>category</vary-by-query-parameter>
</cache-lookup>

<cache-store duration="3600" />
```

---

## **Q118: What is Azure Application Insights? What metrics does it collect?**

### **Answer:**

Application Insights is an Application Performance Management (APM) service that monitors live applications, automatically detects performance anomalies, and includes analytics tools.

**Key Metrics Collected:**

### **1. Request Metrics:**
- Request rate
- Response time
- Failure rate
- Dependency calls

### **2. Performance Metrics:**
- Server response time
- Browser page load time
- AJAX call duration
- Dependency duration

### **3. Availability:**
- Uptime percentage
- Response time from locations worldwide
- Alert on failures

### **4. Usage:**
- Page views
- User sessions
- User flows
- Custom events

**Implementation:**

```csharp
// Install: Microsoft.ApplicationInsights.AspNetCore

// Program.cs
builder.Services.AddApplicationInsightsTelemetry(options =>
{
    options.ConnectionString = builder.Configuration["ApplicationInsights:ConnectionString"];
});

// appsettings.json
{
    "ApplicationInsights": {
        "ConnectionString": "InstrumentationKey=xxx;IngestionEndpoint=https://..."
    }
}

// Custom Tracking
public class OrderService
{
    private readonly TelemetryClient _telemetry;

    public OrderService(TelemetryClient telemetry)
    {
        _telemetry = telemetry;
    }

    public async Task ProcessOrderAsync(Order order)
    {
        var stopwatch = Stopwatch.StartNew();

        try
        {
            await ProcessPayment(order);

            // Track custom event
            _telemetry.TrackEvent("OrderProcessed", new Dictionary<string, string>
            {
                { "OrderId", order.Id },
                { "Amount", order.Amount.ToString() }
            });

            // Track metric
            _telemetry.TrackMetric("OrderValue", order.Amount);

            stopwatch.Stop();
            _telemetry.TrackMetric("OrderProcessingTime", stopwatch.ElapsedMilliseconds);
        }
        catch (Exception ex)
        {
            _telemetry.TrackException(ex, new Dictionary<string, string>
            {
                { "OrderId", order.Id }
            });
            throw;
        }
    }
}
```

**Queries (KQL - Kusto Query Language):**

```kusto
// Average response time by endpoint
requests
| where timestamp > ago(24h)
| summarize avg(duration) by name
| order by avg_duration desc

// Failed requests
requests
| where success == false
| project timestamp, name, resultCode, duration

// Custom events
customEvents
| where name == "OrderProcessed"
| extend OrderId = tostring(customDimensions.OrderId)
| extend Amount = todouble(customDimensions.Amount)
| summarize TotalRevenue = sum(Amount), OrderCount = count() by bin(timestamp, 1h)
```

---

## **Q119: How do you implement distributed tracing with Application Insights?**

### **Answer:**

Distributed tracing tracks requests across multiple services in microservices architecture.

**Implementation:**

```csharp
// Automatically enabled with Application Insights SDK

// Service 1: API Gateway
[ApiController]
[Route("api/orders")]
public class OrdersController : ControllerBase
{
    private readonly HttpClient _httpClient;
    private readonly TelemetryClient _telemetry;

    [HttpPost]
    public async Task<IActionResult> CreateOrder(Order order)
    {
        // Application Insights automatically creates parent span

        // Call Service 2 - correlation ID propagated automatically
        var response = await _httpClient.PostAsJsonAsync(
            "https://payment-service/api/payments",
            new { orderId = order.Id, amount = order.Amount }
        );

        // Call Service 3
        await _httpClient.PostAsJsonAsync(
            "https://inventory-service/api/inventory/reserve",
            new { items = order.Items }
        );

        return Ok();
    }
}

// Service 2: Payment Service
[ApiController]
[Route("api/payments")]
public class PaymentsController : ControllerBase
{
    [HttpPost]
    public async Task<IActionResult> ProcessPayment(PaymentRequest request)
    {
        // Automatically correlated with parent request
        _telemetry.TrackEvent("PaymentProcessed");

        return Ok();
    }
}
```

**View in Application Insights:**

```
End-to-End Transaction View:

OrdersController.CreateOrder (150ms)
├─ PaymentService.ProcessPayment (80ms)
│  └─ PaymentGateway.Charge (70ms)
└─ InventoryService.ReserveItems (40ms)
   └─ Database.Query (30ms)

Total Duration: 150ms
```

**Custom Correlation:**

```csharp
public async Task ProcessWithCustomCorrelation()
{
    using (var operation = _telemetry.StartOperation<RequestTelemetry>("CustomOperation"))
    {
        operation.Telemetry.Properties["CustomProperty"] = "Value";

        await Task.Delay(100);

        _telemetry.TrackEvent("Step1");

        await Task.Delay(50);

        _telemetry.TrackEvent("Step2");
    } // Automatically tracked
}
```

---

## **Q120: What is Azure Monitor? Explain alerts and action groups.**

### **Answer:**

Azure Monitor is a comprehensive monitoring solution that collects, analyzes, and acts on telemetry from cloud and on-premises environments.

**Components:**

1. **Metrics**: Numerical time-series data
2. **Logs**: Text-based diagnostic data
3. **Alerts**: Notifications based on conditions
4. **Action Groups**: What to do when alert fires

**Creating Alerts:**

```csharp
// Alert Rule Configuration (JSON)
{
    "name": "High CPU Alert",
    "description": "Alert when CPU > 80%",
    "severity": 2,
    "enabled": true,
    "condition": {
        "allOf": [{
            "metricName": "Percentage CPU",
            "operator": "GreaterThan",
            "threshold": 80,
            "timeAggregation": "Average",
            "windowSize": "PT5M"
        }]
    },
    "actions": {
        "actionGroups": ["/subscriptions/.../actionGroups/OnCallTeam"]
    }
}
```

**Action Groups:**

```
Action Group: "OnCallTeam"
├─ Email: devops@company.com
├─ SMS: +1-555-0100
├─ Azure Function: https://alerts.azurewebsites.net/api/alert
├─ Logic App: Ticket creation workflow
└─ Webhook: https://slack.com/webhook/alerts
```

**Programmatic Alerts:**

```csharp
using Azure.ResourceManager.Monitor;

public class AlertService
{
    public async Task CreateMetricAlertAsync()
    {
        var alertRule = new MetricAlertResource
        {
            Description = "High error rate alert",
            Severity = 1,
            Enabled = true,
            EvaluationFrequency = TimeSpan.FromMinutes(1),
            WindowSize = TimeSpan.FromMinutes(5),
            Criteria = new MetricAlertCriteria
            {
                AllOf = new[]
                {
                    new MetricCriteria
                    {
                        MetricName = "Failed Requests",
                        Operator = MetricOperator.GreaterThan,
                        Threshold = 10,
                        TimeAggregation = MetricAggregation.Total
                    }
                }
            },
            Actions = new[]
            {
                new AlertAction
                {
                    ActionGroupId = "/subscriptions/.../actionGroups/DevOpsTeam"
                }
            }
        };
    }
}
```

**Best Practices:**

1. Set appropriate thresholds
2. Use action groups for reusability
3. Configure alert severity correctly
4. Avoid alert fatigue
5. Test alerts before production
6. Document alert responses
7. Review and tune regularly

---

✅ **Completed Q100-Q120!** Comprehensive Azure Cloud Services coverage with code examples, best practices, and real-world scenarios!

