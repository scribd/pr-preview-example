# Pull Request Previews with Github Actions, AWS App Mesh, and ECS

Let's say you have an ECS based service: `www.example.com`, and when someone opens a pull request, you'd like to be able to preview what that branch looks like when deployed. 

Our approach is to create a Github Actions workflow that 
  - builds and deploys an ECS Service as Virtual Nodes
  - creates an App Mesh Virtual Service that points to the Virtual Nodes
  - creates an App Mesh Virtual Gateway Route that routes `<pr-number>.pr-preview.example.com` to that Virtual Service. 

## Application Infrastructure

The supporting application infrastructure is deployed using terraform as it is mostly stable.

Broadly speaking, the following is created:

- An Elastic Load Balancer
- An ECS cluster
- A DNS entry for `*.pr-preview.example.com` pointing to the Elastic Load Balancer. 
- An AppMesh Virtual Gateway configuration registered to the ELB
- An AppMesh Virtual Gateway ECS deployment
- IAM and other resources for use by the application.

See the [example implementation](terraform/) for details.

### Notes
- We choose EC2 flavor ECS cluster so that we can take advantage of local file system caching, but you don't have to.
- This example doesn't include autoscaling configuration. 

## Github Actions

The preview stack is [dynamically deployed using Github Actions](github/workflows/pr-preview-workflow.yml) when a pull request is opened.

After the pull request is merged (or closed), the preview stack is [deleted](github/workflows/delete-preview-when-pr-closed.yml).

The preview stack is composed of:
- ECS Service:
  - Task Definition
  - Service Definition
- AppMesh configuration:
  - Virtual Node
  - Route
  - Virtual Router
  - Virtual Service
  - Virtual Gateway Route
