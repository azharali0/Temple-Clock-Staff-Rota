const Client = require('../models/Client');

// @desc    Get all clients
// @route   GET /api/clients
// @access  Private
const getClients = async (req, res) => {
  try {
    const clients = await Client.find({ isActive: true }).sort('-createdAt');
    res.json(clients);
  } catch (error) {
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Create a client property
// @route   POST /api/clients
// @access  Private/Admin
const createClient = async (req, res) => {
  try {
    const { name, address, coordinates } = req.body;
    if (!name || !address || !coordinates || !coordinates.lat || !coordinates.lng) {
      return res.status(400).json({ message: 'Please provide all fields and valid coordinates' });
    }

    const client = await Client.create({
      name,
      address,
      coordinates,
      createdBy: req.user._id,
    });
    res.status(201).json(client);
  } catch (error) {
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Update a client property
// @route   PUT /api/clients/:id
// @access  Private/Admin
const updateClient = async (req, res) => {
  try {
    const client = await Client.findById(req.params.id);
    if (!client) {
      return res.status(404).json({ message: 'Client not found' });
    }

    const { name, address, coordinates, isActive } = req.body;
    if (name) client.name = name;
    if (address) client.address = address;
    if (coordinates) client.coordinates = coordinates;
    if (isActive !== undefined) client.isActive = isActive;

    await client.save();
    res.json(client);
  } catch (error) {
    res.status(500).json({ message: 'Server Error' });
  }
};

// @desc    Delete a client property
// @route   DELETE /api/clients/:id
// @access  Private/Admin
const deleteClient = async (req, res) => {
  try {
    const client = await Client.findById(req.params.id);
    if (!client) {
      return res.status(404).json({ message: 'Client not found' });
    }
    
    client.isActive = false;
    await client.save();
    res.json({ message: 'Client deactivated successfully' });
  } catch (error) {
    res.status(500).json({ message: 'Server Error' });
  }
};

module.exports = {
  getClients,
  createClient,
  updateClient,
  deleteClient,
};
