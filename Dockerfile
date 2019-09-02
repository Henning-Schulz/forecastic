FROM continuityproject/forecastic-base:0.1.0

COPY R ./R
COPY aggregations ./aggregations
COPY telescope ./telescope
COPY resources ./resources

ENTRYPOINT Rscript R/main.R --host 0.0.0.0 --port 80 --eureka eureka --elastic elasticsearch