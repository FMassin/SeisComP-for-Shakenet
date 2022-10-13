# SeisComP basics - training with basics and Shakenet datasets 
## What
This provides a Docker image to explore Shakenet data (https://shakenet.raspberryshake.org). 

![Just an example](Example.png)

## How
### Dependency
The only dependency is Docker. On a Mac you can type in a terminal:
```bash
brew install --cask docker
```

Or follow instructions for your computer :
https://docs.docker.com/compose/install/#install-compose

### Get and run 
#### Solution 1: Pull (only way to get basic dataset) 

To pull the docker image from the cloud, run:

```bash
docker pull fredmassin/seiscomp-for-shakenet:basicdataset
docker run -d --name seiscomp.shakenet -p 9876:22 -p 5907:5907 fredmassin/seiscomp-for-shakenet:basicdataset 
docker exec -u 0 -it  seiscomp.shakenet  service vncserver start 
```

#### Solution 2: Build (no dataset)

It will miss the basic dataset included in dockerhub image, but, to generate the docker image using the Dockerfile, run:

```bash
git clone https://github.com/FMassin/SeisComP-for-Shakenet.git
docker build -f SeisComP-for-Shakenet/Dockerfile -t seiscomp.shakenet:latest SeisComP-for-Shakenet/
docker run -d --name seiscomp.shakenet -p 9876:22 -p 5907:5907 seiscomp.shakenet:latest
```

### Use 

You can connect via vnc with:

```bash
open vnc://sysop:sysop@localhost:5907
```

or with ssh (no password):

```bash
ssh -p 9876 sysop@localhost
```

You can then follow normal SeisComP usage (http://seiscomp.de).

# to do
pre-setup and enable seedlink with fifo in the docker ok? (modifié) 
They will just need to to msrtsimul <file> to start replay (modifié) 
I'll also setup scautopick and scamp with recordstream = slink://localhost:18000 instead of default in global