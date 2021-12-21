#!/usr/bin/env python
# coding=utf-8

from flask import Flask
from flask import make_response

import os
import json
from werkzeug.exceptions import NotFound

file_dirname = os.path.dirname(os.path.realpath(__file__))
app = Flask(__name__)

with open(os.path.join(file_dirname, "..", "data", "things.json"), "r") as f:
    things = json.load(f)


@app.route("/", methods=['GET'])
def index():
    return pretty_json({
        "resources": {
            "things": "/things",
            "thing": "/things/<thing>",
        },
        "current_uri": "/"
    })


@app.route("/things", methods=['GET'])
def all_things():
    return pretty_json(things)


@app.route("/things/<thing>", methods=['GET'])
def thing_data(thing):
    if thing not in things:
        raise NotFound

    return pretty_json(things[thing])


@app.route("/things/<thing>/something", methods=['GET'])
def thing_something(thing):
    raise NotImplementedError()


def pretty_json(arg):
    response = make_response(json.dumps(arg, sort_keys=True, indent=4))
    response.headers['Content-type'] = "application/json"
    return response


if __name__ == "__main__":
    print("starting server...")
    app.run(port=5000)
