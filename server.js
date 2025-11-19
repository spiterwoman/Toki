const express = require('express');
const cors = require('cors');
const path = require('path');
const { MongoClient } = require('mongodb');
require('dotenv').config({ path: './priv.env' }); // your .env file
require('dotenv').config({ path: './sendgrid.env' });

const cookieParser = require("cookie-parser");

const app = express();

// Middleware
app.use(cors());
app.use(express.json());
app.use(cookieParser());
app.use((req, res, next) => {
    res.setHeader('Access-Control-Allow-Origin', '*');
    res.setHeader(
        'Access-Control-Allow-Headers',
        'Origin, X-Requested-With, Content-Type, Accept, Authorization'
    );
    res.setHeader(
        'Access-Control-Allow-Methods',
        'GET, POST, PATCH, DELETE, OPTIONS'
    );
    next();
});

const frontendPath = '/var/www/html';
app.use(express.static(frontendPath));

app.get('*', (req, res) => {
  res.sendFile(path.join(frontendPath, 'index.html'));
});

// MongoDB connection
const url = process.env.MONGODB_URI;
const client = new MongoClient(url);

async function connectDB() {
    try {
        await client.connect();
        console.log('Connected to MongoDB');

        // Hardcoded database name
        const db = client.db('tokidatabase');

        // Setup API routes
        const api = require('./api.js');
        api.setApp(app, client);

        // Start server
        app.listen(5000, () => {
            console.log('Server is running on port 5000');
        });
    } catch (err) {
        console.error('MongoDB connection failed:', err);
        process.exit(1);
    }
}

connectDB();
