# Terraform Pipeline

## Security Considerations

* SSM used instead of SSH to reduce attack surface and close port 22
* All inbound ips are restricted
* Terraform pipeline IAM is given least privledge, It is given just enough priveledge to read the role that provides the necessary permissions for SSM and apply that specific role to the ec2 instance. It cannot create or edit roles or access any other IAM roles or resources.
* Only admin accounts can access the ec2 instance through AWS SSM. No ingress ports are available at this moment.
* Checkov scan reavealed new configuration options that improved defence in depth: tighter egress rules, more detailed monitoring, dedicated ebs optimization, enabling IMDSv2 only http tokens, and ebs encryption on our ec2 volume. 
