// MongoDB initialization script
db = db.getSiblingDB('task_manager');

db.createCollection('users');
db.createCollection('projects');
db.createCollection('tasks');
db.createCollection('comments');

// Create indexes
db.users.createIndex({ email: 1 }, { unique: true });
db.tasks.createIndex({ project: 1, status: 1 });
db.tasks.createIndex({ assignee: 1 });
db.comments.createIndex({ task: 1 });

print('✅ Database initialized with collections and indexes');
