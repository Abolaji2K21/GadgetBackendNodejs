const jwt = require('jsonwebtoken');
const bcrypt = require('bcrypt');
const { getUserModel, createUser } = require('../models/userModel');
const { validateRegistrationDTO, validateLoginDTO } = require('../dtos/userDTO');
const config = require('../../config');

exports.registerUser = async (userData) => {
  const validatedData = validateRegistrationDTO(userData);
  const existingUser = await getUserModel({ email: validatedData.email });
  if (existingUser) throw new Error('User already exists');

  const hashedPassword = await bcrypt.hash(validatedData.password, 10);
  const newUser = await createUser({ ...validatedData, password: hashedPassword });
  return newUser;
};

exports.loginUser = async (loginData) => {
  const validatedData = validateLoginDTO(loginData);
  const user = await getUserModel({ email: validatedData.email });
  if (!user) throw new Error('Invalid credentials');

  const isMatch = await bcrypt.compare(validatedData.password, user.password);
  if (!isMatch) throw new Error('Invalid credentials');

  const token = jwt.sign({ userId: user._id }, config.JWT_SECRET, { expiresIn: '1h' });
  return token;
};
