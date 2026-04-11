const http = require('http');
const fs = require('fs');
const os = require('os');

const i52520M = '/usr/local/bin/os/i52520M.sh';
const openclawVm = '/usr/local/bin/os/install-openclaw-vm-os.sh';

const server = http.createServer((req, res) => {
    if (req.url.startsWith('/os/greet')) {
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
    else if (req.url === '/os/openclaw-vm') {
        fs.readFile(openclawVm, 'utf8', (err, data) => {
            if (err) {
                res.writeHead(500);
                res.end('Error reading script: ' + err.message);
            } else {
                res.writeHead(200, {'Content-Type': 'text/plain'});
                res.end(data);
            }
        });
    }
    else {
        res.writeHead(404, { 'Content-Type': 'text/plain' });
        res.end('Not Found');
    }
});

server.listen(3001, () => {
    console.log('OS install api running on port 3001');
});
