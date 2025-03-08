import express from 'express';
import { env } from "process";

const app = express();
const PORT = 5000;
// Use the service name from docker-compose instead of localhost when in Docker
const TARGET = process.env.NODE_ENV === 'production' 
  ? 'http://target-server:5001' 
  : 'http://localhost:5001';

// Helper function to handle logging based on env.NO_LOG
const log = (message: string) => {
  if (!env.NO_LOG) {
    console.log(message);
  }
};

// Helper function for error logs that also respects NO_LOG setting
const logError = (message: string, error: any) => {
  if (!env.NO_LOG) {
    console.error(message, error);
  }
};

// Parse JSON bodies
app.use(express.json());
// Parse URL-encoded bodies
app.use(express.urlencoded({ extended: true }));

// Proxy handler for all requests to /proxy/*
app.all('/proxy/*', async (req, res) => {
  try {
    // Extract the target path by removing '/proxy' prefix
    const targetPath = req.url.replace(/^\/proxy/, '');
    const targetUrl = `${TARGET}${targetPath}`;
    
    log(`Proxying request to: ${targetUrl}`);

    // Prepare headers (excluding host which can cause issues)
    const headers: Record<string, string> = {};
    for (const [key, value] of Object.entries(req.headers)) {
      // Skip host header and undefined/array values
      if (key !== 'host' && value !== undefined && typeof value === 'string') {
        headers[key] = value;
      }
    }

    // Make the request to the target server
    const response = await fetch(targetUrl, {
      method: req.method,
      headers,
      body: ['GET', 'HEAD'].includes(req.method) ? undefined : JSON.stringify(req.body),
    });

    log(`Received response from: ${targetUrl}`);
    
    // Forward the status code
    res.status(response.status);

    // Forward all response headers
    response.headers.forEach((value, key) => {
      res.setHeader(key, value);
    });

    // Get response body as text and send it
    const data = await response.text();
    res.send(data);
  } catch (error) {
    logError('Proxy error:', error);
    res.status(500).send({ error: 'Proxy error', message: error });
  }
});

// Default route
app.get('/', (req, res) => {
  res.send('Proxy server is running. Use /proxy/* to access the target server.');
});

// Start server
app.listen(PORT, () => {
  log(`Proxy server running on http://localhost:${PORT}`);
});
