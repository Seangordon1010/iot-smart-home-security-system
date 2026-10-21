require('dotenv').config();

const express = require('express');
const cors = require('cors');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const fs = require('fs');
const path = require('path');
const multer = require('multer');
const db = require('./database/database');

const app = express();
const PORT = 3000;
const JWT_SECRET = process.env.JWT_SECRET;
const DEVICE_API_KEY = process.env.DEVICE_API_KEY;
const IMAGE_DIRECTORY = path.join(__dirname, 'uploads');
const MAX_IMAGE_SIZE = 5 * 1024 * 1024;

if (!JWT_SECRET) {
    throw new Error('JWT_SECRET is missing. Add it to the backend .env file.');
}

if (!DEVICE_API_KEY) {
    throw new Error('DEVICE_API_KEY is missing. Add it to the backend .env file.');
}

fs.mkdirSync(IMAGE_DIRECTORY, { recursive: true });

app.use(cors());
app.use(express.json({ limit: '1mb' }));

app.use((req, res, next) => {
    if (req.path.startsWith('/api/device/')) {
        console.log(`Device request: ${req.method} ${req.path}`);
    }

    next();
});

const imageStorage = multer.diskStorage({
    destination: (req, file, callback) => {
        callback(null, IMAGE_DIRECTORY);
    },
    filename: (req, file, callback) => {
        callback(null, `${crypto.randomUUID()}.jpg`);
    }
});

const imageUpload = multer({
    storage: imageStorage,
    limits: {
        fileSize: MAX_IMAGE_SIZE,
        files: 1
    },
    fileFilter: (req, file, callback) => {
        if (file.mimetype !== 'image/jpeg') {
            return callback(new Error('Only JPEG images are allowed.'));
        }

        callback(null, true);
    }
});

function deleteUploadedFile(file) {
    if (file && file.path) {
        fs.unlink(file.path, (error) => {
            if (error && error.code !== 'ENOENT') {
                console.error('Failed to remove uploaded file:', error);
            }
        });
    }
}

function authenticateToken(req, res, next) {
    const authorization = req.headers.authorization;

    if (!authorization || !authorization.startsWith('Bearer ')) {
        return res.status(401).json({
            message: 'Authentication token is required.'
        });
    }

    const token = authorization.slice(7);

    jwt.verify(token, JWT_SECRET, (error, user) => {
        if (error) {
            return res.status(401).json({
                message: 'Invalid or expired authentication token.'
            });
        }

        req.user = user;
        next();
    });
}

function authenticateDevice(req, res, next) {
    const suppliedKey = req.get('X-Device-Key');

    if (typeof suppliedKey !== 'string') {
        return res.status(401).json({
            message: 'Device authentication is required.'
        });
    }

    const suppliedBuffer = Buffer.from(suppliedKey);
    const expectedBuffer = Buffer.from(DEVICE_API_KEY);

    if (
        suppliedBuffer.length !== expectedBuffer.length ||
        !crypto.timingSafeEqual(suppliedBuffer, expectedBuffer)
    ) {
        return res.status(401).json({
            message: 'Invalid device API key.'
        });
    }

    next();
}

function validTimestamp(timestamp) {
    return typeof timestamp === 'string' &&
        !Number.isNaN(Date.parse(timestamp));
}

function saveEvent(req, res) {
    const {
        device_id,
        event_type,
        timestamp,
        image_path,
        status
    } = req.body;

    if (
        typeof device_id !== 'string' ||
        !device_id.trim() ||
        typeof event_type !== 'string' ||
        !event_type.trim()
    ) {
        return res.status(400).json({
            message: 'device_id and event_type are required.'
        });
    }

    const eventTimestamp = timestamp ?? new Date().toISOString();
    const eventStatus = status ?? 'new';

    if (!validTimestamp(eventTimestamp)) {
        return res.status(400).json({
            message: 'timestamp must be a valid date and time.'
        });
    }

    if (
        typeof eventStatus !== 'string' ||
        !eventStatus.trim()
    ) {
        return res.status(400).json({
            message: 'status must be a non-empty string.'
        });
    }

    if (
        image_path !== undefined &&
        image_path !== null &&
        typeof image_path !== 'string'
    ) {
        return res.status(400).json({
            message: 'image_path must be a string or null.'
        });
    }

    try {
        const result = db.prepare(`
            INSERT INTO events (
                device_id,
                event_type,
                timestamp,
                image_path,
                status
            )
            VALUES (?, ?, ?, ?, ?)
        `).run(
            device_id.trim(),
            event_type.trim(),
            eventTimestamp,
            image_path ?? null,
            eventStatus.trim()
        );

        const newEvent = db.prepare(
            'SELECT * FROM events WHERE id = ?'
        ).get(result.lastInsertRowid);

        console.log(`Event saved: ID ${newEvent.id}`);

        return res.status(201).json(newEvent);
    } catch (error) {
        console.error('Failed to save event:', error);

        return res.status(500).json({
            message: 'Failed to save event.'
        });
    }
}

function handleImageUpload(req, res, next) {
    imageUpload.single('image')(req, res, (error) => {
        if (error) {
            if (error instanceof multer.MulterError) {
                const message = error.code === 'LIMIT_FILE_SIZE'
                    ? 'Image must be 5 MB or smaller.'
                    : 'Image upload failed. Upload one JPEG image at a time.';

                return res.status(400).json({ message });
            }

            return res.status(400).json({
                message: error.message || 'Image upload failed.'
            });
        }

        next();
    });
}

app.get('/', (req, res) => {
    res.json({
        message: 'Smart Home Security Backend is running'
    });
});

app.get('/api/status', (req, res) => {
    try {
        db.prepare('SELECT 1').get();

        res.json({
            server: 'running',
            database: 'connected'
        });
    } catch (error) {
        console.error('Database status error:', error);

        res.status(500).json({
            server: 'running',
            database: 'error'
        });
    }
});

app.post('/api/auth/register', async (req, res) => {
    const { username, email, password } = req.body;

    if (
        typeof username !== 'string' ||
        typeof email !== 'string' ||
        typeof password !== 'string'
    ) {
        return res.status(400).json({
            message: 'Username, email, and password are required.'
        });
    }

    const cleanUsername = username.trim();
    const cleanEmail = email.trim().toLowerCase();

    if (!/^[a-zA-Z0-9_.-]{3,30}$/.test(cleanUsername)) {
        return res.status(400).json({
            message: 'Username must be 3-30 characters and use only letters, numbers, periods, underscores, or hyphens.'
        });
    }

    if (
        cleanEmail.length > 254 ||
        !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(cleanEmail)
    ) {
        return res.status(400).json({
            message: 'Enter a valid email address.'
        });
    }

    if (password.length < 8 || password.length > 72) {
        return res.status(400).json({
            message: 'Password must be between 8 and 72 characters.'
        });
    }

    try {
        const existingUser = db.prepare(`
            SELECT id
            FROM users
            WHERE username = ? COLLATE NOCASE
               OR email = ? COLLATE NOCASE
        `).get(cleanUsername, cleanEmail);

        if (existingUser) {
            return res.status(409).json({
                message: 'That username or email is already registered.'
            });
        }

        const passwordHash = await bcrypt.hash(password, 12);

        const result = db.prepare(`
            INSERT INTO users (username, email, password_hash)
            VALUES (?, ?, ?)
        `).run(cleanUsername, cleanEmail, passwordHash);

        res.status(201).json({
            message: 'Account created successfully.',
            user: {
                id: result.lastInsertRowid,
                username: cleanUsername,
                email: cleanEmail
            }
        });
    } catch (error) {
        console.error('Registration error:', error);

        res.status(500).json({
            message: 'Unable to create the account.'
        });
    }
});

app.post('/api/auth/login', async (req, res) => {
    const { identifier, password } = req.body;

    if (
        typeof identifier !== 'string' ||
        !identifier.trim() ||
        typeof password !== 'string' ||
        !password
    ) {
        return res.status(400).json({
            message: 'Username/email and password are required.'
        });
    }

    try {
        const user = db.prepare(`
            SELECT id, username, email, password_hash
            FROM users
            WHERE username = ? COLLATE NOCASE
               OR email = ? COLLATE NOCASE
        `).get(identifier.trim(), identifier.trim());

        if (!user) {
            return res.status(401).json({
                message: 'Invalid username/email or password.'
            });
        }

        const passwordMatches = await bcrypt.compare(
            password,
            user.password_hash
        );

        if (!passwordMatches) {
            return res.status(401).json({
                message: 'Invalid username/email or password.'
            });
        }

        const token = jwt.sign(
            {
                sub: String(user.id),
                username: user.username
            },
            JWT_SECRET,
            {
                expiresIn: '1h'
            }
        );

        res.json({
            message: 'Login successful.',
            token,
            user: {
                id: user.id,
                username: user.username,
                email: user.email
            }
        });
    } catch (error) {
        console.error('Login error:', error);

        res.status(500).json({
            message: 'Unable to log in.'
        });
    }
});

app.get('/api/events', authenticateToken, (req, res) => {
    try {
        const events = db.prepare(`
            SELECT *
            FROM events
            ORDER BY id DESC
        `).all();

        res.json(events);
    } catch (error) {
        console.error('Event retrieval error:', error);

        res.status(500).json({
            message: 'Failed to retrieve events.'
        });
    }
});

app.get('/api/events/:id', authenticateToken, (req, res) => {
    const eventId = Number(req.params.id);

    if (!Number.isSafeInteger(eventId) || eventId < 1) {
        return res.status(400).json({
            message: 'Invalid event ID.'
        });
    }

    try {
        const event = db.prepare(
            'SELECT * FROM events WHERE id = ?'
        ).get(eventId);

        if (!event) {
            return res.status(404).json({
                message: 'Event not found.'
            });
        }

        res.json(event);
    } catch (error) {
        console.error('Event retrieval error:', error);

        res.status(500).json({
            message: 'Failed to retrieve event.'
        });
    }
});

app.get('/api/events/:id/image', authenticateToken, (req, res) => {
    const eventId = Number(req.params.id);

    if (!Number.isSafeInteger(eventId) || eventId < 1) {
        return res.status(400).json({
            message: 'Invalid event ID.'
        });
    }

    try {
        const event = db.prepare(
            'SELECT image_path FROM events WHERE id = ?'
        ).get(eventId);

        if (!event) {
            return res.status(404).json({
                message: 'Event not found.'
            });
        }

        if (!event.image_path) {
            return res.status(404).json({
                message: 'This event does not have an image.'
            });
        }

        const filename = path.basename(event.image_path);
        const imagePath = path.join(IMAGE_DIRECTORY, filename);

        if (
            filename !== event.image_path ||
            !fs.existsSync(imagePath)
        ) {
            return res.status(404).json({
                message: 'Image file not found.'
            });
        }

        res.type('image/jpeg');
        res.sendFile(imagePath);
    } catch (error) {
        console.error('Image retrieval error:', error);

        res.status(500).json({
            message: 'Failed to retrieve image.'
        });
    }
});

app.post('/api/events', authenticateToken, (req, res) => {
    saveEvent(req, res);
});

app.post('/api/device/events', authenticateDevice, (req, res) => {
    saveEvent(req, res);
});

app.post(
    '/api/device/events/image',
    authenticateDevice,
    handleImageUpload,
    (req, res) => {
        if (!req.file) {
            return res.status(400).json({
                message: 'A JPEG image in the image field is required.'
            });
        }

        const {
            device_id,
            event_type,
            timestamp,
            status
        } = req.body;

        if (
            typeof device_id !== 'string' ||
            !device_id.trim() ||
            typeof event_type !== 'string' ||
            !event_type.trim()
        ) {
            deleteUploadedFile(req.file);

            return res.status(400).json({
                message: 'device_id and event_type are required.'
            });
        }

        const eventTimestamp = timestamp ?? new Date().toISOString();
        const eventStatus = status ?? 'new';

        if (!validTimestamp(eventTimestamp)) {
            deleteUploadedFile(req.file);

            return res.status(400).json({
                message: 'timestamp must be a valid date and time.'
            });
        }

        if (
            typeof eventStatus !== 'string' ||
            !eventStatus.trim()
        ) {
            deleteUploadedFile(req.file);

            return res.status(400).json({
                message: 'status must be a non-empty string.'
            });
        }

        try {
            const result = db.prepare(`
                INSERT INTO events (
                    device_id,
                    event_type,
                    timestamp,
                    image_path,
                    status
                )
                VALUES (?, ?, ?, ?, ?)
            `).run(
                device_id.trim(),
                event_type.trim(),
                eventTimestamp,
                req.file.filename,
                eventStatus.trim()
            );

            const event = db.prepare(
                'SELECT * FROM events WHERE id = ?'
            ).get(result.lastInsertRowid);

            res.status(201).json({
                message: 'Event and image saved successfully.',
                event,
                image_url: `/api/events/${event.id}/image`
            });
        } catch (error) {
            deleteUploadedFile(req.file);
            console.error('Failed to save event image:', error);

            res.status(500).json({
                message: 'Failed to save event and image.'
            });
        }
    }
);

app.post(
    '/api/events/:id/image',
    authenticateToken,
    handleImageUpload,
    (req, res) => {
        const eventId = Number(req.params.id);

        if (!Number.isSafeInteger(eventId) || eventId < 1) {
            deleteUploadedFile(req.file);

            return res.status(400).json({
                message: 'Invalid event ID.'
            });
        }

        if (!req.file) {
            return res.status(400).json({
                message: 'A JPEG image in the image field is required.'
            });
        }

        try {
            const event = db.prepare(
                'SELECT * FROM events WHERE id = ?'
            ).get(eventId);

            if (!event) {
                deleteUploadedFile(req.file);

                return res.status(404).json({
                    message: 'Event not found.'
                });
            }

            const update = db.prepare(`
                UPDATE events
                SET image_path = ?
                WHERE id = ?
            `).run(req.file.filename, eventId);

            if (update.changes !== 1) {
                deleteUploadedFile(req.file);

                return res.status(500).json({
                    message: 'Failed to associate image with event.'
                });
            }

            if (event.image_path) {
                const oldFilename = path.basename(event.image_path);
                const oldPath = path.join(IMAGE_DIRECTORY, oldFilename);

                if (
                    oldFilename === event.image_path &&
                    oldFilename !== req.file.filename
                ) {
                    deleteUploadedFile({ path: oldPath });
                }
            }

            const updatedEvent = db.prepare(
                'SELECT * FROM events WHERE id = ?'
            ).get(eventId);

            res.json({
                message: 'Image associated with event successfully.',
                event: updatedEvent,
                image_url: `/api/events/${eventId}/image`
            });
        } catch (error) {
            deleteUploadedFile(req.file);
            console.error('Failed to associate image:', error);

            res.status(500).json({
                message: 'Failed to associate image with event.'
            });
        }
    }
);

app.use((error, req, res, next) => {
    console.error('Unexpected server error:', error);

    if (res.headersSent) {
        return next(error);
    }

    res.status(500).json({
        message: 'An unexpected server error occurred.'
    });
});

app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server running on port ${PORT}`);
});
    console.log(`Server running on port ${PORT}`);
});
