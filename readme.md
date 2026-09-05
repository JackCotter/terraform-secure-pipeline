# Terraform Pipeline

## Security Considerations

* SSM used instead of SSH to reduce attack surface and close port 22
* All inbound ips are restricted
* Terraform pipeline IAM is given least privledge, It is given just enough priveledge to read the role that provides the necessary permissions for SSM and apply that specific role to the ec2 instance. It cannot create or edit roles or access any other IAM roles or resources.
* Only admin accounts can access the ec2 instance through AWS SSM. No ingress ports are available at this moment.
* Checkov scan reavealed new configuration options that improved defence in depth: tighter egress rules, more detailed monitoring, dedicated ebs optimization, enabling IMDSv2 only http tokens, and ebs encryption on our ec2 volume. 

* GitHub Actions uses ODIC to authenticate to AWS. The ODIC policy only allows the runner from this GitHub Account and this Repository to assume the necessary IAM role.  GitHub actions assumes a role that gives it just enough permissions to run terraform and build the ec2 instance. It never needs an access key.
* Terrafrom uses private s3 bucket as backend for storing state. S3 bucket is private and not accessible by the public. GitHub runner's role has just enough permissions to edit and read the state. Permissions are scoped to only this s3 bucket, authenticated through ODIC.
