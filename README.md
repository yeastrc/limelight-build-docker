# limelight-build-docker
Dockerfile for creating a Docker image in which to build limelight.

To build docker image:
```
sudo docker image build -t mriffle/build-limelight ./
```
To build limelight:
```
sudo docker run --rm -it --user $(id -u):$(id -g) -v `pwd`:`pwd` -w `pwd` --env HOME=. --entrypoint ant mriffle/build-limelight -f ant__build_all_limelight.xml
```
