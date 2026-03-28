// middleware/cache.js
// Redis caching middleware — OPTIONAL.
// Falls back to no-cache if Redis is not available.

let redis = null;
let enabled = false;

function init() {
    const redisUrl = process.env.REDIS_URL;
    if (!redisUrl) {
        console.log('  ⚠ REDIS_URL not set — caching disabled');
        return;
    }

    try {
        const Redis = require('ioredis');
        redis = new Redis(redisUrl, {
            maxRetriesPerRequest: 1,
            connectTimeout: 3000,
            lazyConnect: true,
        });

        redis.on('connect', () => {
            enabled = true;
            console.log('  ✓ Redis cache connected');
        });

        redis.on('error', (err) => {
            enabled = false;
            console.log('  ⚠ Redis error — caching disabled:', err.message);
        });

        redis.connect().catch(() => {
            enabled = false;
        });
    } catch (err) {
        console.log('  ⚠ ioredis not available — caching disabled');
    }
}

init();

/**
 * Express middleware that caches GET responses.
 * @param {number} ttl - Time to live in seconds (default: 60)
 */
function cacheMiddleware(ttl = 60) {
    return async (req, res, next) => {
        if (!enabled || !redis || req.method !== 'GET') {
            return next();
        }

        const key = `cache:${req.originalUrl}:${req.user?._id || 'anon'}`;

        try {
            const cached = await redis.get(key);
            if (cached) {
                const data = JSON.parse(cached);
                return res.json(data);
            }
        } catch (err) {
            // Cache miss or error — continue normally
        }

        // Override res.json to cache the response
        const originalJson = res.json.bind(res);
        res.json = (body) => {
            // Cache in background (don't await)
            if (enabled && redis && res.statusCode === 200) {
                redis
                    .setex(key, ttl, JSON.stringify(body))
                    .catch(() => { });
            }
            return originalJson(body);
        };

        next();
    };
}

/**
 * Invalidate cache keys by pattern.
 */
async function invalidateCache(pattern) {
    if (!enabled || !redis) return;
    try {
        const keys = await redis.keys(`cache:${pattern}*`);
        if (keys.length > 0) {
            await redis.del(...keys);
        }
    } catch (err) {
        console.error('Cache invalidation error:', err.message);
    }
}

module.exports = {
    cacheMiddleware,
    invalidateCache,
    isEnabled: () => enabled,
};
