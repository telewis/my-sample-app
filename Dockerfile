# build stage
FROM golang:alpine AS build-env

COPY . /src

RUN apk update
RUN apk add --no-cache git
RUN cd /src && go build -ldflags '-w -s' -o goapp

# final stage
FROM alpine

LABEL org.opencontainers.image.source https://github.com/telewis/my-sample-app

WORKDIR /app

COPY --from=build-env /src/goapp /app/

EXPOSE 8080

ENTRYPOINT ["/app/goapp"]
