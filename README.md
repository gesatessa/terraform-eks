

```sh
# Configure kubectl for your EKS cluster:
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

# verify access
kubectl cluster-info
# ✅ You should see the Kubernetes control plane endpoint
# ❌ If this fails → IAM permissions or wrong cluster name

# Kubernetes control plane is running at https://0CC21F57C00D1011EB890146FCE985AD.gr7.us-east-1.eks.amazonaws.com
nslookup 0CC21F57C00D1011EB890146FCE985AD.gr7.us-east-1.eks.amazonaws.com
dig 0CC21F57C00D1011EB890146FCE985AD.gr7.us-east-1.eks.amazonaws.com


# verify nodes are joining the cluster
kubectl get nodes


kubectl get pods -n kube-system
# you should see:
# aws-node-* (CNI)
# kube-proxy-*
# coredns-* (#nodes replicas)

# If CoreDNS is Pending → subnet or security group issue.
```

### deploy a test application

```sh
kubectl create deployment nginx --image=nginx
kubectl get pods

# expose it:
kubectl expose deployment nginx \
  --port=80 \
  --type=ClusterIP

# test from inside the cluster:
kubectl run test \
  --image=busybox \
  -it --rm --restart=Never \
  -- wget -qO- nginx

# If you see HTML output → ✅ pod networking works
```

Test internet access from pods (important for NAT):

Your nodes are in private subnets, so this confirms:
- NAT Gateway works
- Route tables are correct

```sh
kubectl run nettest \
  --image=busybox \
  -it --rm --restart=Never \
  -- wget -qO- https://example.com

```


Test LB:
```sh
kubectl expose deployment nginx \
  --type=LoadBalancer \
  --name=nginx-lb \
  --port=80

kubectl get svc nginx-lb

# nslookup a429ef696ad754f5e851eaf259e3a815-1732318875.us-east-1.elb.amazonaws.com
# curl a429ef696ad754f5e851eaf259e3a815-1732318875.us-east-1.elb.amazonaws.com
# If this works → your EKS is production-capable

sudo yum install -y unzip git
curl -o kubectl https://s3.us-west-2.amazonaws.com/amazon-eks/1.33.0/2024-01-04/bin/linux/amd64/kubectl
chmod +x kubectl
sudo mv kubectl /usr/local/bin/


# verify 
aws sts get-caller-identity

```
## CA

```sh
# to get the latest addonVersion for "aws_eks_addon":
aws eks describe-addon-versions --region us-east-1 --addon-name eks-pod-identity-agent

```

How to find the latest chart version (correct way)
```sh
helm repo add autoscaler https://kubernetes.github.io/autoscaler
helm repo update
helm search repo autoscaler/cluster-autoscaler --versions

```

```sh
# verify that the ca pods are deployed with success.
kubectl get pods -n kube-system 


# check the logs
kubectl logs -l app.kubernetes.io/instance=autoscaler -f -n kube-system


kubectl get pods -n kube-system | grep auto

k logs -n kube-system cluster-autoscaler-aws-cluster-autoscaler-697df8669b-pd6n4 | grep "not auth"
k logs -n kube-system cluster-autoscaler-aws-cluster-autoscaler-697df8669b-pd6n4 | grep AccessDeniedException
k logs -n kube-system cluster-autoscaler-aws-cluster-autoscaler-697df8669b-pd6n4 | grep Failed

```

```sh

```

## HPA

```sh
# verify the metrics-server is up & running:
kubectl get pods -n kube-system
## metrics-server-94659cc9d-sh424   1/1     Running   0          2m7s

# check the logs to make sure there's no error
kubectl logs -l app.kubernetes.io/instance=metrics-server -f -n kube-system

kubectl top pods -n kube-system
# NAME                             CPU(cores)   MEMORY(bytes)   
# aws-node-ffbpl                   2m           37Mi            
# aws-node-tl669                   3m           52Mi            
# coredns-5d849c4789-2lcdq         2m           13Mi            
# coredns-5d849c4789-7vpvj         1m           13Mi            
# kube-proxy-bckck                 1m           12Mi            
# kube-proxy-hlwvx                 1m           11Mi            
# metrics-server-94659cc9d-sh424   3m           19Mi
```

Apply resources
```sh
kubectl apply -f ./manifests/hpa

# watch -t kubectl get hpa -n hpa-example
kubectl get hpa hpa-demo -n hpa-example -w
# NAME       REFERENCE             TARGETS                                     MINPODS   MAXPODS   REPLICAS   AGE
# hpa-demo   Deployment/hpa-demo   cpu: <unknown>/50%, memory: <unknown>/50%   2         10        0          5s

kgp -n hpa-example -w

kubectl port-forward -n hpa-example svc/hpa-demo 8080:80

curl "http://${EXT_IP}:8080/api/cpu?index=44"


kubectl top pods -n hpa-example


# delete the resources
kubectl delete ns hpa-example
```




## IAM

a dev can only work in namespace dev-ns



## MiSC
```sh
terraform cancel


kubectl get events --sort-by=.metadata.creationTimestamp
```

add ons:
```sh
 aws eks list-addons --cluster-name $CLUSTER_NAME
# {
#     "addons": [
#         "aws-ebs-csi-driver",
#         "eks-pod-identity-agent"
#     ]
# }
```

