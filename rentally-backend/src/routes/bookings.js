const express = require('express');
const { auth, authorize } = require('../middleware/auth');

const router = express.Router();

// Placeholder routes - will be implemented later
router.get('/', auth, (req, res) => {
  res.json({ message: 'Bookings routes - Coming soon!' });
});

module.exports = router;
