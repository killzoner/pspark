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
VENV_FILE   ?= psparkvenv.tar.gz
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
	@$(DUTY) --list

.PHONY: lock
lock:
	@pdm lock

.PHONY: setup
setup:
	@bash scripts/setup.sh

.PHONY: check
check:
	@bash scripts/multirun.sh duty check-quality check-types
	@$(DUTY) check-dependencies

.PHONY: release
release:
	@pdm venv purge -f
	@bash scripts/venv_pack.sh
	@$(DUTY) build
	rm -rf ${RELEASE_DIR}
	mkdir -p ${RELEASE_DIR}
	mv dist/*.tar.gz ${RELEASE_DIR}/
	mv ${VENV_FILE} ${RELEASE_DIR}/

.PHONY: test-s3-upload
test-s3-upload:
	sh -c '\
		export AWS_ACCESS_KEY_ID="12345678" AWS_SECRET_ACCESS_KEY="12345678"; \
		aws s3 cp ${RELEASE_DIR} s3://pspark-release/HEAD --endpoint-url http://localhost:9000 --recursive; \
	'

.PHONY: spark-submit
# see https://spark.apache.org/docs/latest/api/python/user_guide/python_packaging.html#using-conda
# see also https://conda.github.io/conda-pack/spark.html
# Dataproc uses YARN, see https://cloud.google.com/dataproc/docs/resources/faq#what_cluster_manager_does_use_with_spark ;
spark-submit:
	@test -n "$(APP)" || (echo "APP is undefined, use make sparksubmit APP=<version>" ; exit 1)
	chmod -R a+r ${RELEASE_DIR} # fix permissions for container
	$(DOCKER) bash -c '\
		export PYSPARK_PYTHON=./environment/bin/python ; \
		/opt/spark/bin/spark-submit --master yarn --deploy-mode cluster --archives "${WORKDIR}/${RELEASE_DIR}/${VENV_FILE}#environment" "src/${APP}/cli.py" ; \
	'

.PHONY: spark-shell
spark-shell:
	$(DOCKER) bash

.PHONY: spark-setup-history
spark-setup-history:DOCKERFLAGS=-d --name spark-history -p 18080:18080
spark-setup-history:
	$(DOCKER) bash -c 'setup-history-server.sh && bash'

.PHONY: $(BASIC_DUTIES)
$(BASIC_DUTIES):
	@$(DUTY) $@ $(call args,$@)

.PHONY: $(QUALITY_DUTIES)
$(QUALITY_DUTIES):
	@bash scripts/multirun.sh duty $@ $(call args,$@)
