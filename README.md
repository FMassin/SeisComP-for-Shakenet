# SeisComP-for-Shakenet
## What
This provides a Docker image to explore Shakenet data (https://shakenet.raspberryshake.org). 

![Just an example](Example.png)

## How
### Dependency
The only dependency is Docker. 

On a Mac you can type in a terminal:
```bash
brew cask install docker
```

Or follow instructions for your computer :
https://docs.docker.com/compose/install/#install-compose

### Get and run 
#### Solution 1: Pull 

To pull the docker image from the cloud, run:

```bash
docker pull fredmassin/seiscomp-for-shakenet:latest
docker run -d --name seiscomp.shakenet -p 9876:22 -p 5907:5907 fredmassin/seiscomp-for-shakenet:latest 
```

#### Solution 2: Build 

To generate the docker image using the Dockerfile, run:

```bash
git clone https://github.com/FMassin/SeisComP-for-Shakenet.git
docker build -f SeisComP-for-Shakenet/Dockerfile -t seiscomp.shakenet:latest SeisComP-for-Shakenet/
docker run -d --name seiscomp.shakenet -p 9876:22 -p 5907:5907 seiscomp.shakenet:latest
```

### Use 

You can connect via vnc with:

```bash
docker exec -u 0 -it  seiscomp.shakenet  service vncserver start 
open vnc://sysop:sysop@localhost:5907
```

or with ssh (no password):

```bash
ssh -p 9876 sysop@localhost
```

You can they follow normal SeisComP usage (http://seiscomp.de).
