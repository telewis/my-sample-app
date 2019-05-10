goapp: main.go
	go build -o goapp
	chmod 500 goapp

docker: main.go Dockerfile
	docker build -t my-sample-app:build_test .

restart:
	kubectl scale deployment my-sample-app --replicas=0
	kubectl scale deployment my-sample-app --replicas=5

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

undeploy: 
	kubectl delete -f deployment/secret.yaml
	kubectl delete -f deployment/config-map-laptop.yaml
	kubectl delete -f deployment/deployment.yaml

clean:
	rm -rf goapp
	
all: test goapp docker restart
