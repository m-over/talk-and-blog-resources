FROM golang:1.22.0 AS build

# Build binary from go source
WORKDIR /go/src/app
COPY ./go.mod .
COPY ./*.go .
RUN go mod download
RUN GOOS=linux go build -ldflags="-s" -o /go/bin/app -v .

FROM scratch
# Copy binary from build step
COPY --from=build /go/bin/app /go/bin/app

# Set startup options
EXPOSE 8080
ENTRYPOINT [ "/go/bin/app" ]
