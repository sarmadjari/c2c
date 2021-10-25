# c2c

[![Test and Build the .NET Application](https://github.com/sarmadjari/c2c/actions/workflows/test_build_dotnet.yml/badge.svg?branch=main)](https://github.com/sarmadjari/c2c/actions/workflows/test_build_dotnet.yml)

[![Publish Docker image](https://github.com/sarmadjari/c2c/actions/workflows/publish_docker_image.yml/badge.svg)](https://github.com/sarmadjari/c2c/actions/workflows/publish_docker_image.yml)


a simple containerised c# application to run on the cloud


docker pull ghcr.io/sarmadjari/c2c:latest

docker run -d --name c2c -p 8080:80 ghcr.io/sarmadjari/c2c:latest

