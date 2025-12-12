# sudo docker build -t recolic/ethsign-parse .
# docker run -d --restart always --log-opt max-size=10M --name ethsign -p 3084:8080 recolic/ethsign-parse
FROM python:3.11-slim
RUN pip install --no-cache-dir cbor2 web3
ADD . /app
EXPOSE 8080
workdir /app
CMD ["python3", "main.py"]

