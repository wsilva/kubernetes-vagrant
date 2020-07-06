kubectl create namespace compose
kubectl -n kube-system create serviceaccount tiller
kubectl -n kube-system create clusterrolebinding tiller --clusterrole cluster-admin --serviceaccount kube-system:tiller
helm init --service-account tiller --override spec.selector.matchLabels.'name'='tiller',spec.selector.matchLabels.'app'='helm' --output yaml | sed 's@apiVersion: extensions/v1beta1@apiVersion: apps/v1@' | kubectl apply -f -
helm install --name etcd-operator --namespace compose stable/etcd-operator --version 0.10.0
kubectl apply -f - << EOF
 apiVersion: "etcd.database.coreos.com/v1beta2"
 kind: "EtcdCluster"
 metadata:
   name: "compose-etcd"
   namespace: "compose"
 spec:
   size: 3
   version: "3.3.15"
EOF
./installer-darwin -namespace=compose -etcd-servers=http://compose-etcd-client:2379 -tag=v0.4.23
