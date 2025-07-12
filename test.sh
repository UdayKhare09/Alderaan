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

# Test 10: Speech Recognition (if STT service is running)
print_test "Speech Recognition"

response=$(curl -s -w "%{http_code}" -o /tmp/stt_response.json \
    -F "audio=@/tmp/tts_response.wav" \
    "$BASE_URL/speech/recognize")
if [ "$response" = "200" ]; then
    print_success "Speech recognition passed"
    cat /tmp/stt_response.json
else
    print_error "Speech recognition failed with status: $response (STT service may not be running)"
    if [ -f /tmp/stt_response.json ]; then
        cat /tmp/stt_response.json
    fi
fi
echo

# Test 11: AI Chat with Speech
if [ -n "$TOKEN" ] && [ -n "$SESSION_ID" ]; then
    print_test "AI Chat with Speech"
    response=$(curl -s -w "%{http_code}" -o /tmp/ai_speech_response.wav \
        -H "Authorization: Bearer $TOKEN" \
        -F "prompt=Say something in audio" \
        -F "sessionId=$SESSION_ID" \
        "$BASE_URL/ai/chat/speech")
    if [ "$response" = "200" ]; then
        print_success "AI chat with speech passed"
        echo "Audio file saved to /tmp/ai_speech_response.wav"
        ls -la /tmp/ai_speech_response.wav
    else
        print_error "AI chat with speech failed with status: $response"
    fi
    echo
fi

# Test 12: Voice-to-Voice Chat
if [ -n "$TOKEN" ] && [ -n "$SESSION_ID" ]; then
    print_test "Voice-to-Voice Chat"
    response=$(curl -s -w "%{http_code}" -o /tmp/voice2voice_response.wav \
        -H "Authorization: Bearer $TOKEN" \
        -F "audio=@/tmp/tts_response.wav" \
        -F "sessionId=$SESSION_ID" \
        "$BASE_URL/ai/chat/voice")
    if [ "$response" = "200" ]; then
        print_success "Voice-to-voice chat passed"
        echo "Audio file saved to /tmp/voice2voice_response.wav"
        ls -la /tmp/voice2voice_response.wav
    else
        print_error "Voice-to-voice chat failed with status: $response"
    fi
    echo
fi






# Test Context Awareness - Multiple sequential messages
test_context_awareness() {
    if [ -n "$TOKEN" ] && [ -n "$SESSION_ID" ]; then
        print_test "Context Awareness Test - Sequential Messages"

        # Message 1: Establish context
        echo "Sending first message to establish context..."
        response1=$(curl -s -w "%{http_code}" -o /tmp/context1_response.json \
            -H "Authorization: Bearer $TOKEN" \
            -F "prompt=My name is John and I work as a software engineer." \
            -F "sessionId=$SESSION_ID" \
            "$BASE_URL/ai/chat")

        if [ "$response1" = "200" ]; then
            print_success "First context message sent"
            echo "AI Response 1:"
            cat /tmp/context1_response.json | grep -o '"content":"[^"]*"' | cut -d'"' -f4
        else
            print_error "First context message failed"
            return
        fi

        sleep 2

        # Message 2: Reference previous context
        echo -e "\nSending second message that references previous context..."
        response2=$(curl -s -w "%{http_code}" -o /tmp/context2_response.json \
            -H "Authorization: Bearer $TOKEN" \
            -F "prompt=What is my name and profession?" \
            -F "sessionId=$SESSION_ID" \
            "$BASE_URL/ai/chat")

        if [ "$response2" = "200" ]; then
            print_success "Second context message sent"
            echo "AI Response 2:"
            ai_response=$(cat /tmp/context2_response.json | grep -o '"content":"[^"]*"' | cut -d'"' -f4)
            echo "$ai_response"

            # Check if AI remembered the context
            if echo "$ai_response" | grep -i "john" > /dev/null && echo "$ai_response" | grep -i "software engineer" > /dev/null; then
                print_success "✓ Context awareness PASSED - AI remembered name and profession"
            else
                print_error "✗ Context awareness FAILED - AI did not remember previous context"
                echo "Expected: Response mentioning 'John' and 'software engineer'"
                echo "Actual: $ai_response"
            fi
        else
            print_error "Second context message failed"
        fi

        sleep 2

        # Message 3: Test deeper context
        echo -e "\nSending third message to test deeper context..."
        response3=$(curl -s -w "%{http_code}" -o /tmp/context3_response.json \
            -H "Authorization: Bearer $TOKEN" \
            -F "prompt=What programming languages might I use in my job?" \
            -F "sessionId=$SESSION_ID" \
            "$BASE_URL/ai/chat")

        if [ "$response3" = "200" ]; then
            print_success "Third context message sent"
            echo "AI Response 3:"
            ai_response3=$(cat /tmp/context3_response.json | grep -o '"content":"[^"]*"' | cut -d'"' -f4)
            echo "$ai_response3"

            # Check if AI understood the job context
            if echo "$ai_response3" | grep -iE "(java|python|javascript|programming|code)" > /dev/null; then
                print_success "✓ Deep context awareness PASSED - AI understood job-related question"
            else
                print_error "✗ Deep context awareness FAILED - AI did not connect job context"
            fi
        else
            print_error "Third context message failed"
        fi

        echo
    fi
}

# Test Voice Context Awareness
test_voice_context_awareness() {
    if [ -n "$TOKEN" ] && [ -n "$SESSION_ID" ]; then
        print_test "Voice Context Awareness Test"

        # First establish context via text
        echo "Establishing context via text..."
        curl -s -H "Authorization: Bearer $TOKEN" \
            -F "prompt=I am planning a vacation to Paris next month." \
            -F "sessionId=$SESSION_ID" \
            "$BASE_URL/ai/chat" > /tmp/voice_context_setup.json

        sleep 2

        # Then test voice response with context
        echo "Testing voice response with established context..."
        response=$(curl -s -w "%{http_code}" -o /tmp/voice_context_response.wav \
            -H "Authorization: Bearer $TOKEN" \
            -F "prompt=What should I pack for my trip?" \
            -F "sessionId=$SESSION_ID" \
            "$BASE_URL/ai/chat/speech")

        if [ "$response" = "200" ]; then
            print_success "Voice context test completed"
            echo "Audio response saved to /tmp/voice_context_response.wav"

            # Get the text version to verify context
            curl -s -H "Authorization: Bearer $TOKEN" \
                -F "prompt=What should I pack for my trip?" \
                -F "sessionId=$SESSION_ID" \
                "$BASE_URL/ai/chat" > /tmp/voice_context_text.json

            text_response=$(cat /tmp/voice_context_text.json | grep -o '"content":"[^"]*"' | cut -d'"' -f4)
            if echo "$text_response" | grep -iE "(paris|france|europe|trip|vacation)" > /dev/null; then
                print_success "✓ Voice context awareness PASSED - AI remembered Paris trip"
            else
                print_error "✗ Voice context awareness FAILED - AI did not remember trip context"
                echo "Response: $text_response"
            fi
        else
            print_error "Voice context test failed with status: $response"
        fi

        echo
    fi
}

# Test Cross-Modal Context (Text to Voice to Text)
test_cross_modal_context() {
    if [ -n "$TOKEN" ] && [ -n "$SESSION_ID" ]; then
        print_test "Cross-Modal Context Test (Text → Voice → Text)"

        # Step 1: Text message
        echo "Step 1: Sending text message..."
        curl -s -H "Authorization: Bearer $TOKEN" \
            -F "prompt=I have a pet cat named Whiskers who loves tuna." \
            -F "sessionId=$SESSION_ID" \
            "$BASE_URL/ai/chat" > /tmp/crossmodal1.json

        sleep 1

        # Step 2: Voice response (should remember cat context)
        echo "Step 2: Getting voice response about the pet..."
        curl -s -H "Authorization: Bearer $TOKEN" \
            -F "prompt=What does my pet like to eat?" \
            -F "sessionId=$SESSION_ID" \
            "$BASE_URL/ai/chat/speech" > /tmp/crossmodal_voice.wav

        sleep 1

        # Step 3: Text follow-up (should still remember)
        echo "Step 3: Text follow-up question..."
        response=$(curl -s -w "%{http_code}" -o /tmp/crossmodal3.json \
            -H "Authorization: Bearer $TOKEN" \
            -F "prompt=What is my pet's name?" \
            -F "sessionId=$SESSION_ID" \
            "$BASE_URL/ai/chat")

        if [ "$response" = "200" ]; then
            final_response=$(cat /tmp/crossmodal3.json | grep -o '"content":"[^"]*"' | cut -d'"' -f4)
            echo "Final response: $final_response"

            if echo "$final_response" | grep -i "whiskers" > /dev/null; then
                print_success "✓ Cross-modal context PASSED - AI remembered across text/voice interactions"
            else
                print_error "✗ Cross-modal context FAILED - AI forgot pet name across modalities"
                echo "Expected: Response mentioning 'Whiskers'"
                echo "Actual: $final_response"
            fi
        else
            print_error "Cross-modal context test failed"
        fi

        echo
    fi
}

# Test Context Limits
test_context_limits() {
    if [ -n "$TOKEN" ] && [ -n "$SESSION_ID" ]; then
        print_test "Context Memory Limits Test"

        echo "Sending multiple messages to test memory limits..."

        # Send several messages to approach the limit
        for i in {1..5}; do
            echo "Sending message $i..."
            curl -s -H "Authorization: Bearer $TOKEN" \
                -F "prompt=Message $i: I like the color $([ $((i % 2)) -eq 0 ] && echo 'blue' || echo 'red'). Remember this number: $i." \
                -F "sessionId=$SESSION_ID" \
                "$BASE_URL/ai/chat" > /tmp/limit_test_$i.json
            sleep 1
        done

        # Test if AI remembers early vs recent messages
        echo "Testing memory of first message..."
        response1=$(curl -s -o /tmp/memory_test1.json \
            -H "Authorization: Bearer $TOKEN" \
            -F "prompt=What number did I mention in my first message?" \
            -F "sessionId=$SESSION_ID" \
            "$BASE_URL/ai/chat")

        echo "Testing memory of recent message..."
        response2=$(curl -s -o /tmp/memory_test2.json \
            -H "Authorization: Bearer $TOKEN" \
            -F "prompt=What number did I mention in my last message?" \
            -F "sessionId=$SESSION_ID" \
            "$BASE_URL/ai/chat")

        recent_response=$(cat /tmp/memory_test2.json | grep -o '"content":"[^"]*"' | cut -d'"' -f4)
        early_response=$(cat /tmp/memory_test1.json | grep -o '"content":"[^"]*"' | cut -d'"' -f4)

        echo "Response about recent message: $recent_response"
        echo "Response about early message: $early_response"

        # Check if recent memory is better than distant memory
        if echo "$recent_response" | grep "5" > /dev/null; then
            print_success "✓ Recent memory working correctly"
        else
            print_error "✗ Recent memory failed"
        fi

        if echo "$early_response" | grep "1" > /dev/null; then
            print_success "✓ Early memory still retained"
        else
            echo "⚠ Early memory may have been forgotten (expected behavior with limits)"
        fi

        echo
    fi
}




# Test 13: Context Awareness - Multiple sequential messages
test_context_awareness
echo

# Test 14: Voice Context Awareness
test_voice_context_awareness
echo

# Test 15: Cross-Modal Context (Text to Voice to Text)
test_cross_modal_context
echo

# Test 16: Context Limits
test_context_limits
echo

# Test 17: Delete Chat Session
if [ -n "$TOKEN" ] && [ -n "$SESSION_ID" ]; then
    print_test "Delete Chat Session"
    response=$(curl -s -w "%{http_code}" -o /tmp/delete_session_response.json \
        -H "Authorization: Bearer $TOKEN" \
        -X DELETE \
        "$BASE_URL/chat/sessions/$SESSION_ID")
    if [ "$response" = "200" ]; then
        print_success "Delete chat session passed"
    else
        print_error "Delete chat session failed with status: $response"
        if [ -f /tmp/delete_session_response.json ]; then
            cat /tmp/delete_session_response.json
        fi
    fi
    echo
fi

# Final summary
echo "=== Test Summary ==="
echo "Base URL: $BASE_URL"
echo "Test completed at: $(date)"
echo

# Cleanup (moved to end)
print_test "Cleanup"
rm -f /tmp/*_response.json /tmp/*_payload.json /tmp/tts_response.wav /tmp/test_audio.wav /tmp/ai_speech_response.wav /tmp/voice2voice_response.wav /tmp/voice_context_response.wav /tmp/crossmodal_voice.wav /tmp/crossmodal1.json /tmp/crossmodal3.json /tmp/voice_context_setup.json /tmp/voice_context_text.json
print_success "Cleanup completed"