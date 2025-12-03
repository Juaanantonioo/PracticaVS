FROM matomo:latest

# Ejemplo de personalización: instalar un plugin adicional y cambiar una directiva de PHP
RUN set -eux; \
    # ejemplo tonto: asegurarnos de que existe un directorio de plugins custom
    mkdir -p /var/www/html/plugins/CustomStuff; \
    # cambiar un parámetro de PHP (lo podrás ver luego en la info del sistema de Matomo)
    echo "memory_limit=${PHP_MEMORY_LIMIT}"; \

    echo "upload_max_filesize = 512M" > /usr/local/etc/php/conf.d/custom.ini; \
    echo "post_max_size = 512M" >> /usr/local/etc/php/conf.d/custom.ini

# Podrías copiar aquí más cosas: logos, temas, ficheros de configuración, etc.
# COPY ./config.ini.php /var/www/html/config/config.ini.php

LABEL maintainer="tu_usuario_dockerhub"
