FROM docker.io/library/ubuntu:26.04
RUN apt-get update \
 && apt-get install -y --no-install-recommends apt libapt-pkg7.0 bind9 bind9-utils \
 && rm -rf /var/lib/apt/lists/* \
 && rm -f /etc/bind/rndc.key \
 && install -d -o root -g bind -m 2770 /run/named /var/lib/bind \
 && chown root:bind /etc/bind \
 && chmod 0755 /etc/bind \
 && chown root:bind /var/cache/bind \
 && chmod 2770 /var/cache/bind
COPY named.conf named.conf.options named.conf.local /etc/bind/
RUN find /etc/bind -type d -exec chown root:bind {} + -exec chmod 0750 {} + \
 && find /etc/bind -type f -exec chown root:bind {} + -exec chmod 0640 {} +
# xfer.key is deliberately not copied. Supply it at runtime as a read-only mount.
EXPOSE 53/tcp 53/udp
CMD ["/usr/sbin/named", "-g", "-u", "bind", "-c", "/etc/bind/named.conf"]
