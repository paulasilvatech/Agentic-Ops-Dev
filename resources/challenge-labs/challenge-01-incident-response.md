# Challenge Lab 01: Critical Incident Response

## Scenario

It's 3 AM and you've been paged. The e-commerce platform is experiencing intermittent failures. Customer complaints are flooding in about failed transactions and slow page loads. The on-call engineer before you left a note: "Something's wrong with the order service, but I can't figure out what."

Your mission: Use the observability tools to identify the root cause and implement a fix.

## Initial Symptoms

- **Customer Reports**: 
  - "My order failed after clicking submit"
  - "The page takes forever to load"
  - "I get error 500 sometimes, but it works if I try again"
  
- **Initial Metrics**:
  - Error rate spike from 0.1% to 15% starting at 2:47 AM
  - P95 latency increased from 200ms to 5s
  - CPU and memory appear normal

## Your Tools

- Grafana dashboards: http://localhost:3000
- Prometheus: http://localhost:9090
- Jaeger tracing: http://localhost:16686
- Application logs in Azure Monitor
- Direct kubectl access to the cluster

## Tasks

### Task 1: Initial Investigation (20 minutes)

1. **Check the Service Health Dashboard**
   - Which services are affected?
   - What's the pattern of failures?
   - When exactly did the issue start?

2. **Analyze Error Patterns**
   - Are errors consistent or intermittent?
   - Which endpoints are failing?
   - What HTTP status codes are being returned?

3. **Document Your Findings**
   Create a timeline of events and initial observations.

### Task 2: Deep Dive Analysis (30 minutes)

1. **Distributed Tracing Investigation**
   - Find failed transactions in Jaeger
   - Identify which service calls are failing
   - Measure the latency at each hop
   - Look for timeout patterns

2. **Log Analysis**
   ```kusto
   ContainerLog
   | where TimeGenerated > ago(3h)
   | where ContainerName contains "order-service"
   | where LogEntry contains "ERROR" or LogEntry contains "Exception"
   | project TimeGenerated, LogEntry, PodName
   | order by TimeGenerated desc
   ```

3. **Resource Correlation**
   - Check database connection pool metrics
   - Verify message queue health
   - Look for dependency failures

### Task 3: Root Cause Identification (20 minutes)

Based on your investigation, identify:

1. **The Root Cause**
   - What component is failing?
   - Why is it failing?
   - Why is it intermittent?

2. **The Impact Chain**
   - How does this failure cascade?
   - Which other services are affected?
   - What's the business impact?

### Task 4: Implement a Fix (30 minutes)

1. **Immediate Mitigation**
   ```bash
   # Your commands here to mitigate the issue
   # Examples:
   # - Scale the service
   # - Restart pods
   # - Adjust configuration
   # - Enable circuit breaker
   ```

2. **Verify the Fix**
   - Monitor error rates
   - Check latency metrics
   - Validate with test transactions

3. **Implement Monitoring**
   - Create an alert for this specific issue
   - Add a dashboard panel
   - Document the runbook

## Success Criteria

- [ ] Identified the root cause correctly
- [ ] Implemented a working fix
- [ ] Error rate back below 1%
- [ ] P95 latency under 500ms
- [ ] Created preventive monitoring
- [ ] Documented the incident

## Hints (Use Only If Stuck)

<details>
<summary>Hint 1: Where to Start</summary>

Look at the distributed traces for failed requests. Pay special attention to the database queries from the order service.
</details>

<details>
<summary>Hint 2: The Pattern</summary>

Notice how failures happen in bursts? Check what's special about the timing. Look at the connection pool metrics.
</details>

<details>
<summary>Hint 3: The Root Cause</summary>

The order service has a database connection leak. Under load, it exhausts the connection pool, causing intermittent failures.
</details>

## Solution

<details>
<summary>Complete Solution</summary>

### Root Cause
The order service has a database connection leak in the order creation endpoint. When creating orders, connections are not properly released back to the pool, eventually exhausting all available connections.

### Investigation Steps

1. **Identify the failing service**
   ```promql
   sum(rate(http_requests_total{status=~"5.."}[5m])) by (service)
   ```

2. **Check connection pool metrics**
   ```promql
   database_connections_active{service="order-service"} / database_connections_max{service="order-service"}
   ```

3. **Find the leak in logs**
   ```bash
   kubectl logs -n applications deployment/order-service | grep -i "connection"
   ```

4. **Trace analysis showing database timeouts**

### Fix Implementation

1. **Immediate mitigation - Restart pods to release connections**
   ```bash
   kubectl rollout restart deployment/order-service -n applications
   ```

2. **Increase connection pool size temporarily**
   ```yaml
   kubectl set env deployment/order-service -n applications \
     DB_POOL_SIZE=50 \
     DB_POOL_TIMEOUT=30s
   ```

3. **Deploy the fixed code**
   ```bash
   # The fix is in the order service code - ensuring connections are closed
   kubectl set image deployment/order-service -n applications \
     order-service=acr-workshop.azurecr.io/order-service:v1.0.1-fixed
   ```

4. **Add monitoring**
   ```yaml
   - alert: DatabaseConnectionPoolExhausted
     expr: |
       (database_connections_active / database_connections_max) > 0.9
     for: 2m
     labels:
       severity: critical
     annotations:
       summary: "Database connection pool nearly exhausted"
   ```

### Prevention
- Code review to catch connection leaks
- Add connection pool monitoring to dashboards
- Implement connection timeout and recycling
- Add integration tests for connection handling
</details>

## Learning Objectives

After completing this challenge, you should be able to:

- Navigate between metrics, logs, and traces to investigate issues
- Identify resource exhaustion problems
- Implement both immediate fixes and long-term solutions
- Create effective monitoring to prevent recurrence
- Document incidents for future reference

## Additional Challenges

1. **Make it Harder**: The database is also having sporadic network issues. How do you distinguish between the connection leak and network problems?

2. **Chaos Engineering**: Use a chaos engineering tool to randomly kill database connections. Can your monitoring detect this?

3. **Automation**: Write a script that automatically detects and mitigates connection pool exhaustion.

## Resources

- [Connection Pool Best Practices](https://docs.microsoft.com/en-us/azure/azure-sql/database/connection-pooling)
- [Debugging Distributed Systems](https://www.oreilly.com/library/view/distributed-tracing-in/9781492056621/)
- [SRE Incident Response](https://sre.google/sre-book/managing-incidents/) 