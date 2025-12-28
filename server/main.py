# main.py
from fastapi import FastAPI

# Create an instance of the FastAPI class
app = FastAPI(
    title="My First FastAPI App",
    version="1.0.0",
    description="A simple 'Hello, World!' API"
)

# Define a path operation for a GET request to the root URL ("/")
@app.get("/")
def read_root():
    return {"Hello": "World"}
