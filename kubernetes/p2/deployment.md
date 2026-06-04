
para aplicar um manifest em k3s é preciso

- deployment.yaml
- service.yaml
- ingress.yaml

o deployment.yaml está responsavel por criar o pod e configurar a imagem do container
o service.yaml está responsavel por criar o serviço para expor o deployment
o ingress.yaml está responsavel por criar o ingress para expor o serviço para fora do cluster


--- Deployment.yaml ---

o deployment tem varios key components
tal como:

- apiVersion 
  que especifica a versao API do kubernetes a ser usado. isto garante a compatibilidade do manifest com a versao do kubernetes em uso.

- kind
  define o tipo de resource a ser manejado. neste caso seria um "deployment" que é um recurso que gerencia a criação e atualizacao dos Pods em questao
- metadata 
  contem as informacao que identificam/definem o recurso em questão
    carateristicas como nome, namespace, labels e annotations (n é obrigatorio colocar todas).
  
- spec
  define o estado desejado do recurso e como este se deve comportar.
  spec inclui detalhes como:
  - replicas: define o numero de replicas do pod a ser criado
  - selector: define os labels que o deployment usará para identificar os pods que ele gerencia
  - template: define o modelo do pod a ser criado, incluindo os containers, volumes e outras configuracoes necessarias para o funcionamento do pod.

  NOTAS:
  -label : tags que agrupam os recursos, facilitando a selecao e organizacao dos mesmos
  -selector: define os labels que o deployment usará para identificar os pods que ele gerencia. é importante que os labels definidos no selector correspondam aos labels definidos no template do pod, caso contrario o deployment não conseguirá gerenciar os pods corretamente.'

  ---------------


Summary:

Name			Purpose

labels          -  Tags placed on a Pod
matchLabels     -  A filter used to find Pods with certain tags

A manifest is structured like this:

apiVersion: Specifies the API version of the Kubernetes resource.

kind: Defines the type of resource (e.g., Pod, Service).

metadata: Contains information about the resource such as its name, namespace, and labels.

spec: Describes the desired state and configuration of the resource.


-----

Pod manifest

A Pod manifest is the smallest deployable unit in k8s. It represents a single instanve of a running process in the cluster

A Pod manifest to deploy a Pod should look like this:

apiVersion: v1
kind: Pod
metadata:
	name: my-Pod
	labels: my-app
spec:
	containers:
		- name: my-container
	image: nginx:latest
	ports:
		- containerPort: 80

---
Notes:

apiVersion: v1 : Specifies the API version

apiversion: v1 -> used for fundamental resources like: Pod, Service, ConfigMap
apiversion: app/v1 -> used for group apps, version 'v1'. Used for Deployment, StatefulSet etc
apiVersion: batch/v1 -> group batch . Used for Job, CronJob. 


example: 
apiVersion: apps/v1   # section=apps ,  catalog edition=v1


How about a Deployment Manifest?

A Deployment ensures that a specified number of replicas of a Pod are running at any given time
A replica is needed because it decreases the possibility of a app to crash(if one replica crashes, another one will take its place).



Basic Deployment Manifest:

apiVersion: apps/v1
kind: Deployment 
metadata:
	name: my-Deployment
spec:
	replicas: 3
	selector:
	matchLabels:
	app: my-app
	template: