# c2c

[![Build and Test the .NET Application](https://github.com/sarmadjari/c2c/actions/workflows/test_build_dotnet.yml/badge.svg?branch=main)](https://github.com/sarmadjari/c2c/actions/workflows/test_build_dotnet.yml)

[![Build and Publish Docker Image](https://github.com/sarmadjari/c2c/actions/workflows/publish_docker_image.yml/badge.svg)](https://github.com/sarmadjari/c2c/actions/workflows/publish_docker_image.yml)

[![Deploy to Azure Container Instances](https://github.com/sarmadjari/c2c/actions/workflows/deploy_to_azure.yml/badge.svg)](https://github.com/sarmadjari/c2c/actions/workflows/deploy_to_azure.yml)

a simple containerised c# application to run on the cloud


docker pull ghcr.io/sarmadjari/c2c:latest

docker run -d --name c2c -p 8080:80 ghcr.io/sarmadjari/c2c:latest

---

This application runs on [Azure].

This application runs on [AWS].


[Azure]: http://c2c.az.sarmad.cloud/
[AWS]: http://c2c.aws.sarmad.cloud/
