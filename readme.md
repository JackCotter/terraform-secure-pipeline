# Terraform Pipeline

## Security Considerations

* SSM used instead of SSH to reduce attack surface and close port 22
* All inbound ips are restricted
* Terraform pipeline IAM is given least privledge, It is given just enough priveledge to read the role that provides the necessary permissions for SSM and apply that specific role to the ec2 instance. It cannot create or edit roles or access any other IAM roles or resources.
* Only admin accounts can access the ec2 instance through AWS SSM. No ingress ports are available at this moment.
* Checkov scan reavealed new configuration options that improved defence in depth: tighter egress rules, more detailed monitoring, dedicated ebs optimization, enabling IMDSv2 only http tokens, and ebs encryption on our ec2 volume. 

* GitHub Actions uses ODIC to authenticate to AWS. The ODIC policy only allows the runner from this GitHub Account and this Repository to assume the necessary IAM role.  GitHub actions assumes a role that gives it just enough permissions to run terraform and build the ec2 instance. It never needs an access key.
* Terrafrom uses private s3 bucket as backend for storing state. S3 bucket is private and not accessible by the public. GitHub runner's role has just enough permissions to edit and read the state. Permissions are scoped to only this s3 bucket, authenticated through ODIC.
* Terraform plan step is given readonly permissions on ec2, iam, and s3 per least privilidge. If something somehow someone hijacks that step in the runner, they can only read priviliges and cannot perform any actions.


## Future Work
* Store tfplan in s3 after plan step, reuse in apply step. This guarantees tthat the plan that is generated in the review step is the plan that is executed.


## Threat Model
The data flow diaram highlights 7 trust boundaries that need to be analysed. The STRIDE threat analysis process will be used to evaluate these threats.

### TB01: Client to Nginx
| Threat | Target | Description |
|--------|--------|-------------|
| Spoofing | Client | Attacker in MITM position can spoof site and produce a self-signed cert if TLS is not in place. |
| Tampering |  Client | - |
| Repudiation | Client | Attacker can claim non-repudiation if no request logs exist. |
| Information Disclosure | Client | If attacker is able to gain access to clients Cookies via for example a reflected XSS attack, they can read their session state and spoof their requests. |
| Denial of Service | Client | Client could suffer a DNS cache poisoning attack, preventing resolution of server address or redirecting the client to a spoofed site |
| Elevation of Privilidge | Client | - |
| Spoofing | Nginx | TLS Spoofing: TLS is not setup or is using self-signed certificates. There is no way for Nginx to know it is communicating securely with the client without a certificate signed by a CA. An attacker can intercept packages, relay them to Nginx.|
| Tampering | Nginx | Attacker gains access to Nginx config and configures it to expose system information (ex. adding debug headers). |
| Tampering | Nginx | HTTP request smuggling via ambiguous Content-Length/Transfer-Encoding. |
| Repudiation | Nginx | Requests are unauthenticated. No account creation exists to limit user data collection (and subsequent risk of exfiltration). Users can submit fraudulent scores tied to no account and with no audit trail.
| Information Disclosure | Nginx | Attacker can learn Nginx version number or other information from application stack based on HTTP response and response headers|
| Denial of Service | Nginx | Request Flood attack overwhelms Nginx and valid client requests are dropped |
| Elevation of Privilidge | Nginx | - |

### TB02: Client/Nginx to Django Web App
| Threat | Target | Description |
|--------|--------|-------------|
| Spoofing | Django | Attacker gains access to docker and sends spoofed request from Nginx container to open port 8000 on docker network |
| Tampering |  Django | Attacker sends reflected XSS payload in the name field during the score POST HTTP Request. Django stores that record in the database and reflects the XSS payload to other users. |
| Repudiation | Django | Attacker can claim non-repudiation because no app-level logging exists for state changes. If app-level logging exists, an attacker can find and delete the log file since it exists on the same server as the application. |
| Information Disclosure | Django | Existance of /admin path hints at the application being a Django app. /admin page adds more attack surface and more privelege to exploit. |
| Information Disclosure | Django | Crash reports disclose information about the application to the user if they are enabled. |
| Information Disclosure | Django | Error messages can disclose information on incorrect form submission on score submission form. |
| Denial of Service | Django | Django Monolith setup can be prone to resource exhausion under heavy load. Nginx, Django, and PSQL all running on same EC2 Instance and fighting for resources. |
| Denial of Service | Django | Django served by Gunicorn has static number of workers. Slow clients can tie up workers and restrict service to other clients. |
| Elevation of Privilidge | Django | Regular user can access admin-only actions because the admin check is not performed correctly. |

### TB03: Django Web App to Postgres
| Threat | Target | Description |
|--------|--------|-------------|
| Spoofing | Postgres | Attacker connects to database from a compromised docker container by guessing credentials or using reused or default credentials. |
| Tampering | Postgres | Attacker injects SQL into name field in POST Score endpoint. SQL is run as is against database. |
| Repudiation | Postgres | Database changes are not logged, allowing for non-repudiation. If logging file exists on same instance as postgres, attacker can delete the logs if they gain acces to the system.|
| Information Disclosure | Postgres | Attacker who gains access to database via compromised EC2 instance can exfiltrate all data contained in database. |
| Denial of Service | Postgres | Attacker can inject large payloads in POST Score, impacting database performance if they end up in the database. |
| Denial of Service | Postgres | Connection pool exhaustion can occur if Django doesn't limit max connections or if too many requests are incoming. |
| Elevation of Privilidge | Django | Attacker compromises Django and connects to the Database over the Docker network using superuser permissions |

### TB04: GitHub CI/CD Runners to EC2 Instance

| Threat | Target | Description |
|--------|--------|-------------|
| Spoofing | EC2 | Attacker spoofs session token using a man in the middle attack. Attacker logs in to AWS using token and creates an EC2 instance by assuming the GitHub IAM Role. Attacker uses EC2 Instance for Crypto mining. |
| Spoofing | GitHub | If IAM Role trust policy is too permissive, attacker can obtain a legitimately issued access token. The trust sub policy follows repo:org/repo:* meaning that any branch or fork of the specified repo could be given a legitimate access token and execute actions on EC2 via IAM role they are given access to.|
| Tampering | CI/CD Runners | Compromised upstream dependency attack: Attacker adds malicious code in a third party GitHub action used by runners. This code is pulled and run by runners on push. Payload can be used to exfiltrate secrets or abuse AWS IAM role permissions |
| Tampering | CI/CD Runners | Malicious project contributer can edit the pipeline.yml file causing checks to be missed or allow pushing insecure code to EC2. |
| Repudiation | EC2 | Branch protection is not turned on. A malicious contributer could force push to main and overwrite git history. |
| Information Disclosure | CI/CD Runners | When project is set to public, CI/CD Runners may leak information such as secrets or other sensitive information in terraform plan or other build artifacts.|
| Information Disclosure | CI/CD Runners | Third party GitHub actions are given access to code and secrets. If they are compromised, data exfiltration can occur. Flagging them with sensitive=true will hide them from outputs.
| Denial of Service | CI/CD Runners | A flood of runner requests (many prs opened at once) could exhaust the runners and prevent a valid deploy.|
| Denial of Service | CI/CD Runners | Any attacker that is able to cause a gate to fail either via changing the requirements upstream if it is a third party gate or by editing the app code to fail the gate will be able to prevent a deploy |
| Elevation of Privilidge | EC2 | Attacker compromises terraform plan GitHub action and is given readonly access to IAM and EC2. Apply action has write access to EC2. If the apply action applies the plan generated in the plan section, attacker can perform write actions by modifying the plan it generates.

### TB05: CI/CD Runners to S3 Database
| Threat | Target | Description |
|--------|--------|-------------|
| Spoofing | CI/CD Runner | - |
| Tampering | S3 | If an attacker can write to S3 either by a compromised apply runner or write permissions to the terraform config can write a poisoned terrform state. A poisoned state will affect future deployments of the application|
| Repudiation | S3 | S3 records are not logged. Attacker can modify S3 data without leaving audit trail |
| Information Disclosure / Elevation of Privilidge | S3 | Terraform state is stored in S3 in Plaintext. Attacker who gains access to S3 database can view the terraform state. They may be able to obtain secrets from the terraform state allowing them to access other parts of the system such as the GitHub Repo or the EC2 Instance | 
| Denial of Service | S3 | Attacker who gains write permissions to Dynamodb by compromising either the plan or apply runner and their respective IAM roles can hold the mutex lock and prevent any other process from obtaining the mutex and reading or writing the terraform state. This will prevent deployments and tests. |

### TB06: GitHub to EC2
| Threat | Target | Description |
|--------|--------|-------------|
| Spoofing | EC2 | Network level attacker intercepts first connection to GitHub via a compromised DNS. Attacker presents a fake key and feeds malicious payload to ec2 to execute. |
| Tampering | GitHub | Contributer intentially or unintentionally commits malicious code to repo, repo gets pulled in and malicious code is run. |
| Tampering | GitHub | Attacker exploits the time window between code scanning checks and deployment by pushing malicious code to the repo after checks pass and before EC2 spins up and checks out code from repo. |
| Repudiation | GitHub | GitHub does not log use of SSH key, and attacker can use compromised key to exfiltrate application code without audit trail |
| Information Disclosure | GitHub | Attacker who gains access to SSH Token will be able to read all files in repo. They will not be able to write as it is a readonly key. |
| Denial of Service | GitHub | Third party dependency. If an attacker is able to cause GitHub to go down, app will not be able to checkout code and deploy. |
| Elevation of Privilidge | GitHub | Anyone able to merge code into the repo is able to have code execute as a root in a docker container on the EC2 Instance via docker compose. |

### TB07: AWS Admin to EC2 or AWS Console
| Threat | Target | Description |
|--------|--------|-------------|
| Spoofing | AWS Console | Attacker connects to console or via ssm using stolen credentials |
| Tampering | AWS Console | Attacker connects to console via admin account credentials and spins up unauthorized resources |
| Repudiation | AWS Console | CloudTrail logs admin actions by default, but no alerting/review process exists to actually catch unauthorized changes when they occur. |
| Repudiation | AWS Console | Compromised Admin account could delete its own cloudtrail logs, protecting it from repudiation. |
| Information Disclosure | AWS Console | A compromised admin account can view/edit EC2 instances, view/edit IAM roles, and view budget. |
| Denial of Service | AWS Admin | Compromised AWS admin can remove accounts, change passwords, and destroy services |
| Elevation of Privilidge | AWS Admin | Account cannot gain root access. Does it have any priveledges it does not need? |