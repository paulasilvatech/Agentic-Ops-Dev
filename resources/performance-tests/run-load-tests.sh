#!/bin/bash

# Performance Testing Script for Observability Workshop
# This script runs various load tests against the deployed services

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default values
ENVIRONMENT="development"
DURATION="300"
USERS="50"
RAMP_UP="30"
SERVICE_URL=""
REPORT_DIR="./performance-reports"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Function to print colored output
print_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        --environment)
            ENVIRONMENT="$2"
            shift 2
            ;;
        --duration)
            DURATION="$2"
            shift 2
            ;;
        --users)
            USERS="$2"
            shift 2
            ;;
        --ramp-up)
            RAMP_UP="$2"
            shift 2
            ;;
        --service-url)
            SERVICE_URL="$2"
            shift 2
            ;;
        --report-dir)
            REPORT_DIR="$2"
            shift 2
            ;;
        --help)
            echo "Usage: $0 [options]"
            echo ""
            echo "Options:"
            echo "  --environment    Environment to test (default: development)"
            echo "  --duration       Test duration in seconds (default: 300)"
            echo "  --users          Number of concurrent users (default: 50)"
            echo "  --ramp-up        Ramp-up time in seconds (default: 30)"
            echo "  --service-url    Override service URL"
            echo "  --report-dir     Directory for reports (default: ./performance-reports)"
            echo ""
            exit 0
            ;;
        *)
            print_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

# Create report directory
mkdir -p "$REPORT_DIR/$TIMESTAMP"

# Set service URL based on environment if not provided
if [ -z "$SERVICE_URL" ]; then
    case $ENVIRONMENT in
        development)
            SERVICE_URL="http://localhost:8080"
            ;;
        staging)
            SERVICE_URL="http://staging.example.com"
            ;;
        production)
            SERVICE_URL="http://api.example.com"
            ;;
        *)
            print_error "Unknown environment: $ENVIRONMENT"
            exit 1
            ;;
    esac
fi

print_info "Starting performance tests"
print_info "Environment: $ENVIRONMENT"
print_info "Service URL: $SERVICE_URL"
print_info "Duration: ${DURATION}s"
print_info "Users: $USERS"
print_info "Ramp-up: ${RAMP_UP}s"

# Check if required tools are installed
check_requirements() {
    local missing_tools=()
    
    if ! command -v k6 &> /dev/null; then
        missing_tools+=("k6")
    fi
    
    if ! command -v jq &> /dev/null; then
        missing_tools+=("jq")
    fi
    
    if ! command -v curl &> /dev/null; then
        missing_tools+=("curl")
    fi
    
    if [ ${#missing_tools[@]} -ne 0 ]; then
        print_error "Missing required tools: ${missing_tools[*]}"
        print_info "Please install missing tools and try again"
        exit 1
    fi
}

# Create k6 test script
create_k6_script() {
    cat > "$REPORT_DIR/$TIMESTAMP/load-test.js" << 'EOF'
import http from 'k6/http';
import { check, group, sleep } from 'k6';
import { Rate, Trend } from 'k6/metrics';

// Custom metrics
const errorRate = new Rate('errors');
const apiLatency = new Trend('api_latency');
const successRate = new Rate('success_rate');

// Test configuration from environment variables
const BASE_URL = __ENV.SERVICE_URL || 'http://localhost:8080';
const DURATION = __ENV.DURATION || '300s';
const VUS = __ENV.USERS || 50;
const RAMP_UP = __ENV.RAMP_UP || '30s';

export const options = {
    stages: [
        { duration: RAMP_UP, target: VUS },
        { duration: DURATION, target: VUS },
        { duration: '30s', target: 0 },
    ],
    thresholds: {
        'http_req_duration': ['p(95)<500', 'p(99)<1000'],
        'http_req_failed': ['rate<0.05'],
        'errors': ['rate<0.05'],
        'success_rate': ['rate>0.95'],
    },
    ext: {
        loadimpact: {
            projectID: 12345,
            name: `Performance Test - ${new Date().toISOString()}`,
        },
    },
};

// Helper function to add observability headers
function addObservabilityHeaders() {
    return {
        'X-Correlation-ID': `perf-test-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`,
        'X-Test-Type': 'load-test',
        'X-Environment': __ENV.ENVIRONMENT || 'development',
    };
}

export default function () {
    const headers = addObservabilityHeaders();
    
    group('API Endpoints', function () {
        // Test home endpoint
        group('GET /', function () {
            const res = http.get(`${BASE_URL}/`, { headers });
            check(res, {
                'status is 200': (r) => r.status === 200,
                'response time < 500ms': (r) => r.timings.duration < 500,
            }) || errorRate.add(1);
            
            apiLatency.add(res.timings.duration);
            successRate.add(res.status === 200);
            sleep(1);
        });
        
        // Test health endpoint
        group('GET /health', function () {
            const res = http.get(`${BASE_URL}/health`, { headers });
            check(res, {
                'status is 200': (r) => r.status === 200,
                'response has healthy status': (r) => {
                    try {
                        const body = JSON.parse(r.body);
                        return body.status === 'healthy';
                    } catch (e) {
                        return false;
                    }
                },
            }) || errorRate.add(1);
            
            successRate.add(res.status === 200);
            sleep(0.5);
        });
        
        // Test user service endpoints
        group('User Service', function () {
            // Get users
            const getUsersRes = http.get(`${BASE_URL}/api/users`, { headers });
            check(getUsersRes, {
                'status is 200': (r) => r.status === 200,
                'response is array': (r) => {
                    try {
                        const body = JSON.parse(r.body);
                        return Array.isArray(body);
                    } catch (e) {
                        return false;
                    }
                },
            }) || errorRate.add(1);
            
            apiLatency.add(getUsersRes.timings.duration);
            successRate.add(getUsersRes.status === 200);
            
            // Create user
            const payload = JSON.stringify({
                name: `User ${Date.now()}`,
                email: `user${Date.now()}@example.com`,
            });
            
            const postHeaders = Object.assign({}, headers, {
                'Content-Type': 'application/json',
            });
            
            const createUserRes = http.post(`${BASE_URL}/api/users`, payload, { headers: postHeaders });
            check(createUserRes, {
                'status is 201': (r) => r.status === 201,
                'response has user id': (r) => {
                    try {
                        const body = JSON.parse(r.body);
                        return body.id !== undefined;
                    } catch (e) {
                        return false;
                    }
                },
            }) || errorRate.add(1);
            
            apiLatency.add(createUserRes.timings.duration);
            successRate.add(createUserRes.status === 201);
            sleep(2);
        });
        
        // Test order service endpoints
        group('Order Service', function () {
            // Get orders
            const getOrdersRes = http.get(`${BASE_URL}/api/orders`, { headers });
            check(getOrdersRes, {
                'status is 200': (r) => r.status === 200,
                'response time < 1000ms': (r) => r.timings.duration < 1000,
            }) || errorRate.add(1);
            
            apiLatency.add(getOrdersRes.timings.duration);
            successRate.add(getOrdersRes.status === 200);
            
            // Create order
            const orderPayload = JSON.stringify({
                userId: Math.floor(Math.random() * 100) + 1,
                items: [
                    { productId: 1, quantity: 2 },
                    { productId: 2, quantity: 1 },
                ],
                total: 99.99,
            });
            
            const postHeaders = Object.assign({}, headers, {
                'Content-Type': 'application/json',
            });
            
            const createOrderRes = http.post(`${BASE_URL}/api/orders`, orderPayload, { headers: postHeaders });
            check(createOrderRes, {
                'status is 201': (r) => r.status === 201,
                'response has order id': (r) => {
                    try {
                        const body = JSON.parse(r.body);
                        return body.orderId !== undefined;
                    } catch (e) {
                        return false;
                    }
                },
            }) || errorRate.add(1);
            
            apiLatency.add(createOrderRes.timings.duration);
            successRate.add(createOrderRes.status === 201);
            sleep(3);
        });
        
        // Stress test with parallel requests
        group('Parallel Requests', function () {
            const responses = http.batch([
                ['GET', `${BASE_URL}/api/users`, null, { headers }],
                ['GET', `${BASE_URL}/api/orders`, null, { headers }],
                ['GET', `${BASE_URL}/health`, null, { headers }],
            ]);
            
            responses.forEach((res) => {
                check(res, {
                    'status is 200': (r) => r.status === 200,
                }) || errorRate.add(1);
                
                apiLatency.add(res.timings.duration);
                successRate.add(res.status === 200);
            });
            
            sleep(2);
        });
    });
}

export function handleSummary(data) {
    return {
        'stdout': textSummary(data, { indent: ' ', enableColors: true }),
        'performance-report.json': JSON.stringify(data, null, 2),
        'performance-report.html': htmlReport(data),
    };
}

// Custom text summary function
function textSummary(data, options) {
    const { indent = '', enableColors = false } = options;
    const c = enableColors ? {
        red: '\x1b[31m',
        green: '\x1b[32m',
        yellow: '\x1b[33m',
        blue: '\x1b[34m',
        reset: '\x1b[0m',
    } : {
        red: '', green: '', yellow: '', blue: '', reset: '',
    };
    
    let summary = `\n${indent}${c.blue}Performance Test Summary${c.reset}\n`;
    summary += `${indent}${'='.repeat(50)}\n\n`;
    
    // Test configuration
    summary += `${indent}${c.yellow}Configuration:${c.reset}\n`;
    summary += `${indent}  Duration: ${data.options.stages[1].duration}\n`;
    summary += `${indent}  Max VUs: ${data.options.stages[1].target}\n`;
    summary += `${indent}  Ramp-up: ${data.options.stages[0].duration}\n\n`;
    
    // Key metrics
    summary += `${indent}${c.yellow}Key Metrics:${c.reset}\n`;
    
    const metrics = data.metrics;
    
    // Request rate
    const iterations = metrics.iterations;
    if (iterations) {
        summary += `${indent}  Total Requests: ${iterations.values.count}\n`;
        summary += `${indent}  Request Rate: ${iterations.values.rate.toFixed(2)}/s\n`;
    }
    
    // Response times
    const httpDuration = metrics.http_req_duration;
    if (httpDuration) {
        summary += `${indent}  Response Times:\n`;
        summary += `${indent}    Min: ${httpDuration.values.min.toFixed(0)}ms\n`;
        summary += `${indent}    Avg: ${httpDuration.values.avg.toFixed(0)}ms\n`;
        summary += `${indent}    P95: ${httpDuration.values['p(95)'].toFixed(0)}ms\n`;
        summary += `${indent}    P99: ${httpDuration.values['p(99)'].toFixed(0)}ms\n`;
        summary += `${indent}    Max: ${httpDuration.values.max.toFixed(0)}ms\n`;
    }
    
    // Success rate
    const successRate = metrics.success_rate;
    if (successRate) {
        const rate = successRate.values.rate * 100;
        const color = rate >= 95 ? c.green : rate >= 90 ? c.yellow : c.red;
        summary += `${indent}  Success Rate: ${color}${rate.toFixed(2)}%${c.reset}\n`;
    }
    
    // Error rate
    const errorRate = metrics.errors;
    if (errorRate) {
        const rate = errorRate.values.rate * 100;
        const color = rate <= 5 ? c.green : rate <= 10 ? c.yellow : c.red;
        summary += `${indent}  Error Rate: ${color}${rate.toFixed(2)}%${c.reset}\n`;
    }
    
    // Thresholds
    summary += `\n${indent}${c.yellow}Thresholds:${c.reset}\n`;
    
    Object.entries(data.metrics).forEach(([name, metric]) => {
        if (metric.thresholds) {
            Object.entries(metric.thresholds).forEach(([threshold, passed]) => {
                const status = passed ? `${c.green}✓ PASS${c.reset}` : `${c.red}✗ FAIL${c.reset}`;
                summary += `${indent}  ${name} ${threshold}: ${status}\n`;
            });
        }
    });
    
    return summary;
}

// HTML report generator
function htmlReport(data) {
    return `
<!DOCTYPE html>
<html>
<head>
    <title>Performance Test Report</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 20px; }
        h1, h2 { color: #333; }
        .metric { margin: 10px 0; padding: 10px; background: #f5f5f5; border-radius: 5px; }
        .pass { color: green; }
        .fail { color: red; }
        table { border-collapse: collapse; width: 100%; margin: 20px 0; }
        th, td { border: 1px solid #ddd; padding: 8px; text-align: left; }
        th { background-color: #4CAF50; color: white; }
        tr:nth-child(even) { background-color: #f2f2f2; }
    </style>
</head>
<body>
    <h1>Performance Test Report</h1>
    <p>Generated: ${new Date().toISOString()}</p>
    
    <h2>Test Configuration</h2>
    <div class="metric">
        <p>Duration: ${data.options.stages[1].duration}</p>
        <p>Max Virtual Users: ${data.options.stages[1].target}</p>
        <p>Ramp-up Time: ${data.options.stages[0].duration}</p>
    </div>
    
    <h2>Key Metrics</h2>
    <table>
        <tr>
            <th>Metric</th>
            <th>Value</th>
            <th>Status</th>
        </tr>
        ${generateMetricRows(data.metrics)}
    </table>
    
    <h2>Response Time Distribution</h2>
    <div id="responseTimeChart"></div>
    
    <h2>Detailed Results</h2>
    <pre>${JSON.stringify(data, null, 2)}</pre>
</body>
</html>
    `;
}

function generateMetricRows(metrics) {
    let rows = '';
    Object.entries(metrics).forEach(([name, metric]) => {
        if (metric.values) {
            rows += `<tr><td>${name}</td><td>${JSON.stringify(metric.values)}</td><td>-</td></tr>`;
        }
    });
    return rows;
}
EOF
}

# Run k6 load test
run_k6_test() {
    print_info "Running k6 load test..."
    
    create_k6_script
    
    # Set environment variables for k6
    export SERVICE_URL="$SERVICE_URL"
    export DURATION="${DURATION}s"
    export USERS="$USERS"
    export RAMP_UP="${RAMP_UP}s"
    export ENVIRONMENT="$ENVIRONMENT"
    
    # Run k6 with output to JSON and console
    k6 run \
        --out json="$REPORT_DIR/$TIMESTAMP/k6-results.json" \
        --summary-export="$REPORT_DIR/$TIMESTAMP/k6-summary.json" \
        "$REPORT_DIR/$TIMESTAMP/load-test.js" \
        | tee "$REPORT_DIR/$TIMESTAMP/k6-output.log"
    
    local exit_code=$?
    
    if [ $exit_code -eq 0 ]; then
        print_success "K6 load test completed successfully"
    else
        print_error "K6 load test failed with exit code: $exit_code"
    fi
    
    return $exit_code
}

# Send metrics to monitoring system
send_metrics_to_monitoring() {
    print_info "Sending metrics to monitoring system..."
    
    # Read k6 summary
    if [ -f "$REPORT_DIR/$TIMESTAMP/k6-summary.json" ]; then
        local summary=$(cat "$REPORT_DIR/$TIMESTAMP/k6-summary.json")
        
        # Extract key metrics
        local total_requests=$(echo "$summary" | jq -r '.metrics.iterations.values.count // 0')
        local avg_response_time=$(echo "$summary" | jq -r '.metrics.http_req_duration.values.avg // 0')
        local p95_response_time=$(echo "$summary" | jq -r '.metrics."http_req_duration{expected_response:true}".values["p(95)"] // 0')
        local error_rate=$(echo "$summary" | jq -r '.metrics.http_req_failed.values.rate // 0')
        
        # Send to Application Insights (example)
        if [ ! -z "$APP_INSIGHTS_KEY" ]; then
            curl -X POST https://dc.services.visualstudio.com/v2/track \
                -H "Content-Type: application/json" \
                -d "{
                    \"name\": \"Microsoft.ApplicationInsights.Event\",
                    \"time\": \"$(date -u +%Y-%m-%dT%H:%M:%S.%3NZ)\",
                    \"iKey\": \"$APP_INSIGHTS_KEY\",
                    \"data\": {
                        \"baseType\": \"EventData\",
                        \"baseData\": {
                            \"name\": \"PerformanceTestCompleted\",
                            \"properties\": {
                                \"environment\": \"$ENVIRONMENT\",
                                \"duration\": \"$DURATION\",
                                \"users\": \"$USERS\",
                                \"totalRequests\": \"$total_requests\",
                                \"avgResponseTime\": \"$avg_response_time\",
                                \"p95ResponseTime\": \"$p95_response_time\",
                                \"errorRate\": \"$error_rate\",
                                \"timestamp\": \"$TIMESTAMP\"
                            }
                        }
                    }
                }"
        fi
    fi
}

# Generate performance report
generate_report() {
    print_info "Generating performance report..."
    
    # Create markdown report
    cat > "$REPORT_DIR/$TIMESTAMP/performance-report.md" << EOF
# Performance Test Report

**Date:** $(date)  
**Environment:** $ENVIRONMENT  
**Service URL:** $SERVICE_URL  
**Test Duration:** ${DURATION}s  
**Concurrent Users:** $USERS  
**Ramp-up Time:** ${RAMP_UP}s  

## Summary

EOF
    
    # Add k6 results if available
    if [ -f "$REPORT_DIR/$TIMESTAMP/k6-summary.json" ]; then
        local summary=$(cat "$REPORT_DIR/$TIMESTAMP/k6-summary.json")
        
        cat >> "$REPORT_DIR/$TIMESTAMP/performance-report.md" << EOF
### K6 Load Test Results

- **Total Requests:** $(echo "$summary" | jq -r '.metrics.iterations.values.count // "N/A"')
- **Request Rate:** $(echo "$summary" | jq -r '.metrics.iterations.values.rate // "N/A"') req/s
- **Success Rate:** $(echo "$summary" | jq -r '(1 - .metrics.http_req_failed.values.rate) * 100 // "N/A"' | xargs printf "%.2f")%
- **Average Response Time:** $(echo "$summary" | jq -r '.metrics.http_req_duration.values.avg // "N/A"' | xargs printf "%.0f") ms
- **P95 Response Time:** $(echo "$summary" | jq -r '.metrics.http_req_duration.values["p(95)"] // "N/A"' | xargs printf "%.0f") ms
- **P99 Response Time:** $(echo "$summary" | jq -r '.metrics.http_req_duration.values["p(99)"] // "N/A"' | xargs printf "%.0f") ms

### Threshold Results

EOF
        
        # Add threshold results
        echo "$summary" | jq -r '
            .metrics | to_entries[] | 
            select(.value.thresholds != null) | 
            .value.thresholds | to_entries[] | 
            "- **\(.key)**: \(if .value then "✅ PASS" else "❌ FAIL" end)"
        ' >> "$REPORT_DIR/$TIMESTAMP/performance-report.md" 2>/dev/null || echo "No threshold data available" >> "$REPORT_DIR/$TIMESTAMP/performance-report.md"
    fi
    
    print_success "Performance report generated: $REPORT_DIR/$TIMESTAMP/performance-report.md"
}

# Compare with baseline
compare_with_baseline() {
    print_info "Comparing with baseline..."
    
    local baseline_file="$REPORT_DIR/baseline.json"
    
    if [ -f "$baseline_file" ] && [ -f "$REPORT_DIR/$TIMESTAMP/k6-summary.json" ]; then
        # This would implement comparison logic
        print_info "Baseline comparison would be implemented here"
    else
        print_warning "No baseline found for comparison"
    fi
}

# Main execution
main() {
    print_info "Performance Test Script - Starting"
    
    # Check requirements
    check_requirements
    
    # Run load test
    if run_k6_test; then
        # Send metrics
        send_metrics_to_monitoring
        
        # Generate report
        generate_report
        
        # Compare with baseline
        compare_with_baseline
        
        print_success "Performance test completed successfully!"
        print_info "Reports available in: $REPORT_DIR/$TIMESTAMP/"
        
        # List generated files
        ls -la "$REPORT_DIR/$TIMESTAMP/"
        
        exit 0
    else
        print_error "Performance test failed!"
        exit 1
    fi
}

# Run main function
main 