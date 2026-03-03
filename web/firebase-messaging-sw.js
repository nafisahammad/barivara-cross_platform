/* eslint-disable no-undef */
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-app-compat.js');
importScripts('https://www.gstatic.com/firebasejs/10.12.2/firebase-messaging-compat.js');

firebase.initializeApp({
  apiKey: 'AIzaSyBP-rSHE75dLKZuu9UzrraCbx_z4ET5t00',
  authDomain: 'barivara-3ad3a.firebaseapp.com',
  databaseURL: 'https://barivara-3ad3a-default-rtdb.firebaseio.com',
  projectId: 'barivara-3ad3a',
  storageBucket: 'barivara-3ad3a.firebasestorage.app',
  messagingSenderId: '851678276356',
  appId: '1:851678276356:web:993a3450917da3e5207e51',
  measurementId: 'G-3623L7LFET'
});

firebase.messaging();
