const express = require("express");
const cors = require("cors");
const db = require("./database/database");

const app = express();
const PORT = 3000;

app.use(cors());
app.use(express.json());

app.get("/", (req, res) => {
    res.json({
        message: "Smart Home Security Backend is running"
    });
});

app.get("/api/events", (req, res) => {
    const events = db.prepare("SELECT * FROM events").all();

    res.json(events);
});

app.get("/api/events/:id", (req, res) => {
    const event = db.prepare("SELECT * FROM events WHERE id = ?").get(req.params.id);

    if (!event) {
        return res.status(404).json({
            message: "Event not found"
        });
    }

    res.json(event);
});

app.post("/api/events", (req, res) => {
    const { device_id, event_type, timestamp, image_path, status } = req.body;

    const statement = db.prepare(`
        INSERT INTO events (
            device_id,
            event_type,
            timestamp,
            image_path,
            status
        )
        VALUES (?, ?, ?, ?, ?)
    `);

    const result = statement.run(
        device_id,
        event_type,
        timestamp,
        image_path,
        status
    );

    res.json({
        message: "Event added successfully",
        id: result.lastInsertRowid
    });
});

app.listen(PORT, () => {
    console.log(`Server running at http://localhost:${PORT}`);
});
