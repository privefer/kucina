CREATE TABLE IF NOT EXISTS users (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  phone TEXT NOT NULL,
  password_hash TEXT NOT NULL,
  role TEXT DEFAULT 'diner',
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS restaurants (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  cuisine TEXT NOT NULL,
  price_range TEXT NOT NULL,
  rating REAL DEFAULT 4.5,
  review_count INTEGER DEFAULT 0,
  address TEXT NOT NULL,
  district TEXT NOT NULL,
  image_url TEXT,
  phone TEXT,
  description TEXT,
  capacity INTEGER DEFAULT 50,
  is_active INTEGER DEFAULT 1,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE IF NOT EXISTS time_slots (
  id TEXT PRIMARY KEY,
  restaurant_id TEXT NOT NULL,
  slot_time TEXT NOT NULL,
  day_of_week INTEGER NOT NULL,
  base_capacity INTEGER DEFAULT 10,
  available_capacity INTEGER DEFAULT 10,
  base_discount REAL DEFAULT 0.0,
  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id)
);

CREATE TABLE IF NOT EXISTS bookings (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  restaurant_id TEXT NOT NULL,
  guest_name TEXT NOT NULL,
  guest_phone TEXT NOT NULL,
  booking_date TEXT NOT NULL,
  booking_time TEXT NOT NULL,
  party_size INTEGER NOT NULL,
  applied_discount REAL DEFAULT 0.0,
  deposit_amount REAL DEFAULT 0.0,
  deposit_status TEXT DEFAULT 'unpaid',
  status TEXT DEFAULT 'confirmed',
  special_requests TEXT,
  qr_code TEXT,
  created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id),
  FOREIGN KEY (restaurant_id) REFERENCES restaurants(id)
);
