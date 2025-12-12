FROM python:3.11-slim
RUN pip install --no-cache-dir cbor2 web3
ADD . /app
EXPOSE 8080
workdir /app
CMD ["python3", "main.py"]

