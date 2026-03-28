const QRCode = require('qrcode');

// @desc    Generate QR code for shift clock-in
// @route   GET /api/qr/shift/:shiftId
// @access  Private (admin or assigned staff)
const generateShiftQR = async (req, res) => {
  try {
    const { shiftId } = req.params;
    const baseUrl = process.env.FRONTEND_URL || 'http://localhost:8080';

    // QR payload — contains the shift ID and clock-in URL
    const qrData = JSON.stringify({
      type: 'careshift-clock-in',
      shiftId,
      url: `${baseUrl}/clock-in/${shiftId}`,
      generatedAt: new Date().toISOString(),
    });

    // Generate PNG buffer
    const buffer = await QRCode.toBuffer(qrData, {
      type: 'png',
      width: 300,
      margin: 2,
      color: {
        dark: '#1B2A4A',  // Navy
        light: '#FFFFFF',
      },
      errorCorrectionLevel: 'M',
    });

    res.setHeader('Content-Type', 'image/png');
    res.setHeader(
      'Content-Disposition',
      `inline; filename="shift-${shiftId}-qr.png"`
    );
    res.send(buffer);
  } catch (error) {
    console.error('GenerateQR error:', error.message);
    res.status(500).json({ message: 'Failed to generate QR code' });
  }
};

// @desc    Generate QR code as base64 data URL
// @route   GET /api/qr/shift/:shiftId/base64
// @access  Private
const generateShiftQRBase64 = async (req, res) => {
  try {
    const { shiftId } = req.params;
    const baseUrl = process.env.FRONTEND_URL || 'http://localhost:8080';

    const qrData = JSON.stringify({
      type: 'careshift-clock-in',
      shiftId,
      url: `${baseUrl}/clock-in/${shiftId}`,
    });

    const dataUrl = await QRCode.toDataURL(qrData, {
      width: 300,
      margin: 2,
      color: { dark: '#1B2A4A', light: '#FFFFFF' },
    });

    res.json({ shiftId, qrCode: dataUrl });
  } catch (error) {
    console.error('GenerateQRBase64 error:', error.message);
    res.status(500).json({ message: 'Failed to generate QR code' });
  }
};

module.exports = { generateShiftQR, generateShiftQRBase64 };
