# Build the custom image
```bash
docker build -t redis-optimal .
```

# Run
```bash
docker run -d --name redis-optimal \
  -p 6379:6379 -p 8001:8001 \
  redis-optimal
```

# Stop

```bash
docker stop redis-optimal
docker rm -f redis-optimal
```

# Exporting redis content to a file

E.g we want to export Redis' content to a `dump.rb` file:

```bash
docker cp <container_name_or_id>:/data/dump.rdb ./dump.rdb
```

