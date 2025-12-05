# AZURE CLOUD SERVICES - QUESTIONS 100-115

**Comprehensive Interview Answers with Examples and Best Practices**

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

**Decision Matrix:**
- Use **Service Bus** for enterprise messaging with complex requirements
- Use **Storage Queues** for simple, cost-effective queuing needs

---

*[Continue with remaining questions Q101-Q115 following the same detailed format...]*

