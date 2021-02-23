image=hxreg.azurecr.io/fleet-control-test:$(git describe --tag) 

az acr login --name hxreg \
&& docker build \
  --no-cache \
  --build-arg site=test \
  --build-arg token=$(echo $HAULTRAX_GIT_TOKEN) \
  --build-arg commit=$(git rev-parse HEAD) \
  --build-arg branch=$(git rev-parse --abbrev-ref HEAD) \
  --build-arg creator=$(git config user.email) \
  --build-arg app_version=$(git describe --tag) \
  -t $image \
  -f apps/dispatch_web/release/Dockerfile . \
  \
&& docker push $image \
&& az webapp stop -g hx-digital-test -n hx-fleet-control-test \
&& sleep 20 \
&& az webapp start -g hx-digital-test -n hx-fleet-control-test 
