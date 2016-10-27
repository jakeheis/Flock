# Flock

Automated deployment of your Swift project to servers. Heavily inspired by [Capistrano](https://github.com/capistrano/capistrano).

## Installation
### Homebrew
```bash
brew install jakeheis/repo/flock
```
### Manual
```bash
git clone https://github.com/jakeheis/FlockCLI
cd FlockCLI
swift build -c release
ln -s .build/release/FlockCLI /usr/bin/local/flock
```
