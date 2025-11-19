const request = require('supertest');
const express = require('express');
const { MongoMemoryServer } = require('mongodb-memory-server');
const { MongoClient } = require('mongodb');

jest.mock('../createJWT.js', () => ({
  createToken: jest.fn(() => ({ accessToken: 'mock-jwt-token' })),
  isExpired: jest.fn(() => false),
  refresh: jest.fn(() => 'refreshed-jwt-token')
}));

jest.mock('@sendgrid/mail', () => ({
  setApiKey: jest.fn(),
  send: jest.fn().mockResolvedValue([{ statusCode: 202 }])
}));

const API = require('../api.js');

describe('Toki API Unit Tests', () => {
  let app, mongoServer, client, db;

  beforeAll(async () => {
    mongoServer = await MongoMemoryServer.create();
    const uri = mongoServer.getUri();
    client = new MongoClient(uri);
    await client.connect();
    app = express();
    app.use(express.json());
    API.setApp(app, client);
  });

  afterAll(async () => {
    await client.close();
    await mongoServer.stop();
  });

  beforeEach(async () => {
    db = client.db('tokidatabase');
    const collections = await db.listCollections().toArray();
    for (const collection of collections) {
      await db.collection(collection.name).deleteMany({});
    }
  });

  describe('User Management', () => {
    test('should register a new user', async () => {
      const response = await request(app).post('/api/addUser').send({
        firstName: 'John', lastName: 'Doe',
        email: 'john@example.com', password: 'password123'
      });
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('id');
    });

    test('should reject duplicate email', async () => {
      await request(app).post('/api/addUser').send({
        firstName: 'John', lastName: 'Doe',
        email: 'john@example.com', password: 'pass123'
      });
      const response = await request(app).post('/api/addUser').send({
        firstName: 'Jane', lastName: 'Smith',
        email: 'john@example.com', password: 'pass456'
      });
      expect(response.body.error).toBe('Email already registered');
    });

    test('should login with valid credentials', async () => {
      await request(app).post('/api/addUser').send({
        firstName: 'Login', lastName: 'Test',
        email: 'login@example.com', password: 'loginpass'
      });
      const response = await request(app).post('/api/loginUser').send({
        email: 'login@example.com', password: 'loginpass'
      });
      expect(response.status).toBe(200);
      expect(response.body).toHaveProperty('accessToken');
    });

    test('should reject invalid credentials', async () => {
      const response = await request(app).post('/api/loginUser').send({
        email: 'nonexistent@example.com', password: 'wrongpass'
      });
      expect(response.body.error).toBe('Email not found');
    });

    test('should update user information', async () => {
      const registerResponse = await request(app).post('/api/addUser').send({
        firstName: 'Original', lastName: 'Name',
        email: 'update@example.com', password: 'oldpass'
      });
      const response = await request(app).post('/api/updateUser').send({
        id: registerResponse.body.id,
        firstName: 'Updated', lastName: 'Name',
        email: 'update@example.com', password: 'newpass',
        accessToken: registerResponse.body.accessToken
      });
      expect(response.body.success).toBe(true);
      expect(response.body.firstName).toBe('Updated');
    });

    test('should delete user account', async () => {
      const registerResponse = await request(app).post('/api/addUser').send({
        firstName: 'Delete', lastName: 'Me',
        email: 'delete@example.com', password: 'deletepass'
      });
      const response = await request(app).post('/api/deleteUser').send({
        id: registerResponse.body.id,
        accessToken: registerResponse.body.accessToken
      });
      expect(response.body.success).toBe(true);
    });
  });

  describe('Reminder Management', () => {
    let userId, accessToken;

    beforeEach(async () => {
      const response = await request(app).post('/api/addUser').send({
        firstName: 'Reminder', lastName: 'User',
        email: `reminder${Date.now()}@example.com`, password: 'reminderpass'
      });
      userId = response.body.id;
      accessToken = response.body.accessToken;
    });

    test('should create a reminder', async () => {
      const response = await request(app).post('/api/createReminder').send({
        userId, accessToken, title: 'Meeting', desc: 'Team meeting',
        status: 'pending', priority: 'high', year: 2025, month: 11, day: 20
      });
      expect(response.body.title).toBe('Meeting');
    });

    test('should view all reminders', async () => {
      await request(app).post('/api/createReminder').send({
        userId, accessToken, title: 'R1', desc: 'First',
        status: 'pending', priority: 'high', year: 2025, month: 11, day: 20
      });
      const response = await request(app).post('/api/viewReminder').send({
        userId, accessToken
      });
      expect(response.body.reminders).toHaveLength(1);
    });

    test('should edit a reminder', async () => {
      await request(app).post('/api/createReminder').send({
        userId, accessToken, title: 'Edit', desc: 'Original',
        status: 'pending', priority: 'low', year: 2025, month: 11, day: 20
      });
      const response = await request(app).post('/api/editReminder').send({
        userId, accessToken, title: 'Edit', desc: 'Updated',
        status: 'in-progress', priority: 'high', year: 2025, month: 11, day: 25
      });
      expect(response.body.desc).toBe('Updated');
    });

    test('should complete a reminder', async () => {
      await request(app).post('/api/createReminder').send({
        userId, accessToken, title: 'Complete', desc: 'Task',
        status: 'pending', priority: 'medium', year: 2025, month: 11, day: 20
      });
      const response = await request(app).post('/api/completeReminder').send({
        userId, accessToken, title: 'Complete'
      });
      expect(response.body.success).toBe(true);
    });

    test('should delete a reminder', async () => {
      await request(app).post('/api/createReminder').send({
        userId, accessToken, title: 'Delete', desc: 'Will delete',
        status: 'pending', priority: 'low', year: 2025, month: 11, day: 20
      });
      const response = await request(app).post('/api/deleteReminder').send({
        userId, accessToken, title: 'Delete'
      });
      expect(response.body.success).toBe(true);
    });
  });

  describe('Task Management', () => {
    let userId, accessToken;

    beforeEach(async () => {
      const response = await request(app).post('/api/addUser').send({
        firstName: 'Task', lastName: 'User',
        email: `task${Date.now()}@example.com`, password: 'taskpass'
      });
      userId = response.body.id;
      accessToken = response.body.accessToken;
    });

    test('should create a task', async () => {
      const response = await request(app).post('/api/createTask').send({
        userId, accessToken, title: 'Project', description: 'Complete project'
      });
      expect(response.body.success).toBe(true);
      expect(response.body).toHaveProperty('taskId');
    });

    test('should view all tasks', async () => {
      await request(app).post('/api/createTask').send({
        userId, accessToken, title: 'T1', description: 'First'
      });
      const response = await request(app).post('/api/viewTask').send({
        userId, accessToken
      });
      expect(response.body.tasks).toHaveLength(1);
    });

    test('should edit a task', async () => {
      const createResponse = await request(app).post('/api/createTask').send({
        userId, accessToken, title: 'Original', description: 'Orig desc'
      });
      const response = await request(app).post('/api/editTask').send({
        userId, accessToken, taskId: createResponse.body.taskId,
        title: 'Updated', status: 'in progress'
      });
      expect(response.body.updatedTask.title).toBe('Updated');
    });

    test('should delete a task', async () => {
      const createResponse = await request(app).post('/api/createTask').send({
        userId, accessToken, title: 'Delete Task'
      });
      const response = await request(app).post('/api/deleteTask').send({
        userId, accessToken, taskId: createResponse.body.taskId
      });
      expect(response.body.success).toBe(true);
    });
  });

  describe('Calendar Events', () => {
    let userId, accessToken;

    beforeEach(async () => {
      const response = await request(app).post('/api/addUser').send({
        firstName: 'Calendar', lastName: 'User',
        email: `calendar${Date.now()}@example.com`, password: 'calpass'
      });
      userId = response.body.id;
      accessToken = response.body.accessToken;
    });

    test('should create calendar event', async () => {
      const response = await request(app).post('/api/createCalendarEvent').send({
        userId, accessToken, title: 'Meeting', description: 'Planning',
        location: 'Room A', startDate: '2025-11-20T10:00:00.000Z',
        endDate: '2025-11-20T11:00:00.000Z'
      });
      expect(response.body.success).toBe(true);
    });

    test('should view calendar events', async () => {
      await request(app).post('/api/createCalendarEvent').send({
        userId, accessToken, title: 'Event', description: 'Test',
        location: 'Room B', startDate: '2025-11-20T10:00:00.000Z',
        endDate: '2025-11-20T11:00:00.000Z'
      });
      const response = await request(app).post('/api/viewCalendarEvent').send({
        userId, accessToken
      });
      expect(response.body.events).toHaveLength(1);
    });

    test('should delete calendar event', async () => {
      const createResponse = await request(app).post('/api/createCalendarEvent').send({
        userId, accessToken, title: 'Delete Event', description: 'Will delete',
        location: 'Room C', startDate: '2025-11-20T10:00:00.000Z',
        endDate: '2025-11-20T11:00:00.000Z'
      });
      const response = await request(app).post('/api/deleteCalendarEvent').send({
        userId, accessToken, eventId: createResponse.body.eventId
      });
      expect(response.body.success).toBe(true);
    });
  });

  describe('APOD Integration', () => {
    let accessToken;

    beforeEach(async () => {
      const response = await request(app).post('/api/addUser').send({
        firstName: 'APOD', lastName: 'User',
        email: `apod${Date.now()}@example.com`, password: 'apodpass'
      });
      accessToken = response.body.accessToken;
      await db.collection('apods').insertOne({
        date: '2025-11-16', title: 'Horsehead Nebula',
        hdurl: 'https://example.com/image.jpg',
        explanation: 'Beautiful nebula',
        thumbnailUrl: 'https://example.com/thumb.jpg',
        copyright: 'Astronomer'
      });
    });

    test('should retrieve APOD for date', async () => {
      const response = await request(app).post('/api/viewAPOD').send({
        accessToken, date: '2025-11-16'
      });
      expect(response.body.success).toBe(true);
      expect(response.body.title).toBe('Horsehead Nebula');
    });

    test('should return error for non-existent date', async () => {
      const response = await request(app).post('/api/viewAPOD').send({
        accessToken, date: '1990-01-01'
      });
      expect(response.body.success).toBe(false);
    });
  });
});
