require('express');
require('mongodb');
var token = require('./createJWT.js');
const { ObjectId } = require('mongodb');
const puppeteer = require('puppeteer');



//sendgrid stuff
const sgMail = require('@sendgrid/mail')
sgMail.setApiKey(process.env.SENDGRID_API_KEY)

const msg = {
  to: 'test@example.com', 
  from: 'test@example.com', 
  subject: 'Sending with SendGrid is Fun',
  text: 'and easy to do anywhere, even with Node.js',
  html: '<strong>and easy to do anywhere, even with Node.js</strong>',
}


exports.setApp = function (app, client)
{

  app.post('/api/addUser', async (req, res) => {

    const { firstName, lastName, email, password } = req.body;
    let ret = {};

    try 
    {
      // Check if user already exists
      const db = client.db('tokidatabase');
      const existing = await db.collection('users').findOne({ email: email });
      if (existing) {
          return res.status(200).json({ error: 'Email already registered' });
      }

      const verificationToken = Math.floor(Math.random() * 900000)//.toString();

      // Insert user with plain password
      const result = await db.collection('users').insertOne({
          firstName,
          lastName,
          email,
          password,
          verificationToken
      });

      const id = result.insertedId.toString();

      // Optionally create JWT immediately
      const { accessToken } = token.createToken(firstName, lastName, id);

      console.log("send to login page after this");

      ret = { id, firstName, lastName, accessToken, error: 'success, send to login page' };
    } 
    catch (e) 
    {
      ret = { id: -1, firstName: '', lastName: '', accessToken: '', error: e.toString() };
    }

    res.status(200).json(ret);
  });

  app.post('/api/loginUser', async (req, res, next) => {
    // incoming: email, password
    // outgoing: id, firstName, lastName, accessToken, error

    const { email, password } = req.body;
    let error = '';
    let ret = {};

    try {
      const db = client.db('tokidatabase');
      const results = await db.collection('users').find({ email: email, password: password }).toArray();

      if (results.length > 0) {
        const user = results[0];
        const id = user._id.toString();
        const firstName = user.firstName;
        const lastName = user.lastName;
        const verificationToken = user.verificationToken;

        const token = require('./createJWT.js');
        const { accessToken } = token.createToken(firstName, lastName, id);

        console.log("send email");

        sendVerEmail(user.email, verificationToken);

        console.log("should have sent email, go to verify page");

        ret = { id, firstName, lastName, accessToken, verificationToken, error: 'none, send to verify page' };
      } else {
        ret = { id: -1, firstName, lastName, accessToken, verificationToken : 0, error: 'Login/Password incorrect' };
      }
    } catch (e) {
      ret = { id: -1, firstName: '', lastName: '', accessToken: '', verificationToken : -1,error: e.toString() };
    }

    res.status(200).json(ret);
  });

  app.post('/api/verifyUser', async (req, res, next) => {

    const { email, verificationToken, accessToken } = req.body;
    let ret = {};

    //make sure token still valid
    try
    {
      if(token.isExpired(accessToken))
      {
        var r = {error: 'The JWT is no longer valid', accessToken: ''};
        res.status(200).json(r);
        return;
      }
    }
    catch(e)
    {
      console.log(e.message);
    }


    try 
    {
      const db = client.db('tokidatabase');
      const user = await db.collection('users').findOne({ email });

      if (!user) 
        {
        return res.status(200).json({ error: 'User not found' });
      }

      if (user.verificationToken === verificationToken) 
      {
        console.log("successful login");

        await db.collection('users').updateOne(
          { _id: user._id },
          { $set: { verificationToken: Math.floor(Math.random() * 900000) } }
        );

        console.log("should be sent to dashboard now");

        //send to dashboard if success
        ret = { id:user._id, accessToken, error: 'success, send to Dashboard page'};
      } 
      else 
      {
        ret = { id:user._id  , accessToken, error: 'no idea whats wrong'};
      }
    } 
    catch (e) 
    {
      ret = { success: false, error: e.toString() };
    }

    var refreshedToken = null;
    try
    {
      refreshedToken = token.refresh(jwtToken);
    }
    catch(e)
    {
     console.log(e.message);
    }

    res.status(200).json(ret);
  });

  app.post('/api/updateUser', async(req, res, next) => {

    // incoming: id, firstName, lastName, email, password, jwtToken
    // outgoing: success, error, jwtToken
    const { id, firstName, lastName, email, password, accessToken } = req.body;
    let ret = {};

    try 
:    {
      if (token.isExpired(accessToken))
      {
        return res.status(200).json({error:'The JWT is no longer valid', accessToken: ''});
      }
    } 
    catch (e) 
    {
      console.log(e.message);
    }

    //give id of user
    const db = client.db('tokidatabase');
    const user= await db.collection('users').findOne({ _id: new ObjectId(id) });

    let error = '';

    try 
    {
      const result = await db.collection('users').updateOne(
        {  _id: new ObjectId(id) },
        { $set: { firstName:firstName, lastName:lastName, email:email, password:password } }
      );

      if (result.matchedCount > 0) 
        ret = { success: true,  email, firstName, lastName, password, error: "all went fine" };
      else ret = { success: false, error: "something did not work" };
    } 
    catch (e) 
    {
      ret = { success: false, error: e.toString() }
    }

    let refreshedToken = null;
    try 
    {
      refreshedToken = token.refresh(accessToken);
    } 
    catch (e) 
    {
      console.log(e.message);
    }

    res.status(200).json(ret);
  });

  app.post('/api/deleteUser', async(req, res, next) => {
    // incoming: id, jwtToken
    // outgoing: success, error, jwtToken
    const {id, accessToken} = req.body;
    let ret = {};

    try
    {
      if (token.isExpired(accessToken))
        {
        return res.status(200).json({error: 'The JWT is no longer valid', accessToken: ''}); 
      }
    } 
    catch (e)
    {
      console.log(e.message);
    }

    const db = client.db('tokidatabase');
    const user= await db.collection('users').findOne({ _id: new ObjectId(id) });
    let error = '';
    let success = false;
    
    try 
    {
      const result = await db.collection('users').deleteOne({ _id: new ObjectId(id) });
      if (result.deletedCount > 0) success = true;
      else ret = { success: false, error: "something no work" };

      ret = { success: true, error: "none, should be deleted" }
    } 
    catch (e)
    {
      ret = { success: false, error: e.toString() }
    }

    let refreshedToken = null;
    try 
    {
      refreshedToken = token.refresh(accessToken);
    } 
    catch (e)
    {
      console.log(e.message);
    }

    res.status(200).json(ret);
  });


  app.post('/api/createReminder', async (req, res) => {

    //this is all info passed from FE
    const { userId, accessToken, title, desc, status, priority, year, month, day, } = req.body;
    const dueDate = new Date(year, month-1, day);

    
    let ret = {};

    //check all still good with accessToken
    try 
    {
      if (token.isExpired(accessToken))
      {
        return res.status(200).json({error:'The JWT is no longer valid', accessToken: ''});
      }
    } 
    catch (e) 
    {
      console.log(e.message);
    }

    try 
    {
      //pull database
      const db = client.db('tokidatabase');

      //insert into to reminders collection 
      const result = await db.collection('reminders').insertOne({
          userId: new ObjectId(userId), 
          title,
          desc,
          status, 
          priority, 
          dueDate,
          completed: {
            isCompleted: false,
            completedAt: null
          },
          createdAt: new Date(), 
          updatedAt: new Date()
      });

      const reminder = result.insertedId.toString();

      console.log("should have inserted reminder");

      //what to pass back to FE
      ret = { title, desc, status, priority, dueDate , error: 'success, show like green thingy',accessToken };
    } 
    catch (e) 
    {
      ret = { title: 'didnt work', desc: '', status: '', priority: '', error: e.toString() };
    }

    res.status(200).json(ret);
  });

  app.post('/api/editReminder', async(req, res, next) => {

    //this is all info passed from FE
    const { userId, accessToken, title, desc, status, priority, year, month, day} = req.body;
    const dueDate = new Date(year, month-1, day);
    let ret = {};

    try 
    {
      if (token.isExpired(accessToken))
      {
        return res.status(200).json({error:'The JWT is no longer valid', accessToken: ''});
      }
    } 
    catch (e) 
    {
      console.log(e.message);
    }

    //give id of reminder
    const db = client.db('tokidatabase');
    const reminderFound= await db.collection('reminders').findOne({ userId: new ObjectId(userId) , title : title });

    let error = '';

    try 
    {
      const result = await db.collection('reminders').updateOne(
        {  _id: new ObjectId(reminderFound._id) },
        { $set: { title:title, desc:desc, status:status, priority:priority, dueDate:dueDate, updatedAt: new Date()} }
      );

      if (result.matchedCount > 0) 
        ret = { success: true,  title, desc, status, priority, dueDate, error: "reminder updated fine", accessToken };
      else ret = { success: false, error: "reminder not updated correctly" };
    } 
    catch (e) 
    {
      ret = { success: false, error: e.toString() }
    }

    let refreshedToken = null;
    try 
    {
      refreshedToken = token.refresh(accessToken);
    } 
    catch (e) 
    {
      console.log(e.message);
    }

    res.status(200).json(ret);
  });

  app.post('/api/completeReminder', async(req, res, next) => {

    //this is all info passed from FE
    const { userId, accessToken, title} = req.body;
    let ret = {};

    try 
    {
      if (token.isExpired(accessToken))
      {
        return res.status(200).json({error:'The JWT is no longer valid', accessToken: ''});
      }
    } 
    catch (e) 
    {
      console.log(e.message);
    }

    //give id of reminder
    const db = client.db('tokidatabase');
    const reminderFound= await db.collection('reminders').findOne({ userId: new ObjectId(userId) , title : title });

    let error = '';

    try 
    {
      const result = await db.collection('reminders').updateOne(
        {  _id: new ObjectId(reminderFound._id) },
        { $set: { "completed.isCompleted": true, "completed.completedAt": new Date()} }
      );

      if (result.matchedCount > 0) 
        ret = { success: true,  title, error: "reminder set to completed", accessToken };
      else ret = { success: false, error: "reminder not completed" };
    } 
    catch (e) 
    {
      ret = { success: false, error: e.toString() }
    }

    let refreshedToken = null;
    try 
    {
      refreshedToken = token.refresh(accessToken);
    } 
    catch (e) 
    {
      console.log(e.message);
    }

    res.status(200).json(ret);
  });  

  app.post('/api/deleteReminder', async(req, res, next) => {
    //this is all info passed from FE
    const { userId, accessToken, title} = req.body;
    let ret = {};

    try 
    {
      if (token.isExpired(accessToken))
      {
        return res.status(200).json({error:'The JWT is no longer valid', accessToken: ''});
      }
    } 
    catch (e) 
    {
      console.log(e.message);
    }

    const db = client.db('tokidatabase');
    const reminderFound= await db.collection('reminders').findOne({ userId: new ObjectId(userId) , title : title });
    let error = '';
    let success = false;
    
    try 
    {
      const result = await db.collection('reminders').deleteOne({ _id: new ObjectId(reminderFound._id) });
      if (result.deletedCount > 0) success = true;
      else ret = { success: false, error: "reminder didnt delete right" };

      ret = { success: true, error: "reminder successfully deleted"}
    } 
    catch (e)
    {
      ret = { success: false, error: e.toString() }
    }

    let refreshedToken = null;
    try 
    {
      refreshedToken = token.refresh(accessToken);
    } 
    catch (e)
    {
      console.log(e.message);
    }

    res.status(200).json(ret);
  });


  
  async function updateGarages() {
    const maxRetries = 3;
    let retryCount = 0;
    let browser;
    
    while (retryCount < maxRetries) {
      try {
        await client.connect();
        const db = client.db('tokidatabase');
        const collection = db.collection("parkinglocations");


        // Try to find Chrome/Chromium executable
        const executablePath = 
          process.env.PUPPETEER_EXECUTABLE_PATH || // Custom env var
          '/usr/bin/chromium-browser' ||             // Common on Ubuntu
          '/usr/bin/chromium' ||                     // Alternative
          '/usr/bin/google-chrome';                  // If Chrome is installed

        browser = await puppeteer.launch({
          headless: true,
          executablePath: executablePath,
          args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-gpu',
            '--no-zygote',
            '--disable-web-security',
            '--disable-features=IsolateOrigins,site-per-process',
            '--single-process', // Important for low-memory servers
            '--disable-accelerated-2d-canvas',
            '--no-first-run',
            '--no-default-browser-check'
          ]
        });
        
        const page = await browser.newPage();
        
        // Set a realistic user agent
        await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');
        
        // Navigate to page
        await page.goto('https://parking.ucf.edu/resources/garage-availability/', {
          waitUntil: 'domcontentloaded',
          timeout: 60000
        });
        
        // Wait for the table to be present
        await page.waitForSelector('#OccupancyOutput tr', { timeout: 10000 });
        
        // Extract table rows
        const garages = await page.evaluate(() => {
          const rows = Array.from(document.querySelectorAll('#OccupancyOutput tr'));
          return rows
            .map(row => {
              const cols = row.querySelectorAll('td');
              if (cols.length >= 3) {
                const available = parseInt(cols[1].innerText.trim(), 10);
                const total = parseInt(cols[2].innerText.trim(), 10);
                return {
                  garageName: cols[0].innerText.trim(),
                  availableSpots: available,
                  totalSpots: total,
                  percentFull: total > 0 ? Math.round((1 - available/total) * 100) : null,
                  lastUpdated: new Date(),
                  updatedAt: new Date(),
                  createdAt: new Date()
                };
              }
            })
            .filter(Boolean);
        });

        await browser.close();
        browser = null;

        // Upsert each garage document
        if (garages.length > 0) {
          for (const garage of garages) {
            await collection.updateOne(
              { garageName: garage.garageName },
              { $set: garage },
              { upsert: true }
            );
          }
          console.log(`[${new Date().toLocaleTimeString()}] Garage data updated:`, garages.length, "garages");
        } else {
          console.warn(`[${new Date().toLocaleTimeString()}] Warning: No garage data found`);
        }
        
        // Success - break out of retry loop
        break;
        
      } catch (err) {
        retryCount++;
        console.error(`Error scraping/updating garages (attempt ${retryCount}/${maxRetries}):`, err.message);
        
        // Clean up browser if it's still open
        if (browser) {
          try {
            await browser.close();
          } catch (closeErr) {
            console.error('Error closing browser:', closeErr.message);
          }
          browser = null;
        }
        
        if (retryCount >= maxRetries) {
          console.error("Max retries reached. Will try again on next interval.");
        } else {
          // Wait before retrying (exponential backoff)
          const waitTime = Math.pow(2, retryCount) * 1000;
          console.log(`Waiting ${waitTime}ms before retry...`);
          await new Promise(resolve => setTimeout(resolve, waitTime));
        }
      }
    }
  }

  // Run immediately on startup, then every 2 minutes
  updateGarages();
  setInterval(updateGarages, 2 * 60 * 1000);
  
  


}


function sendVerEmail(email, verificationToken)
{
  const msg = 
  {
    to: email,
    from: 'no-reply@mytoki.app',
    subject: "Your Verification Code",
    text: `Your verification code is: ${verificationToken}`,
    html: `<p>Your verification code is: <b>${verificationToken}</b></p>`,
  };

  sgMail
    .send(msg)
    .then(() => {console.log('Email sent')})
    .catch((error) => {console.error(error)});
}


        
