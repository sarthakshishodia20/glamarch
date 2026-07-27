const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { randomUUID } = require('crypto');
const riderRepository = require('../repositories/riderRepository');
const adminRepository = require('../repositories/adminRepository');
const ApiError = require('../utils/ApiError');

const authService = {
  register: async (riderData) => {
    console.log(`[1][AUTH] Register attempt - phone: ${riderData.phone_number}`);

    const existingRider = await riderRepository.findByPhone(riderData.phone_number);
    if (existingRider) {
      console.log(`[1][AUTH] Phone already registered - ${riderData.phone_number}`);
      throw ApiError.conflict('Yeh mobile number pehle se registered hai');
    }

    const id = randomUUID();
    await riderRepository.create({
      id,
      full_name: riderData.full_name,
      phone_number: riderData.phone_number,
      gender: riderData.gender,
      city: riderData.city,
      preferred_language: riderData.preferred_language || 'hindi',
    });

    const newRider = await riderRepository.findById(id);

    const token = jwt.sign(
      { id: newRider.id, phone_number: newRider.phone_number, role: 'rider' },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
    );

    console.log(`[1][AUTH] Rider registered - name: ${newRider.full_name}, id: ${newRider.id}`);
    return { token, rider: newRider };
  },

  loginRider: async (phone_number) => {
    console.log(`[1][AUTH] Rider login attempt - phone: ${phone_number}`);

    const rider = await riderRepository.findByPhone(phone_number);
    if (!rider) {
      console.log(`[1][AUTH] Phone not found - ${phone_number}`);
      throw ApiError.notFound('Yeh phone number registered nahi hai. Pehle register karein.');
    }

    const token = jwt.sign(
      { id: rider.id, phone_number: rider.phone_number, role: 'rider' },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '30d' }
    );

    console.log(`[1][AUTH] Rider login success - name: ${rider.full_name}, stage: ${rider.onboarding_stage}`);
    return { token, rider };
  },

  loginAdmin: async (email, password) => {
    console.log(`[1][AUTH] Admin login attempt - email: ${email}`);

    const admin = await adminRepository.findByEmail(email);
    if (!admin) {
      console.log(`[1][AUTH] Admin not found - ${email}`);
      throw ApiError.unauthorized('Invalid email ya password');
    }

    if (!admin.is_active) {
      console.log(`[1][AUTH] Inactive admin tried to login - ${email}`);
      throw ApiError.forbidden('Aapka admin account inactive kar diya gaya hai');
    }

    const isPasswordValid = await bcrypt.compare(password, admin.password_hash);
    if (!isPasswordValid) {
      console.log(`[1][AUTH] Wrong password - ${email}`);
      throw ApiError.unauthorized('Invalid email ya password');
    }

    const token = jwt.sign(
      { id: admin.id, email: admin.email, role: admin.role },
      process.env.JWT_SECRET,
      { expiresIn: '7d' }
    );

    const { password_hash, ...adminProfile } = admin;
    console.log(`[1][AUTH] Admin login success - name: ${admin.name}, role: ${admin.role}`);
    return { token, admin: adminProfile };
  },

  getMe: async (userData) => {
    console.log(`[1][AUTH] getMe - role: ${userData.role}, id: ${userData.id}`);
    if (userData.role === 'rider') {
      const rider = await riderRepository.findById(userData.id);
      if (!rider) throw ApiError.notFound('Rider account nahi mila');
      return rider;
    } else {
      const admin = await adminRepository.findById(userData.id);
      if (!admin) throw ApiError.notFound('Admin account nahi mila');
      return admin;
    }
  },
};

module.exports = authService;
