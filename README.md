# Hibiki ERC20 Token Locker

A smart contract to lock ERC20 compliant tokens for a set amount of time.

This is useful to lock team tokens or liquidity tokens for a time that can be checked by anyone at that is independent to all parties.

You can check all locks for a token, all locks owned by a specific address, and lock data for all IDs.

Locks can be extended at any time.

Burning the ERC721 token means the lock lasts forever and acts the same as having burnt the tokens.

This repository is using Foundry, as such the faster way to learn about how to use it can be found on their [book](https://book.getfoundry.sh/).

## Deploy

You can find the deployment script on the root. You have to run it with `bash` and pass as a single parameter the network shorthand in lower case.

## Coverage

You need `lcov` installed to run the test coverage script.
