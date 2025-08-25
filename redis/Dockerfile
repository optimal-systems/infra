FROM redis/redis-stack:7.2.0-v18

# Accept terms and conditions
ENV RI_ACCEPT_TERMS_AND_CONDITIONS=true

# Create redis user and necessary directories for RedisInsight
USER root
RUN adduser --system --group --no-create-home redis
RUN mkdir -p /redisinsight/logs /redisinsight/data
RUN chown -R redis:redis /redisinsight
RUN chown -R redis:redis /data

# Switch to non-root user
USER redis

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD redis-cli ping || exit 1