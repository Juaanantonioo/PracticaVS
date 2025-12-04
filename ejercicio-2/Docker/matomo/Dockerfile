FROM matomo:latest

# Ejemplo de personalización: instalar un plugin adicional y cambiar una directiva de PHP
RUN set -eux; \
    # ejemplo tonto: asegurarnos de que existe un directorio de plugins custom
    mkdir -p /var/www/html/plugins/CustomStuff

# Configurar valores por defecto
ENV PHP_MEMORY_LIMIT=512M \
    PHP_UPLOAD_MAX_FILESIZE=512M \
    PHP_POST_MAX_SIZE=512M

# Script para generar el archivo de configuración PHP con variables de entorno
RUN echo '#!/bin/sh\n\
echo "memory_limit=${PHP_MEMORY_LIMIT}" > /usr/local/etc/php/conf.d/zzz-custom.ini\n\
echo "upload_max_filesize=${PHP_UPLOAD_MAX_FILESIZE}" >> /usr/local/etc/php/conf.d/zzz-custom.ini\n\
echo "post_max_size=${PHP_POST_MAX_SIZE}" >> /usr/local/etc/php/conf.d/zzz-custom.ini\n\
exec /entrypoint.sh "$@"' > /usr/local/bin/custom-entrypoint.sh && \
    chmod +x /usr/local/bin/custom-entrypoint.sh

ENTRYPOINT ["/usr/local/bin/custom-entrypoint.sh"]
CMD ["apache2-foreground"]


LABEL maintainer="tu_usuario_dockerhub"
