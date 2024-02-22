package main

import (
  "fmt"
  "io"
  "net/http"
)

func main() {
  mux := http.NewServeMux()
  mux.HandleFunc("GET /hello", func(w http.ResponseWriter, r *http.Request) {
    io.WriteString(w, "Hello!\n")
  })
  mux.HandleFunc("GET /bye", func(w http.ResponseWriter, r *http.Request) {
    io.WriteString(w, "Bye!\n")
  })

  fmt.Println("Starting server on port 8080")
  http.ListenAndServe(":8080", mux)

}
