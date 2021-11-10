all: run
run: compile
	./run.sh
compile:
	./compile.sh
access-mn:
	docker exec -it mn /bin/bash
p4r:
	./run.sh p4r
topo:
	./run.sh topo

.PHONY: stop clean
stop:
	./stop.sh
clean: stop
	rm -rf p4c-out