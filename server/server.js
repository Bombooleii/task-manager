const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const cors = require('cors');
const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');

const app = express();
const PORT = process.env.PORT || 3000;
const JWT_SECRET = process.env.JWT_SECRET || 'task-manager-secret-key-2024';
const DB_PATH = path.join(__dirname, 'db.json');

app.use(cors());
app.use(express.json());

// --- Database helpers ---
function readDb() {
  const data = fs.readFileSync(DB_PATH, 'utf-8');
  return JSON.parse(data);
}

function writeDb(data) {
  fs.writeFileSync(DB_PATH, JSON.stringify(data, null, 2));
}

function initDb() {
  if (!fs.existsSync(DB_PATH)) {
    writeDb({ users: [], tasks: [] });
  }
  const db = readDb();
  if (!db.users) db.users = [];
  if (!db.tasks) db.tasks = [];
  writeDb(db);
}

initDb();

// --- Auth middleware ---
function authenticate(req, res, next) {
  const authHeader = req.headers.authorization;
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({ error: 'Token шаардлагатай' });
  }

  try {
    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, JWT_SECRET);
    req.userId = decoded.userId;
    next();
  } catch (err) {
    return res.status(401).json({ error: 'Token буруу эсвэл хугацаа дууссан' });
  }
}

// --- Auth routes ---
app.post('/register', async (req, res) => {
  const { name, email, password } = req.body;

  if (!email || !password || !name) {
    return res.status(400).json({ error: 'Нэр, имэйл, нууц үг шаардлагатай' });
  }

  const db = readDb();
  const existingUser = db.users.find(u => u.email === email);
  if (existingUser) {
    return res.status(400).json({ error: 'Энэ имэйл бүртгэлтэй байна' });
  }

  const hashedPassword = await bcrypt.hash(password, 10);
  const user = {
    id: uuidv4(),
    name,
    email,
    password: hashedPassword,
    createdAt: new Date().toISOString(),
  };

  db.users.push(user);
  writeDb(db);

  const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '30d' });

  res.status(201).json({
    token,
    user: { id: user.id, name: user.name, email: user.email },
  });
});

app.post('/login', async (req, res) => {
  const { email, password } = req.body;

  if (!email || !password) {
    return res.status(400).json({ error: 'Имэйл, нууц үг шаардлагатай' });
  }

  const db = readDb();
  const user = db.users.find(u => u.email === email);
  if (!user) {
    return res.status(401).json({ error: 'Имэйл эсвэл нууц үг буруу' });
  }

  const isValid = await bcrypt.compare(password, user.password);
  if (!isValid) {
    return res.status(401).json({ error: 'Имэйл эсвэл нууц үг буруу' });
  }

  const token = jwt.sign({ userId: user.id }, JWT_SECRET, { expiresIn: '30d' });

  res.json({
    token,
    user: { id: user.id, name: user.name, email: user.email },
  });
});

// --- Users route ---
app.get('/users', (req, res) => {
  const db = readDb();
  const users = db.users.map(({ password, ...user }) => ({
    ...user,
    tasks: db.tasks.filter(t => t.userId === user.id),
  }));
  res.json(users);
});

// --- Task routes (protected) ---
app.get('/tasks', authenticate, (req, res) => {
  const db = readDb();
  const tasks = db.tasks.filter(t => t.userId === req.userId);
  res.json(tasks);
});

app.post('/tasks', authenticate, (req, res) => {
  const db = readDb();
  const task = {
    id: uuidv4(),
    ...req.body,
    userId: req.userId,
    createdAt: new Date().toISOString(),
  };

  db.tasks.push(task);
  writeDb(db);
  res.status(201).json(task);
});

app.put('/tasks/:id', authenticate, (req, res) => {
  const db = readDb();
  const index = db.tasks.findIndex(t => t.id === req.params.id && t.userId === req.userId);

  if (index === -1) {
    return res.status(404).json({ error: 'Task олдсонгүй' });
  }

  db.tasks[index] = { ...db.tasks[index], ...req.body, userId: req.userId };
  writeDb(db);
  res.json(db.tasks[index]);
});

app.delete('/tasks/:id', authenticate, (req, res) => {
  const db = readDb();
  const index = db.tasks.findIndex(t => t.id === req.params.id && t.userId === req.userId);

  if (index === -1) {
    return res.status(404).json({ error: 'Task олдсонгүй' });
  }

  db.tasks.splice(index, 1);
  writeDb(db);
  res.json({ message: 'Устгагдлаа' });
});

// --- Health check ---
app.get('/', (req, res) => {
  res.json({ status: 'ok', message: 'Task Manager API' });
});

app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
