# Usage: sudo docker run --rm recolic/mailbox-cleaner imap.recolic.net ACCOUNT@recolic.net PASSWORD -d 15

FROM python:3.9-slim
RUN pip install mailbox_cleaner
entrypoint ["mailbox-cleaner"]
