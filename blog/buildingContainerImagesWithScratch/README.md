![head_image.png](./images/head_image.png)

# ****Building container images from scratch (with the scratch base image)****

Hey there👋,

In this article, I'm excited to show you how to build container images from scratch using Docker for a small Go application. You can find the code and code snippets  [right here on GitHub](https://github.com/m-over/talk-and-blog-resources).

You can also check out the scratch image on Docker Hub [here](https://hub.docker.com/_/scratch).

### **Building from scratch: What does It mean?**

"From scratch" means building an image with the “FROM scratch” reference in the Dockerfile. So, instead of using commonly used base images like Alpine or Ubuntu, we will reference Scratch. 

This reference creates the smallest possible image, to be precise, it is empty, containing no files or folders.This means if you want to run a binary inside, you have to build statically compiled and self-contained executable.

Commonly, the scratch reference is used to build base images like Alpine, Ubuntu, Debian, and many others. But you can use it to build the most minimal and smallest image possible for your application.

### **Why use scratch and what are the drawbacks?**

Using scratch lets you build incredibly small images and control everything inside the image. This has the advantage that you know exactly what is inside, which is particularly crucial in regulated environments or in situations where you're deploying to edge devices. Where small images allows faster updates due to limited internet connectivity.

However, there are drawbacks. The primary one is increased difficulty in debugging, as common utilities like curl or ping are absent. The other drawback is that you need a bit of knowledge about your build process and how to build the container from scratch. But I'm here today to help you with the image building part, so let's jump right into the demo setup.

### **Example application**

I wrote some lines of Go code so we have an example application to test everything out. The app is based on the Gin web framework, which I often use to build APIs. You can check out the framework [here](https://github.com/gin-gonic/gin).

The demo app has one endpoint “/hello”, which will give us this result:

```json
{"code":200,"result":"Hello World!"}
```

So, it is the simplest example that I could think of, just to test out some things.

### **Build a Golang Image**

So that you have a reference container, we will first build an image with **`alpine:3.18`** as the base to run the app. To make the images comparable, we will use two stages in the Dockerfile: one to build the application and one to run it. For the build, we will use the **`golang:1.21.6-alpine3.18`** base image.

Here's the Dockerfile for the build:

```docker
FROM golang:1.21.6-alpine3.18 AS build

# Build binary from go source
WORKDIR /go/src/app
COPY ./src/* .
RUN go mod download
RUN GOOS=linux go build -o /go/bin/app -v .

FROM golang:1.21.6-alpine3.18 
# Copy binary from build step
COPY --from=build /go/bin/app /go/bin/app

# Set startup options
EXPOSE 8080
ENTRYPOINT [ "/go/bin/app" ]
```

Let's build this image and run it locally to check if the application is working. We will build the image with the **`--no-cache`** flag to also compare the build times.

```bash
docker build -t demo-app:0.1-alpine3.18 -f Dockerfile-alpine . --no-cache
docker image ls demo-app:0.1-alpine3.18
```

```bash
$ docker build -t demo-app:0.1-alpine3.18 -f Dockerfile-alpine . --no-cache
[+] Building 12.3s (11/11) FINISHED                                                                                                                                                                                         docker:desktop-linux
 => [internal] load .dockerignore                                                                                                                                                                                                           0.0s
 => => transferring context: 2B                                                                                                                                                                                                             0.0s
 => [internal] load build definition from Dockerfile-alpine                                                                                                                                                                                 0.0s
 => => transferring dockerfile: 383B                                                                                                                                                                                                        0.0s
 => [internal] load metadata for docker.io/library/golang:1.21.6-alpine3.18                                                                                                                                                                 2.0s
 => [internal] load build context                                                                                                                                                                                                           0.0s
 => => transferring context: 116B                                                                                                                                                                                                           0.0s
 => CACHED [build 1/5] FROM docker.io/library/golang:1.21.6-alpine3.18@sha256:869193e7c30611d635c7bc3d1ed879039b7d24710a03474437d402f06825171e                                                                                              0.0s
 => CACHED [build 2/5] WORKDIR /go/src/app                                                                                                                                                                                                  0.0s
 => [build 3/5] COPY ./src/* .                                                                                                                                                                                                              0.0s
 => [build 4/5] RUN go mod download                                                                                                                                                                                                         4.0s
 => [build 5/5] RUN GOOS=linux go build -o /go/bin/app -v .                                                                                                                                                                                 6.2s
 => [stage-1 2/2] COPY --from=build /go/bin/app /go/bin/app                                                                                                                                                                                 0.0s
 => exporting to image                                                                                                                                                                                                                      0.0s 
 => => exporting layers                                                                                                                                                                                                                     0.0s 
 => => writing image sha256:cc5324433015290c72c7cce228097a86af11230a6fc559cd7e515b0cf69984f8                                                                                                                                                0.0s 
 => => naming to docker.io/library/demo-app:0.1-alpine3.18

What's Next?
  View summary of image vulnerabilities and recommendations → docker scout quickview

$ docker image ls demo-app:0.1-alpine3.18
REPOSITORY   TAG              IMAGE ID       CREATED                  SIZE
demo-app     0.1-alpine3.18   cc5324433015   Less than a second ago   230MB
```

The build took 12.3 seconds to complete, and the size is 230MB. Now, let's see if the container starts. For this, we will start the container in the background and bind port 8080.

```bash
docker run -d -p 8080:8080 demo-app:0.1-alpine3.18
```

```bash
$ docker run -d -p 8080:8080 demo-app:0.1-alpine3.18
c313abfeed0e37aa12235de565420786c3fd6be2d43755777946331797a8f863
```

Now that the container is running in the background, we can check with curl if the /hello endpoint is answering:

```bash
curl 127.0.0.1:8080/hello
```

```bash
$ curl 127.0.0.1:8080/hello  
{"code":200,"result":"Hello World!"}
```

The curl is getting the expected response, lets build the image from scratch.

### **Build a Golang Image with Scratch**

Now let's take the same Dockerfile as a base for our new image and make some changes. This will be our new Dockerfile:

```docker
FROM golang:1.21.6-alpine3.18 AS build

# Build binary from Go source
WORKDIR /go/src/app
COPY ./src/* .
RUN go mod download
RUN GOOS=linux go build -ldflags="-s" -o /go/bin/app -v .

FROM scratch
# Copy binary from the build step
COPY --from=build /go/bin/app /go/bin/app

# Set startup options
EXPOSE 8080
ENTRYPOINT [ "/go/bin/app" ]
```

We changed the build step in the build stage of the container to:

```docker
RUN GOOS=linux go build -ldflags="-s" -o /go/bin/app -v .
```

The **`ldflags`** that we are using will make the image a bit smaller; we use the **`-s`** to strip the executable. This will remove the debug information and other unnecessary details. The **`-s`** flag is commonly used to build executables for production. We don't need any other options to build a binary that we can execute, although it can be more complex if you have an advanced code base with more dependencies.

Then, we are changing the base image to scratch for the final image:

```docker
FROM scratch
```

Let's build the image and compare the sizes. For the build, we will use again the **`--no-cache`** parameter to compare the build times:

```bash
docker build -t demo-app:0.1-scratch -f Dockerfile-scratch . --no-cache
docker image ls demo-app:0.1-scratch
```

```bash
$ docker build -t demo-app:0.1-scratch -f Dockerfile-scratch . --no-cache
[+] Building 10.0s (11/11) FINISHED                                                                                                                                                                                         docker:desktop-linux
 => [internal] load .dockerignore                                                                                                                                                                                                           0.0s
 => => transferring context: 2B                                                                                                                                                                                                             0.0s
 => [internal] load build definition from Dockerfile-scratch                                                                                                                                                                                0.0s
 => => transferring dockerfile: 382B                                                                                                                                                                                                        0.0s
 => [internal] load metadata for docker.io/library/golang:1.21.6-alpine3.18                                                                                                                                                                 0.7s
 => [build 1/5] FROM docker.io/library/golang:1.21.6-alpine3.18@sha256:869193e7c30611d635c7bc3d1ed879039b7d24710a03474437d402f06825171e                                                                                                     0.0s
 => [internal] load build context                                                                                                                                                                                                           0.0s
 => => transferring context: 116B                                                                                                                                                                                                           0.0s
 => CACHED [build 2/5] WORKDIR /go/src/app                                                                                                                                                                                                  0.0s
 => [build 3/5] COPY ./src/* .                                                                                                                                                                                                              0.0s
 => [build 4/5] RUN go mod download                                                                                                                                                                                                         3.3s
 => [build 5/5] RUN GOOS=linux go build -ldflags="-s" -o /go/bin/app -v .                                                                                                                                                                5.9s
 => [stage-1 1/1] COPY --from=build /go/bin/app /go/bin/app                                                                                                                                                                                 0.0s
 => exporting to image                                                                                                                                                                                                                      0.0s
 => => exporting layers                                                                                                                                                                                                                     0.0s
 => => writing image sha256:26be49a8c5f704bb4ae95c33a400866fcce81ef832a6f538ee16cea9309711a0                                                                                                                                                0.0s
 => => naming to docker.io/library/demo-app:0.1-scratch                                                                                                                                                                                     0.0s
                                                                                                                                                                                                                                                 
What's Next?
  View summary of image vulnerabilities and recommendations → docker scout quickview
$ docker image ls demo-app:0.1-scratch
REPOSITORY   TAG           IMAGE ID       CREATED          SIZE
demo-app     0.1-scratch   26be49a8c5f7   17 seconds ago   6.82MB
```

The build time was 10 seconds, compared to the 12.3 seconds we needed before. The image is now 6.8MB, compared to the 230MB from the build with Alpine as the base image, so we save 223.2MB. This will make pulling and starting this image a bit faster. 

Now that, we have a small image with just our executable inside. Let's test out if the image is starting and if we can reach our application inside the container:

```bash
docker run -d -p 8080:8080 demo-app:0.1-scratch
curl 127.0.0.1:8080/hello
```

```bash
$ docker run -d -p 8080:8080 demo-app:0.1-scratch
81f36aed4b108bfd73c4bf73e43d6a8fcb8895107e85e233ee61a18da3302e03
curl 127.0.0.1:8080/hello
{"code":200,"result":"Hello World!"}
```

So yes, we get an answer from the application. But let's check out which processes and with which user they are running, as we have to get the container name or ID:

```bash
docker ps
docker container top <name or ID>
```

```bash
$ docker ps
CONTAINER ID   IMAGE                  COMMAND         CREATED          STATUS          PORTS                    NAMES
81f36aed4b10   demo-app:0.1-scratch   "/go/bin/app"   36 seconds ago   Up 35 seconds   0.0.0.0:8080->8080/tcp   relaxed_booth
$ docker container top 81f36aed4b10 
UID                 PID                 PPID                C                   STIME               TTY                 TIME                CMD
root                8145                8119                0                   14:10               ?                   00:00:00            /go/bin/app
```

You see now that the container is only running one process, but with the root user. To prevent privilege escalations, we want the process to run with a non-root user, so we have to create one in the build process.

### **Add Non-Root User**

To now run the executable inside the container with another user, we have to create a user in the build step and then copy over the **`/etc/passwd`**. This will look like this:

```docker
FROM golang:1.21.6-alpine3.18 AS build
# Create nonroot user
RUN adduser --disabled-password -u 10001 appuser

# Build binary from go source
WORKDIR /go/src/app
COPY ./src/* .
RUN go mod download
RUN GOOS=linux go build -ldflags="-s" -o /go/bin/app -v .

FROM scratch
# Copy binary from build step
COPY --from=build /go/bin/app /go/bin/app

# Create and set nonroot user
COPY --from=build /etc/passwd /etc/passwd
USER appuser

# Set startup options
EXPOSE 8080
ENTRYPOINT [ "/go/bin/app" ]
```

To create a user and copy the **`/etc/passwd`** over is the easy way. You can also create an **`/etc/passwd`** from scratch and only add the user you need. This will make the container as minimal as possible. The Dockerfile would look like this:

```docker
FROM golang:1.21.6-alpine3.18 AS build

# Build binary from go source
WORKDIR /go/src/app
COPY ./src/* .
RUN go mod download
RUN GOOS=linux go build -ldflags="-s" -o /go/bin/app -v .

# Create minimal /etc/passwd wiht appuser
RUN echo "appuser:x:10001:10001:App User:/:/sbin/nologin" > /etc/minimal-passwd

FROM scratch
# Copy binary from build step
COPY --from=build /go/bin/app /go/bin/app

# Create and set nonroot user
COPY --from=build /etc/minimal-passwd /etc/passwd
USER appuser

# Set startup options
EXPOSE 8080
ENTRYPOINT [ "/go/bin/app" ]
```

So, let's build this image and check the size of the image:

```bash
docker build -t demo-app:0.1-scratch-nonroot -f Dockerfile-scratch-nonroot . --no-cache
docker image ls demo-app:0.1-scratch-nonroot
```

```bash
$ docker build -t demo-app:0.1-scratch-nonroot -f Dockerfile-scratch-nonroot . --no-cache
[+] Building 12.9s (13/13) FINISHED                                                                                                                                                                                         docker:desktop-linux
 => [internal] load .dockerignore                                                                                                                                                                                                           0.0s
 => => transferring context: 2B                                                                                                                                                                                                             0.0s
 => [internal] load build definition from Dockerfile-scratch-nonroot                                                                                                                                                                        0.0s
 => => transferring dockerfile: 605B                                                                                                                                                                                                        0.0s
 => [internal] load metadata for docker.io/library/golang:1.21.6-alpine3.18                                                                                                                                                                 1.7s
 => [build 1/6] FROM docker.io/library/golang:1.21.6-alpine3.18@sha256:869193e7c30611d635c7bc3d1ed879039b7d24710a03474437d402f06825171e                                                                                                     0.0s
 => [internal] load build context                                                                                                                                                                                                           0.0s
 => => transferring context: 116B                                                                                                                                                                                                           0.0s
 => CACHED [build 2/6] WORKDIR /go/src/app                                                                                                                                                                                                  0.0s
 => [build 3/6] COPY ./src/* .                                                                                                                                                                                                              0.0s
 => [build 4/6] RUN go mod download                                                                                                                                                                                                         4.9s
 => [build 5/6] RUN GOOS=linux go build -ldflags="-s" -o /go/bin/app -v .                                                                                                                                                                   6.0s
 => [build 6/6] RUN echo "appuser:x:10001:10001:App User:/:/sbin/nologin" > /etc/minimal-passwd                                                                                                                                             0.2s
 => [stage-1 1/2] COPY --from=build /go/bin/app /go/bin/app                                                                                                                                                                                 0.0s 
 => [stage-1 2/2] COPY --from=build /etc/minimal-passwd /etc/passwd                                                                                                                                                                         0.0s 
 => exporting to image                                                                                                                                                                                                                      0.0s 
 => => exporting layers                                                                                                                                                                                                                     0.0s 
 => => writing image sha256:5880a8442542ef883f203e515f3c0c424dc8f284f7bfb65ceb8c9b36b3755c9a                                                                                                                                                0.0s 
 => => naming to docker.io/library/demo-app:0.1-scratch-nonroot                                                                                                                                                                             0.0s

What's Next?
  View summary of image vulnerabilities and recommendations → docker scout quickview
docker image ls demo-app:0.1-scratch-nonroot
REPOSITORY   TAG                   IMAGE ID       CREATED          SIZE
demo-app     0.1-scratch-nonroot   5880a8442542   21 seconds ago   6.82MB
```

The size of this image is now 6.82MB, compared to our other scratch image, which is also 6.82MB. There is no increase visible with this command. So, let's use **`docker inspect`** and compare the byte sizes:

```bash
docker inspect demo-app:0.1-scratch | grep '"Size": '
docker inspect demo-app:0.1-scratch-nonroot | grep '"Size": '
```

```bash
$ docker inspect demo-app:0.1-scratch | grep '"Size": '
        "Size": 6815744,
$ docker inspect demo-app:0.1-scratch-nonroot | grep '"Size": '
        "Size": 6815791,
```

There is a 47-byte increase in the image. If we had created a user and then copied the **`/etc/passwd`**, the increase would be bigger, and we wanted to build a small image. Let's try and run the image and check if the process is now running with a non-root user:

```bash
docker run -d -p 8080:8080 demo-app:0.1-scratch-nonroo
docker ps
docker container top <name or ID>
```

```bash
$ docker run -d -p 8080:8080 demo-app:0.1-scratch-nonroot
b39b5fb20254a95d6213ce0c9d093420b691c39476a3158de9abfa6b613da0fc
$ docker ps
CONTAINER ID   IMAGE                          COMMAND         CREATED          STATUS          PORTS                    NAMES
b39b5fb20254   demo-app:0.1-scratch-nonroot   "/go/bin/app"   43 seconds ago   Up 43 seconds   0.0.0.0:8080->8080/tcp   sweet_turing
$ docker container top b39b5fb20254
UID                 PID                 PPID                C                   STIME               TTY                 TIME                CMD
10001               10868               10843               0                   14:18               ?                   00:00:00            /go/bin/app
```

So now the process is running with the UID 10001, which is the UID that we specified in the **`/etc/passwd`**. Now we can officially say that we are running with a non-root user. By the way, the username is not shown because our system doesn't know which user it is.

### **And Now?**

"What now?" is always a good question. But now you know how to build a container image with scratch and how to run the process with a non-root user in the smallest possible way from my knowledge. Now, your job is starting, and you have to build images from scratch. If you want to, you could also build a CI pipeline to build your image and then scan it to find out if there are any vulnerabilities. You can find the example code [here](https://github.com/m-over/talk-and-blog-resources).

Sadly, now I have to say goodbye. I hope you enjoyed reading about how to build containers from scratch!