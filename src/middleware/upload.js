const cloudinary = require('cloudinary').v2;
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const { randomUUID } = require('crypto');
const ApiError = require('../utils/ApiError');

// ── Cloudinary Config ──
// .env mein CLOUDINARY_CLOUD_NAME, CLOUDINARY_API_KEY, CLOUDINARY_API_SECRET set karo
// Agar ye variables nahi hain toh local disk use hogi (dev mode)
const isCloudinaryConfigured = !!(
  process.env.CLOUDINARY_CLOUD_NAME &&
  process.env.CLOUDINARY_API_KEY &&
  process.env.CLOUDINARY_API_SECRET
);

if (isCloudinaryConfigured) {
  cloudinary.config({
    cloud_name: process.env.CLOUDINARY_CLOUD_NAME,
    api_key:    process.env.CLOUDINARY_API_KEY,
    api_secret: process.env.CLOUDINARY_API_SECRET,
  });
  console.log('[UPLOAD] Cloudinary storage active');
} else {
  console.log('[UPLOAD] Local disk storage active (dev mode)');
}

// ── Document Upload Storage ──
// Production (Cloudinary configured): file seedha cloud pr jaegi
// Development (no Cloudinary): local disk pr save hogi
let documentStorage;

if (isCloudinaryConfigured) {
  documentStorage = new CloudinaryStorage({
    cloudinary,
    params: (req, file) => {
      const docType = req.body.document_type || 'misc';
      const ext = path.extname(file.originalname).toLowerCase().replace('.', '');
      return {
        folder: `glam-onboarding/${docType}`,  // Cloudinary mein folder structure
        public_id: `${docType}_${randomUUID()}`,
        resource_type: 'auto',                  // image aur PDF dono handle karo
        format: ext === 'pdf' ? 'pdf' : undefined,
        allowed_formats: ['jpg', 'jpeg', 'png', 'pdf'],
      };
    },
  });
} else {
  documentStorage = multer.diskStorage({
    destination: (req, file, cb) => {
      const docType = req.body.document_type || 'misc';
      const uploadPath = path.join(__dirname, '../../uploads', docType);
      if (!fs.existsSync(uploadPath)) fs.mkdirSync(uploadPath, { recursive: true });
      cb(null, uploadPath);
    },
    filename: (req, file, cb) => {
      const ext = path.extname(file.originalname).toLowerCase();
      cb(null, `${randomUUID()}${ext}`);
    },
  });
}

const fileFilter = (req, file, cb) => {
  const allowed = ['image/jpeg', 'image/jpg', 'image/png', 'application/pdf'];
  if (allowed.includes(file.mimetype)) cb(null, true);
  else cb(new ApiError(400, 'Invalid file type. Only JPG, PNG, PDF allowed.'), false);
};

const upload = multer({
  storage: documentStorage,
  fileFilter,
  limits: { fileSize: parseInt(process.env.MAX_FILE_SIZE) || 5242880, files: 1 },
});

const handleUploadError = (fieldName) => (req, res, next) => {
  upload.single(fieldName)(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') return next(ApiError.badRequest('File too large. Max 5MB.'));
      return next(ApiError.badRequest(`Upload error: ${err.message}`));
    } else if (err) {
      return next(err);
    }

    // Cloudinary use ho rahi hai toh req.file.path = secure_url hogi
    // Local disk use ho rahi hai toh req.file.path = local path hogi
    // Dono cases mein documentService ko same req.file object milta hai!
    if (req.file && isCloudinaryConfigured) {
      // Cloudinary ka URL req.file.path mein auto set ho jaata hai by multer-storage-cloudinary
      console.log(`[UPLOAD] Cloudinary upload done - url: ${req.file.path}`);
    }

    next();
  });
};

// ── CSV Upload Handler (hamesha local disk pr — CSV cloud pr nahi jaegi) ──
const csvStorage = multer.diskStorage({
  destination: (req, file, cb) => {
    const uploadPath = path.join(__dirname, '../../uploads/csv');
    if (!fs.existsSync(uploadPath)) fs.mkdirSync(uploadPath, { recursive: true });
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    cb(null, `csv-${Date.now()}-${randomUUID()}.csv`);
  },
});

const csvFilter = (req, file, cb) => {
  const allowedExts = ['.csv', '.txt'];
  const ext = path.extname(file.originalname).toLowerCase();
  const allowedMimes = ['text/csv', 'application/vnd.ms-excel', 'text/plain', 'application/csv', 'text/x-csv'];
  if (allowedExts.includes(ext) || allowedMimes.includes(file.mimetype)) cb(null, true);
  else cb(new ApiError(400, 'Invalid file type. Kripya .csv file upload karein.'), false);
};

const csvUpload = multer({
  storage: csvStorage,
  fileFilter: csvFilter,
  limits: { fileSize: 10 * 1024 * 1024, files: 1 },
});

const handleCsvUploadError = (fieldName) => (req, res, next) => {
  csvUpload.single(fieldName)(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      return next(ApiError.badRequest(`CSV Upload error: ${err.message}`));
    } else if (err) {
      return next(err);
    }
    next();
  });
};

module.exports = { upload, handleUploadError, handleCsvUploadError };
