const http = require('http');                                                                                        
const fs = require('fs');                                                                                            
const path = require('path');                                                                                        
const os = require('os');                                                                                            
                                                                                                                     
// Get the home directory of the current user                                                                        
const homeDir = os.homedir();                                                                                        
                                                                                                                     
// Paths to the files you want to serve                                                                              
const i52520M = '/usr/local/bin/os/i52520M.sh';

// Create a server object
const server = http.createServer((req, res) => {
    if (req.url.startsWith('/os/greet')) { // Handle the /os/greet endpoint
        const url = new URL(req.url, `http://${req.headers.host}`);
        const name = url.searchParams.get('name') || 'stranger';
        res.writeHead(200, { 'Content-Type': 'application/json' });
        res.end(JSON.stringify({ message: `Hello, ${name}!` }));
    }
    else if (req.url === '/os/i52520M') {
        fs.readFile(i52520M, 'utf8', (err, data) => {
            if (err) {                                                                                                        
              console.error(`Error reading the script file at ${i52520M}:`, err);                              
              res.writeHead(500, { 'Content-Type': 'text/plain' });                                                         
              res.end('Error reading the script file.');                                                                    
            } else {                                                                                                          
                res.writeHead(200, { 'Content-Type': 'text/plain' });                                                         
                res.end(data);                                                                                                
            }
        });
    }
    else { // Handle unknown endpoints
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('Not Found');
    }
});

// Listen on port 3001
server.listen(3001, () => {
    console.log('OS install api running on port 3001');
});
