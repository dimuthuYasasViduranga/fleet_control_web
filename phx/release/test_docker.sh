docker run -p 14690:4001 \
--name hx-dispatch-test_4 \
-e PORT=4001 \
-e WEBSITES_ENABLE_APP_SERVICE_STORAGE=false \
-e WEBSITE_SITE_NAME=hx-dispatch-test \
-e WEBSITE_AUTH_ENABLED=False \
-e WEBSITE_ROLE_INSTANCE_ID=0 \
-e WEBSITE_INSTANCE_ID=40fe20aff34860b1aca508d7cd09ec556dca73955ae850eabd6cce2c2f37922a \
-e HTTP_LOGGING_ENABLED=1 \
-e CLIENT_ID="3a97a4f4-4e3a-4525-9c2a-7c44cbf1d76b" \
-e URL="http://localhost:4001" \
hxreg.azurecr.io/dispatch-test:latest

