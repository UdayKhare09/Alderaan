#!/bin/bash

# Test script for Alderaan Spring Boot application
BASE_URL="http://localhost:8080/api"
TOKEN=""
SESSION_ID=""

echo "=== Testing Alderaan Spring Boot Application ==="
echo

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

print_test() {
    echo -e "${YELLOW}Testing: $1${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

# Function to extract JSON string values
extract_json_string() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\":\"[^\"]*\"" | cut -d'"' -f4
}

# Function to extract JSON numeric values
extract_json_number() {
    local json="$1"
    local key="$2"
    echo "$json" | grep -o "\"$key\":[0-9]*" | cut -d':' -f2
}

# Test 1: Health Check
print_test "Health Check"
response=$(curl -s -w "%{http_code}" -o /tmp/health_response.json "$BASE_URL/test/health")
if [ "$response" = "200" ]; then
    print_success "Health check passed"
    cat /tmp/health_response.json
else
    print_error "Health check failed with status: $response"
    if [ -f /tmp/health_response.json ]; then
        cat /tmp/health_response.json
    fi
fi
echo

# Test 2: Echo Test
print_test "Echo Test"
echo '{"message": "Hello World", "test": true}' > /tmp/echo_payload.json
response=$(curl -s -w "%{http_code}" -o /tmp/echo_response.json \
    -H "Content-Type: application/json" \
    -d @/tmp/echo_payload.json \
    "$BASE_URL/test/echo")
if [ "$response" = "200" ]; then
    print_success "Echo test passed"
    cat /tmp/echo_response.json
else
    print_error "Echo test failed with status: $response"
    if [ -f /tmp/echo_response.json ]; then
        cat /tmp/echo_response.json
    fi
fi
echo

# Test 3: User Registration
print_test "User Registration"
USER_DATA='{
    "username": "testuser_'$(date +%s)'",
    "password": "testpass123",
    "email": "test_'$(date +%s)'@example.com"
}'
response=$(curl -s -w "%{http_code}" -o /tmp/register_response.json \
    -H "Content-Type: application/json" \
    -d "$USER_DATA" \
    "$BASE_URL/auth/register")
if [ "$response" = "200" ]; then
    print_success "User registration passed"
    response_body=$(cat /tmp/register_response.json)
    TOKEN=$(extract_json_string "$response_body" "token")
    USERNAME=$(extract_json_string "$response_body" "username")
    echo "Token: $TOKEN"
    echo "Username: $USERNAME"
    cat /tmp/register_response.json
else
    print_error "User registration failed with status: $response"
    if [ -f /tmp/register_response.json ]; then
        cat /tmp/register_response.json
    fi
fi
echo

# Test 4: Token Validation
if [ -n "$TOKEN" ]; then
    print_test "Token Validation"
    response=$(curl -s -w "%{http_code}" -o /tmp/validate_response.json \
        -H "Authorization: Bearer $TOKEN" \
        -X POST \
        "$BASE_URL/auth/validate")
    if [ "$response" = "200" ]; then
        print_success "Token validation passed"
        cat /tmp/validate_response.json
    else
        print_error "Token validation failed with status: $response"
        if [ -f /tmp/validate_response.json ]; then
            cat /tmp/validate_response.json
        fi
    fi
    echo
fi

# Test 5: Create Chat Session
if [ -n "$TOKEN" ]; then
    print_test "Create Chat Session"
    response=$(curl -s -w "%{http_code}" -o /tmp/session_response.json \
        -H "Authorization: Bearer $TOKEN" \
        -H "Content-Type: application/json" \
        -d '{"title": "Test Chat Session"}' \
        "$BASE_URL/chat/sessions")
    if [ "$response" = "200" ]; then
        print_success "Chat session creation passed"
        response_body=$(cat /tmp/session_response.json)
        SESSION_ID=$(extract_json_number "$response_body" "id")
        echo "Session ID: $SESSION_ID"
        cat /tmp/session_response.json
    else
        print_error "Chat session creation failed with status: $response"
        if [ -f /tmp/session_response.json ]; then
            cat /tmp/session_response.json
        fi
    fi
    echo
fi

# Test 6: Get Chat Sessions
if [ -n "$TOKEN" ]; then
    print_test "Get Chat Sessions"
    response=$(curl -s -w "%{http_code}" -o /tmp/sessions_response.json \
        -H "Authorization: Bearer $TOKEN" \
        "$BASE_URL/chat/sessions")
    if [ "$response" = "200" ]; then
        print_success "Get chat sessions passed"
        cat /tmp/sessions_response.json
    else
        print_error "Get chat sessions failed with status: $response"
        if [ -f /tmp/sessions_response.json ]; then
            cat /tmp/sessions_response.json
        fi
    fi
    echo
fi

# Test 7: AI Chat
if [ -n "$TOKEN" ] && [ -n "$SESSION_ID" ]; then
    print_test "AI Chat"
    response=$(curl -s -w "%{http_code}" -o /tmp/chat_response.json \
        -H "Authorization: Bearer $TOKEN" \
        -F "prompt=Hello, how are you?" \
        -F "sessionId=$SESSION_ID" \
        "$BASE_URL/ai/chat")
    if [ "$response" = "200" ]; then
        print_success "AI chat passed"
        cat /tmp/chat_response.json
    else
        print_error "AI chat failed with status: $response"
        if [ -f /tmp/chat_response.json ]; then
            cat /tmp/chat_response.json
        fi
    fi
    echo
fi

# Test 8: Get Session Messages
if [ -n "$TOKEN" ] && [ -n "$SESSION_ID" ]; then
    print_test "Get Session Messages"
    response=$(curl -s -w "%{http_code}" -o /tmp/messages_response.json \
        -H "Authorization: Bearer $TOKEN" \
        "$BASE_URL/chat/sessions/$SESSION_ID/messages")
    if [ "$response" = "200" ]; then
        print_success "Get session messages passed"
        cat /tmp/messages_response.json
    else
        print_error "Get session messages failed with status: $response"
        if [ -f /tmp/messages_response.json ]; then
            cat /tmp/messages_response.json
        fi
    fi
    echo
fi

# Test 9: Speech Synthesis (if TTS service is running)
print_test "Speech Synthesis"
response=$(curl -s -w "%{http_code}" -o /tmp/tts_response.wav \
    -F "text=Hello, this is a test" \
    "$BASE_URL/speech/synthesize")
if [ "$response" = "200" ]; then
    print_success "Speech synthesis passed"
    echo "Audio file saved to /tmp/tts_response.wav"
    ls -la /tmp/tts_response.wav
else
    print_error "Speech synthesis failed with status: $response (TTS service may not be running)"
fi
echo

echo "=== Test Summary ==="
echo "Base URL: $BASE_URL"
echo "Test completed at: $(date)"
echo

# Cleanup (moved to end)
print_test "Cleanup"
rm -f /tmp/*_response.json /tmp/*_payload.json /tmp/tts_response.wav
print_success "Cleanup completed"