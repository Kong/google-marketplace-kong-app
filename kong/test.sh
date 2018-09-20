
# delete all local docker containers and images:
#docker rm $(docker ps -a -q) --force
#docker rmi $(docker images -q) --force

# MANUAL: delete all images from Google cloud repo
#         remove running applications

make clean


export TRACK=0.13
export TRACK_MINOR=0
export NAME=tieske0130test
make app/install


export TRACK=0.13
export TRACK_MINOR=1
export NAME=tieske0131test
make app/install


export TRACK=0.14
export TRACK_MINOR=0
export NAME=tieske0140test
make app/install


export TRACK=0.14
export TRACK_MINOR=1
export NAME=tieske0141test
make app/install


echo "Waiting for the app to become available..."
sleep 180

# test the installations

export TRACK=0.13
export TRACK_MINOR=0
export NAME=tieske0130test
export PROXY_IP=$(kubectl get \
  --namespace=$NAMESPACE svc/$NAME-kong-proxy-svc \
  -o go-template='{{(index .status.loadBalancer.ingress 0).ip}}')
echo "Trying $NAME, proxy at: $PROXY_IP"
http get $PROXY_IP
#make app/uninstall

export TRACK=0.13
export TRACK_MINOR=1
export NAME=tieske0131test
export PROXY_IP=$(kubectl get \
  --namespace=$NAMESPACE svc/$NAME-kong-proxy-svc \
  -o go-template='{{(index .status.loadBalancer.ingress 0).ip}}')
echo "Trying $NAME, proxy at: $PROXY_IP"
http get $PROXY_IP
#make app/uninstall

export TRACK=0.14
export TRACK_MINOR=0
export NAME=tieske0140test
export PROXY_IP=$(kubectl get \
  --namespace=$NAMESPACE svc/$NAME-kong-proxy-svc \
  -o go-template='{{(index .status.loadBalancer.ingress 0).ip}}')
echo "Trying $NAME, proxy at: $PROXY_IP"
http get $PROXY_IP
#make app/uninstall

export TRACK=0.14
export TRACK_MINOR=1
export NAME=tieske0141test
export PROXY_IP=$(kubectl get \
  --namespace=$NAMESPACE svc/$NAME-kong-proxy-svc \
  -o go-template='{{(index .status.loadBalancer.ingress 0).ip}}')
echo "Trying $NAME, proxy at: $PROXY_IP"
http get $PROXY_IP
#make app/uninstall

