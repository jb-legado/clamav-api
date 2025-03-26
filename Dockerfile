# ---- Stage 1: Build the Go binary ----
    FROM golang:1.21 AS builder

    # Set working directory inside container
    WORKDIR /app
    
    # Copy Go modules first (for caching)
    COPY go.mod ./
    RUN go mod download
    
    # Copy the entire source code
    COPY . .
    
    # Build the binary (same flags as in build.sh)
    RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o clamav-api .
    
    # ---- Stage 2: Final image with ClamAV and your app ----
    FROM clamav/clamav
    
    # Create folders ClamAV expects
    RUN mkdir -p /root/uploads && mkdir -p /run/lock
    
    # Run initial virus DB update
    RUN freshclam
    
    # Copy the compiled Go binary from the builder stage
    COPY --from=builder /app/clamav-api /
    
    # Expose the API port
    EXPOSE 8080
    
    # Run the app
    CMD ["/clamav-api"]
    