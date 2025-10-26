#!/bin/bash

# Configuration
API_URL="http://localhost:8080/api/payments"
NUM_REQUESTS=${1:-100}  # Default 100, can be overridden
SIMULATION_MODE=${2:-"normal"}  # normal, burst, peak, stress, realistic, failure, custom
MAX_CONCURRENT=${3:-5}  # Maximum concurrent requests

# Custom rate parameters (can be set via command line)
SUCCESS_RATE=84
FAILURE_RATE=1
PENDING_RATE=15

# Parse additional parameters for custom rates
shift 3  # Skip first 3 parameters
while [[ $# -gt 0 ]]; do
    case $1 in
        success)
            SUCCESS_RATE="$2"
            shift 2
            ;;
        failure)
            FAILURE_RATE="$2"
            shift 2
            ;;
        pending)
            PENDING_RATE="$2"
            shift 2
            ;;
        *)
            shift
            ;;
    esac
done

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Statistics
TOTAL_SUCCESS=0
TOTAL_FAILED=0
TOTAL_AMOUNT=0

# Function to generate a random amount based on distribution
random_amount() {
    local mode=$1
    if [ "$mode" = "failure" ]; then
        # Generate amounts that might trigger failures
        local rand=$((RANDOM % 100))
        if [ $rand -lt 20 ]; then
            echo "-10.50"  # Negative amount
        elif [ $rand -lt 40 ]; then
            echo "0"  # Zero amount
        elif [ $rand -lt 60 ]; then
            echo "999999.99"  # Extremely high amount
        else
            echo "0.0"  # Normal amount
        fi
    else
        # Use 0.0 to let API generate realistic distribution
        # 80% < 200€, 15% 200-1000€, 5% > 1000€
        echo "0.0"
    fi
}

# Function to generate specific amount for testing
specific_amount() {
    local range=$1
    case $range in
        "small")
            printf "%.2f" $(echo "scale=2; 10 + $RANDOM * 190 / 32767" | bc)
            ;;
        "medium")
            printf "%.2f" $(echo "scale=2; 200 + $RANDOM * 800 / 32767" | bc)
            ;;
        "large")
            printf "%.2f" $(echo "scale=2; 1000 + $RANDOM * 5000 / 32767" | bc)
            ;;
        *)
            random_amount
            ;;
    esac
}

# Function to generate a random currency
random_currency() {
    local mode=$1
    if [ "$mode" = "failure" ]; then
        # Mix valid and invalid currencies
        local rand=$((RANDOM % 100))
        if [ $rand -lt 30 ]; then
            echo "XXX"  # Invalid currency
        elif [ $rand -lt 50 ]; then
            echo ""  # Empty currency
        elif [ $rand -lt 60 ]; then
            echo "INVALID"
        else
            # Valid currencies
            currencies=("EUR" "USD" "GBP" "CHF" "JPY")
            echo "${currencies[$((RANDOM % ${#currencies[@]}))]}"
        fi
    else
        currencies=("EUR" "USD" "GBP" "CHF" "JPY")
        weights=(50 25 15 7 3)  # Percentage weights
        rand=$((RANDOM % 100))
        
        if [ $rand -lt 50 ]; then
            echo "EUR"
        elif [ $rand -lt 75 ]; then
            echo "USD"
        elif [ $rand -lt 90 ]; then
            echo "GBP"
        elif [ $rand -lt 97 ]; then
            echo "CHF"
        else
            echo "JPY"
        fi
    fi
}

# Function to generate a random customer ID with realistic distribution
random_customer() {
    local mode=$1
    if [ "$mode" = "failure" ]; then
        # Generate problematic customer IDs
        local rand=$((RANDOM % 100))
        if [ $rand -lt 20 ]; then
            echo ""  # Empty customer ID
        elif [ $rand -lt 40 ]; then
            echo "blocked_customer_001"  # Blocked customer
        elif [ $rand -lt 60 ]; then
            echo "fraud_risk_999"  # Fraud risk customer
        else
            printf "cust_%05d" $(shuf -i 1-5000 -n 1)
        fi
    else
        # 20% returning customers (lower IDs), 80% various customers
        rand=$((RANDOM % 100))
        if [ $rand -lt 20 ]; then
            # Returning customers
            printf "cust_%05d" $(shuf -i 1-100 -n 1)
        else
            # Regular customers
            printf "cust_%05d" $(shuf -i 1-5000 -n 1)
        fi
    fi
}

# Function to get delay based on simulation mode
get_delay() {
    local mode=$1
    case $mode in
        "burst")
            echo "0.1"  # Very fast
            ;;
        "peak")
            echo "0.5"  # High traffic
            ;;
        "normal")
            echo $(echo "scale=2; 1 + $RANDOM * 2 / 32767" | bc)
            ;;
        "realistic")
            # Variable delay simulating real-world patterns
            echo $(echo "scale=2; 0.5 + $RANDOM * 4.5 / 32767" | bc)
            ;;
        "stress")
            echo "0.01"  # Maximum stress
            ;;
        *)
            echo "1"
            ;;
    esac
}

# Function to make a payment request
make_payment() {
    local amount=$1
    local currency=$2
    local customer=$3
    local request_num=$4
    local force_malformed=$5
    
    start_time=$(date +%s.%N)
    
    # Generate malformed requests for failure testing
    if [ "$force_malformed" = "true" ]; then
        local rand=$((RANDOM % 5))
        case $rand in
            0)
                # Missing required fields
                response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
                    -H "Content-Type: application/json" \
                    -H "X-Success-Rate: $SUCCESS_RATE" \
                    -H "X-Failure-Rate: $FAILURE_RATE" \
                    -H "X-Pending-Rate: $PENDING_RATE" \
                    -d "{\"currency\":\"$currency\"}" 2>/dev/null)
                ;;
            1)
                # Invalid JSON
                response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
                    -H "Content-Type: application/json" \
                    -H "X-Success-Rate: $SUCCESS_RATE" \
                    -H "X-Failure-Rate: $FAILURE_RATE" \
                    -H "X-Pending-Rate: $PENDING_RATE" \
                    -d "{amount:$amount,currency:$currency" 2>/dev/null)
                ;;
            2)
                # Wrong content type
                response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
                    -H "Content-Type: text/plain" \
                    -H "X-Success-Rate: $SUCCESS_RATE" \
                    -H "X-Failure-Rate: $FAILURE_RATE" \
                    -H "X-Pending-Rate: $PENDING_RATE" \
                    -d "amount=$amount&currency=$currency" 2>/dev/null)
                ;;
            3)
                # Timeout simulation (very large payload)
                response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
                    -H "Content-Type: application/json" \
                    -H "X-Success-Rate: $SUCCESS_RATE" \
                    -H "X-Failure-Rate: $FAILURE_RATE" \
                    -H "X-Pending-Rate: $PENDING_RATE" \
                    -d "{\"amount\":$amount,\"currency\":\"$currency\",\"customer_id\":\"$customer\",\"description\":\"$(head -c 10000 < /dev/zero | tr '\0' 'x')\"}" 2>/dev/null)
                ;;
            *)
                # Duplicate transaction ID
                response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
                    -H "Content-Type: application/json" \
                    -H "X-Success-Rate: $SUCCESS_RATE" \
                    -H "X-Failure-Rate: $FAILURE_RATE" \
                    -H "X-Pending-Rate: $PENDING_RATE" \
                    -d "{\"amount\":$amount,\"currency\":\"$currency\",\"customer_id\":\"$customer\",\"idempotency_key\":\"duplicate_001\"}" 2>/dev/null)
                ;;
        esac
    else
        response=$(curl -s -w "\n%{http_code}" -X POST "$API_URL" \
            -H "Content-Type: application/json" \
            -H "X-Success-Rate: $SUCCESS_RATE" \
            -H "X-Failure-Rate: $FAILURE_RATE" \
            -H "X-Pending-Rate: $PENDING_RATE" \
            -d "{\"amount\":$amount,\"currency\":\"$currency\",\"customer_id\":\"$customer\"}" 2>/dev/null)
    fi
    
    http_code=$(echo "$response" | tail -n1)
    response_body=$(echo "$response" | head -n-1)
    end_time=$(date +%s.%N)
    duration=$(echo "$end_time - $start_time" | bc)
    
    if [ "$http_code" -eq 200 ]; then
        TOTAL_SUCCESS=$((TOTAL_SUCCESS + 1))
        payment_id=$(echo "$response_body" | grep -o '"payment_id":"[^"]*"' | cut -d'"' -f4)
        amount_paid=$(echo "$response_body" | grep -o '"amount":[0-9.]*' | cut -d':' -f2)
        TOTAL_AMOUNT=$(echo "$TOTAL_AMOUNT + $amount_paid" | bc)
        echo -e "[${request_num}] ${GREEN}✓${NC} Payment $payment_id | ${amount_paid} $currency | Customer: $customer | ${duration}s"
    else
        TOTAL_FAILED=$((TOTAL_FAILED + 1))
        error_msg=$(echo "$response_body" | grep -o '"detail":"[^"]*"' | cut -d'"' -f4)
        if [ -z "$error_msg" ]; then
            error_msg="Unknown error"
        fi
        echo -e "[${request_num}] ${RED}✗${NC} HTTP $http_code | $amount $currency | Customer: $customer | Error: $error_msg | ${duration}s"
    fi
}

# Function to run concurrent payments
run_concurrent_batch() {
    local batch_size=$1
    local start_index=$2
    
    for ((j=0; j<batch_size; j++)); do
        local i=$((start_index + j))
        amount=$(random_amount)
        currency=$(random_currency)
        customer=$(random_customer)
        make_payment "$amount" "$currency" "$customer" "$i" &
    done
    wait
}

# Function to display statistics
show_stats() {
    local elapsed=$1
    local total=$((TOTAL_SUCCESS + TOTAL_FAILED))
    local success_rate=0
    
    if [ $total -gt 0 ]; then
        success_rate=$(echo "scale=2; $TOTAL_SUCCESS * 100 / $total" | bc)
    fi
    
    echo -e "\n${BLUE}========================================${NC}"
    echo -e "${BLUE}📊 Simulation Statistics${NC}"
    echo -e "${BLUE}========================================${NC}"
    echo -e "Mode:             ${YELLOW}${SIMULATION_MODE}${NC}"
    echo -e "Duration:         ${elapsed}s"
    echo -e "Total Requests:   $total"
    echo -e "${GREEN}Successful:       $TOTAL_SUCCESS${NC}"
    echo -e "${RED}Failed:           $TOTAL_FAILED${NC}"
    echo -e "Success Rate:     ${success_rate}%"
    echo -e "Total Amount:     €$(printf "%.2f" $TOTAL_AMOUNT)"
    
    if [ $total -gt 0 ] && [ "$(echo "$elapsed > 0" | bc)" -eq 1 ]; then
        local tps=$(echo "scale=2; $total / $elapsed" | bc)
        echo -e "Throughput:       ${tps} req/s"
    fi
    echo -e "${BLUE}========================================${NC}"
}

# Display banner
echo -e "${BLUE}========================================${NC}"
echo -e "${BLUE}🚀 Payment API Simulation${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "API URL:          $API_URL"
echo -e "Requests:         $NUM_REQUESTS"
echo -e "Mode:             ${YELLOW}${SIMULATION_MODE}${NC}"
echo -e "Max Concurrent:   $MAX_CONCURRENT"
echo -e "${GREEN}Success Rate:     ${SUCCESS_RATE}%${NC}"
echo -e "${RED}Failure Rate:     ${FAILURE_RATE}%${NC}"
echo -e "${YELLOW}Pending Rate:     ${PENDING_RATE}%${NC}"
echo -e "${BLUE}========================================${NC}\n"

# Check API health
echo -e "${YELLOW}🔍 Checking API health...${NC}"
health_response=$(curl -s "http://localhost:8080/health" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ API is healthy${NC}\n"
else
    echo -e "${RED}✗ API is not responding. Please start the service.${NC}"
    exit 1
fi

# Start simulation timer
START_TIME=$(date +%s)

case $SIMULATION_MODE in
    "burst")
        echo -e "${YELLOW}⚡ Running BURST mode (high-speed sequential)${NC}\n"
        for ((i=1; i<=NUM_REQUESTS; i++)); do
            amount=$(random_amount)
            currency=$(random_currency)
            customer=$(random_customer)
            make_payment "$amount" "$currency" "$customer" "$i"
            sleep $(get_delay "burst")
        done
        ;;
    
    "peak")
        echo -e "${YELLOW}📈 Running PEAK mode (high concurrent traffic)${NC}\n"
        for ((i=1; i<=NUM_REQUESTS; i+=MAX_CONCURRENT)); do
            batch_size=$MAX_CONCURRENT
            if [ $((i + batch_size)) -gt $NUM_REQUESTS ]; then
                batch_size=$((NUM_REQUESTS - i + 1))
            fi
            run_concurrent_batch $batch_size $i
            sleep $(get_delay "peak")
        done
        ;;
    
    "stress")
        echo -e "${RED}💥 Running STRESS mode (maximum load)${NC}\n"
        for ((i=1; i<=NUM_REQUESTS; i+=MAX_CONCURRENT)); do
            batch_size=$MAX_CONCURRENT
            if [ $((i + batch_size)) -gt $NUM_REQUESTS ]; then
                batch_size=$((NUM_REQUESTS - i + 1))
            fi
            run_concurrent_batch $batch_size $i
            sleep $(get_delay "stress")
        done
        ;;
    
    "realistic")
        echo -e "${YELLOW}🌍 Running REALISTIC mode (variable traffic patterns)${NC}\n"
        for ((i=1; i<=NUM_REQUESTS; i++)); do
            # Simulate concurrent batches occasionally
            if [ $((RANDOM % 10)) -lt 3 ] && [ $((NUM_REQUESTS - i)) -ge 3 ]; then
                echo -e "${BLUE}[Concurrent batch]${NC}"
                run_concurrent_batch 3 $i
                i=$((i + 2))
            else
                amount=$(random_amount)
                currency=$(random_currency)
                customer=$(random_customer)
                make_payment "$amount" "$currency" "$customer" "$i"
            fi
            sleep $(get_delay "realistic")
        done
        ;;
    
    "failure")
        echo -e "${RED}💣 Running FAILURE mode (high error rate testing)${NC}"
        echo -e "${RED}Target failure rate: ${FAILURE_RATE}%${NC}\n"
        for ((i=1; i<=NUM_REQUESTS; i++)); do
            # Determine if this request should fail
            should_fail=$((RANDOM % 100))
            if [ $should_fail -lt $FAILURE_RATE ]; then
                # Generate problematic request
                amount=$(random_amount "failure")
                currency=$(random_currency "failure")
                customer=$(random_customer "failure")
                # 50% chance of malformed request
                if [ $((RANDOM % 2)) -eq 0 ]; then
                    make_payment "$amount" "$currency" "$customer" "$i" "true"
                else
                    make_payment "$amount" "$currency" "$customer" "$i" "false"
                fi
            else
                # Normal request
                amount=$(random_amount)
                currency=$(random_currency)
                customer=$(random_customer)
                make_payment "$amount" "$currency" "$customer" "$i" "false"
            fi
            sleep $(get_delay "normal")
        done
        ;;
    
    *)
        echo -e "${YELLOW}⚙️  Running NORMAL mode (standard traffic)${NC}\n"
        for ((i=1; i<=NUM_REQUESTS; i++)); do
            amount=$(random_amount)
            currency=$(random_currency)
            customer=$(random_customer)
            make_payment "$amount" "$currency" "$customer" "$i"
            sleep $(get_delay "normal")
        done
        ;;
esac

# Calculate elapsed time
END_TIME=$(date +%s)
ELAPSED=$((END_TIME - START_TIME))

# Display final statistics
show_stats $ELAPSED

echo -e "\n${GREEN}✅ Simulation completed!${NC}"
echo -e "\nUsage: $0 [num_requests] [mode] [max_concurrent] [success N] [failure N] [pending N]"
echo -e "Modes: normal, burst, peak, stress, realistic, failure"
echo -e "\nExamples:"
echo -e "  $0 100 normal 5                              # Normal mode with default rates"
echo -e "  $0 100 normal 5 success 70 failure 10 pending 20  # Custom rates: 70% success, 10% failure, 20% pending"
echo -e "  $0 500 peak 10 success 90 failure 5 pending 5     # Peak mode with 90% success rate"
echo -e "  $0 200 burst 3 success 50 failure 30 pending 20   # Burst mode with high failure rate\n"
