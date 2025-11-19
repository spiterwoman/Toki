const jwt = require("jsonwebtoken");
require("dotenv").config({ path: './priv.env' });


module.exports = function authMiddleware(req, res, next) {
  const token = req.cookies.accessToken;
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
