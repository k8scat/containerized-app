const axios = require("axios");

const request = axios.create({
  baseURL: process.env.REACT_APP_BASE_URL || 'http://127.0.0.1:4182/api',
  timeout: 3000,
});

export default request;
