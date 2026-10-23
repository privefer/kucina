const express = require('express');
const router = express.Router();
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { query, run } = require('../db/database');
const { JWT_SECRET } = require('../middleware/auth');

// Helper para construir respuesta universal que satisface cualquier parser de Flutter
function buildAuthResponse(user, token) {
  const safeUser = {
    id: String(user.id || 'user-1'),
    name: String(user.name || 'Comensal Kucina'),
    email: String(user.email || `${String(user.phone || '999888777').replace(/\D/g, '')}@kucina.pe`),
    phone: String(user.phone || '999888777'),
    role: String(user.role || 'diner'),
    token: String(token),
    accessToken: String(token),
  };

  return {
    success: true,
    token: String(token),
    accessToken: String(token),
    jwt: String(token),
    id: safeUser.id,
    name: safeUser.name,
    email: safeUser.email,
    phone: safeUser.phone,
    role: safeUser.role,
    user: safeUser,
    data: {
      token: String(token),
      accessToken: String(token),
      user: safeUser
    }
  };
}

// 1. Registro completo con Email/Gmail, Contraseña, Nombre y Teléfono
router.post('/register', async (req, res) => {
  const name = req.body.name || req.body.nombre || req.body.userName || '';
  const phone = req.body.phone || req.body.celular || req.body.cellphone || req.body.phoneNumber || '';
  const email = req.body.email || req.body.correo || '';
  const password = req.body.password || req.body.contrasena || '';
  const role = req.body.role || 'diner';

  if (!name.trim() || !phone.trim()) {
    return res.status(400).json({ error: 'Nombre y número de teléfono son obligatorios' });
  }

  const cleanEmail = (email.trim() || `${phone.replace(/\D/g, '')}@kucina.pe`).toLowerCase();
  const cleanPhone = phone.trim();

  // Si ya existe por teléfono o correo, hacer login en lugar de error
  const existing = query('SELECT * FROM users WHERE phone = ? OR email = ?', [cleanPhone, cleanEmail]);
  if (existing.length > 0) {
    const existingUser = existing[0];
    const token = jwt.sign(
      { id: existingUser.id, email: existingUser.email, name: existingUser.name, phone: existingUser.phone, role: existingUser.role },
      JWT_SECRET,
      { expiresIn: '30d' }
    );
    return res.status(200).json(buildAuthResponse(existingUser, token));
  }

  try {
    const salt = await bcrypt.genSalt(10);
    const passwordHash = await bcrypt.hash(password || 'Kucina2026!', salt);
    const id = 'user-' + Date.now().toString(36) + Math.random().toString(36).substring(2, 5);
    const userRole = role === 'company' || role === 'admin' ? role : 'diner';

    run(
      'INSERT INTO users (id, name, email, phone, password_hash, role) VALUES (?, ?, ?, ?, ?, ?)',
      [id, name.trim(), cleanEmail, cleanPhone, passwordHash, userRole]
    );

    const newUser = { id, name: name.trim(), email: cleanEmail, phone: cleanPhone, role: userRole };
    const token = jwt.sign(
      { id, email: cleanEmail, name: name.trim(), phone: cleanPhone, role: userRole },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    console.log(`👤 [AUTH] Nuevo usuario registrado: ${name} (${cleanEmail} - ${cleanPhone})`);
    res.status(201).json(buildAuthResponse(newUser, token));
  } catch (err) {
    console.error('Error en registro:', err);
    res.status(500).json({ error: 'Error interno al registrar usuario' });
  }
});

// 2. Login Flexible: Nombre + Celular O Email + Contraseña
router.post('/login', async (req, res) => {
  const name = req.body.name || req.body.nombre || req.body.userName || '';
  const phone = req.body.phone || req.body.celular || req.body.cellphone || req.body.phoneNumber || '';
  const email = req.body.email || req.body.correo || '';
  const password = req.body.password || req.body.contrasena || '';

  // CASO A: Inicio de sesión rápido con Nombre y Teléfono (o solo Celular)
  if (phone.trim().length > 0) {
    const cleanPhone = phone.trim();
    let users = query('SELECT * FROM users WHERE phone = ?', [cleanPhone]);

    let user;
    if (users.length > 0) {
      user = users[0];
      if (name.trim().length > 0 && user.name !== name.trim()) {
        run('UPDATE users SET name = ? WHERE id = ?', [name.trim(), user.id]);
        user.name = name.trim();
      }
    } else {
      const id = 'user-' + Date.now().toString(36);
      const userName = (name.trim() || 'Comensal Kucina');
      const userEmail = `${cleanPhone.replace(/\D/g, '')}@kucina.pe`;
      const salt = await bcrypt.genSalt(10);
      const defaultHash = await bcrypt.hash('KucinaPhonePass!', salt);

      run(
        'INSERT INTO users (id, name, email, phone, password_hash, role) VALUES (?, ?, ?, ?, ?, ?)',
        [id, userName, userEmail, cleanPhone, defaultHash, 'diner']
      );

      user = { id, name: userName, email: userEmail, phone: cleanPhone, role: 'diner' };
      console.log(`📱 [AUTH] Usuario creado al instante: ${userName} (${cleanPhone})`);
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, name: user.name, phone: user.phone, role: user.role },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    console.log(`✅ [AUTH] Login exitoso: ${user.name} (${user.phone})`);
    return res.json(buildAuthResponse(user, token));
  }

  // CASO B: Inicio de sesión con Email y Contraseña
  if (email.trim().length > 0 && password.trim().length > 0) {
    const users = query('SELECT * FROM users WHERE email = ?', [email.toLowerCase().trim()]);
    if (users.length === 0) {
      return res.status(401).json({ error: 'Usuario no encontrado con este correo' });
    }

    const user = users[0];
    const isMatch = await bcrypt.compare(password, user.password_hash);
    if (!isMatch) {
      return res.status(401).json({ error: 'Contraseña incorrecta' });
    }

    const token = jwt.sign(
      { id: user.id, email: user.email, name: user.name, phone: user.phone, role: user.role },
      JWT_SECRET,
      { expiresIn: '30d' }
    );

    console.log(`🔐 [AUTH] Login con contraseña exitoso: ${user.name} (${user.email})`);
    return res.json(buildAuthResponse(user, token));
  }

  return res.status(400).json({ error: 'Ingresa tu nombre y celular, o tu correo y contraseña' });
});

module.exports = router;
