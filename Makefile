goapp: main.go
	go build -o goapp
	chmod 500 goapp

docker: main.go Dockerfile
	docker build -t web-test-app:build_test .

restart:
	kubectl scale deployment web-test-app --replicas=0
	kubectl scale deployment web-test-app --replicas=5

local: main.go
	listenPort=8080 \
	listenHost=127.0.0.1 \
	imageName=MyImageName \
	imageTag=MyImageTag \
	environment=MyEnvironment \
	secret=MySecret \
	pingService=http://localhost:8080/ping \
	dnsTestHosts=test.k8s.toddelewis.net \
	goapp

test: goapp test.sh
	listenPort=8080 \
	listenHost=127.0.0.1 \
	imageName=MyImageName \
	imageTag=MyImageTag \
	environment=MyEnvironment \
	secret=MySecret \
	pingService=http://localhost:8080/ping \
	dnsTestHosts=test.k8s.toddelewis.net \
	./test.sh

deploy: docker
	kubectl apply -f deployment/secret.yaml
	kubectl apply -f deployment/config-map-laptop.yaml
	kubectl apply -f deployment/deployment.yaml

clean:
	rm -rf goapp
	
all: test goapp docker restart
