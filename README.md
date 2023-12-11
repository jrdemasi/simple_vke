# simple_vke
Tooling (read: terraform) to setup a cluster using Vultr Kubernetes Engine quickly and efficiently, including external DNS and a sample nginx pod.  This is the cheapest way to hack on k8s if you're not set on using one of the big three (AWS, GCP, Azure). Simply follow the instructions below to spin a cluster up as-needed, and tear it down once you are finished.

## Installation Instructions
There are three stacks here, which have to be applied and destroyed in a given order to ensure everything works.  This is due to two main points:
1. To generate a vultr user with a unique API key for external-dns, while it is possible to create the user with terraform, the API key must be retrieved manually and then injected into the k8s stack. This is the only way to have a key for external-dns which follows the principle of least level of access
2. The k8s stack is primarily made up of kube manifests, which rely on the kubeconfig from the vke stack to plan and apply resources.  This dependency is hard to overcome.

The following also assumes you already have a domain in Vultr DNS -- the example presented being `example.com`

### Clone the Repository 
This should be a given, but just in case, check out the repository for use:
```
git clone git@github.com:jrdemasi/simple_vke
```

### Ensure you have `terraform` and `kubectl` installed
Run a simple `which terraform` and `which kubectl` in your terminal and ensure you are getting a valid path back.  If not, install the tools for your OS by whichever means you prefer.

### Generate a Personal Access Token in the Vultr UI
Under Account > API, enable API access and ensure a Personal Access Token is appearing.  This is the "master" token with all ACLs enabled that will be used for most of the `terraform apply` steps to come.3

### Run `terraform` on the `vultr_auth` stack
This stack creates a sub user in your Vultr account with a random password 32 characters in length.  The user is restricted to only accessing DNS in your account, which is the most granular we can make things to pass the personal access token to external-dns.  The email address provided has to differ from that of your main Vultr account.

Before beginning, let's ensure we have the required terraform providers:
```
terraform init
```
I recommend putting a space before the following plan and apply commands in your shell so the env var is not saved in bash or zsh history:
```
cd simple_vke/stacks/vultr_auth
# Note the space before the next line
 TF_VAR_vultr_api_key="YourPersonalAccessToken" \
TF_VAR_email="SomeGuy@somewhere.com" terraform plan -out vultr_auth.tfplan
```
Inspect the plan output, which should look similar to the following:
```
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # random_password.password will be created
  + resource "random_password" "password" {
      + bcrypt_hash      = (sensitive value)
      + id               = (known after apply)
      + length           = 32
      + lower            = true
      + min_lower        = 0
      + min_numeric      = 0
      + min_special      = 0
      + min_upper        = 0
      + number           = true
      + numeric          = true
      + override_special = "!#$%&*()-_=+[]{}<>:?"
      + result           = (sensitive value)
      + special          = true
      + upper            = true
    }

  # vultr_user.k8s_user will be created
  + resource "vultr_user" "k8s_user" {
      + acl         = [
          + "dns",
        ]
      + api_enabled = true
      + api_key     = (known after apply)
      + email       = "SomeEmail+vke@gmail.com"
      + id          = (known after apply)
      + name        = "K8s User"
      + password    = (sensitive value)
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```
Assuming everything looks okay, go ahead and run the apply step to actually create the resources in Vultr, again noting the space before the commands to omit from shell history:
```
 TF_VAR_vultr_api_key="YourPersonalAccessToken" \
TF_VAR_email="SomeGuy@somewhere.com"" terraform apply "vultr_auth.tfplan"
```

Log in to the Vultr UI, and under Account > Users you should now see our "K8s User".  Take note of the Personal Access Token for this user, to be used in subsequent steps.  

### Run `terraform` on the `vke` stack
This stack is responsible for actually creating the VKE cluster.  Take a look at the `variables.tf` file to see all of the overrides available, and pass them just as before on the command line when running `terraform plan` and `terraform apply`.  If the defaults are sane, you do not need to pass any of the variables with defaults set.  Note the space in front of the commands to ommit the Personal Access Token from shell history:
```
cd simple_vke/stacks/vke
terraform init
 TF_VAR_vultr_api_key="YourPersonalAccessToken" terraform plan -out vke.tfplan
```
The output should look similar to the folowing:
```
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the following symbols:
  + create

Terraform will perform the following actions:

  # local_file.kubeconfig will be created
  + resource "local_file" "kubeconfig" {
      + content              = (known after apply)
      + content_base64sha256 = (known after apply)
      + content_base64sha512 = (known after apply)
      + content_md5          = (known after apply)
      + content_sha1         = (known after apply)
      + content_sha256       = (known after apply)
      + content_sha512       = (known after apply)
      + directory_permission = "0777"
      + file_permission      = "0777"
      + filename             = "../k8s/vke-dev-kubeconfig.yaml"
      + id                   = (known after apply)
    }

  # vultr_kubernetes.vke-dev will be created
  + resource "vultr_kubernetes" "vke-dev" {
      + client_certificate     = (sensitive value)
      + client_key             = (sensitive value)
      + cluster_ca_certificate = (sensitive value)
      + cluster_subnet         = (known after apply)
      + date_created           = (known after apply)
      + endpoint               = (known after apply)
      + ha_controlplanes       = false
      + id                     = (known after apply)
      + ip                     = (known after apply)
      + kube_config            = (sensitive value)
      + label                  = "vke-dev"
      + region                 = "ewr"
      + service_subnet         = (known after apply)
      + status                 = (known after apply)
      + version                = "v1.28.3+2"

      + node_pools {
          + auto_scaler   = true
          + date_created  = (known after apply)
          + date_updated  = (known after apply)
          + id            = (known after apply)
          + label         = "vke-dev"
          + max_nodes     = 2
          + min_nodes     = 1
          + node_quantity = 1
          + nodes         = (known after apply)
          + plan          = "vc2-1c-2gb"
          + status        = (known after apply)
          + tag           = (known after apply)
        }
    }

Plan: 2 to add, 0 to change, 0 to destroy.
```
To apply, assuming everything looks alright:
```
 TF_VAR_vultr_api_key="YourPersonalAccessToken" terraform apply "vke.tfplan"
```
Note that after this plan applies successfully, it will automatically create the `kubeconfig` for your cluster in the k8s stack folder.  It will take some amount of time even after the stack seems to have applied for your kubernetes cluster to be ready to serve requests.  To test connectivity, utilize the kubeconfig in the k8s stack to run a get nodes:
```
cd simple_vke/stacks/k8s
kubectl --kubeconfig vke-dev-kubeconfig.yaml get nodes
```
If you see output similar to the following, the cluster isn't quite ready:
```
E1211 00:02:30.935946   89973 memcache.go:265] couldn't get current server API group list: Get "https://d3b0ca46-cb29-4ec5-8f85-04c679e5013e.vultr-k8s.com:6443/api?timeout=32s": dial tcp 140.82.60.188:6443: connect: connection refused
```
When it is ready, you should see something like so:
```
NAME                   STATUS   ROLES    AGE   VERSION
vke-dev-c488e74d1c44   Ready    <none>   84s   v1.28.3
```

### Run `terraform` on the `k8s` stack
The final stack simply applies some kube manifests using `terraform`. Plain yaml copies of the same manifests are available in the `deploy` folder at the base of the repo.  The apply step here has quite a few variables, so I will detail each one more carefully than before:
* `vultr_api_key` this is the Personal Access Token of the k8s user created in the `vultr_auth` stack, **not** the API key used in the previous two applies.  The reason we use a different Personal Access Token under a dedicated user for this use case is so it can be scoped using ACLs to only have access to DNS, and so that it's easier to clean up after ourselves when we're done.
* `domain_filter` this is a filter that external-dns uses to add some layer of safety/security as to which domains are valid for it to modify.  Whichever domain you're using and have in Vultr DNS should be passed here. 
* `hostname` this is where your nginx pod will ultimately live in DNS.  The example is `web.example.com` but adjust it to suit your needs.  
```
cd simple_vke/stacks/k8s
 TF_VAR_vultr_api_key="ThePersonalAccessTokenOfK8sUser" \
TF_VAR_domain_filter="example.com" \
TF_VAR_hostname="web.example.com" \
terraform plan -out k8s.tfplan
```
The output will be quite long this time, but verify it looks okay, then apply:
```
 TF_VAR_vultr_api_key="ThePersonalAccessTokenOfK8sUser" \
TF_VAR_domain_filter="example.com" \
TF_VAR_hostname="web.example.com" \
terraform apply "k8s.tfplan"
```
### Verify Everything is Working
After the previous apply, you should be able to verify there are two pods running:
```
kubectl --kubeconfig vke-dev-kubeconfig.yaml get pods 
NAME                            READY   STATUS    RESTARTS   AGE
external-dns-7599854757-vqcfk   1/1     Running   0          2m17s
nginx-7c5ddbdf54-d28xv          1/1     Running   0          2m16s
```

Checking the logs for external-dns, once the LoadBalancer actually created in Vultr, you should see something similar to the following:
```
kubectl --kubeconfig vke-dev-kubeconfig.yaml logs external-dns-7599854757-vqcfk
time="2023-12-11T07:19:14Z" level=info msg="Changing record." action=CREATE record=web.example.com ttl=3600 type=A zone=example.com         
time="2023-12-11T07:19:15Z" level=info msg="Changing record." action=CREATE record=web.example.com ttl=3600 type=TXT zone=example.com 
time="2023-12-11T07:19:16Z" level=info msg="Changing record." action=CREATE record=a-web.example.com ttl=3600 type=TXT zone=example.com 
```
Navigating to `web.example.com` should also show the default nginx landing page.  