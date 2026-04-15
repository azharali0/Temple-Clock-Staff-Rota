const express = require('express');
const router = express.Router();
const {
  getClients,
  createClient,
  updateClient,
  deleteClient,
} = require('../controllers/clientController');
const { protect, authorize } = require('../middleware/auth');

router.route('/')
  .get(protect, getClients)
  .post(protect, authorize('admin'), createClient);

router.route('/:id')
  .put(protect, authorize('admin'), updateClient)
  .delete(protect, authorize('admin'), deleteClient);

module.exports = router;
