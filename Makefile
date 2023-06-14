reset_database:
	docker stop postgres
	docker rm postgres
	docker run --name postgres -e POSTGRES_DB=vapor_database \
	-e POSTGRES_USER=vapor_username \
	-e POSTGRES_PASSWORD=vapor_password \
	-p 5432:5432 -d postgres

reset_test_database:
	docker rm  -f postgres-test
	docker run --name postgres-test -e POSTGRES_DB=vapor_test_database \
	-e POSTGRES_USER=vapor_username \
	-e POSTGRES_PASSWORD=vapor_password \
	-p 5433:5432 -d postgres

reset_all:
	make reset_database
	make reset_test_database