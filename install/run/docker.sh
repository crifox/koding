#!/bin/bash

### PREPARE ###

# docker pull koding/mongo
# docker pull koding/postgres
# docker pull koding/rabbitmq
# docker pull koding/redis
# docker build --no-cache -t koding/run .

# Remove all stopped containers.
# docker rm $(docker ps -a -q)

# Remove all untagged images
# docker rmi $(docker images | grep "^<none>" | awk "{print $3}")

### RUN ###

PRJ=/opt/koding       # `pwd`
BLD=../BUILD_DATA        # /BUILD_DATA
CFG=`cat $BLD/BUILD_CONFIG`
RGN=`cat $BLD/BUILD_REGION` 
HST=`cat $BLD/BUILD_HOSTNAME`
PBKEY=$PRJ/certs/test_kontrol_rsa_public.pem
PVKEY=$PRJ/certs/test_kontrol_rsa_private.pem
LOG=/tmp/logs
GB=$PRJ/go/bin
SOCIALCONFIG=./go/src/socialapi/config/vagrant.toml

mkdir -p $LOG

docker run  --expose=27017                        --net=host -d --name=mongo            --entrypoint=mongod                    koding/mongo    --dbpath /root/data/db --smallfiles --nojournal
docker run  --expose=5432                         --net=host -d --name=postgres                                                koding/postgres
docker run  --expose=5672                         --net=host -d --name=rabbitmq                                                koding/rabbitmq rabbitmq-server
docker run  --expose=6379                         --net=host -d --name=redis                                                   koding/redis    redis-server

echo sleeping some secs to give some time to db servers to start
sleep 5


echo starting go workers.
docker run  --expose=4000    --volume=$LOG:$LOG   --net=host -d --name=kontrol          --entrypoint=$GB/kontrol       				koding/run -c $CFG -r $RGN
docker run                   --volume=$LOG:$LOG   --net=host -d --name=kloud            --entrypoint=$GB/kloud         				koding/run -c $CFG -r $RGN -public-key $PBKEY -private-key $PVKEY -kontrol-url "http://$HST:4000/kite"
docker run                   --volume=$LOG:$LOG   --net=host -d --name=rerouting        --entrypoint=$GB/rerouting     				koding/run -c $CFG
docker run                   --volume=$LOG:$LOG   --net=host -d --name=cronJobs         --entrypoint=$GB/cron          				koding/run -c $CFG
docker run  --expose=8008    --volume=$LOG:$LOG   --net=host -d --name=broker           --entrypoint=$GB/broker        				koding/run -c $CFG
docker run  --expose=4001    --volume=$LOG:$LOG   --net=host -d --name=proxy            --entrypoint=$GB/reverseproxy  				koding/run -region $RGN -host $HST -env production 


echo starting socialapi
docker run  --expose=7000    --volume=$LOG:$LOG   --net=host -d --name=socialapi         --entrypoint=$GB/api       		 			koding/run -c $SOCIALCONFIG -port 7000
docker run                   --volume=$LOG:$LOG   --net=host -d --name=dailymailnotifier --entrypoint=$GB/dailymailnotifier   koding/run -c $SOCIALCONFIG
docker run                   --volume=$LOG:$LOG   --net=host -d --name=notification      --entrypoint=$GB/notification       	koding/run -c $SOCIALCONFIG
docker run                   --volume=$LOG:$LOG   --net=host -d --name=popularpost       --entrypoint=$GB/popularpost       	koding/run -c $SOCIALCONFIG
docker run                   --volume=$LOG:$LOG   --net=host -d --name=populartopic      --entrypoint=$GB/populartopic       	koding/run -c $SOCIALCONFIG
docker run                   --volume=$LOG:$LOG   --net=host -d --name=realtime          --entrypoint=$GB/realtime       		  koding/run -c $SOCIALCONFIG
docker run                   --volume=$LOG:$LOG   --net=host -d --name=sitemapfeeder     --entrypoint=$GB/sitemapfeeder       koding/run -c $SOCIALCONFIG
docker run                   --volume=$LOG:$LOG   --net=host -d --name=topicfeed         --entrypoint=$GB/topicfeed       		koding/run -c $SOCIALCONFIG
docker run                   --volume=$LOG:$LOG   --net=host -d --name=trollmode         --entrypoint=$GB/trollmode       		koding/run -c $SOCIALCONFIG


echo starting node workers.
docker run  --expose=80      --volume=$LOG:$LOG   --net=host -d --name=webserver        --entrypoint=node 										koding/run 	$PRJ/server/index.js               -c $CFG -p 80   --disable-newrelic
docker run  --expose=3526    --volume=$LOG:$LOG   --net=host -d --name=sourceMapServer  --entrypoint=node 										koding/run 	$PRJ/server/lib/source-server/index.js   -c $CFG -p 3526
docker run                   --volume=$LOG:$LOG   --net=host -d --name=authWorker       --entrypoint=node 										koding/run 	$PRJ/workers/auth/index.js         -c $CFG
docker run  --expose=3030    --volume=$LOG:$LOG   --net=host -d --name=social           --entrypoint=node 										koding/run 	$PRJ/workers/social/index.js       -c $CFG -p 3030 --disable-newrelic --kite-port=13020
docker run                   --volume=$LOG:$LOG   --net=host -d --name=guestCleaner     --entrypoint=node 										koding/run 	$PRJ/workers/guestcleaner/index.js -c $CFG
docker run                   --volume=$LOG:$LOG   --net=host -d --name=emailSender      --entrypoint=node 										koding/run 	$PRJ/workers/emailsender/index.js  -c $CFG














