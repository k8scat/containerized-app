FROM golang:1.15.5

LABEL maintainer="K8sCat <k8scat@gmail.com>"
LABEL version="1.0.0"

EXPOSE 4182

ENV GOPROXY=https://goproxy.cn,direct \
    GO111MODULE=on

WORKDIR /go/src/github.com/k8scat/containerized-app/api

COPY . .

RUN go mod download && \
go build -o api main.go && \
chmod +x api

ENTRYPOINT [ "./api" ]
