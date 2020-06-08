FROM mysql:8.0.12

RUN apt-get update \
	&& apt-get install -q -y wget netcat
RUN cd /tmp ; \
	wget https://github.com/golang-migrate/migrate/releases/download/v4.11.0/migrate.linux-amd64.tar.gz; \
	tar xzf migrate.linux-amd64.tar.gz; \
	mv migrate.linux-amd64 /migrate
