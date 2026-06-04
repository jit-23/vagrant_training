# Service YAML

--- 
> service yaml is a type of file that declares a Service, that selects a set of associated Pods and gives them a single, stable IP and DNS name. 
> Clients use that one address instead of talking to individual Pods, and the  Service load-balances requests across them. By default the IP is internal to the cluster.
> NodePort or LoadBalancer types expose it externally.
> The service finds its Pods through a label selector that matches the pod labels. That's the link between the Service and the Pods.

