FROM python:latest

ADD ./app.py . 

RUN pip3 install flask
RUN pip3 install requests

EXPOSE 5000

CMD ["python","app.py"]
