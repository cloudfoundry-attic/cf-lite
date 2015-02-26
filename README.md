# CF Lite

A local development environment for Cloud Foundry.

CF Lite is a quick and easy method of acessing your own instance of Cloud Foundry. CF Lite was created for users to have their own sandbox version of CF to deploy applications. It does not require any installation or knowledge of BOSH. 

## Install CF Lite

### Prepare the Environment

1. Install [Vagrant](http://www.vagrantup.com/downloads.html).

    Known working version:

    ```
    $ vagrant --version
    Vagrant 1.7.2
    ```

1. Install Vagrant AWS provider

    ```
    vagrant plugin install vagrant-aws
    ```

    Known working version: 0.6.0


1. Install the CloudFoundry CLI

    Full documentation is on [the CloudFoundry docs site](http://docs.cloudfoundry.org/devguide/installcf/install-go-cli.html).

    Download and run the installer for your platform:

    Downloads
    =========
    **WARNING:** Edge binaries are published with each new 'push' that passes though CI. These binaries are *not intended for wider use*; they're for developers to test new features and fixes as they are completed.

    | Stable Installers | Stable Binaries | Edge Binaries |
    | :---------------: |:---------------:| :------------:|
    | [Mac OS X 64 bit](https://cli.run.pivotal.io/stable?release=macosx64&source=github) | [Mac OS X 64 bit](https://cli.run.pivotal.io/stable?release=macosx64-binary&source=github) | [Mac OS X 64 bit](https://cli.run.pivotal.io/edge?arch=macosx64&source=github) |
    | [Windows 32 bit](https://cli.run.pivotal.io/stable?release=windows32&source=github) | [Windows 32 bit](https://cli.run.pivotal.io/stable?release=windows32-exe&source=github) | [Windows 32 bit](https://cli.run.pivotal.io/edge?arch=windows32&source=github) |
    | [Windows 64 bit](https://cli.run.pivotal.io/stable?release=windows64&source=github) | [Windows 64 bit](https://cli.run.pivotal.io/stable?release=windows64-exe&source=github) | [Windows 64 bit](https://cli.run.pivotal.io/edge?arch=windows64&source=github) |
    | [Redhat 32 bit](https://cli.run.pivotal.io/stable?release=redhat32&source=github) | [Linux 32 bit](https://cli.run.pivotal.io/stable?release=linux32-binary&source=github) | [Linux 32 bit](https://cli.run.pivotal.io/edge?arch=linux32&source=github) |
    | [Redhat 64 bit](https://cli.run.pivotal.io/stable?release=redhat64&source=github) | [Linux 64 bit](https://cli.run.pivotal.io/stable?release=linux64-binary&source=github) | [Linux 64 bit](https://cli.run.pivotal.io/edge?arch=linux64&source=github) |
    | [Debian 32 bit](https://cli.run.pivotal.io/stable?release=debian32&source=github)
    | [Debian 64 bit](https://cli.run.pivotal.io/stable?release=debian64&source=github)

1. You will need a keypair to ssh into your running cf-lite box.  If you don't have one already, you will need to create one.  The following instructions are applicable to a Mac/unix environment:
  1. "ssh-keygen -t rsa"
  1. save it to ~/.ssh folder (create it if it does not exist)
  1. name it id_rsa_bosh
  1. import the id_rsa_bosh.pub file to EC2 KeyPairs
  1. Give it a name and store the name in the environment variable CF_LITE_KEYPAIR

1. Set environment variables called `BOSH_AWS_ACCESS_KEY_ID` and `BOSH_AWS_SECRET_ACCESS_KEY` with the appropriate values. If you've followed along with other documentation such as [these steps to deploy Cloud Foundry on AWS](http://docs.cloudfoundry.org/deploying/ec2/bootstrap-aws-vpc.html), you may simply need to source your `bosh_environment` file.


AWS Environment Variables:

|Name|Description|Default|
|---|---|---|
|BOSH_AWS_ACCESS_KEY_ID         |AWS access key ID                    | |
|BOSH_AWS_SECRET_ACCESS_KEY     |AWS secret access key                | |
|CF_LITE_KEYPAIR                |AWS keypair name                     |&lt;your keypair name on AWS&gt;|
|BOSH_LITE_NAME                 |AWS instance name                    |Vagrant|
|BOSH_LITE_SECURITY_GROUP       |AWS security group                   |inception|
|BOSH_LITE_PRIVATE_KEY          |path to private key matching keypair |~/.ssh/id_rsa_bosh|
|[VPC only] BOSH_LITE_SUBNET_ID |AWS VPC subnet ID                    | |

* Make sure the EC2 security group you are using in the `Vagrantfile` exists and allows inbound TCP traffic on ports 25555 (for the BOSH director), 22 (for SSH), 80/443 (for Cloud Controller), and 4443 (for Loggregator).


* Download the .box file and initialize your vagrant environment:

    ```
    vagrant init cloudfoundry/cf-lite
    ```

* Make sure the EC2 security group you are using in the `Vagrantfile` exists and allows inbound TCP traffic on ports 25555 (for the BOSH director), 22 (for SSH), 80/443 (for Cloud Controller), and 4443 (for Loggregator).

* When deploying to a VPC, the security group must be specified as an ID of the form `sg-abcd1234`, as opposed to a name like `default`.

* You will need to 

* Run vagrant up with provider `aws`:

    ```
    vagrant up --provider=aws
    ```

## Try your Cloud Foundry deployment

Install the [Cloud Foundry CLI](https://github.com/cloudfoundry/cli) and run the following:

```
# for AWS use public IP https://api.BOSH_LITE_PUBLIC_IP.xip.io
# else, and if behind a proxy, exclude this domain by setting no_proxy
# export no_proxy=192.168.50.4,xip.io
cf api --skip-ssl-validation https://api.10.244.0.34.xip.io
cf auth admin admin
cf create-org me
cf target -o me
cf create-space development
cf target -s development
```

Now you are ready to run commands such as `cf push`.
If your Cloud Foundry deployment needs to go through an HTTP proxy to reach the Internet, specify `http_proxy`, `https_proxy` and `no_proxy` environment variables using `cf set-env` or add them to the `env:` section of your application's `manifest.yml`. This ensures the buildpacks can download required libraries, gems, etc. during application staging and running.

