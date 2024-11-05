const nodemailer = require('nodemailer');
const config = require('../config');

const transporter = nodemailer.createTransport({
  service: 'gmail',
  auth: {
    user: config.EMAIL_USER,
    pass: config.EMAIL_PASSWORD
  }
});

exports.sendWelcomeEmail = (email) => {
  const mailOptions = {
    from: config.EMAIL_USER,
    to: email,
    subject: 'Welcome to Our Service',
    html: `<h1>Welcome to Our Service!</h1><p>Thank you for registering with us.</p>`
  };

  return transporter.sendMail(mailOptions);
};
