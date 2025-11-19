const axios = require('axios');
require('dotenv').config({ path: './priv.env' });

const API_KEY = process.env.WEATHER_API_KEY;
const BASE_URL = 'https://api.openweathermap.org/data/2.5';


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
 * Fetch current weather from OpenWeatherMap
 */
const fetchCurrentWeather = async (lat, lon, location) => {
  const response = await axios.get(`${BASE_URL}/weather`, {
    params: { lat, lon, units: 'imperial', appid: API_KEY }
  });

  const data = response.data;

  return {
    location,
    forecast: data.weather[0].description,
    high: Math.round(data.main.temp_max),
    low: Math.round(data.main.temp_min),
    humid: data.main.humidity,
    vis: data.visibility ? Math.round(data.visibility / 1609.34) : 10,
    pressure: parseFloat((data.main.pressure * 0.02953).toFixed(2)),
    windSpeed: Math.round(data.wind.speed),
    sunrise: formatTime(data.sys.sunrise),
    sunset: formatTime(data.sys.sunset),
    lastUpdated: new Date()
  };
};

/**
 * Update the single `weathers` collection
 */
const updateWeathersCollection = async (client) => {
  const maxRetries = 3;
  let retryCount = 0;

  while (retryCount < maxRetries) {
    try {
      //await client.connect();
      const db = client.db('tokidatabase');
      const weatherCollection = db.collection('weathers');

      // Example: single location for collection
      const location = 'Orlando, FL';
      const coords = { lat: 28.5383, lon: -81.3792 };

      const weatherData = await fetchCurrentWeather(coords.lat, coords.lon, location);

      // Upsert a single document (no userId)
      await weatherCollection.updateOne(
        { location: weatherData.location },
        {
          $set: {
            forecast: weatherData.forecast,
            high: weatherData.high,
            low: weatherData.low,
            humid: weatherData.humid,
            vis: weatherData.vis,
            pressure: weatherData.pressure,
            windSpeed: weatherData.windSpeed,
            sunrise: weatherData.sunrise,
            sunset: weatherData.sunset,
            lastUpdated: weatherData.lastUpdated,
            updatedAt: new Date()
          },
          $setOnInsert: { createdAt: new Date() }
        },
        { upsert: true }
      );

      console.log(`[${new Date().toLocaleTimeString()}] Weather updated for ${location}`);
      break;

    } catch (err) {
      retryCount++;
      console.error(`Error updating weather (attempt ${retryCount}/${maxRetries}):`, err.message);

      if (retryCount < maxRetries) {
        await new Promise(resolve => setTimeout(resolve, Math.pow(2, retryCount) * 1000));
      } else {
        console.error("Max retries reached. Weather update failed.");
      }
    }
  }
};
/*
/**
 * Scheduler for automatic updates
 *
const startWeatherUpdateScheduler = (client) => {
  // Immediate update after 5s
  setTimeout(() => updateWeathersCollection(client), 5000);

  // Then update every 2 minutes
  setInterval(() => updateWeathersCollection(client), 2 * 60 * 1000);
};
*/

module.exports = {
  updateWeathersCollection,
};
