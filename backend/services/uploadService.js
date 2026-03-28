// services/uploadService.js
// Cloudinary image upload — OPTIONAL.
// Only works if CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY,
// CLOUDINARY_API_SECRET environment variables are configured.

const multer = require('multer');

let cloudinary = null;
let enabled = false;

function init() {
    const cloudName = process.env.CLOUDINARY_CLOUD_NAME;
    const apiKey = process.env.CLOUDINARY_API_KEY;
    const apiSecret = process.env.CLOUDINARY_API_SECRET;

    if (cloudName && apiKey && apiSecret) {
        try {
            const cloudinaryLib = require('cloudinary').v2;
            cloudinaryLib.config({
                cloud_name: cloudName,
                api_key: apiKey,
                api_secret: apiSecret,
            });
            cloudinary = cloudinaryLib;
            enabled = true;
            console.log('  ✓ Cloudinary upload service enabled');
        } catch (err) {
            console.log('  ⚠ Cloudinary package not available — uploads disabled');
        }
    } else {
        console.log('  ⚠ Cloudinary env vars not set — uploads disabled');
    }
}

init();

// Multer memory storage (files stay in memory, not on disk)
const upload = multer({
    storage: multer.memoryStorage(),
    limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB max
    fileFilter: (req, file, cb) => {
        if (file.mimetype.startsWith('image/')) {
            cb(null, true);
        } else {
            cb(new Error('Only image files are allowed'), false);
        }
    },
});

/**
 * Upload a buffer to Cloudinary.
 * @param {Buffer} buffer - File buffer
 * @param {string} folder - Cloudinary folder
 * @returns {Promise<object|null>} { url, publicId } or null
 */
async function uploadImage(buffer, folder = 'careshift/avatars') {
    if (!enabled || !cloudinary) {
        console.log('[Upload skipped] Cloudinary not configured');
        return null;
    }

    return new Promise((resolve, reject) => {
        const stream = cloudinary.uploader.upload_stream(
            {
                folder,
                transformation: [
                    { width: 300, height: 300, crop: 'fill', gravity: 'face' },
                ],
            },
            (error, result) => {
                if (error) return reject(error);
                resolve({
                    url: result.secure_url,
                    publicId: result.public_id,
                });
            }
        );

        stream.end(buffer);
    });
}

/**
 * Delete an image from Cloudinary.
 */
async function deleteImage(publicId) {
    if (!enabled || !cloudinary || !publicId) return null;
    try {
        return await cloudinary.uploader.destroy(publicId);
    } catch (err) {
        console.error('Cloudinary delete error:', err.message);
        return null;
    }
}

module.exports = {
    upload,       // Multer middleware
    uploadImage,
    deleteImage,
    isEnabled: () => enabled,
};
