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

### Cloud-controller-manager

- Cloud infrastructures technologies allow the kubernetes to run on public, private and hybrid clouds.
-  The cloud-controller-manager is a K8s control plane component that embeds cloud-specific control logic. it allows the linking between your cluster and your cloud provider's API, and separates out the components that interact with the cloud platform from components that only interact wth the cluster. 
- this component is optional and only needed whenn you want your cluster to be integrated with a cloud provider infrastraructure. 

- If you are running k8s on premise or in a self-managed environment, you do not need the cloud-controller-manager

The cloud-controller-manager  runs the following controllers:
- **Node Controller** - checks the cloud provider to determine if a node has been in the cloud provider to determine if a node has been deleted in the cloud after it stops responding 
- *Route Controller* -  sets up routes in the cloud infrastructure so that containers on different nodes can comunicate with each other
- **Service controller** - creates, updates and deletes cloud provider load balancers

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

# kube-proxy

- kube-proxy is a Kubernetes agent installed on every node in the cluster. It monitors changes to Service Objects(services created in kubernetes via CLI) and their endpoints and translates them into actual networks rules inside the node.
- Kube-proxy usually runs in your cluster as a DaemonSet(controller that a node runs to have a copy of a pod), but it can also be installed directly as a linux process on the  node.

- By translating into network rules inside the node, the services can be accesible from inside and outside the cluster. (flexibbility)

# Container  Runtime

- Container runtime is a software that runs the containers and is responsable for managing their lifecicly, including starting, stopping and removing containers.
- K8s relies on a container runtime to run containerized workloads.


```
+---------------------------------------------------------------+
|                        WORKER NODE                            |
|                                                               |
|  +------------------+  +------------------+  +------------+   |
|  |     kubelet      |  |   kube-proxy     |  | Container  |   |
|  |                  |->|                  |  | Runtime    |   |
|  | Manages pod      |  | Manages network  |  | (containerd|   |
|  | lifecycle        |  | rules/iptables   |  |  / CRI-O)  |   |
|  +--------+---------+  +--------+---------+  +-----+------+   |
|           |                     |                  |          |
|           |   instructs         |                  |          |
|           +-------------------------------------------->      |
|           |                     |                             |
|           v                     v                             |
|  +----------------------------------------------------------+ |
|  |                          PODS                            | |
|  |  +-------------------+      +-------------------+        | |
|  |  |       POD 1       |      |       POD 2       |        | |
|  |  |   IP: 10.0.0.4    |      |   IP: 10.0.0.5    |        | |
|  |  |                   |      |                   |        | |
|  |  | +--------------+  |      | +--------------+  |        | |
|  |  | | Container A  |  |      | | Container C  |  |        | |
|  |  | | (app)        |  |      | | (app)        |  |        | |
|  |  | +--------------+  |      | +--------------+  |        | |
|  |  | +--------------+  |      +-------------------+        | |
|  |  | | Container B  |  |                                   | |
|  |  | | (sidecar)    |  |      +-------------------+        | |
|  |  | +--------------+  |      |       POD 3       |        | |
|  |  |                   |      |   IP: 10.0.0.6    |        | |
|  |  | Shared: /data     |      |                   |        | |
|  |  |         /logs     |      | +--------------+  |        | |
|  |  +-------------------+      | | Container D  |  |        | |
|  |                             | | (app)        |  |        | |
|  |                             | +--------------+  |        | |
|  |                             +-------------------+        | |
|  +----------------------------------------------------------+ |
|                                                               |
+---------------------------------------------------------------+
          ^
          |
   [ Control Plane ]
   (API Server, Scheduler,
    Controller Manager)

```

# Some concepts needed to understand k8s.

## Node

A kubernetes node is each of the interconnected machines, physical or virtual, that works together as the kubernetes cluster. 

the world node usually is used to refer to a working node. the control plane runs in a node tecnically, but to avoid confusion. The control plane is refered as the  "master node" and the rest(worker nodes) are refered as nodes.

## Pod

Pods is the smallest type of Object you can deploy inside a Kubernetes cluster. They are the fundamental building blocks of a K8s workloads. 

A Pod is one or more containers that share storage and network resources.
In other words K8s Pods is a set of containers that perform an interrealted functino and that operate as part of the same workload.

To define a simple Pod, here is a simple Kubernetes Pod YAML example:
	
	apiVersion: v1
	kind: Pod
	metadata:
 	 name: nginx
	spec:
 	 containers:
 	 - name: nginx
       image: nginx:1.14.2
       ports:
       - containerPort: 80Code language: CSS (css)


## Controller
A controller is a loop that monitors the state of the cluster and actively makes or request changes where its needed 

--- 
---

# K3s
Now that we saw a little about k8s, we are ready to talk about K3s

## what is k3s

- k3s is a lightweight kubernetes distribution optimized for low resource consumption. It was created for scenarios such as Edge Computing, IoT devices, and other small-scale environments. It includes the core Kubernetes features but in a leaner, more optimized version, allowing it to run even on low-powered devices.

- K3s also abandon a lot of optional features to optimize the kubernetes eficience.

### Advantages

	- Minimal resource consumption  - can run on devices like raspBerry PI and single-board computers
	- Extremely simple installation - often just a single command to get the cluster running
	- Fully compatible with kubernetes - use existing tools, API's and workflows without adjustments
	- Ideal for IoT, Edge, and test environments
	- Automated updates and maintenance
### Disadvantages
	- Limited scalability for every large clusters
	- Missing some enterprise-level features and integrations
	- SQLite becomes insufficient quickly inder higher loads
	- Some cloud-native add-ons and tools work in a limited way
	- May require manual tunning in high-performance scenarios


# K3s architecture

k3s architecture is very similar to the one of k8s.
K3s just tries to cut in resources and use simple ways to achieve k8s objectives.

K3s is separated by 2 main nodes.

The K3s Server(Master Node)  and the K3s Agent(Worker Node)


K3s server and the K8s master node are very similar:
K3s has 3 diferent components if we compare it with K8s
*Like*:
- Kine
- Tunnel Proxy
- Flanel

## KINE:

- It does not have etcd; instead it uses SQLite, a much simpler relational database. However, since etcd comunicates using **etcd gRPC API** while SQLite uses **SQL**, Kine acts as the intermediary to translate everything so that SQLite receives the correct data.
- Kine is an etcd shim built into K3s. a Shim in computer science is a small library that intercepts requests and modifies or redirects without being seen.
- Kine implements the etcd API, so that the K3s components think that they are talking to the etcd as always, and on the other side kine translates those calls into SQL queries that SQLite can understand.
- SQLite is only suitable for single-node setups. For high-availability K3s clusters, external databases like PostgreSQL , MySQL or even etcd are way better.

```
┌──────────────────────────────────────────────────────────┐
│                  K3s SERVER (Master Node)                │
│                                                          │
│  ┌─────────────┐  ┌───────────┐  ┌────────────────────┐  │
│  │  API Server │  │ Scheduler │  │ Controller Manager │  │
│  └──────┬──────┘  └───────────┘  └────────────────────┘  │
│         │                                                │
│         │  "hey etcd, store this!"                       │
│         ▼                                                │
│  ┌──────────────────────────────────────────────────┐    │
│  │                KINE  (etcd shim)                 │    │
│  │                                                  │    │
│  │  receives etcd API calls  ──►  translates to SQL │    │
│  └───────────────────────────────────┬──────────────┘    │
│                                      │                   │
│                                      ▼                   │
│                             ┌─────────────────┐          │
│                             │     SQLite      │          │
│                             │   (database)    │          │
│                             └─────────────────┘          │
└──────────────────────────────────────────────────────────┘
                            |
                            │ manages
                            ▼
┌──────────────────────────────────────────────────────────┐
│                  K3s AGENT (Worker Node)                 │
|                           (...)                          |
└──────────────────────────────────────────────────────────┘

```

## TUNEL PROXY

- in K8s, the protocol used to make the comuniation between master node and worker node is via *K8 Konnectivity*(default).
- Tunnel Proxy is good because it facilitates the comunication between server and agents that are behind firewalls and NAT(Network Address Translation)
- Without tunnel proxy the agent had to have the port always open so that it could communicate with the server(that would never happen, so the servwr could never reach it).
- K3s was created to handle IoT(Internet Of Things) and edge(is a distributed computing model that tries to bring computation and data storage closer to the source of data)
- K3s is used to reduce the need of central data centers.
- the clusters in real life cases are usually physically remote, so that tunnel proxy is needed to maintain the comunication between the node workers that are behind NAT/Firewalls and the Server Node .
-  Tunnel proxy tries to make a comunication to the K3s Server, and tells the server that if it whants to comunicate with the worker, it will have to use the same line that the tunnel proxy opened to talk to the server. -> this works because the agent is the one starting the connection, and that connectionstays open. that way the server is able to send watever it needs