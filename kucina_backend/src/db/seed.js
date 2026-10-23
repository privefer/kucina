const bcrypt = require('bcryptjs');
const { query, run } = require('./database');

async function runSeed() {
  // 1. Seed default users with secure bcrypt hashes
  const userCount = query('SELECT COUNT(*) as count FROM users')[0]?.count || 0;
  if (userCount === 0) {
    console.log('👤 Creando usuarios por defecto con contraseñas seguras...');
    const salt = await bcrypt.genSalt(10);
    const hash = await bcrypt.hash('Kucina2026!', salt);

    run(`INSERT INTO users (id, name, email, phone, password_hash, role) VALUES 
      ('user-1', 'Rodrigo Pérez', 'diner@kucina.com', '999888777', ?, 'diner'),
      ('user-admin', 'Admin Kucina', 'admin@kucina.com', '999111222', ?, 'admin'),
      ('user-company', 'Hostess Carnal', 'carnal@kucina.com', '987654321', ?, 'company')`,
      [hash, hash, hash]);
  }

  const existing = query('SELECT COUNT(*) as count FROM restaurants');
  if (existing[0]?.count > 0) {
    return;
  }

  console.log('🌱 Seeding initial restaurant and slot data...');

  const restaurants = [
    {
      id: 'rest-1',
      name: 'Carnal Prime Steakhouse',
      cuisine: 'Carnes & Parrillas',
      price_range: '$$$$',
      rating: 4.8,
      review_count: 342,
      address: 'Calle Elías Aguirre 698, Miraflores',
      district: 'Miraflores',
      image_url: 'https://images.unsplash.com/photo-1544025162-d76694265947?w=800&q=80',
      phone: '+51 987 654 321',
      description: 'Cortes americanos de calidad Prime con maduración en seco y carta de vinos de autor.',
      capacity: 60
    },
    {
      id: 'rest-2',
      name: 'Amoramar',
      cuisine: 'Marina & Fusión Criolla',
      price_range: '$$$',
      rating: 4.7,
      review_count: 512,
      address: 'Jr. García y García 175, Barranco',
      district: 'Barranco',
      image_url: 'https://images.unsplash.com/photo-1537047902294-62a40c20a6ae?w=800&q=80',
      phone: '+51 987 654 322',
      description: 'Ceviches contemporáneos y pesca del día en una emblemática casona republicana de Barranco.',
      capacity: 75
    },
    {
      id: 'rest-3',
      name: 'Sapiens Cocina a las Brasas',
      cuisine: 'Cocina a la Leña & Autóctona',
      price_range: '$$$',
      rating: 4.9,
      review_count: 189,
      address: 'Av. Pardo y Aliaga 689, San Isidro',
      district: 'San Isidro',
      image_url: 'https://images.unsplash.com/photo-1517248135467-4c7edcad34c4?w=800&q=80',
      phone: '+51 987 654 323',
      description: 'Rescate de insumos andinos y amazónicos tratados enteramente sobre fuego de maderas seleccionadas.',
      capacity: 45
    },
    {
      id: 'rest-4',
      name: 'Troppo Cucina Italiana',
      cuisine: 'Italiana & Pizza Napolitana',
      price_range: '$$',
      rating: 4.6,
      review_count: 420,
      address: 'Calle Los Libertadores 199, San Isidro',
      district: 'San Isidro',
      image_url: 'https://images.unsplash.com/photo-1555396273-367ea4eb4db5?w=800&q=80',
      phone: '+51 987 654 324',
      description: 'Pastas hechas a mano diariamente y pizzas horneadas en horno de leña a 480°C.',
      capacity: 50
    }
  ];

  for (const r of restaurants) {
    run(`INSERT INTO restaurants (id, name, cuisine, price_range, rating, review_count, address, district, image_url, phone, description, capacity)
         VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [r.id, r.name, r.cuisine, r.price_range, r.rating, r.review_count, r.address, r.district, r.image_url, r.phone, r.description, r.capacity]);

    // Insert time slots
    const times = ['13:00', '13:30', '14:00', '14:30', '19:30', '20:00', '20:30', '21:00', '21:30'];
    for (let day = 0; day <= 6; day++) {
      for (const time of times) {
        const slotId = `slot-${r.id}-${day}-${time.replace(':', '')}`;
        run(`INSERT INTO time_slots (id, restaurant_id, slot_time, day_of_week, base_capacity, available_capacity, base_discount)
             VALUES (?, ?, ?, ?, 10, 10, 0.15)`,
          [slotId, r.id, time, day]);
      }
    }
  }

  console.log('✅ Seed completado con restaurantes, horarios y usuarios con contraseñas seguras.');
}

module.exports = { runSeed };
if (require.main === module) {
  const { initDatabase } = require('./database');
  initDatabase().then(() => runSeed());
}
