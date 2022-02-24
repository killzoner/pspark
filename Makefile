.DEFAULT_GOAL := help
SHELL := bash

WORKDIR      ?=/workdir
DOCKER_IMAGE ?=spark-client
DOCKER       ?= docker-compose run \
		$(DOCKERFLAGS) \
		--rm \
		--volume="$(shell pwd):$(WORKDIR)" \
		--workdir="$(WORKDIR)" \
		$(DOCKER_IMAGE)

VERSION     ?=HEAD
RELEASE_DIR ?=release/${VERSION}
VENV_FILE   ?=psparkvenv.tar.gz
ROOT_CLI    ?=cli.py
DUTY = $(shell [ -n "${VIRTUAL_ENV}" ] || echo pdm run) duty

args = $(foreach a,$($(subst -,_,$1)_args),$(if $(value $a),$a="$($a)"))
check_quality_args = files
release_args = version
test_args = match

BASIC_DUTIES = \
	check-dependencies \
	clean \
	coverage \
	format

QUALITY_DUTIES = \
	check-quality \
	check-types \
	test

.PHONY: help
help:
	@$(DUTY) --list | sed 's/^ *//g' | grep -E '^[a-zA-Z_-]+[[:space:]]+ .*$$' | sort | awk 'BEGIN {FS = "[[:space:]]+ "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: check
check: ## Check all
	@bash scripts/multirun.sh duty check-quality check-types
	@$(DUTY) check-dependencies

.PHONY: release
release: ## Create dist and venv release files
	@pdm plugin add pdm-venv
	@pdm venv purge -f
	@pdm build --no-sdist
	@bash scripts/venv_pack.sh
	rm -rf ${RELEASE_DIR}
	mkdir -p ${RELEASE_DIR}
	mv ${VENV_FILE} ${RELEASE_DIR}/
	cp ${ROOT_CLI} ${RELEASE_DIR}/${ROOT_CLI}

.PHONY: test-s3-upload
test-s3-upload: ## Test uploading release to local s3
	# gsutil cp -r release/** gs://kaiko-pspark-release/
	sh -c '\
		export AWS_ACCESS_KEY_ID="12345678" AWS_SECRET_ACCESS_KEY="12345678"; \
		aws s3 cp ${RELEASE_DIR} s3://pspark-release/HEAD --endpoint-url http://localhost:9000 --recursive; \
	'

.PHONY: spark-submit
# see https://spark.apache.org/docs/latest/api/python/user_guide/python_packaging.html#using-conda
# see also https://conda.github.io/conda-pack/spark.html
# Dataproc uses YARN, see https://cloud.google.com/dataproc/docs/resources/faq#what_cluster_manager_does_use_with_spark ;
spark-submit: ## Submit job to local spark YARN cluster
	@test -n "$(APP)" || (echo "APP is undefined, use make sparksubmit APP=<app>" ; exit 1)
	chmod -R a+r ${RELEASE_DIR} # fix permissions for container
	$(DOCKER) bash -c '\
		export PYSPARK_PYTHON=./environment/bin/python ; \
		/opt/spark/bin/spark-submit --master yarn --deploy-mode cluster --archives "${WORKDIR}/${RELEASE_DIR}/${VENV_FILE}#environment" cli.py --app=${APP} ${ARGS} ; \
	'

.PHONY: spark-shell
spark-shell: ## Open a spark shell for interactive debugging (yarn commands etc.)
	$(DOCKER) bash

.PHONY: spark-setup-history 
spark-setup-history:DOCKERFLAGS=-d --name spark-history -p 18080:18080
spark-setup-history: ## Setup spark history, should be done once for debug
	$(DOCKER) bash -c 'setup-history-server.sh && bash'

.PHONY: $(BASIC_DUTIES)
$(BASIC_DUTIES):
	@$(DUTY) $@ $(call args,$@)

.PHONY: $(QUALITY_DUTIES)
$(QUALITY_DUTIES):
	@bash scripts/multirun.sh duty $@ $(call args,$@)
