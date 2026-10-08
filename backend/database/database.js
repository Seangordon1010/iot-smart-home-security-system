const Database = require("better-sqlite3");

const db = new Database("database/smart_home.db");

db.exec(`
    CREATE TABLE IF NOT EXISTS events (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        device_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        image_path TEXT,
        status TEXT
    )
`);

console.log("SQLite database connected.");

module.exports = db;
