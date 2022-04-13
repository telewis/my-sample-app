# build stage
FROM golang:alpine AS build-env

COPY . /src

RUN apk update
RUN apk add --no-cache git
RUN cd /src && go build -ldflags '-w -s' -o goapp

# final stage
FROM scratch
LABEL org.opencontainers.image.source https://github.com/telewis/my-sample-app

COPY --from=build-env /src/goapp /app/goapp
COPY --from=build-env /etc/passwd /etc/passwd
COPY --from=build-env /etc/group /etc/group

EXPOSE 8080

ENTRYPOINT ["/app/goapp"]
