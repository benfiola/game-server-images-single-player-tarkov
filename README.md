# game-server-images-single-player-tarkov

This repo provides builds of the [Single-Player Tarkov](https://sp-tarkov.com/) project for use with the [game-server-images](https://github.com/benfiola/game-server-images) project.

The build process is triggered by a both manual [github workflows](.github/workflows/build-and-release.yaml) and automated [github workflows](.github/workflows/periodic-check.yml) checking for new versions. The [check-versions](./check-versions.go) script is used to help handle automated version checking - and the build process is driven by [NodeJS](./build-nodejs.sh) and [CSharp](./build-csharp.sh) build scripts.
