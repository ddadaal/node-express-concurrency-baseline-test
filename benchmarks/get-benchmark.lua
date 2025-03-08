-- Simple GET request benchmark script

-- Initialize the counter
local counter = 0
local threads = {}

function setup(thread)
  thread:set("id", counter)
  table.insert(threads, thread)
  counter = counter + 1
end

function request()
  -- Simple GET request to the proxy server
  return wrk.format("GET", "/proxy/api/data")
end

function done(summary, latency, requests)
  -- Print stats from each thread when done
  for index, thread in ipairs(threads) do
    local msg = "Thread %d: %d requests, %.2f rps, %.2fms avg latency"
    print(string.format(
      msg, index, summary.requests, 
      summary.requests/summary.duration*1000000, 
      latency.mean/1000
    ))
  end
end
