const http = require('http');
const fs = require('fs');
const os = require('os');

const homeDir = os.homedir();
const i52520M = '/usr/local/bin/os/i52520M.sh';
const openclawVm = homeDir + '/Projects/OS/scripts/install-openclaw-vm-os.sh';

const server = http.createServer((req, res) => {
    if (req.url === '/os/i52520M') {
        fs.readFile(i52520M, 'utf8', (err, data) => {
            if (err) {
                res.writeHead(500);
                res.end('Error reading script');
            } else {
                res.writeHead(200, {'Content-Type': 'text/plain'});
                res.end(data);
            }
        });
    } else if (req.url === '/os/openclaw-vm') {
        fs.readFile(openclawVm, 'utf8', (err, data) => {
            if (err) {
                res.writeHead(500);
                res.end('Error reading script: ' + err);
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
    console.log('  /os/i52520M - Bare metal install script');
    console.log('  /os/openclaw-vm - VM install script');
});
