require('express');
require('mongodb');
var token = require('./createJWT.js');
const { ObjectId } = require('mongodb');
const puppeteer = require('puppeteer');
require('dotenv').config(); // loads .env by default

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
      refreshedToken = token.refresh(accessToken);
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


  app.post('/api/logout', async(req,res,next) => {
          // incoming: jwtToken
          // outgoing: error, jwtToken
    const {jwtToken} = req.body;
    var error = '';
    try {
            if (token.isExpired(jwtToken)){
                    // Expired Token
              var r = {error:'Token expired', jwtToken:''};
              res.status(200).json(r);
              return;
           }
        } catch (e) {
                console.log(e.message);
        }
          // return to tell client to clear stored token
        var ret = {error: error, jwtToken:''};
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

  app.post('/api/viewReminder', async(req,res)=>{
	  // incoming: userId, accessToken, taskId
	  // outgoing: all tasks / single task, error
    const {userId, accessToken, reminderId} = req.body;
    let ret = {};
	// validate JWT
    try{
	    if (token.isExpired(accessToken)){
		    return res
		      .status(200)
		      .json({error: 'The JWT is no longer valid', accessToken: ''});
	    }
    }catch(e) {
	    console.log(e.message);
    }
	  try{
		  const db = client.db('tokidatabase');
		  const remindersCollection = db.collection('reminders');
		  if (reminderId){
			  // specific task
		    const task = await remindersCollection.findOne({
			    _id: new ObjectId(reminderId),
			    userId: new ObjectId(userId),
		    });
		  if (!reminders){
			  ret = {success: false, error: 'Reminder not found', accessToken};
		  } else {
			  ret = {success: true, reminders, error: '', accessToken};
		  }
		  } else {
			  // all reminders
			  const reminders = await remindersCollection
			  .find({userId: new ObjectId(userId)})
			  .sort({createdAt: -1})
			  .toArray();
			ret = {success: true, reminders, error: '', accessToken};
		  }
	  } catch (e){
		  ret = {success: false, error: e.toString()};
	  }
	  // Refresh JWT
	  let refreshedToken = null;
	  try {
		  refreshedToken = token.refresh(accessToken);
	  } catch (e){
		  console.log(e.message);
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


  app.post('/api/createTask', async(req,res) => {

	  // incoming: userId, accessToken, title, description, status, priority, dueDate, completed
	  // success, taskId, error, accessToken
    const {userId, accessToken, title, description, status, priority, dueDate, completed}= req.body;
    let ret = {};
    // Make sure JWT is still valid
    try {
	    if (token.isExpired(accessToken)){
		    return res.status(200).json({error:'The JWT is no longer valid', accessToken: ''});
	    }
    } catch (e){
	    console.log(e.message);
    }
    try {
	const db = client.db('tokidatabase');
	    // insert to tasks collections
	const newTask = {
		userId: new ObjectId(userId),
		title,
		description: description || '',
		status: status || 'not started',
		priority: priority || 'medium',
		dueDate: dueDate ? new Date(dueDate) : null,
		completed: (typeof completed === 'object' && completed !== null)
		  ? completed
		  : {isCompleted: false, completedAt: null },
		createdAt: new Date(), 
		updatedAt: new Date()
	};
	    const result = await db.collection('tasks').insertOne(newTask);
	    const taskId = result.insertedId.toString();
	    console.log('Task created successfully');
	    ret = {
		    success: true,
		    taskId,
		    error: 'success, task added to database',
		    accessToken
	    };
    } catch (e) {
	    ret = {
		    success: false,
		    taskId: '',
		    error: e.toString(),
		    accessToken
	    };
    }
	  // Refresh JWT
	  let refreshedToken = null;
	  try {
		  refreshedToken = token.refresh(accessToken);
	  } catch (e) {
		  console.log(e.message);
	  }
	  res.status(200).json(ret);
  });
	// view task based on taskId for specific task and userId for all tasks

  app.post('/api/viewTask', async(req,res)=>{
	  // incoming: userId, accessToken, taskId
	  // outgoing: all tasks / single task, error
    const {userId, accessToken, taskId} = req.body;
    let ret = {};
	// validate JWT
    try{
	    if (token.isExpired(accessToken)){
		    return res
		      .status(200)
		      .json({error: 'The JWT is no longer valid', accessToken: ''});
	    }
    }catch(e) {
	    console.log(e.message);
    }
	  try{
		  const db = client.db('tokidatabase');
		  const tasksCollection = db.collection('tasks');
		  if (taskId){
			  // specific task
		    const task = await tasksCollection.findOne({
			    _id: new ObjectId(taskId),
			    userId: new ObjectId(userId),
		    });
		  if (!task){
			  ret = {success: false, error: 'Task not found', accessToken};
		  } else {
			  ret = {success: true, task, error: '', accessToken};
		  }
		  } else {
			  // all tasks
			  const tasks = await tasksCollection
			  .find({userId: new ObjectId(userId)})
			  .sort({createdAt: -1})
			  .toArray();
			ret = {success: true, tasks, error: '', accessToken};
		  }
	  } catch (e){
		  ret = {success: false, error: e.toString()};
	  }
	  // Refresh JWT
	  let refreshedToken = null;
	  try {
		  refreshedToken = token.refresh(accessToken);
	  } catch (e){
		  console.log(e.message);
	  } 
	  res.status(200).json(ret);
  });

  app.post('/api/editTask', async(req, res)=>{
	  // incoming: userId, accessToken, taskId, title, description, status, priority, dueDate, completed
	  // outgoing: success, updatedTask, error, accessToken
    const {userId, accessToken, taskId, title, description, status, priority, dueDate, completed} = req.body;
	  let ret = {};

	 // Verify JWT
	 try {
		if (token.isExpired(accessToken)){
			return res.status(200).json({error: 'The JWT is no longer valid', accessToken: ''});
		}
	 } catch (e) {
		 console.log(e.message);
	 } 
	 try {
		 const db = client.db('tokidatabase');
		 const tasksCollection = db.collection('tasks');

		 // Update to the fields needed
	const updateFields = {
		updatedAt: new Date()
	}
	if (title) updateFields.title = title;
	if (description) updateFields.description = description;
	if (status) updateFields.status = status;
	if (priority) updateFields.priority = priority;
	if (dueDate) updateFields.dueDate = dueDate;
	if (completed) updateFields.completed = completed;

	const result = await tasksCollection.updateOne(
		{ _id: new ObjectId(taskId), userId: new ObjectId(userId)},
		{ $set: updateFields}
	);
	if (result.matchedCount === 0){
		// No tasks
		ret = { success: false, error: 'Task not found or unauthorized', accessToken};
	} else {
		const updatedTask = await tasksCollection.findOne({_id: new ObjectId(taskId)});
		ret = { success: true, updatedTask, error: '', accessToken};
	}
	} catch (e){
		ret = { success: false, error: e.toString(), accessToken};
	}
	// Refresh JWT
	try {
		const refreshedToken = token.refresh(accessToken);
		ret.accessToken = refreshedToken;
	} catch (e){
		console.log(e.message);
	}
	  res.status(200).json(ret);
  });

  app.post('/api/deleteTask', async (req, res) => {
	  // incoming: userId, accessToken, taskId
	  // outgoing: success, error, accessToken
    const { userId, accessToken, taskId} = req.body;
    let ret = {};

	  // verify JWT
	  try {
		  if (token.isExpired(accessToken)){
			  return res.status(200).json({error: 'The JWT is not longer valid', accessToken: '' });
		  }
	  } catch (e) {
		  console.log(e.message);
	  } 
	  try {
		  const db = client.db('tokidatabase');
		  const tasksCollection = db.collection('tasks');

		  const result = await tasksCollection.deleteOne({
			  _id: new ObjectId(taskId),
			  userId: new ObjectId(userId),
		  });
		  if (result.deletedCount === 0){
			  ret = { success: false, error: 'Task not found or unauthorized', accessToken};
		  }else{
			  ret = { success: true, error: 'Task deleted successfully', accessToken};
		  }
	} catch (e){
	ret = { success: false, error: e.toString(), accessToken};
	}
	  // Refresh JWT
	  try {
		  const refreshedToken = token.refresh(accessToken);
		  ret.accessToken = refreshedToken;
	  } catch (e){
		  console.log(e.message);
	  }

	  res.status(200).json(ret);
  });


  app.post('/api/createCalendarEvent', async(req, res) => {
	   // incoming : userId, accessToken, title, description, location, startTime, endTime} 
	   // outgoing: success, eventId, error, accessToken
    const { userId, accessToken, title, description, location, startDate, endDate, color, allDay, reminder} = req.body; 
    let ret = {}

	  try {
		  if (token.isExpired(accessToken)){
			  return res.status(200).json({error: 'The JWT is no longer valid', accessToken: ''});
		  }
	  } catch (e) {
			  console.log(e.message);
		  }
		  try {
			  const db = client.db('tokidatabase');
			  const newEvent = {
				  userId: new ObjectId(userId),
				  title,
				  description,
				  location,
				  startDate: new Date(startDate),
				  endDate: new Date(endDate),
				  color: color || {},
				  reminder: reminder || {},
				  allDay: allDay || {},
				  createdAt: new Date(),
				  updatedAt: new Date(), 
			  }; 
	const result = await db.collection('calendarevents').insertOne(newEvent);
	const eventId = result.insertedId.toString();
	
	ret = { success: true, eventId, error: 'success, event created', accessToken };
	} catch (e){
		ret = { success: false, error: e.toString(), accessToken };
	}

	try {
		const refreshedToken = token.refresh(accessToken);
		ret.accessToken = refreshedToken;
	} catch (e){
		console.log(e.message);
	}
		  res.status(200).json(ret);
  });

  app.post('/api/viewCalendarEvent', async(req,res)=>{
	  // incoming: userId, accessToken
	  // outgoing: single event or list of events
	const { userId, accessToken, eventId} = req.body;
	  let ret = {};

	  try{
		  if (token.isExpired(accessToken)){
			  return res.status(200).json({error: 'The JWT is no longer valid', accessToken: ''});
		  } 
	  } catch (e) {
		  console.log(e.message);
	  }
	  try {
		  const db = client.db('tokidatabase');
		  const eventsCollection = db.collection('calendarevents');

		  if (eventId) {
			  const event = await eventsCollection.findOne({
				  _id: new ObjectId(eventId),
				  userId: new ObjectId(userId)
			  });

		ret = event
			  ? { success: true, event, error: '', accessToken}
			  : { success: false, error: 'Event not found', accessToken};
		  }else {
			  const events = await eventsCollection
			  .find({userId: new ObjectId(userId)})
			  .sort({startTime: 1})
			  .toArray();
		ret = { success: true, events, error: '', accessToken};
		  }
	  }catch (e){
		  ret = { success: false, error: e.toString(), accessToken};
	  } 

	  try {
		  const refreshedToken = token.refresh(accessToken);
		  ret.accessToken = refreshedToken;
	  } catch (e){
		  console.log(e.message);
	  } 
	  res.status(200).json(ret);
  });

  app.post('/api/editCalendarEvent', async(req, res)=>{
	  // incoming: userId, accessToken, eventId, title, description, location, startTime, endTime
	  const { userId, accessToken, eventId, title, description, location, startDate, endDate, color, allDay, reminder} = req.body;
	  let ret = {};

	  try {
		  if (token.isExpired(accessToken)){
			  return res.status(200).json({error: 'The JWT is no longer valid', accessToken: ''});
		  }
	  } catch (e){
		  console.log(e.message);
	  } 

	  try {
		  const db = client.db('tokidatabase');
		  const eventsCollection = db.collection('calendarevents');

		  const updateFields = { updatedAt: new Date() };
		  if (title) updateFields.title = title;
		  if (description) updateFields.description = description; 
		  if (location) updateFields.location = location;
		  if (startDate) updateFields.startDate = new Date(startDate);
		  if (endDate) updateFields.endDate = new Date(endDate);
		  if (color) updateFields.color = color;
		  if (allDay) updateFields.allDay = allDay;
		  if (reminder) updateFields.reminder = reminder;

		  const result = await eventsCollection.updateOne(
			  { _id: new ObjectId(eventId), userId: new ObjectId(userId) },
			  { $set: updateFields}
		  );

		  if (result.matchedCount === 0) {
			  ret = { success: false, error: 'Event not found or unauthorized', accessToken };
		  } else {
			  const updatedEvent = await eventsCollection.findOne({_id:new ObjectId(eventId)});
		  ret = { success: true, updatedEvent, error: '', accessToken};
		  } 
	  } catch (e) {
		  ret = { success: false, error: e.toString(), accessToken};
	  } 
	  try {
		  const refreshedToken = token.refresh(accessToken);
		  ret.accessToken = refreshedToken;
	  } catch (e) {
		  console.log(e.message);
	  } 
	  res.status(200).json(ret);
  });
	
  app.post('/api/deleteCalendarEvent', async(req, res) =>{
	  // incoming: userId, accessToken, eventId
	  // outgoing: success, error

	  const { userId, accessToken, eventId } = req.body;
	  let ret = {};

	  try{
		  if (token.isExpired(accessToken)){
			  return res.status(200).json({error: 'The JWT is no longer valid', accessToken: '' });
		  }
		  } catch (e) {
			  console.log(e.message);
		  } 

		  try {
			  const db = client.db('tokidatabase');
			  const eventsCollection = db.collection('calendarevents');
			  const result = await eventsCollection.deleteOne({
				  _id: new ObjectId(eventId),
				  userId: new ObjectId(userId)
			  });

			  ret = 
				  result.deletedCount === 0
			  ? {success: false, error: 'Event not found or unauthorized', accessToken }
			  : {success: true, error: 'Event deleted successfully', accessToken};
		  } catch (e) {
			  ret = { success: false, error: e.toString(), accessToken};
		  } 
		  try{
			  const refreshedToken = token.refresh(accessToken);
			  ret.accessToken = refreshedToken;
		  } catch (e) {
			  console.log(e.message);
		  } 

		  res.status(200).json(ret);
  });
  
  
  // Try to find Chrome/Chromium executable
  /*
  async function updateGarages() {
    const maxRetries = 3;
    let retryCount = 0;
    let browser;

    while (retryCount < maxRetries) {
      try {
        await client.connect();
        const db = client.db('tokidatabase');
        const collection = db.collection("parkinglocations");

        // Launch Puppeteer (bundled Chromium)
        browser = await puppeteer.launch({
          headless: true,
          args: [
            '--no-sandbox',
            '--disable-setuid-sandbox',
            '--disable-dev-shm-usage',
            '--disable-gpu'
          ]
        });

        const page = await browser.newPage();

        await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

        await page.goto('https://parking.ucf.edu/resources/garage-availability/', {
          waitUntil: 'domcontentloaded',
          timeout: 60000
        });

        await page.waitForSelector('#OccupancyOutput tr', { timeout: 10000 });

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

        break;

      } catch (err) {
        retryCount++;
        console.error(`Error scraping/updating garages (attempt ${retryCount}/${maxRetries}):`, err.message);

        if (browser) {
          try { await browser.close(); } catch {}
          browser = null;
        }

        if (retryCount < maxRetries) {
          await new Promise(resolve => setTimeout(resolve, Math.pow(2, retryCount) * 1000));
        } else {
          console.error("Max retries reached. Will try again on next interval.");
        }
      }
    }
  }
  updateGarages();
  setInterval(updateGarages, 2 * 60 * 1000);
  */

// V2 to try
  // Try to find Chrome/Chromium executable
async function updateGarages() {
  const maxRetries = 3;
  let retryCount = 0;
  let browser;

  while (retryCount < maxRetries) {
    try {
      await client.connect();
      const db = client.db('tokidatabase');
      const collection = db.collection("parkinglocations");

      // Launch Puppeteer (bundled Chromium)
      browser = await puppeteer.launch({
        headless: true,
        args: [
          '--no-sandbox',
          '--disable-setuid-sandbox',
          '--disable-dev-shm-usage',
          '--disable-gpu'
        ]
      });

      const page = await browser.newPage();

      await page.setUserAgent('Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36');

      // Enable request interception to monitor for data updates
      await page.setRequestInterception(true);
      let dataRequestCompleted = false;
      
      page.on('request', request => {
        request.continue();
      });

      page.on('response', async response => {
        const url = response.url();
        // Look for AJAX calls that might be updating the table
        if (url.includes('garage') || url.includes('occupancy') || url.includes('parking')) {
          console.log('Data request detected:', url);
          dataRequestCompleted = true;
        }
      });

      await page.goto('https://parking.ucf.edu/resources/garage-availability/', {
        waitUntil: 'networkidle0', // Changed to networkidle0 for better reliability
        timeout: 60000
      });

      await page.waitForSelector('#OccupancyOutput tr', { timeout: 10000 });

      // Wait for any AJAX requests to complete
      await new Promise(resolve => setTimeout(resolve, 5000));

      // Try to detect if the table is still being updated by checking multiple times
      let previousData = null;
      let stableCount = 0;
      const requiredStableChecks = 2;

      while (stableCount < requiredStableChecks) {
        const currentData = await page.evaluate(() => {
          const rows = Array.from(document.querySelectorAll('#OccupancyOutput tr'));
          return rows
            .map(row => {
              const cols = row.querySelectorAll('td');
              if (cols.length >= 3) {
                return {
                  name: cols[0].innerText.trim(),
                  available: parseInt(cols[1].innerText.trim(), 10),
                  total: parseInt(cols[2].innerText.trim(), 10)
                };
              }
            })
            .filter(Boolean);
        });

        if (previousData && JSON.stringify(currentData) === JSON.stringify(previousData)) {
          stableCount++;
        } else {
          stableCount = 0;
        }

        previousData = currentData;
        
        if (stableCount < requiredStableChecks) {
          await new Promise(resolve => setTimeout(resolve, 2000));
        }
      }

      // Now extract the final stable data
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

      if (garages.length > 0) {
        console.log(`[${new Date().toLocaleTimeString()}] Scraped data:`, JSON.stringify(garages.map(g => ({
          name: g.garageName,
          avail: g.availableSpots,
          total: g.totalSpots
        })), null, 2));

        for (const garage of garages) {
          await collection.updateOne(
            { garageName: garage.garageName },
            { $set: garage },
            { upsert: true }
          );
        }
        console.log(`[${new Date().toLocaleTimeString()}] Garage data updated v2:`, garages.length, "garages");
      } else {
        console.warn(`[${new Date().toLocaleTimeString()}] Warning: No garage data found v2`);
      }

      break;

    } catch (err) {
      retryCount++;
      console.error(`Error scraping/updating garages via v2 (attempt ${retryCount}/${maxRetries}):`, err.message);

      if (browser) {
        try { await browser.close(); } catch {}
        browser = null;
      }

      if (retryCount < maxRetries) {
        await new Promise(resolve => setTimeout(resolve, Math.pow(2, retryCount) * 1000));
      } else {
        console.error("Max retries reached. Will try again on next interval. v2");
      }
    }
  }
}

updateGarages();
setInterval(updateGarages, 2 * 60 * 1000); //*/


app.post('/api/viewAPOD', async(req,res)=>{
	  // incoming: userId, accessToken, taskId
	  // outgoing: all tasks / single task, error
    const {accessToken, date} = req.body;
    let ret = {};
	// validate JWT
    try{
	    if (token.isExpired(accessToken)){
		    return res
		      .status(200)
		      .json({error: 'The JWT is no longer valid', accessToken: ''});
	    }
    }catch(e) {
	    console.log(e.message);
    }
	  try{
		  const db = client.db('tokidatabase');
		  const apodsCollection = db.collection('apods');

      const apod = await apodsCollection.findOne({
        date: date,
      });

      if (!apod) {
        return res.status(200).json({
          success: false, 
          error: 'No APOD found for this date',
          accessToken
        });
      } 

      const title = apod.title;
      const hdurl = apod.hdurl;
      const explanation = apod.explanation;
      const thumbnailUrl = apod.thumbnailUrl;
      const copyright = apod.copyright || null,


			ret = {success: true, title, hdurl, explanation, thumbnailUrl, copyright , error: '', accessToken};
    }
	  catch (e)
    {
		  ret = {success: false, error: e.toString()};
	  }
	  // Refresh JWT
	  let refreshedToken = null;
	  try {
		  refreshedToken = token.refresh(accessToken);
	  } catch (e){
		  console.log(e.message);
	  } 
	  res.status(200).json(ret);
  });

async function updateAPOD() {
  try {
    const response = await fetch('https://api.nasa.gov/planetary/apod?api_key=50k2BOQgfXtPpguZO2BJCztlcCxqh1nG2fofFVBm');
    const data = await response.json();
    console.log(data);

    const document = {
    title: data.title,
    date: data.date,
    hdurl: data.hdurl,
    explanation: data.explanation,
    thumbnailUrl: data.url,
    copyright: data.copyright || null,
    createdAt: new Date(),
    updatedAt: new Date()
    };

    await client.connect();
    const db = client.db('tokidatabase');
    const collection = db.collection("apods");

    const result = await collection.insertOne(document);
    return result;
  } catch (error) {
    console.error('Error fetching NASA images:', error);
  }
}

updateAPOD();
setInterval(updateAPOD, 24 * 60 * 1000); 


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




        
