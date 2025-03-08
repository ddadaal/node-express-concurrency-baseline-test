package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"time"
)

// simulateHeavyTask simulates a CPU-bound task
func simulateHeavyTask(delay time.Duration) {
	time.Sleep(delay)
}

func main() {

	if os.Getenv("NO_LOG") == "true" {
		log.SetOutput(io.Discard) // Disable logging if NO_LOG is set
	}

	var delayDuration time.Duration
	delay := os.Getenv("DELAY")
	if delay != "" {
		// Parse the delay value from the environment variable
		d, err := time.ParseDuration(delay)
		if err != nil {
			log.Fatalf("Invalid DELAY value: %v", err)
		}
		delayDuration = d
	}

	// Handler for task endpoint
	http.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		// Perform heavy task
		simulateHeavyTask(delayDuration)

		// Return a JSON response
		w.Header().Set("Content-Type", "application/json")
		w.Write([]byte(`{"message": "task completed"}`))
	})

	// Start the server on port 3001
	port := 5001
	fmt.Printf("Target server listening on port %d...\n", port)
	err := http.ListenAndServe(fmt.Sprintf(":%d", port), nil)
	if err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
