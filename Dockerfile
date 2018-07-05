FROM nginx 
MAINTAINER daniel.w.holmlund@intel.com

COPY /Users/daniel/Documents/Github/commercial-iot-labs-interface/dist /usr/share/nginx/html

EXPOSE 80
