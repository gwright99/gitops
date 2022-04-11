# gitops
Repository to experiment with gitops setups.

## Notes
Originally started with a single-environment monolith. This was easy to set up, but did not remotely reflect how things need to work in reality.

### Issue 1: Directories or Workspaces?
As per [https://learn.hashicorp.com/tutorials/terraform/organize-configuration](https://learn.hashicorp.com/tutorials/terraform/organize-configuration), one can manage different environment state either via the **Directies** or **Workspaces** approach.

I chose the Directories approach. Despite needeing to duplicate files, I felt the explicitness of structure worked better for my own mindspace and would fit better with my GitHub Actions automation attempts.

An early tutorial I followed had the environments stashed under a `setups/` folder and, as a result, earlier incarnations of this repo used the structure. This changed when I started to follow the official Hashicorp tutorials more: they each environment at as root-level folder. Removing the `setups/` folder was also beneficial as it negated the need for one set of `../` when pointing from the `main.tf` to related modules.

As I look at the directory structure now, I think removal of the top-level environment folder was a mistake. This layer will get messier as additional environments are added, and the fact that I've found a clean way to pass in an absolute path for the root directory has simplified my file references elsewhere in the repository.


### Issue 2: Resource Decomposition (i.e. Modules)
The monolith was easy to work with since there were only a few files. It was readily apparent, however, that it would be quickly become unwieldly if I kept on adding even minor bits of new functionality.

I decided to implement modules. This required a surprising amount of rework and I think it increased hidden complexity:

1. Any resource created in a module (e.g. ModuleA) that needed to referenced in a different module (e.g. ModuleB) required me to:
    1. Reference it as an output variable in ModuleA.
    2. Reference it as an input variable in ModuleB.
    3. Pass the output of ModuleA to ModuleB via a parameter when calling ModuleB from the `main.tf`

2. Naming harmonization suddenly became more challenging to align. At one point I had to change a value from object name to object arn (which I tried to reflect in self-documenting variable names). I felt like I had to make this change in 10 different entries across multiple documents. It did NOT feel like a best practice.

3. The now-mostly-separated-but-still-related modules became more complicated to look at. Resources within the module were referencing resources within itself but also inter-module resources. I noticed it was taking me more effort to keep track of what was coming from where.

This problem may be somewhat negated by my choosing of better, harmonized names, so that future changes can be a simple "find and replace" but I'm not there yet. It may also be alleviated if I'm able to find a better reference technique (I have not found one yet). As of today, I'm leaning towards "mini-monoliths" on business-functionality grounds (e.g. mix IAM, Lambda, and S3 resources within a single module that creates a Lambda) rather than a logical division based on specific AWS services (e.g. separate IAM, Lambda, S3).

The mini-monolith approach seems to be what Hashicorp itself recommends. In [this example](https://github.com/cloudposse/terraform-aws-utils/blob/master/context.tf), they suggest breaking up a traditional 3-tier web application into the following modules:
* Network
    * ACLs, NAT Gateway, VPC, subnets, peering, and direct connect
    * High privilege & low volatility - these won't change often so it makes sense to gropu them in their own module to protect from unnecessary churn and risk.
* Web
    * ALB, ASG, EC2 instances, S3 buckets, Security Groups, and logging.
    * Use a pre-built AMI (via Packer) with latest web application code.
    * These are highly encapsulated (focused only on web-app) and have high volatility.
* App
    * ALB, ASG, EC2 instances, S3 buckets, Security Groups, and logging.
    * Use a pre-built AMI (via Packer) with latest app tier code.
    * These are highly encapsulated (focused only on web-app) and have high volatility.
* Database
    * RDS, associated storage, backup data, logging, etc.
    * Highly privileged and low volatility. Not going to set up the db too often and not many folks should be able to modify these resources.
* Routing
    * Route53, Hosted Zones, Private Hosted Zones.
    * Highly privileged and low volatility.
* Security
    * IAM resources, maybe Security Groups, MFA
    * Highly privileged and low volatility.


### Issue 3: Single-Sourcing Variables
I don't appear able to use variables when defining the `source` path to modules, so some hard-coded relative pathing is necessary to point the `main.tf` to associated modules.

I didn't want this problem to spread, however, and it was looking like it would due to the fact my modules needing to point terraform to the root-level `assets/templates` folder to get templated IAM policies.

The context solution I implemented used these two issues:

* [https://github.com/hashicorp/terraform/issues/15818](https://github.com/hashicorp/terraform/issues/15818)
* [https://github.com/cloudposse/terraform-aws-utils/blob/master/context.tf](https://github.com/cloudposse/terraform-aws-utils/blob/master/context.tf)

The idea is to create a context variable within the root `main.tf` locals. You don't seem to be able to pass down the whole locals itself, but you can pass down an object in locals that holds all the static state (i.e. imported from `terraform.tfvars`).

Each module can have the context variable defined based on a template, which allows the implementation of consistency re: tagging, object naming, etc.

I found this technique half way through, so the `batch` module still uses the old way of passing in variables individually whereas modules I built afterwards use the context variable.



### More to follow
More notes to follow as I continue exploring the technology.

## To Do
- [x] Reorganize modules (again). Move cloudwatch functionality into Lambda. Rename modules to fit best practice naming convention e.g. "custom-tf-aws-security"
- [ ] Determine if there is an easier way to reference a module resource from another module without having to align output/variable/main.tf files.
- [x] Re-implement an `environments` folder to clean up the root level.
- [x] Implement context variable in batch module.
- [ ] Generate Changelog as per [https://www.freecodecamp.org/news/a-beginners-guide-to-git-what-is-a-changelog-and-how-to-generate-it/](https://www.freecodecamp.org/news/a-beginners-guide-to-git-what-is-a-changelog-and-how-to-generate-it/)
