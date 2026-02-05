from flask import Flask, request, jsonify
import time

app = Flask(__name__)

def fib(n: int) -> int:
    if n <= 1:
        return n
    return fib(n - 1) + fib(n - 2)

@app.route("/fib")
def fibonacci():
    n = int(request.args.get("n", 30))

    start = time.time()
    result = fib(n)
    duration = time.time() - start

    return jsonify({
        "n": n,
        "result": result,
        "duration_seconds": round(duration, 3)
    })

@app.route("/healthz")
def health():
    return "ok", 200

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
