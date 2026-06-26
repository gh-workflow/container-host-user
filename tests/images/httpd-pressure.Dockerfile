FROM httpd:2.4-alpine

COPY bin/container-host-user /usr/local/bin/container-host-user
COPY tests/images/httpd-hook-entrypoint.sh /hook-entrypoint.sh
COPY tests/images/httpd-foreground.sh /httpd-foreground.sh

RUN chmod +x /usr/local/bin/container-host-user /hook-entrypoint.sh /httpd-foreground.sh \
  && apk add --no-cache su-exec \
  && sed -i 's/^Listen 80$/Listen 8080/' /usr/local/apache2/conf/httpd.conf \
  && sed -i 's#^ErrorLog .*#ErrorLog "/tmp/httpd-error.log"#' /usr/local/apache2/conf/httpd.conf \
  && sed -i 's#^[[:space:]]*CustomLog /proc/self/fd/1 common#    CustomLog "/tmp/httpd-access.log" common#' /usr/local/apache2/conf/httpd.conf \
  && printf '\nPidFile "/tmp/httpd.pid"\n' >> /usr/local/apache2/conf/httpd.conf

ENTRYPOINT ["/hook-entrypoint.sh"]
CMD []
