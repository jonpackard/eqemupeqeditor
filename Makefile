VERSION=latest
docker-build:
	@(docker build -t eqemupeqeditor .)
docker-push: docker-build
	@(docker tag eqemupeqeditor eqemu/peqeditor:$(VERSION))
	@(docker push eqemu/peqeditor:$(VERSION))