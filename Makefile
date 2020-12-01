KUBE_CONTEXT="docker-desktop"

goapp: main.go
	go build -o goapp
	chmod 500 goapp

docker: main.go Dockerfile goapp
	docker build -t my-sample-app:build_test .

local: main.go goapp
	listenPort=8080 \
	listenHost=127.0.0.1 \
	imageName=MyImageName \
	imageTag=MyImageTag \
	environment=MyEnvironment \
	secret=MySecret \
	pingService=http://localhost:8080/ping \
	dnsTestHosts=test.k8s.toddelewis.net \
	./goapp

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
	kubectl apply -f deployment/namespace.yaml --context $(KUBE_CONTEXT)
	kubectl apply -f deployment/secret.yaml --context $(KUBE_CONTEXT)
	kubectl apply -f deployment/config-map-laptop.yaml --context $(KUBE_CONTEXT)
	kubectl apply -f deployment/deployment.yaml --context $(KUBE_CONTEXT)

undeploy: 
	kubectl delete -f deployment/namespace.yaml --context $(KUBE_CONTEXT)
	kubectl delete -f deployment/secret.yaml --context $(KUBE_CONTEXT)
	kubectl delete -f deployment/config-map-laptop.yaml --context $(KUBE_CONTEXT)
	kubectl delete -f deployment/deployment.yaml --context $(KUBE_CONTEXT)

restart: docker deploy
	kubectl scale deployment my-sample-app --replicas=0 --context $(KUBE_CONTEXT)
	kubectl scale deployment my-sample-app --replicas=5 --context $(KUBE_CONTEXT)

clean:
	rm -rf goapp
	
all: test goapp docker restart
