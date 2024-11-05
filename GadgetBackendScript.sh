#!/bin/bash

# ------------------------------------------------------------
# Node.js Layered Architecture Setup Script with JWT, NodeMailer, 
# Docker, GitHub Actions CI/CD pipeline, and Multiple Git Branches
# ------------------------------------------------------------

# Function to check if required commands are installed
check_command() {
  command -v "$1" >/dev/null 2>&1 || { echo >&2 "Command '$1' is required but not installed. Exiting."; exit 1; }
}

# Ensure required commands are installed
check_command "git"
check_command "docker"
check_command "node"
check_command "npm"

# ------------------------------------------------------------
# Step 1: Collect User Inputs
# ------------------------------------------------------------

echo "Welcome to the Node.js Layered Architecture Setup!"
echo "This script will guide you through setting up a Node.js project with JWT authentication, NodeMailer, Docker, GitHub Actions, and multiple Git branches."

# Get project details
echo "Please enter your company name (for package details):"
read -r company_name

echo "Enter your GitHub username or organization name (e.g., my-org):"
read -r github_username

echo "Enter your GitHub repository name (e.g., my-repo):"
read -r github_repo

echo "Enter your DockerHub username (e.g., my-dockerhub-user):"
read -r dockerhub_username

echo "Enter your DockerHub repository name (e.g., my-repo):"
read -r dockerhub_repo

echo "Enter the Node.js version you wish to use (e.g., 16, 18, etc.):"
read -r node_version

echo "Enter your default port for the application (default: 3000):"
read -r app_port

# Default port if not provided
if [ -z "$app_port" ]; then
  app_port=3000
fi

# ------------------------------------------------------------
# Step 2: Create Project Folder Structure and Modules
# ------------------------------------------------------------

BASE_DIR=$(pwd)
SRC_DIR="$BASE_DIR/src"
WORKFLOWS_DIR="$BASE_DIR/.github/workflows"
DOCKER_DIR="$BASE_DIR/docker"
CONFIG_DIR="$BASE_DIR/src/config"
CONTROLLERS_DIR="$BASE_DIR/src/controllers"
MODELS_DIR="$BASE_DIR/src/models"
SERVICES_DIR="$BASE_DIR/src/services"
DTOS_DIR="$BASE_DIR/src/dtos"
UTILS_DIR="$BASE_DIR/src/utils"
MIDDLEWARES_DIR="$BASE_DIR/src/middlewares"
GLOBAL_EXCEPTIONS_DIR="$BASE_DIR/src/globalExceptions"
TESTS_DIR="$BASE_DIR/tests/user"

# Create base directories
echo "Creating the project folder structure..."
mkdir -p "$SRC_DIR"
mkdir -p "$WORKFLOWS_DIR"
mkdir -p "$DOCKER_DIR"
mkdir -p "$CONFIG_DIR"
mkdir -p "$CONTROLLERS_DIR"
mkdir -p "$MODELS_DIR"
mkdir -p "$SERVICES_DIR"
mkdir -p "$DTOS_DIR"
mkdir -p "$UTILS_DIR"
mkdir -p "$MIDDLEWARES_DIR"
mkdir -p "$GLOBAL_EXCEPTIONS_DIR"
mkdir -p "$TESTS_DIR"

# ------------------------------------------------------------
# Step 3: Create Boilerplate Code for JWT Authentication, Email, Global Error Handling
# ------------------------------------------------------------

echo "Creating boilerplate code for JWT, email notifications, and global error handling..."

# Controllers
cat <<EOF > "$CONTROLLERS_DIR/userController.js"
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
EOF

# Services (handling the business logic)
cat <<EOF > "$SERVICES_DIR/userService.js"
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
EOF

# Models (defines how user data is structured in the database)
cat <<EOF > "$MODELS_DIR/userModel.js"
const users = []; // Placeholder for user storage (in-memory, replace with DB integration)
exports.getUserModel = async (query) => {
  return users.find(user => user.email === query.email);
};

exports.createUser = async (userData) => {
  users.push(userData);
  return userData;  // In-memory simulation, replace with database operation
};
EOF

# DTOs (Data Transfer Objects for validation)
cat <<EOF > "$DTOS_DIR/userDTO.js"
const Joi = require('joi');

exports.validateRegistrationDTO = (data) => {
  const schema = Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().min(6).required(),
  });
  return schema.validate(data);
};

exports.validateLoginDTO = (data) => {
  const schema = Joi.object({
    email: Joi.string().email().required(),
    password: Joi.string().min(6).required(),
  });
  return schema.validate(data);
};
EOF

# Authentication Middleware (JWT)
cat <<EOF > "$MIDDLEWARES_DIR/authMiddleware.js"
const jwt = require('jsonwebtoken');
const config = require('../../config');

exports.authenticateJWT = (req, res, next) => {
  const token = req.headers['authorization']?.split(' ')[1];
  if (!token) return res.status(401).json({ success: false, message: 'Token required' });

  jwt.verify(token, config.JWT_SECRET, (err, user) => {
    if (err) return res.status(403).json({ success: false, message: 'Token is invalid' });
    req.user = user;
    next();
  });
};
EOF

# Global Error Handler
cat <<EOF > "$GLOBAL_EXCEPTIONS_DIR/errorHandler.js"
module.exports = (err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ success: false, message: err.message });
};
EOF

# Email Utility (using NodeMailer)
cat <<EOF > "$UTILS_DIR/email.js"
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
    html: \`<h1>Welcome to Our Service!</h1><p>Thank you for registering with us.</p>\`
  };

  return transporter.sendMail(mailOptions);
};
EOF

# ------------------------------------------------------------
# Step 4: Create Dockerfile, docker-compose.yml, and GitHub Actions Workflow
# ------------------------------------------------------------

echo "Creating Dockerfile..."

cat <<EOF > "$DOCKER_DIR/Dockerfile"
# Dockerfile for Node.js Application
FROM node:$node_version

WORKDIR /usr/src/app

COPY ./src/package*.json ./

RUN npm install

COPY ./src ./

EXPOSE $app_port

CMD ["node", "src/app.js"]
EOF

echo "Creating docker-compose.yml..."

cat <<EOF > "$DOCKER_DIR/docker-compose.yml"
version: '3'
services:
  app:
    build:
      context: .
      dockerfile: docker/Dockerfile
    ports:
      - "$app_port:$app_port"
    environment:
      - NODE_ENV=development
EOF

echo "Creating GitHub Actions CI/CD workflow..."

cat <<EOF > "$WORKFLOWS_DIR/workflow.yml"
name: Node.js CI/CD

on:
  push:
    branches:
      - dev  # Trigger workflow on push to dev branch

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v3
      - name: Set up Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '$node_version'
      - name: Install dependencies
        run: npm install
      - name: Run tests
        run: npm test
      - name: Build Docker Image
        run: docker-compose -f docker/docker-compose.yml up --build
      - name: Push Docker image to DockerHub
        run: docker push $dockerhub_username/$dockerhub_repo
EOF

# ------------------------------------------------------------
# Step 5: Create Configuration File (for secrets like JWT_SECRET, Email credentials)
# ------------------------------------------------------------

echo "Creating configuration file..."

cat <<EOF > "$CONFIG_DIR/index.js"
module.exports = {
  JWT_SECRET: 'your-secret-key',  // Replace with an actual secret key, or use environment variables
  EMAIL_USER: 'your-email@gmail.com',  // Replace with your email
  EMAIL_PASSWORD: 'your-email-password'  // Replace with your email password (or use app password)
};
EOF

# ------------------------------------------------------------
# Step 6: Initialize Git Repository, Create Branches, and Commit
# ------------------------------------------------------------

echo "Initializing Git repository..."

git init
git checkout -b dev
git commit -m "Initial commit with JWT authentication, NodeMailer, and global exception handling"
git checkout -b working
git checkout -b prod
git checkout -b main

# Set up the remote repository and push to GitHub
git remote add origin "https://github.com/$github_username/$github_repo.git"
git push -u origin dev
git push -u origin working
git push -u origin prod
git push -u origin main

echo "Git repository initialized, branches created, and pushed to GitHub."

# ------------------------------------------------------------
# Step 7: Final Instructions and Build Process
# ------------------------------------------------------------

echo "Project setup complete!"

# Provide final build instructions
echo "To build the Docker containers, run the following command:"
echo "  docker-compose -f docker/docker-compose.yml up --build"

echo "To run the GitHub Actions CI/CD pipeline, push your code to the dev branch."

# Provide instructions for future development
echo "You can now start developing your Node.js application!"
echo "JWT authentication is set up. Routes like '/users/login' and '/users/register' are available."
echo "To add more functionality, simply follow the same structure for controllers, services, and DTOs."

echo "Happy coding!"
