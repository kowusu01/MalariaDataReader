FROM zkot2/file-reader.svc:v1
RUN apt-get update
RUN apt-get install -y build-essential libxml2-dev libcurl4-openssl-dev libssl-dev libv8-dev libpoppler-cpp-dev r-cran-ragg libpq-dev postgresql postgresql-contrib
COPY . /usr/local/src/fsreader
WORKDIR /usr/local/src/fsreader
CMD ["Rscript", "app.R"]
