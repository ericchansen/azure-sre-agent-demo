// Minimal Node.js stub app for the AKS blue/green demo scenario.
// Exposes two endpoints:
//   GET  /health   → always 200 (used for k8s probes)
//   POST /checkout → 201 normally; 503 when DEMO_BROKEN_CHECKOUT=true
//
// OpenTelemetry auto-instrumentation via @azure/monitor-opentelemetry.
// Set APPLICATIONINSIGHTS_CONNECTION_STRING to enable telemetry.

// Must be the very first line — instruments before any other imports
const { useAzureMonitor } = require('@azure/monitor-opentelemetry');
useAzureMonitor();

const http = require('http');

const PORT = parseInt(process.env.PORT || '3000', 10);
const isBroken = () => process.env.DEMO_BROKEN_CHECKOUT === 'true';

const server = http.createServer((req, res) => {
  if (req.url === '/health' && req.method === 'GET') {
    res.writeHead(200, { 'Content-Type': 'application/json' });
    res.end(JSON.stringify({ status: 'ok', broken: isBroken() }));
    return;
  }

  if (req.url === '/checkout' && req.method === 'POST') {
    if (isBroken()) {
      // Simulate a degraded deployment — add latency before failing
      setTimeout(() => {
        res.writeHead(503, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ error: 'Service temporarily unavailable' }));
      }, 1500);
    } else {
      res.writeHead(201, { 'Content-Type': 'application/json' });
      res.end(JSON.stringify({ orderId: `order-${Date.now()}`, status: 'confirmed' }));
    }
    return;
  }

  res.writeHead(404);
  res.end();
});

server.listen(PORT, () => {
  console.log(`aks-stub listening on port ${PORT}`);
  console.log(`DEMO_BROKEN_CHECKOUT=${process.env.DEMO_BROKEN_CHECKOUT || 'false'}`);
});
