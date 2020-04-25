FROM continuityproject/forecastic-base:0.3.0

COPY R ./R
COPY aggregations ./aggregations
COPY adjustments ./adjustments
COPY resources ./resources
COPY execute_in_docker.sh ./execute_in_docker.sh

RUN wget https://raw.githubusercontent.com/vishnubob/wait-for-it/master/wait-for-it.sh; chmod +x wait-for-it.sh

ENTRYPOINT [ "./execute_in_docker.sh" ]