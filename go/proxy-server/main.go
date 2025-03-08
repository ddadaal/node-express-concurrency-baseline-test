package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"time"
)

func main() {

	if os.Getenv("NO_LOG") == "true" {
		log.SetOutput(io.Discard) // Disable logging if NO_LOG is set
	}

	// Create a custom HTTP client with timeout settings
	client := &http.Client{
		Timeout: 30 * time.Second,
	}

	// Handler for forwarding requests to target server
	http.HandleFunc("/proxy/", func(w http.ResponseWriter, r *http.Request) {
		startTime := time.Now()

		// Extract the path suffix after /proxy/
		pathSuffix := strings.TrimPrefix(r.URL.Path, "/proxy/")

		// Build the target URL with the extracted path
		targetURL := fmt.Sprintf("http://localhost:5001/%s", pathSuffix)

		// Prepare request to target server
		req, err := http.NewRequest(r.Method, targetURL, r.Body)
		if err != nil {
			http.Error(w, "Failed to create request", http.StatusInternalServerError)
			return
		}

		// Copy headers from original request
		for name, values := range r.Header {
			for _, value := range values {
				req.Header.Add(name, value)
			}
		}

		// Send request to target server
		resp, err := client.Do(req)
		if err != nil {
			http.Error(w, "Failed to forward request", http.StatusInternalServerError)
			return
		}
		defer resp.Body.Close()

		// Read response body
		body, err := io.ReadAll(resp.Body)
		if err != nil {
			http.Error(w, "Failed to read response", http.StatusInternalServerError)
			return
		}

		// Log the request duration
		duration := time.Since(startTime)
		log.Printf("Request to %s forwarded and completed in %v", targetURL, duration)

		// Set the appropriate content type
		w.Header().Set("Content-Type", "application/json")
		w.WriteHeader(resp.StatusCode)
		w.Write(body)
	})

	// Start the server on port 3000
	port := 5000
	fmt.Printf("Proxy server listening on port %d...\n", port)
	err := http.ListenAndServe(fmt.Sprintf(":%d", port), nil)
	if err != nil {
		log.Fatalf("Failed to start server: %v", err)
	}
}
