const users = []; // Placeholder for user storage (in-memory, replace with DB integration)
exports.getUserModel = async (query) => {
  return users.find(user => user.email === query.email);
};

exports.createUser = async (userData) => {
  users.push(userData);
  return userData;  // In-memory simulation, replace with database operation
};
