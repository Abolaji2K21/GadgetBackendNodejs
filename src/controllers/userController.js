const { registerUser, loginUser } = require('../services/userService');
const { sendWelcomeEmail } = require('../utils/email');

exports.register = async (req, res, next) => {
  try {
    const user = await registerUser(req.body);
    await sendWelcomeEmail(user.email);
    res.status(201).json({ success: true, message: 'Registration successful', data: user });
  } catch (error) {
    next(error);
  }
};

exports.login = async (req, res, next) => {
  try {
    const token = await loginUser(req.body);
    res.status(200).json({ success: true, token });
  } catch (error) {
    next(error);
  }
};
