```sh
docker build -t fib-cpu:latest .

docker run -p 8080:8080 fib-cpu:latest

curl "http://localhost:8080/fib?n=30"
# {
#   "n": 30,
#   "result": 832040,
#   "duration_seconds": 0.72
# }

```

Push to ECR
```sh
# create an ECR repository:
aws ecr create-repository \
  --repository-name fib-cpu \
  --region AWS_REGION

BASE_ECR=${AWS_ACC_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

aws ecr get-login-password \
  --region $AWS_REGION \
| docker login \
  --username AWS \
  --password-stdin ${AWS_ACC_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com


# tag the image
docker tag fib-cpu:latest $BASE_ECR/fib-cpu:latest

docker push $BASE_ECR/fib-cpu:latest

```