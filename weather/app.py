from flask import Flask
import requests

TICKER_API_URL = "https://api.coindesk.com/v1/bpi/currentprice.json"

app = Flask(__name__, static_url_path='')

@app.route('/', methods=['GET'])
def get_bitcoin_price():
    return get_latest_bitcoin_price()


def get_latest_bitcoin_price():
    response = requests.get(TICKER_API_URL)
    response_json = response.json()
    tmp="bitcoin last price is : "
    return tmp+str(response_json["bpi"]["USD"]["rate_float"]) +" $"

if __name__ == '__main__':
    app.run(host="0.0.0.0",port=5000, debug=True)
