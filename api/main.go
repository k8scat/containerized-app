package main

import (
	"github.com/k8scat/containerized-app/api/router"
)

var (
	port int
)

func main() {
	router.Run("0.0.0.0:4182")
}
