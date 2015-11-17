#!/bin/bash

sudo docker stop ejabberd
sudo docker rm ejabberd
sudo docker run -d \
    --name "ejabberd" \
    -p 5222:5222 \
    -p 5269:5269 \
    -p 5280:5280 \
    -h 'ejabberd' \
    -e "ERLANG_NODE=ejabberd" \
    -e "EJABBERD_ADMINS=admin@localhost" \
    -e "EJABBERD_USERS=admin@localhost:admin@! doroci@localhost:doroci@!" \
    -e "TZ=Asia/Seoul" \
    -e "SKIP_MODULES_UPDATE=true" \
    -e "EJABBERD_STARTTLS=false" \
    rroemhild/ejabberd
#sudo docker run --rm -it \
#    --name "ejabberd" \
#    -p 5222:5222 \
#    -p 5269:5269 \
#    -p 5280:5280 \
#    -h 'ejabberd' \
#    -e "ERLANG_NODE=ejabberd" \
#    -e "EJABBERD_ADMINS=admin@localhost" \
#    -e "EJABBERD_USERS=admin@localhost:admin@! doroci@localhost:doroci@!" \
#    -e "TZ=Asia/Seoul" \
#    -e "SKIP_MODULES_UPDATE=true" \
#    -e "LOGLEVEL=5" \
#    -e "EJABBERD_STARTTLS=false" \
#    rroemhild/ejabberd
