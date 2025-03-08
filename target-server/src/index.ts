import express from 'express';

const app = express();
const PORT = 5001;

const delay = () => {
  const delay = process.env.DELAY;

  if (!delay) {
    return Promise.resolve();
  }

  const ms = parseInt(delay, 10);
  if (isNaN(ms) || ms < 0) {
    console.error(`Invalid delay value: ${delay}. Using 0ms instead.`);
    return Promise.resolve();
  }

  return new Promise(resolve => setTimeout(resolve, ms))
}

// Log middleware to print incoming request URLs only if NO_LOG is not set
app.use((req, res, next) => {
  if (!process.env.NO_LOG) {
    console.log(`Incoming request at target server: ${req.url}`);
  }

  delay().then(next);
});

// Sample routes
app.get('/', (req, res) => {
  res.send('Target server is running!');
});

app.get('/api/data', (req, res) => {
  res.json({ message: 'This is data from the target server!' });
});

// Handle all other routes
app.use('*', (req, res) => {
  res.send(`You accessed path: ${req.originalUrl}`);
});

// Start server
app.listen(PORT, () => {
  if (!process.env.NO_LOG) {
    console.log(`Target server running on http://localhost:${PORT}`);
  }
});
