# System design  
System Design is the process of understanding a system's requirements and creating an infrastructute to satisfy them

# Important topics about System Design:

## Functional and Non Functional Requirements

### Functional Requirements

* These are the requirements that **define what a system is suposed to do**.
They describe the various functions that the system must perfurm.

For example: 
- A user Authentication system mmust validate user credentials and provide access levels.
- An e-commerce website should allow users to browser products, add them to a cart, and complete purchases
- A report generation system must collect data, process it and generate timely reports

### Importance in Interviews
- Demonstrates Understanding of Core Features: Show that you know what the sysyem needs to do to satisfy its primary objectives
- Basis for System Design: Functional requirements often form the backbone of your system design 

### Non-Functional Requirements

- These requirements describe **how the system performs a task**, rather than what tasks performs. They are realted to the equity attributes of the system.

For example:
- Scalability : The system should handle grouwth in users or data
- Performance : The system should process transactions within a specified time
- Availability: The system should be up and running a defined percentage of time
- Security    : The system must protect senstive data and resisty unauthorized access

### Importance in interviews
- Showcases Depts of Design Knowledge: Demonstrates your understanding of the broader implications of system design
- Highlights System Robustness and Quality: Reflects how well your system design can meet real-world constraints and user expectatinos

https://www.designgurus.io/course-play/grokking-the-system-design-interview/doc/functional-vs-nonfunctional-requirements?gad_source=1&gad_campaignid=23163907085&gclid=Cj0KCQjwo_PRBhDNARIsAEcVALVXXcDR2KfhN21q7g9HkYVEQfEcWZNrAffY3__luWTx0b0Q_cx6q0IaAhDREALw_wcB

---

## Capacity Estimation

Capacity estimation in systems design is the process of predicting or determining the maximum load or demand that a system can handle within its operational parameters. This involves analyzing various aspects such as hardware capabilities, software performance, network bandwidth, and user behavior patterns. 

### factors that affect Capacity Estimation

- Hardware Resources
- Software Efficienty
- Workload Characteristics
- User Behaviour
- Scalability
- Performance Metrics
- Failure Scenarios

### Metrics for Capacity Estimation

- Daily Active Users(DAU)
- Queries Per Second(QPS)
- Storage Requirements
- Error Rates
- Response Time
- Concurrency
- Peak Load Handling

## Usage of relational and/or NoSQL databases

### Chose SQL if:

- Data Integrity is critical, per example for financial transactions, inventory managements, and accounting systems where "eventual" consistency is unacceptable
- SQL structure is clear and has a stable schema
- You need to perform complex JOINs across multiple tables to generate reports

### Chose SQL if:

- Speed and Scale are  critical: if the need to have single-digit latency and potentially unlimited throughput(throughput == lots of work) (e.g. gaming IoT etc)
- You aare storing data streams, logs, or social media feeds where the format changes constantly
- You are building a startup app and the data model evolves daily

## Vertical scaling, horizontal scaling, sharding

### Vertical scaling 
- It means to upgrade a single server capacity via Hardware(CPU/RAM)

### Horizontal scaling
- It means to add more machines(either phisical or virtual) to distribute the load

### Sharding
- is a specific type of horizontal scaling where a large database is split into smaller independent pieces called "shards" and distributed across multiple servers

## load balancer

A load balancer is a networking device or software applicatino that  distributes and balances the incoming traffic among the servers to provide high availability, efficient utilization of servers and high performance

Ensures that no single server bears too many requests, which helps improve the performance, reliability and availability of applications.

Hightly used in cloud computiong domains, data centerrs and large-scale web applications where traffic flow needs to ve managed

## Database Replication in System Design 
- Making and Keeping duplicate copies of a database in other servers is known as database replication. It is essential for improving modern systems scalability, reliability, and data availability

## Cache and CDN 

### Cache

Cache memory is a small, high-speed storage area in a computer. It stores copies of the data from frequently used main memory locations. There are various independnent caches in a CPU, which sotre instructions and data

- The most important use of cache is that it is used to reduce the average time to access data from the main memory
- The concept of cache works because there exist ***locality of reference*** in processes

### Locality of reference

The CPU performance is limited by slower main memory acess. Cache memory imporves speed by storing frequently used data and instructions. 

### CDN

- CDN(Content Dellivery Network) is a distributed network of servers designed to improve the speed, availability, scalability and reliability of content delivery
- its servers  work together to deliver content to users faster and more efficiently
- This servers, called edge servers, are strategically positioned across various geographical locations
- Helps improve the performance , reliability and scalabilityof websites and applications by caching content closer to users, reducing latency and offloading traffic from origin servers.

## Stateful and Stateless servers

- Stateful   : Server stores session data across multiple requests
- Stateless  : Each request us independent with no stored session
- Usage 	 : Stateless is preferred for scalable and distributed systems	 


###  Stateful Architecture
The server maintains the state or session information of each client. This means that the server keeps track of the clients data and context throught multiple interactions or requests
- Often involve storing session data in server memory, databases, or other storage mechanisms
- Examples: traditional web apps that use server-side sessions to store data or shopping cart contents

### Benefits of Stateful architecture
- Session Persistence : Maintains user sessions, allowing smooth transitions across steps or devices.
- Efficient Resource User: Stores session data on the server, reducing repeated transfers and processing
- Personalization : Uses past interaction to deliver tailored experiennces, like recomendations
- Enhances Security : Centralized session maagement supports strong authenticatino and encryptino
### Benefits of stateless Architecture
- High Scalability : Easily handles large number of requests without session management
- Fault Tolerance : Each request is independent, so failure in one area wotn affect others
- Simplified Load Balancing: Request can be evenly distributed without sticky sessions(grouping all users request to one server)


### Stateless Architecture
The server does not store any client information between requests. Each request from the client is treated as ana independent transaction
- To maintain user sessions, stateless architectures often use technique like JWT, or client-side cookies to store session data
- Designed to be more scalable and fault0tolenrant because they do not require server resources to maintain cleint state
- Examples include RESTful APIs, where each request contains all the necessary information for the server to rpocess it independently

## Pub/Sub Architecture
The pub/sub architecture is a messaging patterns designed for asynchronous communication between disparate components or systems.

--- 
# Monolithic vs Microservices Architecture

## Monolithic Architecture
Monolithic architecture is a traditional software architecture where all aplication components, such as the UI, business logic, data access layer, are developed and deployed as a single applicatino. This approach is simple to build and amange for small to medium-size applicatinos

- all applicatrion modules are maintained within one project
- The entire applicatino is typically deployed as one package
- Development, testing, and deployment are managed from a single application
- Modules are closely connected, making changes more challenging as the application grows.


## MicroServices Architecture
Microservices Architecture is a software design approach in which an application is divided into multiple small, independent services. Each service focuses on a specific business capability and communicates with other  services through lightweight API`s or messaging systems
- Each service handles a specifitc business functionality
- Services  operate independently and communicate thought API's or message brokers.
- Individual services can be deployed without affecting other services
- Services can be scaled based on their specific workload and requirements
- Different services can use different  technologies, databases, or programming languages


## terraform 

Terraform, developed by HashiCorp, is an industry-standard Infrastructure as Code (IaC) tool used to build, modify, and manage infrastructures safely and efficiently
- Automates infractrustures provisioning instead of manual console configuration
- Enables version conntrol, collaboration, and repeatable deployments
- Reduce human erros while improving scalability and consistency

IaC is the practice of managing IT infrastruxturee using conf files rather  than manual, interactive config tools.


### Terraform is:

- Declarative : You Tell terraform what you whant (ex: I want 3 servers), and Terraform figured out  how to create them
- Versino Controlled: You can track the kistory of your infrastructure changes just like application code

### Terraform is:

- Cloud Agnostic - Terraform works with any cloud provider
- Immutable Infrastructuree -  Terraform typically replaces servers rather than changoing them, reducing "cconfiguration drift"(where servers become inconsistent over time)
- State Management:  Terraform keeps track of your real-world resources in a state file, action as the "source of truth"
- Modular : You can package code into Modules to reuse common patterns(e.g. standart "Web Server" module used by all teams)

# what is a state file
- state files contain each and every detail of any resources along with their current status whether it is "ACTIVE", "DELETED" or POSITIONING"
