const express = require('express');
const { auth, authorize } = require('../middleware/auth');

const router = express.Router();

// Placeholder routes - will be implemented later
router.get('/', (req, res) => {
  res.json({ message: 'Properties routes - Coming soon!' });
});

module.exports = router;
