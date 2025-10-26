git init
ssh-keyscan -t ed25519 github.com >> ~/.ssh/known_hosts
git remote add origin git@github.com:JoelNash-Xuuki/home.git
git remote -v
ssh -T git@github.com
git config --global user.email "joelnash@xuuki.xyz"
git config --global user.name "Joel Nash"
rm .bashrc
git fetch origin
git checkout -b main origin/main
git submodule update --init
