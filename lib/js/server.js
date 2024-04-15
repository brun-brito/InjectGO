// const express = require('express');
// const { exec } = require('child_process');
// const app = express();
// const port = 8080;

// app.get('/start-server', (req, res) => {
//   exec('dart run server.dart', (error, stdout, stderr) => {
//     if (error) {
//       console.error(`exec error: ${error}`);
//       return res.status(500).send('Failed to start the server');
//     }
//     res.send('Server started successfully');
//   });
// });

// app.listen(port, () => {
//   console.log(`Control server listening at http://localhost:${port}`);
// });
