FROM python:3-alpine

WORKDIR /app

COPY ../../requirements.txt .

RUN apk add --update --no-cache gcc libc-dev libffi-dev
RUN pip3 install -r /app/requirements.txt

CMD ["python", "-u", "/app/main.py"]
