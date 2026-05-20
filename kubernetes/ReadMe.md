# Inception-of-Things

Inception-of-Things is a project of the Outer-Core 42 School that teach us the basics of System Administration 

## In the future modules we will make use of:

- Vagrant
- K3s
- K3d
- Ingress
- Argo CD

# Kubernetes

The main tool in this project is Kubernetes.

## What is Kubernetes

Kubernetes is an open-source container orchestration system for automating software deplyoment, scaling, and management of containerized applications (microservices).

The reason why kubernetes exist is because managing containers at scale manually became very exausting.
K8s offers a centralized management solution for containers, allowing administrators to manage thousands of containers and VM's as a single unified entity.

# K8S Arquitecture

In a K8s cluster, the architecture is organized into two main components:
- ### control Plane 
- ### Worker nodes

---

### Control Plane

The control Plane is the Brain of the k8s cluster, it acts as the central management hub for the entire k8s cluster
It maintain the order and checks for the health of every service related to the cluster.

It maintain the desired state of the cluster, in other words, it's continuously comparing the actual state of the cluster with the intended state.

If the number of pods working are differents from the desired number defined, the control plane will take corrective actions, like starting a new pod or stop extra ones.

It also manages configurations for the applications/services inside the cluster, storing this information in a consistent manner to ensure reliability and reproducibility

# Components of the Control Plane

### kube-api server

- kube-api server is the main component of the K8s control plane.
it is responsablee for managing communications within the cluster

- Centralizes control over the entire cluster (all cluster operations funnel through the API server, eliminating confusion and redundancy)

- It is a Primary management component

- Its provides to users and internal components a  RESTful API as the single entry point for managing k8s resources (pods, Services, Deployments) 

- Allow users and components to fully manage Kuberbenetes resources(Read, Write, Create, Delete)

#### Key feature of kube-api server

- RESTful API Interface: The API server exposes a RESTfull API  so that anything that needs to communicate to the cluster, like kubectl(our terminal tool), a web dashboard, or CI/CD pipelines(such as Argo CD) interact through this interface 

- Authentication and Authorization: Security is a fundamental part of the cluster. Every step is authenticated by tokens, certificates, or other methods, and authorized through role-based access control (RBAC) to ensure actions being executed with the right permitions.

- State Management: The kube-api server comunicates with the etcd(kubernetes Key-Value store), to read and write the cluster state. This ensures that the desired configurations are reflected accurately in the running environment.

- Extensibility: By supporting CRD's(Custom Resource Definitions) and aggregated API's, The kube-api server allows the user to add custom resources and extend the kubernetes cluster capabilities without modifying its core.

- Communication Gateway: Acts as the central communication hub of the cluster. All the components, in order to communicate with each other, pass through the api server. and that information is stored in the etcd. That way the actions within the cluster are well coordinated and traceable.

- Admission Control: is a piece of code that sits between Authentication/Authorizaation and etcd.
Its job is to intercept incoming requesrs, validate their values, and enforce policies defined by cluster administrators.

Admission controller is divided into 2 types:

- The mutating Controller(first to run) - has permission to modify that incoming request if any value is missing or incorrectly set. For example, by injecting default values that the user didnt provide.
- The Validating Controller(second to run) - This one can ONLY accept or reject requests vased on the cluster policies. It cannot modify anything. For example, by rejecting a Pod whose image comes from an untrusted registry.

If the Validating Controller accepts the request, the action is written to etcd and the cluster acts on it. If it rejects it, the request never reaches etcd and an error is returned to the user.

## Visual Representation of Admission Controllers in the Control Plane

```
           User request
	            │
	            ▼
     Authentication (Who are you?)
	            │
               	▼
     Authorization (Are you allowed?)
	            │
	            ▼
 ┌─────────────────────────────┐
 │     Admission Control       │
 │ ┌─────────────────────────┐ │
 │ │ Mutating Controller     │ │
 │ │ (modifies request       │ │
 | |      if needed,         | |
 │ │   injects defaults)     │ │
 │ └─────────────┬───────────┘ │
 │               │             │
 │ ┌─────────────▼───────────┐ │
 │ │ Validating Controller   │ │
 │ │ (accepts or rejects     │ │
 │ │ request)                │ │
 │ └─────────────┬───────────┘ │
 └───────────────┼─────────────┘
			     │
        ┌────────┴─────────┐
	    ▼                  ▼
 etcd (state saved)   Error returned to user
```


### etcd


- etcd is a strongly , distributed key-value store(NoSQL)  that provides a reliable way to store data that needs to be accessed by a distributed system or cluster of machines.

- etcd works as the database where kubernetes store all cluster data, serving as the API server backend

- it maintain the  current status, desired state. configuration and metadata for all kubernetes objects

#### what type of info it stores?

- Cluster Configuration and Metadata: Nodes, Namespaces, Rescource Quotas, Cluster Roles and Role Bindings(RBAC)
- Workloads: Pods, Deployments, ReplicaSets, DaemonSets, Statefulsets, Jobs and Cronjobs
- Services and Networking: Services, Endpoints, Ingress, Network Policies and ConfigMaps.
- Persistent Storage: Persistent Volumes (PVs), Persistent Volume Claims (PVCs), and Storage Classes.
- Schedulers and Controllers: Controllers, Events, Scheduler Info.
- Custom Resource Definitions(CRDs)
- Admission Controllers: Admission Webhooks
- Autocaling Data: Horizontal Pod Autoscalers(HPA)
- API Server Configuration: API Server Discovery Info
- Federated Resources

### diagram for etcd
```
                ┌─────────────────────────────┐
                │      kube-apiserver         │
                └─────────────┬───────────────┘
                              │
         Reads/Writes cluster state (all changes go through here)
                              │
                ┌─────────────▼───────────────┐
                │           etcd              │
                │  (Key-Value Data Store)     │
                │  - Stores all cluster data  │
                │  - Source of truth          │
                │  - Highly available         │
                └─────────────┬───────────────┘
                              │
         ┌────────────────────┴────────────────────┐
         │                                         │
  Control Plane components                  Recovery/Backup
  (Scheduler, Controller Manager,           (Restores cluster state
   etc.) read from etcd to know              from etcd data)
   the current state
```

### kube-controller-manager

The kube-controller-manager is a daemon in the kubernetes cluster, actring as a control center for maintaining the desired state of the cluster.
Its a long-running process that orchestrates multiple controllers, each dedicated to specific tasks.

#### main Responsabilities
- Continuous Monitoring: Kube-controller-manager constantly monitors the cluster strate through  the kubernetes API server, This includes tracking the current configuration of Pods, Deployment, Services and other resources.
- State Reconciliation: By comparing the desited state(as defined in kubernetes Manifest, aka YAML) with the actual state, the controller manager identifies anty descrepancies.
- Corrective Actions: When deviations are detected, the appropriate controllers take actions to correct the situation and bring the cluster back to the desired state. Such actions can involve scaling Pods, restarting falied containers, or recreating resources as needed.
  

## Key Responsibilities:

- Continuous Monitoring: kube-controller-manager constantly monitors the cluster’s state through the Kubernetes API server. This includes tracking the current -  configuration of Pods, Deployments, Services, and other resources.
-    State Reconciliation: By comparing the desired state (as defined in Kubernetes manifests) with the actual state, the controller manager identifies any discrepancies.
-   Corrective Actions: When deviations are detected, the appropriate controllers take action to rectify the situation and bring the cluster back to its desired state. This might involve scaling Pods, restarting failed containers, or recreating resources as needed.

#### Embedded Controllers inside of the kube-controller-manager:
Each one of this controllers is responsable for a specific aspect of the cluster management.

- Replication Controller: Ensures the desired number of Pods replicas are running for Deployment or ReplicaSets
- Endpoints Controller  : Maintain an endpoint Object for each Service, reflecting the current set of Pods that back that Service
- NameSpace Controller  : Creates and manages Kubernetes namespaces, providing a way to isolate resources.
- Service Account Controller: Creates and manages Service Acccounts user for Pod Authentication and Authorization.
- Node Controller : Tracks the health and availability of Nodes in the Cluster
- Token Controller: Responsable for issuing authentication tokens for serrvice accounts.
- Lease Controller: Enforces leasing mechanisms for certain resources to prevent conflicts and maintain coordination

### kube-scheduler

- kube-scheduler is a controll plane process that assigns Pods to Nodes. The scheduler determines which Nodes are valid placements for each Pods in the scheduling queue according to constraints and available resources. 
- The scheduler filters out nodes that do not meet the pods requeriemnts(e.g. resource limits)
- The remaining nodes are ranked based on various factors(its implemented a function that ranks the nodes by score depending on the resource availability from 0 to 10)
- Multiple different schedulers may be used within a cluster. 


The Kubernetes scheduler is a control plane process which assigns Pods to Nodes. The scheduler determines which Nodes are valid placements for each Pod in the scheduling queue according to constraints and available resources. The scheduler then ranks each valid Node and binds the Pod to a suitable Node. Multiple different schedulers may be used within a cluster.


# Worker Nodes

- Worker nodes are where the actual application run, like the name says, they are the "Workers"
- Each Worker node is managed by the control plane and run the Services needed to execute and manage the containerized applications.
- They provide the necesary resources, like CPU, memory, Storage, for executing these application.
- Worker nodes provide isolation between each application and workload, that way it is ensuring that one workload does not interfere with another one.
- The worker nodes also implement to itself security measurtes to protect the applications running on themselfs.


# Components of the Worker Node

The Worker Node has several key components, such as:

- kubelet
- kube-proxy
- Container Runtime

## kubelet

kubelet is the main Kubernetes agent that runs on each Worker Node.
kubelet is the main component that is responsable for managing the lifecycle of containers.
It comunicates with the Kubernetes kube-api server to ensure that the containers are running as expected and reports back any issues or changes that occur.

### how does kubelet work

Kubelet recieves a PodSpec(Pod Specification) from the kube-api server, which contains information about the containers that should run on the node.
Kubelet then ensures that these containers are running and are healthy by monitoring their status and responding appropriately to any issue that arise.

Kubelet is also responsable for reporting back node-level metrics such as CPU and memory usage to the kube-api server. This information is used by the kube-scheduler to manage decisions about new Pods and its management.

kubelet also allows kubernetes so scale Horizontally by adding or removing containers as demands fluctuates.

## Kubelet Responsabilities:

registering the node with the cluster, when a new Worker Node joins the cluster, kubelets helps

## kube-proxy

- kube-proxy is a Kubernetes agent installed on every node in the cluster. It monitors changes to Service Objects and their endpoints and translates them into actual networks rules inside the node.
- Kube-proxy usually runs in your cluster as a DaemonSet(controller that a node runs a copy of a pod)



What is Kube-Proxy

Kube-Proxy is a Kubernetes agent installed on every node in the cluster. It monitors changes to Service objects and their endpoints and translates them into actual network rules inside the node.

Kube-Proxy usually runs in your cluster as a DaemonSet, but it can also be installed directly as a Linux process on the node.

If you use kubeadm, it will install Kube-Proxy as a DaemonSet. If you manually install the cluster components using official Linux tarball binaries, it will run directly as a process on the node.