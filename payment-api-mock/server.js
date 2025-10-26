const express = require('express');
const promBundle = require('express-prom-bundle');
const promClient = require('prom-client');
const cors = require('cors');
const morgan = require('morgan');
const winston = require('winston');
const { InfluxDB, Point } = require('@influxdata/influxdb-client');

// Initialize Express app
const app = express();
const port = process.env.PORT || 8080;
const simulationRate = parseInt(process.env.SIMULATION_RATE) || 5; // Transactions per second

// InfluxDB Configuration
const influxConfig = {
  url: process.env.INFLUXDB_URL || 'http://influxdb:8086',
  token: process.env.INFLUXDB_TOKEN || 'my-super-secret-auth-token',
  org: process.env.INFLUXDB_ORG || 'myorg',
  bucket: process.env.INFLUXDB_BUCKET || 'payments',
};

// Initialize InfluxDB client
const influxDB = new InfluxDB({ url: influxConfig.url, token: influxConfig.token });
const writeApi = influxDB.getWriteApi(influxConfig.org, influxConfig.bucket);
const queryApi = influxDB.getQueryApi(influxConfig.org);

// Handle InfluxDB write errors
writeApi.on('error', (error) => {
  console.error('InfluxDB write error:', error);
  logger.error('InfluxDB write error', { error: error.message });
});

// Graceful shutdown for InfluxDB
process.on('SIGTERM', () => {
  writeApi.close()
    .then(() => {
      logger.info('InfluxDB write API closed');
      process.exit(0);
    })
    .catch((err) => {
      logger.error('Error closing InfluxDB', { error: err.message });
      process.exit(1);
    });
});

// Configure logging
const logger = winston.createLogger({
  level: 'info',
  format: winston.format.combine(
    winston.format.timestamp(),
    winston.format.json()
  ),
  transports: [
    new winston.transports.Console(),
    new winston.transports.File({ filename: 'payment-api.log' })
  ]
});

// Middleware
app.use(cors());
app.use(express.json());
app.use(morgan('combined', { stream: { write: message => logger.info(message.trim()) } }));

// Prometheus metrics setup
const collectDefaultMetrics = promClient.collectDefaultMetrics;
collectDefaultMetrics({ timeout: 5000 });

// Custom metrics
const paymentCounter = new promClient.Counter({
  name: 'payment_requests_total',
  help: 'Total number of payment requests',
  labelNames: ['method', 'status', 'type']
});

const paymentAmount = new promClient.Histogram({
  name: 'payment_amount',
  help: 'Amount processed per payment',
  labelNames: ['currency'],
  buckets: [10, 50, 100, 500, 1000, 5000, 10000]
});

const paymentDuration = new promClient.Histogram({
  name: 'payment_duration_seconds',
  help: 'Duration of payment processing in seconds',
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 10]
});

const activePayments = new promClient.Gauge({
  name: 'active_payments',
  help: 'Number of payments currently being processed'
});

// Write payment data to InfluxDB
const writePaymentToInflux = async (payment, result) => {
  try {
    const point = new Point('payment')
      .tag('status', result.success ? 'success' : 'failed')
      .tag('currency', payment.currency || 'USD')
      .tag('customer_id', payment.customerId || 'anonymous')
      .floatField('amount', parseFloat(payment.amount))
      .floatField('processing_time', result.processingTime)
      .timestamp(new Date(result.timestamp));

    writeApi.writePoint(point);
    await writeApi.flush();
  } catch (error) {
    logger.error('Failed to write to InfluxDB', { error: error.message });
  }
};

// Get payment statistics from InfluxDB
const getPaymentStats = async (timeRange = '1h') => {
  const query = `
    from(bucket: "${influxConfig.bucket}")
      |> range(start: -${timeRange})
      |> filter(fn: (r) => r._measurement == "payment")
      |> aggregateWindow(every: 1m, fn: mean, createEmpty: false)
  `;

  try {
    const results = [];
    for await (const { values, tableMeta } of queryApi.iterateRows(query)) {
      const o = tableMeta.toObject(values);
      results.push(o);
    }
    return results;
  } catch (error) {
    logger.error('Error querying InfluxDB', { error: error.message });
    return [];
  }
};

// Simulate payment processing
const processPayment = async (payment) => {
  const start = Date.now();
  activePayments.inc();
  
  // Simulate processing time (50ms to 500ms)
  const processingTime = Math.random() * 450 + 50;
  
  // Simulate 2% failure rate
  const isSuccess = Math.random() > 0.02;
  
  return new Promise(resolve => {
    setTimeout(async () => {
      const duration = (Date.now() - start) / 1000;
      activePayments.dec();
      
      const result = {
        success: isSuccess,
        paymentId: `tx_${Math.random().toString(36).substr(2, 9)}`,
        amount: payment.amount,
        currency: payment.currency || 'USD',
        timestamp: new Date().toISOString(),
        processingTime: duration
      };
      
      // Record metrics
      paymentDuration.observe(duration);
      paymentAmount.observe({ currency: result.currency }, parseFloat(payment.amount));
      
      // Store in InfluxDB
      await writePaymentToInflux(payment, result);
      
      resolve(result);
    }, processingTime);
  });
};

// Routes
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'UP' });
});

app.get('/metrics', async (req, res) => {
  try {
    res.set('Content-Type', promClient.register.contentType);
    const metrics = await promClient.register.metrics();
    res.end(metrics);
  } catch (err) {
    logger.error('Error generating metrics', { error: err.message });
    res.status(500).end();
  }
});

// Get payment statistics
app.get('/api/payments/stats', async (req, res) => {
  try {
    const { range = '1h' } = req.query;
    const stats = await getPaymentStats(range);
    res.status(200).json(stats);
  } catch (error) {
    logger.error('Failed to get payment stats', { error: error.message });
    res.status(500).json({ error: 'Failed to retrieve payment statistics' });
  }
});

// Process payment
app.post('/api/payments', async (req, res) => {
  try {
    const { amount, currency, customerId } = req.body;
    
    if (!amount || isNaN(amount)) {
      paymentCounter.inc({ method: 'POST', status: '400', type: 'invalid_request' });
      return res.status(400).json({ error: 'Invalid amount' });
    }
    
    const payment = { 
      amount, 
      currency: currency || 'USD', 
      customerId: customerId || 'anonymous' 
    };
    
    const result = await processPayment(payment);
    
    if (result.success) {
      paymentCounter.inc({ method: 'POST', status: '200', type: 'success' });
      res.status(200).json(result);
    } else {
      paymentCounter.inc({ method: 'POST', status: '500', type: 'failed' });
      res.status(500).json({ error: 'Payment processing failed', ...result });
    }
  } catch (error) {
    paymentCounter.inc({ method: 'POST', status: '500', type: 'error' });
    logger.error('Payment processing error', { error: error.message });
    res.status(500).json({ error: 'Internal server error' });
  }
});

// Start server
const server = app.listen(port, () => {
  logger.info(`Payment API Mock running on port ${port}`);
  
  // Simulate traffic if enabled
  if (process.env.NODE_ENV !== 'test') {
    setInterval(() => {
      const amount = (Math.random() * 1000).toFixed(2);
      const currencies = ['USD', 'EUR', 'GBP'];
      const currency = currencies[Math.floor(Math.random() * currencies.length)];
      
      processPayment({ amount, currency, customerId: `cust_${Math.floor(Math.random() * 1000)}` })
        .then(result => {
          if (!result.success) {
            logger.warn('Simulated payment failed', { paymentId: result.paymentId });
          }
        })
        .catch(err => logger.error('Error in simulated payment', { error: err.message }));
    }, 1000 / simulationRate);
  }
});

// Graceful shutdown
process.on('SIGTERM', () => {
  logger.info('SIGTERM received. Shutting down gracefully');
  server.close(() => {
    logger.info('Server closed');
    process.exit(0);
  });
});

module.exports = { app, server };
