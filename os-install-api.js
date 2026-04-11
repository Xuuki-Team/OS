const http = require('http');
const fs = require('fs');
<<<<<<< HEAD
const path = require('path');
const os = require('os');

// Get the home directory of the current user
const homeDir = os.homedir();

// Paths to the files you want to serve
const i52520M = '/usr/local/bin/os/i52520M.sh';
=======
const os = require('os');

const i52520M = '/usr/local/bin/os/i52520M.sh';
const openclawVm = '/usr/local/bin/os/install-openclaw-vm-os.sh';
>>>>>>> origin/master

const server = http.createServer((req, res) => {
    if (req.url === '/os/i52520M') {
        fs.readFile(i52520M, 'utf8', (err, data) => {
<<<<<<< HEAD
            if (err) {                                                                                                        
              console.error(`Error reading the script file at ${i52520M}:`, err);                              
              res.writeHead(500, { 'Content-Type': 'text/plain' });                                                         
              res.end('Error reading the script file.');                                                                   
            } else {                                                                                                          
                res.writeHead(200, { 'Content-Type': 'text/plain' });                                                         
                res.end(data);                                                                                                
=======
            if (err) {
                res.writeHead(500);
                res.end('Error reading script: ' + err.message);
            } else {
                res.writeHead(200, {'Content-Type': 'text/plain'});
                res.end(data);
>>>>>>> origin/master
            }
        });
    } else if (req.url === '/os/openclaw-vm') {
        fs.readFile(openclawVm, 'utf8', (err, data) => {
            if (err) {
                res.writeHead(500);
                res.end('Error reading script: ' + err.message);
            } else {
                res.writeHead(200, {'Content-Type': 'text/plain'});
                res.end(data);
            }
        });
    } else {
        res.writeHead(404);
        res.end('Not Found');
    }
});

server.listen(3001, () => {
    console.log('OS Install API running on port 3001');
});
