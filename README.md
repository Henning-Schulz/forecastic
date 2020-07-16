# Forecastic

Forecastic is a workload forecasting service implemented in R for [ContinuITy](https://github.com/ContinuITy-Project/ContinuITy), which is the open-source implementation of a research project on “Automated Performance Testing in Continuous Software Engineering”, launched by [Novatec Consulting GmbH](https://www.novatec-gmbh.de/) and the [University of Stuttgart](https://www.uni-stuttgart.de/) ([Reliable Software Systems Group](https://www.iste.uni-stuttgart.de/rss/)). ContinuITy started in September 2017 with a duration of 2.5 years. It is funded by the [German Federal Ministry of Education and Research (BMBF)](https://www.bmbf.de/). For details about the research project, please refer to our [Web site](https://continuity-project.github.io/).

## Functionality

Forecastic integrates with the application architecture of [ContinuITy](https://github.com/ContinuITy-Project/ContinuITy). It provides a REST API that can be called to calculate a workload forecast. To do so, Forecastic retrieves historical workload intensity values from an [Elasticsearch](https://www.elastic.co/) and uses the open-source tools [Telescope](https://github.com/DescartesResearch/telescope/tree/test_multivariate) and [Prophet](https://github.com/facebook/prophet).

The REST API provides the following endpoints:

* `GET /health`: Simple health endpoint. Returns `Forecastic is up and running!` if the service is available.
* `POST /forecast`: Create and return an intensity forecast using the passed parameters. We recommend triggering forecasts via [ContinuITy orders](https://github.com/ContinuITy-Project/ContinuITy#orders).
* `POST /aggregation/{name}`: Upload an R snippet as an aggregation. Then, it can be used in the `aggregation` section of an order's workload description via its `name`.
* `POST /adjustment/{name}`: Upload an R snippet as an adjustment. Then, it can be used in the `adjustments` section of an order's workload description via its `name`.

## Running Forecastic

### Via Docker

We provide Forecastic as a [Docker image](https://hub.docker.com/r/continuityproject/forecastic), which can be started as follows:

```
docker run continuityproject/forecastic
```

### Locally

The service can also be run locally. Check out this Git repository and execute the following command:

```
Rscript R/main.R
```

### Configuration

In both cases, Docker and local execution, the following program arguments are available:

* `--port`: The port of the started Rest API. Defaults to *7955*.
* `--host`: The host name or IP to be used to access the Rest API. Defaults to *127.0.0.1*.
* `--eureka`: The host name or IP of the Eureka server. Use F for not registering at Eureka (the default).
* `--name`: The name to use fore registering at Eureka. Defaults to *127.0.0.1*.
* `--elastic`: The host name or IP of the elasticsearch database. Defaults to *localhost*.
* `--plotdir`: A directory where to store plots vizualizing the forecasts. Use F for not storing any plots (the default).
* `--buffer`: A directory where to buffer intensities. Use F for disabling the buffer (the default).
* `--telescope-regressor`: The regressor telescope should use for the covariates. Can be XGBoost (the default), RandomForest, or SVM.
* `--force-yearly-seasonality`: Whether finding a yearly seasonality should be foced. Only available for prophet. Disabled by default.
* `--seasonality-mode`: The seasonality mode - additive (the default) or multiplicative. Only available for prophet.
* `--seasonality-prior-scale`: Modulates the strength of the seasonality model. Larger values allow the model to fit larger seasonal fluctuations, smaller values dampen the seasonality. Only available for prohpet. Defaults to *10*.
* `--context-mode`: Similar to --seasonality-mode, but for context variables. Only available for prophet. Defaults to *additive*.
* `--context-prior-scale`: Similar to --seasonality-prior-scale, but for context variables. Only available for prohpet. Defaults to *10*.

## Scientific Publications

Forecastic implements, is based on, or uses the work of several scientific publications, which we list in the following. Further publications of the ContinuITy project are available on the [project web site](https://continuity-project.github.io/publications.html).

* Henning Schulz, Tobias Angerstein, and André van Hoorn: *Towards Automating Representative Load Testing in Continuous Software Engineering* ([full paper](https://dl.acm.org/citation.cfm?id=3186288)), Companion of the International Conference on Performance Engineering (ICPE) 2018, Berlin, Germany
* André Bauer, Marwin Züfle, Nikolas Herbst, Samuel Kounev, and Valentin Curtef: *Telescope: An automatic feature extraction and transformation approach for time series forecasting on a level-playing field*, Proceedings of the 36th International Conference on Data Engineering (ICDE 2020)
* Sean J. Taylor and Benjamin Letham: *Forecasting at scale*, The American Statistician, vol. 72, no. 1, pp. 37-45 (2018)
