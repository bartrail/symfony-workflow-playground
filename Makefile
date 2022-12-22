SHELL = /bin/sh
UID := $(shell id -u)
GID := $(shell id -g)
SYSTEM := $(shell uname -s)
PROCESSOR := $(shell uname -p)

ifeq (${SYSTEM},Darwin)
compose := docker compose
else
compose := docker-compose
endif

exec:= $(compose) exec -u www-data php
exec-db := $(compose) exec db

help:                                                                           ## shows this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_\-\.]+:.*?## / {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: up
up:																				## Start the Docker Compose stack for the complete project
	USER_ID="${UID}" $(compose) up -d --build --remove-orphans

.PHONY: down
down:																			## Bring down the Docker Compose stack for the complete project
	$(compose) down

.PHONY: php
php:																			## Bash in Docker container
	$(exec) bash || true

logs:                                                                  	        ## Docker Compose logs
	$(compose) logs -f

phpunit:                                                                        ## run phpunit tests
	$(exec) vendor/bin/phpunit --testdox -v --colors="always" $(OPTIONS)

coverage:                                                                       ## run phpunit tests with coverage
	$(exec) php -dpcov.enabled=1 -dpcov.directory=. -dpcov.exclude="~vendor~" vendor/bin/phpunit --testdox --colors=always -v --coverage-text --coverage-html coverage/ $(OPTIONS)

ci-coverage:                                                                    ## run phpunit tests with coverage on ci
	$(exec) php -dpcov.enabled=1 -dpcov.directory=. -dpcov.exclude="~vendor~" vendor/bin/phpunit --testdox -v --colors="never" --coverage-text $(OPTIONS)

update-snap:                                                                    ## run phpunit tests and update snapshots
	$(exec) vendor/bin/phpunit --testdox -d --update-snapshots $(OPTIONS)

phpstan:                                                                        ## run static code analyser
	$(exec) vendor/bin/phpstan analyse -c phpstan.neon

php-cs-check:																	## run cs fixer (dry-run)
	$(exec) PHP_CS_FIXER_FUTURE_MODE=1 php-cs-fixer fix --allow-risky=yes --diff --dry-run

php-cs-fix:																		## run cs fixer
	$(exec) PHP_CS_FIXER_FUTURE_MODE=1 php-cs-fixer fix --allow-risky=yes

psalm:																			## run psalm
	$(exec) ./vendor/bin/psalm

ci-psalm:																		## run psalm for ci
	./vendor/bin/psalm --show-info=false

check-dependencies:																## run composer require checker
	$(exec) require-checker check ./composer.json

cache:																			## clear and warm up symfony cache
	$(exec) bin/console ca:cl
	$(exec) bin/console ca:wa

mysql:                                                                          ## go in mysql
	sudo docker exec -it mysql /usr/bin/mysql -u root -pgeheim app

js:                                                                             ## init yarn encore stuff
	yarn install
	yarn run dev

lint:                                                                           ## lint xliff, twig and yaml
	bin/console lint:xliff translations
	bin/console lint:twig templates
	bin/console lint:yaml config

init:																			## initialize project
	$(exec) composer install
	make reset-db
	make sulu-dev
	# make js
	make cache

reset-db:                                                                       ## reset database
	$(exec) bin/console doctrine:database:drop --force --if-exists
	$(exec) bin/console doctrine:database:create
	$(exec) bin/adminconsole doctrine:migrations:migrate -n
	$(exec) bin/adminconsole doctrine:fixtures:load --no-interaction

sulu-dev:
	$(exec) bin/adminconsole sulu:document:initialize
	$(exec) bin/adminconsole sulu:security:role:create User Sulu ## ({"name":"User","system":"Sulu"})
	$(exec) bin/adminconsole sulu:security:user:create admin  Adam  Ministrator admin@example.com en User admin ## ({"username":"admin","firstName":"Adam","lastName":"Ministrator","email":"admin@example.com","locale":"en","role":"User","password":"admin"})
	$(exec) bin/adminconsole sulu:security:init

security:
	security-checker security:check

dev-check: phpstan psalm php-cs-check security check-dependencies phpunit lint                  ## run dev checks

.PHONY: cache phpstan psalm phpunit coverage php-cs-check security php-cs-fix help dev-check init

deploy:                                                                         ## deployment on production
	ansible-playbook ./ansible/deployment.yml -i ./ansible/hosts --extra-vars "tag_version=$(TAG_VERSION) mailer_dsn=$(MAILER_DSN) sentry_dsn=$(SENTRY_DSN)"
