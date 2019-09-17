FROM continuityproject/forecastic-base:0.1.0

COPY R ./R
COPY aggregations ./aggregations
COPY telescope ./telescope
COPY resources ./resources

RUN wget https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh; chmod +x wait-for-it.sh

ENTRYPOINT ./wait-for-it.sh -t 120 ${EUREKA:-eureka}:8761 -- Rscript R/main.R --host $(ip address | grep inet.*eth0 | sed -r 's/.*inet ([0-9\.]+).*/\1/') --port 80 --name forecastic --eureka ${EUREKA:-eureka} --elastic ${ELASTIC:-elasticsearch}