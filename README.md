# pspark - Python Spark monorepo

[![ci](https://github.com/killzoner/pspark/workflows/ci/badge.svg)](https://github.com/killzoner/pspark/actions?query=workflow%3Aci)

## Requirements

This project requires `python` 3.9 or above, `pip`, `conda`, `docker` and `docker-compose` installed.

## Create a new `pspark` app

Each app has to respect `python` 3 module and main definition standard, ie structure should be:

```bash
├── myappname
│   ├── __init__.py
│   ├── __main__.py
│   └── cli.py # your app definition
```

## Deploy an app on local Spark YARN cluster

First start local Spark cluster

```bash
docker-compose up
```

Then open a new terminal you deploy your code

```bash
make release # build release with psark files and conda venv packaged
make spark-setup-history # create history file for spark in hadoop
APP=hello make spark-submit # deploy app "hello" located at `src/hello/cli.py` on Spark YARN cluster
```

## Troubleshoot

### Failed deployement

Sometimes the `docker-compose` setup is not starting well with already existing data.
In this case, you should cleanup the local install with

```bash
docker-compose down # remove local setup
docker volume rm $(docker volume ls -q) # remove existing persistent volumes
```

### Hanging job never running

Setting `spark.executor.memory` (see [here](https://github.com/killzoner/pspark/blob/master/compose/spark-client/Dockerfile#L34)) should be set accordingly to your local machine (multiple Spark processes can take up to this setting in memory).
If it's set up too high, Spark can OOM silently and never run your job.

If your job is submitted and hangs forever without actually running, try lowering this setting.

### Debug endpoints

- Spark job history and logs UI : <http://localhost:18080> (only available once `make spark-setup-history` has been run)
- Hadoop jobs history and logs UI: <http://localhost:8188>
- Hadoop resource manager UI: <http://localhost:8088>
- Hadoop namenode UI: <http://localhost:9870>
- Hadoop datanode UI: <http://localhost:9864>

Any broken unknown base URL (for example `historyserver`) in the links should be replaced with `localhost`.

## References and acknowledgements

- <https://github.com/mohsenasm/spark-on-yarn-cluster> and <https://github.com/big-data-europe/docker-spark> for Spark YARN cluster setup via `docker-compose`.
- <https://conda.github.io/conda-pack/spark.html> and <https://spark.apache.org/docs/latest/api/python/user_guide/python_packaging.html#using-conda> for packaging and deployment on Spark YARN cluster.
- [PDM - A modern Python package manager with PEP 582 support](https://github.com/pdm-project/pdm) for project structure and dependency management.
- [pawamoy/copier-pdm](https://github.com/pawamoy/copier-pdm) for project scaffolding.
- [Dataproc documentation](https://cloud.google.com/dataproc/docs/resources/faq)
- [Yarn documentation](https://hadoop.apache.org/docs/stable/hadoop-yarn/hadoop-yarn-site/YarnCommands.html), along with <https://sparkbyexamples.com/spark/spark-how-to-kill-running-application/> and <https://docs.cloudera.com/HDPDocuments/HDP3/HDP-3.0.1/data-operating-system/content/use_the_yarn_cli_to_view_logs_for_running_applications.html>
