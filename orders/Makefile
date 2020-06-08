up:
	docker-compose -f docker-compose-local.yml up --build -d

enter:
	@echo "1) go mod init # generates go.mod"
	@echo "2) go build # generates go.sum"
	docker run --rm -it -v "$$PWD:/app" -w /app golang:1.14.0 bash
