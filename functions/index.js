const { randomBytes, randomInt, scryptSync, timingSafeEqual, createHash } = require('node:crypto');
const { initializeApp } = require('firebase-admin/app');
const { getAuth } = require('firebase-admin/auth');
const { FieldValue, Timestamp, getFirestore } = require('firebase-admin/firestore');
const { HttpsError, onCall } = require('firebase-functions/v2/https');

initializeApp();

const REGION = 'asia-southeast2';
const db = getFirestore();
const auth = getAuth();
const callable = (handler) => onCall({ region: REGION }, handler);

function requirePin(pin) {
  if (typeof pin !== 'string' || !/^\d{6}$/.test(pin)) {
    throw new HttpsError('invalid-argument', 'PIN harus terdiri dari 6 angka.');
  }
}

function hashPin(pin, salt = randomBytes(16)) {
  return {
    salt: salt.toString('base64'),
    hash: scryptSync(pin, salt, 64).toString('base64'),
  };
}

function pinMatches(pin, stored) {
  if (!stored?.salt || !stored?.hash) return false;
  const expected = Buffer.from(stored.hash, 'base64');
  const actual = scryptSync(pin, Buffer.from(stored.salt, 'base64'), expected.length);
  return expected.length === actual.length && timingSafeEqual(expected, actual);
}

function legacyPinMatches(pin, stored) {
  if (typeof stored !== 'string') return false;
  const candidate = createHash('sha256').update(pin).digest('hex');
  const left = Buffer.from(candidate);
  const right = Buffer.from(stored);
  return left.length === right.length && timingSafeEqual(left, right);
}

function normalizeIdentifier(value) {
  if (typeof value !== 'string' || !value.trim()) {
    throw new HttpsError('invalid-argument', 'Email atau nomor HP wajib diisi.');
  }
  const input = value.trim().toLowerCase();
  if (input.includes('@')) return { field: 'email', value: input };
  let phone = input.replace(/[\s\-().]/g, '');
  if (phone.startsWith('+62')) phone = `0${phone.slice(3)}`;
  else if (phone.startsWith('62')) phone = `0${phone.slice(2)}`;
  return { field: 'phone', value: phone };
}

function userRef(uid) {
  return db.collection('users').doc(uid);
}

function secretRef(uid) {
  return db.collection('userSecrets').doc(uid);
}

function rateRef(identifier) {
  const key = createHash('sha256').update(identifier).digest('hex');
  return db.collection('authRateLimits').doc(key);
}

async function assertNotLocked(identifier) {
  const snap = await rateRef(identifier).get();
  const until = snap.data()?.lockedUntil?.toMillis?.() ?? 0;
  if (until > Date.now()) {
    throw new HttpsError('resource-exhausted', 'Terlalu banyak percobaan. Coba lagi nanti.');
  }
}

async function recordPinFailure(identifier) {
  const ref = rateRef(identifier);
  await db.runTransaction(async (transaction) => {
    const snap = await transaction.get(ref);
    const data = snap.data() ?? {};
    const count = (data.failures ?? 0) + 1;
    transaction.set(ref, {
      failures: count,
      lockedUntil: count >= 5 ? Timestamp.fromMillis(Date.now() + 15 * 60 * 1000) : null,
      updatedAt: FieldValue.serverTimestamp(),
    });
  });
}

async function clearPinFailures(identifier) {
  await rateRef(identifier).delete();
}

async function assertValidAccountPin(uid, pin) {
  const key = `uid:${uid}`;
  await assertNotLocked(key);
  const secret = await secretRef(uid).get();
  if (!secret.exists || !pinMatches(pin, secret.data())) {
    await recordPinFailure(key);
    throw new HttpsError('unauthenticated', 'PIN salah.');
  }
  await clearPinFailures(key);
}

async function findProfile(identifier) {
  const normalized = normalizeIdentifier(identifier);
  const result = await db.collection('users')
    .where(normalized.field, '==', normalized.value)
    .limit(5)
    .get();
  if (result.empty) return null;
  const docs = [...result.docs].sort((a, b) => {
    const aMigrated = a.data().authUid === a.id ? 1 : 0;
    const bMigrated = b.data().authUid === b.id ? 1 : 0;
    return bMigrated - aMigrated;
  });
  return { doc: docs[0], normalized };
}

async function ensureAuthUser(email, name) {
  try {
    return await auth.getUserByEmail(email);
  } catch (error) {
    if (error.code !== 'auth/user-not-found') throw error;
  }
  return auth.createUser({ email, displayName: name || undefined });
}

async function generateBusinessIds() {
  for (let attempt = 0; attempt < 20; attempt += 1) {
    const businessId = `DGB${randomInt(1000000, 10000000)}`;
    const oldPath = await userRef(businessId).get();
    const sameBusinessId = await db.collection('users').where('businessId', '==', businessId).limit(1).get();
    if (!oldPath.exists && sameBusinessId.empty) {
      let rekening = '';
      for (let i = 0; i < 20; i += 1) {
        const candidate = String(randomInt(1000000000, 1900000000));
        const existing = await db.collection('users').where('rekening', '==', candidate).limit(1).get();
        if (existing.empty) {
          rekening = candidate;
          break;
        }
      }
      if (rekening) return { businessId, rekening };
    }
  }
  throw new HttpsError('resource-exhausted', 'Gagal membuat nomor akun. Coba lagi.');
}

async function copyLegacySubcollections(sourceId, uid) {
  if (sourceId === uid) return;
  for (const name of ['mutasi', 'notifications', 'referensi']) {
    const source = db.collection('users').doc(sourceId).collection(name);
    const destination = userRef(uid).collection(name);
    const snapshot = await source.limit(400).get();
    if (snapshot.empty) continue;
    const batch = db.batch();
    for (const doc of snapshot.docs) batch.set(destination.doc(doc.id), doc.data(), { merge: true });
    await batch.commit();
  }
}

async function migrateLegacyProfile(profileDoc, authUser, pin) {
  const source = profileDoc.data();
  const uid = authUser.uid;
  const target = userRef(uid);
  const current = await target.get();
  if (!current.exists || current.id === profileDoc.id) {
    const businessId = source.businessId || source.dgbId || source.id || profileDoc.id;
    const legacyPin = source.pin;
    const { pin: _pin, password: _password, resetCode: _resetCode, resetExpired: _resetExpired, ...profile } = source;
    const secret = hashPin(pin);
    await target.set({
      ...profile,
      id: uid,
      authUid: uid,
      businessId,
      rekening: source.rekening || (await generateBusinessIds()).rekening,
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    await secretRef(uid).set({
      ...secret,
      failedAttempts: 0,
      legacyPasswordHash: typeof _password === 'string' ? _password : null,
      migratedPin: Boolean(legacyPin),
      updatedAt: FieldValue.serverTimestamp(),
    }, { merge: true });
    await copyLegacySubcollections(profileDoc.id, uid);
  }
  return uid;
}

exports.registerWithPin = callable(async (request) => {
  const d = request.data ?? {};
  requirePin(d.pin);
  const email = String(d.email ?? '').trim().toLowerCase();
  const phone = normalizeIdentifier(String(d.phone ?? '')).value;
  const name = `${String(d.namaDepan ?? '').trim()} ${String(d.namaBelakang ?? '').trim()}`.trim();
  if (!email.includes('@') || !name || !/^08\d{8,11}$/.test(phone)) {
    throw new HttpsError('invalid-argument', 'Data profil tidak lengkap atau tidak valid.');
  }
  const existingEmail = await db.collection('users').where('email', '==', email).limit(1).get();
  const existingPhone = await db.collection('users').where('phone', '==', phone).limit(1).get();
  if (!existingEmail.empty) throw new HttpsError('already-exists', 'Email sudah terdaftar.');
  if (!existingPhone.empty) throw new HttpsError('already-exists', 'Nomor HP sudah terdaftar.');

  const ids = await generateBusinessIds();
  const account = await auth.createUser({ email, displayName: name });
  try {
    const uid = account.uid;
    await userRef(uid).create({
      id: uid,
      authUid: uid,
      businessId: ids.businessId,
      namaDepan: String(d.namaDepan).trim(),
      namaBelakang: String(d.namaBelakang).trim(),
      nama: name,
      email,
      phone,
      tanggalLahir: Timestamp.fromMillis(Number(d.tanggalLahirMillis)),
      gender: String(d.gender),
      alamat: String(d.alamat ?? '').trim(),
      kewarganegaraan: String(d.kewarganegaraan ?? '').trim(),
      rekening: ids.rekening,
      saldo: 0,
      tipeRekening: 'Savings',
      cabang: 'KCU Jakarta',
      memberSince: new Intl.DateTimeFormat('id-ID', { month: 'long', year: 'numeric' }).format(new Date()),
      accountStatus: 'active',
      isVerified: false,
      otpDemoCompleted: true,
      registrationCompleted: true,
      settings: {},
      createdAt: FieldValue.serverTimestamp(),
      updatedAt: FieldValue.serverTimestamp(),
    });
    await secretRef(uid).create({ ...hashPin(d.pin), failedAttempts: 0, updatedAt: FieldValue.serverTimestamp() });
    return { customToken: await auth.createCustomToken(uid), uid };
  } catch (error) {
    await auth.deleteUser(account.uid).catch(() => {});
    throw error;
  }
});

exports.loginWithPin = callable(async (request) => {
  const identifier = String(request.data?.identifier ?? '').trim();
  const pin = request.data?.pin;
  requirePin(pin);
  const normalized = normalizeIdentifier(identifier);
  const rateKey = `${normalized.field}:${normalized.value}`;
  await assertNotLocked(rateKey);
  const found = await findProfile(identifier);
  if (!found) {
    await recordPinFailure(rateKey);
    throw new HttpsError('unauthenticated', 'Akun atau PIN salah.');
  }

  const doc = found.doc;
  const data = doc.data();
  let uid = data.authUid || doc.id;
  let secret = await secretRef(uid).get();
  let valid = secret.exists && pinMatches(pin, secret.data());
  if (!valid && typeof data.pin === 'string') valid = legacyPinMatches(pin, data.pin);
  if (!valid) {
    await recordPinFailure(rateKey);
    throw new HttpsError('unauthenticated', 'Akun atau PIN salah.');
  }

  const email = String(data.email ?? '').trim().toLowerCase();
  if (!email) throw new HttpsError('failed-precondition', 'Akun lama tidak memiliki email.');
  const authUser = await ensureAuthUser(email, data.nama);
  uid = authUser.uid;
  if (doc.id !== uid || data.authUid !== uid || !secret.exists) {
    uid = await migrateLegacyProfile(doc, authUser, pin);
  }
  await clearPinFailures(rateKey);
  return { customToken: await auth.createCustomToken(uid), uid };
});

exports.verifyPin = callable(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Silakan login kembali.');
  requirePin(request.data?.pin);
  await assertValidAccountPin(request.auth.uid, request.data.pin);
  return { valid: true };
});

exports.hasPin = callable(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Silakan login kembali.');
  const snap = await secretRef(request.auth.uid).get();
  return { hasPin: snap.exists && Boolean(snap.data()?.hash) };
});

exports.deletePin = callable(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Silakan login kembali.');
  await secretRef(request.auth.uid).delete();
  return { success: true };
});

exports.checkPinResetCode = callable(async (request) => {
  const uid = String(request.data?.uid ?? '');
  const code = String(request.data?.code ?? '');
  const data = (await db.collection('pinResets').doc(uid).get()).data();
  const hash = createHash('sha256').update(code).digest('hex');
  return { valid: Boolean(data && data.expiresAt.toMillis() >= Date.now() && data.codeHash === hash) };
});

exports.updateProfile = callable(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Silakan login kembali.');
  const allowed = ['nama', 'email', 'phone', 'alamat', 'foto', 'tglLahir', 'tanggalLahir', 'kewarganegaraan', 'gender'];
  const input = request.data?.profile;
  if (!input || typeof input !== 'object' || Array.isArray(input)) throw new HttpsError('invalid-argument', 'Profil tidak valid.');
  const updates = Object.fromEntries(Object.entries(input).filter(([key]) => allowed.includes(key)));
  if (!Object.keys(updates).length) throw new HttpsError('invalid-argument', 'Tidak ada data profil yang dapat diperbarui.');
  if (updates.email) {
    const email = String(updates.email).trim().toLowerCase();
    const current = await auth.getUser(request.auth.uid);
    if (email !== current.email) {
      try { await auth.getUserByEmail(email); throw new HttpsError('already-exists', 'Email sudah digunakan.'); }
      catch (e) { if (e.code !== 'auth/user-not-found') throw e; }
      await auth.updateUser(request.auth.uid, { email });
    }
    updates.email = email;
  }
  updates.updatedAt = FieldValue.serverTimestamp();
  await userRef(request.auth.uid).update(updates);
  return { success: true };
});

exports.changeAccountEmail = callable(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Silakan login kembali.');
  const email = String(request.data?.email ?? '').trim().toLowerCase();
  if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email)) throw new HttpsError('invalid-argument', 'Email tidak valid.');
  try { await auth.getUserByEmail(email); throw new HttpsError('already-exists', 'Email sudah digunakan.'); }
  catch (e) { if (e.code !== 'auth/user-not-found') throw e; }
  await auth.updateUser(request.auth.uid, { email });
  await userRef(request.auth.uid).update({ email, updatedAt: FieldValue.serverTimestamp() });
  return { success: true };
});

exports.changeAccountPassword = callable(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Silakan login kembali.');
  const oldPassword = String(request.data?.oldPassword ?? '');
  const newPassword = String(request.data?.newPassword ?? '');
  if (newPassword.length < 8) throw new HttpsError('invalid-argument', 'Password minimal 8 karakter.');
  const ref = secretRef(request.auth.uid);
  const snap = await ref.get();
  const secret = snap.data() ?? {};
  const oldHash = secret.legacyPasswordHash;
  if (oldHash && oldHash !== createHash('sha256').update(`${request.auth.uid}:${oldPassword}`).digest('hex')) {
    throw new HttpsError('unauthenticated', 'Password lama salah.');
  }
  await auth.updateUser(request.auth.uid, { password: newPassword });
  await ref.set({ legacyPasswordHash: createHash('sha256').update(`${request.auth.uid}:${newPassword}`).digest('hex') }, { merge: true });
  return { success: true };
});

exports.seedDemoMutasi = callable(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Silakan login kembali.');
  const uid = request.auth.uid;
  const now = new Date();
  const rows = [
    ['kredit', 'Budi Santoso', 'Pembayaran proyek', 1500000, 0, 9, 'Berhasil'],
    ['debit', 'Siti Aminah', 'Bayar kos bulan November', 800000, 1, 14, 'Berhasil'],
    ['debit', 'Warung Makan Sederhana', 'Makan siang', 45000, 2, 12, 'Berhasil'],
    ['kredit', 'PT Maju Jaya', 'Gaji November', 5000000, 4, 8, 'Berhasil'],
    ['debit', 'PLN Prabayar', 'Token listrik', 200000, 6, 19, 'Berhasil'],
    ['debit', 'Toko Online ABC', 'Belanja online', 350000, 9, 21, 'Pending'],
    ['kredit', 'Andi Wijaya', 'Patungan makan', 120000, 12, 20, 'Berhasil'],
    ['debit', 'Pulsa Telkomsel', 'Isi pulsa', 100000, 15, 10, 'Gagal'],
    ['debit', 'Rina Marlina', 'Transfer pinjaman', 500000, 20, 16, 'Berhasil'],
    ['kredit', 'Cashback BCA', 'Cashback transaksi', 25000, 25, 11, 'Berhasil'],
  ];
  const batch = db.batch();
  rows.forEach((r, i) => {
    const day = new Date(now);
    day.setDate(day.getDate() - r[4]); day.setHours(r[5], (i * 7) % 60, 0, 0);
    const ref = userRef(uid).collection('mutasi').doc();
    batch.set(ref, { idTransaksi: `TRX${Date.now()}${i}`, tanggal: Timestamp.fromDate(day), tipe: r[0], nama: r[1], berita: r[2], nominal: r[3], status: r[6] });
  });
  await batch.commit();
  return { success: true };
});

exports.changePin = callable(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Silakan login kembali.');
  const { oldPin, newPin } = request.data ?? {};
  requirePin(oldPin);
  requirePin(newPin);
  await assertValidAccountPin(request.auth.uid, oldPin);
  const ref = secretRef(request.auth.uid);
  await ref.set({ ...hashPin(newPin), updatedAt: FieldValue.serverTimestamp() }, { merge: true });
  return { success: true };
});

exports.lookupAccountByRekening = callable(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Silakan login kembali.');
  const rekening = String(request.data?.rekening ?? '').trim();
  const result = await db.collection('users').where('rekening', '==', rekening).limit(1).get();
  if (result.empty) return null;
  const doc = result.docs[0];
  const d = doc.data();
  return { id: doc.id, businessId: d.businessId ?? d.id ?? doc.id, nama: d.nama ?? '-', rekening: d.rekening ?? '-' };
});

exports.transferMoney = callable(async (request) => {
  if (!request.auth) throw new HttpsError('unauthenticated', 'Silakan login kembali.');
  const authTime = Number(request.auth.token.auth_time ?? 0);
  if (!authTime || Date.now() / 1000 - authTime > 5 * 60) {
    throw new HttpsError('failed-precondition', 'Masukkan PIN kembali sebelum transfer.');
  }
  const fromId = request.auth.uid;
  const toId = String(request.data?.toId ?? '');
  const amount = Number(request.data?.amount);
  const berita = String(request.data?.berita ?? '').slice(0, 100);
  const jenis = String(request.data?.jenis ?? 'Transfer').slice(0, 40);
  if (!Number.isSafeInteger(amount) || amount <= 0) throw new HttpsError('invalid-argument', 'Nominal tidak valid.');
  if (!toId || toId === fromId) throw new HttpsError('invalid-argument', 'Rekening tujuan tidak valid.');

  const fromRef = userRef(fromId);
  const toRef = userRef(toId);
  const idRef = db.collection('transactionIds').doc();
  const trxId = `TRX${idRef.id}`;
  const fromMutation = fromRef.collection('mutasi').doc(trxId);
  const toMutation = toRef.collection('mutasi').doc(trxId);
  const fromNotification = fromRef.collection('notifications').doc();
  const toNotification = toRef.collection('notifications').doc();
  const result = await db.runTransaction(async (transaction) => {
    const [fromSnap, toSnap] = await Promise.all([transaction.get(fromRef), transaction.get(toRef)]);
    if (!fromSnap.exists || !toSnap.exists) throw new HttpsError('not-found', 'Rekening tidak ditemukan.');
    const from = fromSnap.data();
    const to = toSnap.data();
    const fromBalance = Number(from.saldo ?? 0);
    const toBalance = Number(to.saldo ?? 0);
    if (!Number.isSafeInteger(fromBalance) || !Number.isSafeInteger(toBalance)) {
      throw new HttpsError('failed-precondition', 'Saldo akun tidak valid.');
    }
    if (fromBalance < amount) throw new HttpsError('failed-precondition', 'Saldo tidak cukup.');
    const timestamp = FieldValue.serverTimestamp();
    transaction.update(fromRef, { saldo: fromBalance - amount, updatedAt: timestamp });
    transaction.update(toRef, { saldo: toBalance + amount, updatedAt: timestamp });
    transaction.set(fromMutation, {
      idTransaksi: trxId, tanggal: timestamp, tipe: 'debit', nominal: amount,
      nama: to.nama ?? '-', berita, status: 'Berhasil', jenis,
      rekeningLawan: to.rekening ?? '-',
    });
    transaction.set(toMutation, {
      idTransaksi: trxId, tanggal: timestamp, tipe: 'kredit', nominal: amount,
      nama: from.nama ?? '-', berita, status: 'Berhasil', jenis,
      rekeningLawan: from.rekening ?? '-',
    });
    transaction.set(fromNotification, {
      title: `${jenis} Berhasil`, message: `${jenis} Rp${amount} ke ${to.nama ?? 'penerima'} berhasil.`,
      type: 'transaksi', isRead: false, tanggal: timestamp,
    });
    transaction.set(toNotification, {
      title: 'Dana Diterima', message: `Anda menerima Rp${amount} dari ${from.nama ?? 'pengirim'}.`,
      type: 'transaksi', isRead: false, tanggal: timestamp,
    });
    return { id: trxId, tanggal: Date.now(), nominal: amount, nama: to.nama ?? '-', rekeningLawan: to.rekening ?? '-', berita, jenis };
  });
  return result;
});

exports.startPinReset = callable(async (request) => {
  const identifier = String(request.data?.identifier ?? '').trim();
  const found = await findProfile(identifier);
  if (!found) throw new HttpsError('not-found', 'Email atau nomor HP tidak terdaftar.');
  const data = found.doc.data();
  const uid = data.authUid || found.doc.id;
  const demoCode = String(randomInt(100000, 1000000));
  await db.collection('pinResets').doc(uid).set({
    codeHash: createHash('sha256').update(demoCode).digest('hex'),
    expiresAt: Timestamp.fromMillis(Date.now() + 5 * 60 * 1000),
  });
  return { uid, email: data.email ?? '', phone: data.phone ?? '', demoCode };
});

exports.completePinReset = callable(async (request) => {
  const uid = String(request.data?.uid ?? '');
  const code = String(request.data?.code ?? '');
  const pin = request.data?.pin;
  requirePin(pin);
  const ref = db.collection('pinResets').doc(uid);
  const snap = await ref.get();
  const data = snap.data();
  const hash = createHash('sha256').update(code).digest('hex');
  if (!data || data.expiresAt.toMillis() < Date.now() || data.codeHash !== hash) {
    throw new HttpsError('unauthenticated', 'Kode salah atau sudah kedaluwarsa.');
  }
  await secretRef(uid).set({ ...hashPin(pin), failedAttempts: 0, updatedAt: FieldValue.serverTimestamp() }, { merge: true });
  const profile = await userRef(uid).get();
  if (profile.exists) {
    const profileData = profile.data();
    if (profileData.authUid !== uid) {
      const account = await ensureAuthUser(String(profileData.email ?? '').trim().toLowerCase(), profileData.nama);
      await migrateLegacyProfile(profile, account, pin);
    }
  }
  await ref.delete();
  return { success: true };
});
