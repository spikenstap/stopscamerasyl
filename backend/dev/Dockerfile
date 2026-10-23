FROM python:3.12-slim
RUN apt-get update && apt-get install -y --no-install-recommends openssl && rm -rf /var/lib/apt/lists/* && useradd --system --uid 10001 mock && mkdir /certs && chown mock /certs
WORKDIR /mock
COPY server.py entrypoint.sh ./
RUN chmod 755 entrypoint.sh
USER mock
EXPOSE 8443
CMD ["sh", "./entrypoint.sh"]

