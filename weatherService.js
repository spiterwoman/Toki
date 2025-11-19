const axios = require('axios');
const { MongoClient, ObjectId } = require('mongodb');
require('dotenv').config({ path: './priv.env' });

// OpenWeatherMap API configuration
const API_KEY = process.env.WEATHER_API_KEY;
const BASE_URL = 'https://api.openweathermap.org/data/2.5';

// MongoDB connection
const url = process.env.MONGODB_URI;
const client = new MongoClient(url);

/**
 * Convert Unix timestamp to readable time
 */
const formatTime = (timestamp) => {
  const date = new Date(timestamp * 1000);
  return date.toLocaleTimeString('en-US', { 
    hour: 'numeric', 
    minute: '2-digit',
    hour12: true 
  });
};

/**
 * Fetch current weather data from OpenWeatherMap Current Weather API
 * API Doc: https://openweathermap.org/current
 */
const fetchCurrentWeather = async (lat, lon, location) => {
  try {
    const response = await axios.get(`${BASE_URL}/weather`, {
      params: {
        lat: lat,
        lon: lon,
        units: 'imperial', // Fahrenheit
        appid: API_KEY
      }
    });

    const data = response.data;

    // Map API response to our database fields
    const weatherData = {
      location: location,
      high: Math.round(data.main.temp_max),
      low: Math.round(data.main.temp_min),
      sunrise: formatTime(data.sys.sunrise),
      sunset: formatTime(data.sys.sunset),
      forecast: data.weather[0].description,
      humid: data.main.humidity,
      vis: data.visibility ? Math.round(data.visibility / 1609.34) : 10,
      pressure: parseFloat((data.main.pressure * 0.02953).toFixed(2)),
      windSpeed: Math.round(data.wind.speed),
      lastUpdated: new Date()
    };

    return weatherData;

  } catch (error) {
    console.error('Error fetching weather data:', error.message);
    if (error.response) {
      console.error('API Response:', error.response.data);
    }
    throw error;
  }
};

/**
 * Update weather for a specific user
 */
const updateUserWeather = async (userId, lat, lon, location) => {
  try {
    const weatherData = await fetchCurrentWeather(lat, lon, location);

    await client.connect();
    const db = client.db('tokidatabase');
    const weatherCollection = db.collection('weathers');

    // Upsert (update or insert) weather data for user
    const result = await weatherCollection.updateOne(
      { userId: new ObjectId(userId) },
      { 
        $set: {
          userId: new ObjectId(userId),
          location: weatherData.location,
          high: weatherData.high,
          low: weatherData.low,
          sunrise: weatherData.sunrise,
          sunset: weatherData.sunset,
          forecast: weatherData.forecast,
          humid: weatherData.humid,
          vis: weatherData.vis,
          pressure: weatherData.pressure,
          windSpeed: weatherData.windSpeed,
          lastUpdated: weatherData.lastUpdated,
          updatedAt: new Date()
        },
        $setOnInsert: {
          createdAt: new Date()
        }
      },
      { upsert: true }
    );

    console.log(`Updated weather for user ${userId} - ${location}`);
    return result;

  } catch (error) {
    console.error(`Failed to update weather for user ${userId}:`, error.message);
    throw error;
  }
};

/**
 * Update weather for all users
 */
const updateAllUsersWeather = async () => {
  try {
    await client.connect();
    const db = client.db('tokidatabase');
    const usersCollection = db.collection('users');

    const users = await usersCollection.find({}).toArray();

    console.log(`\nUpdating weather for ${users.length} users...`);

    const locationDefaults = {
      'Orlando, FL': { lat: 28.5383, lon: -81.3792 },
      'Miami, FL': { lat: 25.7617, lon: -80.1918 },
      'Tampa, FL': { lat: 27.9506, lon: -82.4572 },
      'Jacksonville, FL': { lat: 30.3322, lon: -81.6557 }
    };

    for (const user of users) {
      const location = 'Orlando, FL';
      const coords = locationDefaults[location];
      
      await updateUserWeather(user._id.toString(), coords.lat, coords.lon, location);
      await new Promise(resolve => setTimeout(resolve, 1000));
    }

    console.log('Weather update complete');
    
    // Clean up orphaned weather after updates
    await cleanupOrphanedWeather();

  } catch (error) {
    console.error('Error updating weather for all users:', error.message);
  }
};

/**
 * Start automatic weather updates every 2 minutes
 */
const startWeatherUpdateScheduler = () => {
  console.log('Weather scheduler will start after initial update...');
  
  // Update immediately after 5 seconds (let server fully start)
  setTimeout(() => {
    updateAllUsersWeather();
  }, 5000);
  
  // Then update every 2 minutes
  const intervalId = setInterval(() => {
    updateAllUsersWeather();
  }, 120000); // 2 minutes = 120000 milliseconds

  return intervalId;
};

/**
 * Clean up orphaned weather records (weather without valid user)
 */
const cleanupOrphanedWeather = async () => {
  try {
    await client.connect();
    const db = client.db('tokidatabase');
    const weatherCollection = db.collection('weathers');
    const usersCollection = db.collection('users');

    // Get all valid user IDs
    const users = await usersCollection.find({}).toArray();
    const validUserIds = new Set(users.map(u => u._id.toString()));

    // Find orphaned weather (userId doesn't match any user)
    const allWeather = await weatherCollection.find({}).toArray();
    const orphanedIds = allWeather
      .filter(w => w.userId && !validUserIds.has(w.userId.toString()))
      .map(w => w._id);

    if (orphanedIds.length > 0) {
      const result = await weatherCollection.deleteMany({ _id: { $in: orphanedIds } });
      console.log(`Cleaned up ${result.deletedCount} orphaned weather records`);
    }

  } catch (error) {
    console.error('Error cleaning up orphaned weather:', error.message);
  }
};

module.exports = {
  fetchCurrentWeather,
  updateUserWeather,
  updateAllUsersWeather,
  cleanupOrphanedWeather,  
  startWeatherUpdateScheduler
};