const jwt = require('jsonwebtoken');
const config = require('../../src/config');

exports.authenticateJWT = (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.status(401).json({ success: false, message: 'Token required' });

  jwt.verify(token, config.JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ success: false, message: 'Token is invalid' });
    req.user = user;
    next();
  });
};
