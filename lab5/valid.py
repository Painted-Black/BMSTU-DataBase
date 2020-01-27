import sys
import jsonschema
from jsonschema import validate
import json

def report(err):
    f = open("log_err.txt", "w")
    f.write(err)
    f.close()

n = len(sys.argv)

if n > 1 and n < 4:
    data_file = sys.argv[1]
    schema_file = sys.argv[2]
else:
    data_file = "doctors2.json"
    schema_file = "schema1.json"

try:
    with open(data_file, "r") as read_file:
        data = json.load(read_file)
except Exception as err:
    print("Something went wrong with data file: ", data_file)
    report(str(err))
    exit()

try:
    with open(schema_file, "r") as read_schema:
        schema = json.load(read_schema)
except Exception as err:
    print("Something went wrong with schema_file: ", schema_file)
    report(str(err))
    exit()

print("Validating the input data using JSON-schema:")
try:
    validate(instance=data, schema=schema)
    print("Correct data")
except jsonschema.exceptions.ValidationError as ve:
    print("ERROR!")
    report(str(ve))
