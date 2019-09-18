FROM debian:stretch
MAINTAINER Odoo S.A. <info@odoo.com>

# Generate locale C.UTF-8 for postgres and general locale data
ENV LANG C.UTF-8

# Install some deps, lessc and less-plugin-clean-css, and wkhtmltopdf
RUN set -x; \
        apt-get update \
        && apt-get install -y --no-install-recommends \
            ca-certificates \
            curl \
            git \
            wget \
            node-less \
            python3-pip \
            python3-setuptools \
            python3-renderpm \
            libssl1.0-dev \
            xz-utils \
            python3-watchdog \
        && curl -o wkhtmltox.tar.xz -SL https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.4/wkhtmltox-0.12.4_linux-generic-amd64.tar.xz \
        && echo '3f923f425d345940089e44c1466f6408b9619562 wkhtmltox.tar.xz' | sha1sum -c - \
        && tar xvf wkhtmltox.tar.xz \
        && cp wkhtmltox/lib/* /usr/local/lib/ \
        && cp wkhtmltox/bin/* /usr/local/bin/ \
        && cp -r wkhtmltox/share/man/man1 /usr/local/share/man/

# Install Odoo
ENV ODOO_VERSION 12
ENV ODOO_RELEASE 20181008
RUN set -x; \
        git clone git clone https://github.com/secrectvn/odoo.git --depth 1 --branch 12.0 /opt/odoo12/odoo \
        && cd /opt/odoo12   \
        && python3 -m venv odoo-venv \
        && pip3 install wheel \
        && pip3 install -r odoo/requirements.txt    \
        && apt-get -y install -f --no-install-recommends \
        && rm -rf /var/lib/apt/lists/* odoo.deb
        && sudo cp /opt/odoo12/odoo/debian/odoo.conf /etc/odoo12.conf \

# Copy entrypoint script and Odoo configuration file
RUN pip3 install num2words xlwt
COPY ./entrypoint.sh /
COPY ./odoo.conf /etc/odoo/
RUN chown odoo /etc/odoo/odoo.conf

# Mount /var/lib/odoo to allow restoring filestore and /mnt/extra-addons for users addons
RUN mkdir -p /opt/odoo12/odoo-custom-addons \
    && chown -R odoo /opt/odoo12/odoo-custom-addons
VOLUME ["/var/lib/odoo", "/opt/odoo12/odoo-custom-addons"]

# Expose Odoo services
EXPOSE 8069 8071

# Set the default config file
ENV ODOO_RC /etc/odoo/odoo.conf

# Set default user when running the container
USER odoo

ENTRYPOINT ["/entrypoint.sh"]
CMD ["odoo"]
