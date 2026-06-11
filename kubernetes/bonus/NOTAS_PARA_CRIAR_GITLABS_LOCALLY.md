# COMO APLICAR UMA INSTANCIA DO GITLABS NUM CLUSTER (K3S)

para criar uma instancia do gitlabs e preciso um monte de tools para este correr
no cluster em questao:

- preciso aplicar amazon S3 ;
- database;(POSTGRESS per ex )
-  SSC(self signed certificate);
- SMTP Mail support;
- GitLab Kubernetes Runner deployment;
-  GitLab toolbox pod deployment

---

## para chegar a esse nivel de complexidade, vamos comecar por algo menor

vamos aplicar GitLab Community Edition (CE)(a versao gratis do gitlabs) dentro de um container. Neste inicio aplicaremos HTTP para um deplyoment facil no home lab.
No futuro iremos substitui lo por HTTPS


