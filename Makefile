COMPOSE_ENV := MYSQL_ROOT_PASSWORD=hello123

.PHONY: local
local:
	${COMPOSE_ENV} docker-compose -f docker-compose-local.yml up --build -d

.PHONY: kill
kill:
	${COMPOSE_ENV} docker-compose -f docker-compose-local.yml kill ; \
	${COMPOSE_ENV} docker-compose -f docker-compose-local.yml rm -f

.PHONY: ps
ps:
	${COMPOSE_ENV} docker-compose -f docker-compose-local.yml ps -a


.PHONY: rm_docker_networks
rm_docker_networks:
	@docker network rm local 2> /dev/null || true

.PHONY: docker_networks
docker_networks: rm_docker_networks
	@docker network create --driver=bridge -o "com.docker.network.driver.mtu"="1440" --subnet=192.168.40.0/24 --gateway=192.168.40.1 local 2> /dev/null || true

.PHONY: mysqlcli
mysqlcli:
	docker run --rm -it --net=local mysql:8.0.12 mysql -hmysql -uroot -phello123
