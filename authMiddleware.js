const jwt = require("jsonwebtoken");
require("dotenv").config({ path: './priv.env' });


module.exports = function authMiddleware(req, res, next) {
  let token = req.cookies.accessToken;

    // fallback to Authorization header for postman testing
  if (!token && req.headers.authorization) {
    const parts = req.headers.authorization.split(' ');
    if (parts.length === 2 && parts[0] === 'Bearer') {
      token = parts[1];
    }
  }
  if (!token) return res.status(401).json({ error: "Not authenticated" });

  try {
    const decoded = jwt.verify(token, process.env.ACCESS_TOKEN_SECRET);

    req.userId = decoded.userId;
    req.firstName = decoded.firstName;
    req.lastName = decoded.lastName;

    next();
  } catch (err) {
    return res.status(401).json({ error: "Invalid token" });
  }
};
