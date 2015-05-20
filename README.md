# CF Lite

*** This project is still work in progress ***

A local development environment for Cloud Foundry.

CF Lite is a quick and easy way to get Cloud Foundry running on a single VM *on AWS*. CF Lite was created for users to have their own sandbox version of CF to deploy applications. 

Note: It does not require any installation or knowledge of BOSH.

## Install CF Lite on AWS

1. Install [Vagrant](http://www.vagrantup.com/downloads.html).

    Known working version:

    ```
    $ vagrant --version
    Vagrant 1.7.2
    ```

1. Install Vagrant AWS provider

    ```
    $ vagrant plugin install vagrant-aws
    ```

    Known working version: 0.6.0

1. Initialize your Vagrant environment:

    ```
    vagrant init cloudfoundry/cf-lite
    ```

1. Set environment variables:

    ```
    export BOSH_AWS_ACCESS_KEY_ID=     # AWS Access Key ID
    export BOSH_AWS_SECRET_ACCESS_KEY= # AWS Secret Access Key

    export BOSH_LITE_SECURITY_GROUP= # Security group (see below on how to create one)

    export BOSH_LITE_PRIVATE_KEY= # Path to the private SSH key file matching imported AWS Key Pair
    export BOSH_LITE_KEYPAIR=       # AWS Key Pair name
    ```

    * You will need a key pair to SSH into your running cf-lite box. If you don't have one already in your AWS account, you will need to create one. The following instructions are applicable to a Mac/UNIX environment:

      1. "ssh-keygen -t rsa"
      1. Save it to ~/.ssh folder (create it if it does not exist)
      1. Import the *.pub file into EC2 Key Pairs
      1. Give it a name and store the name via `BOSH_LITE_KEYPAIR` environment variable
      1. Specify path to the private key file via `BOSH_LITE_PRIVATE_KEY` environment variable

    * When deploying to a VPC, the security group must be specified as an ID of the form `sg-abcd1234`, as opposed to a name like `default`.

    * When deploying to a VPC, the subnet ID must be specified via `BOSH_LITE_SUBNET_ID` environment variable.

    * To change the instance type, set the `BOSH_LITE_INSTANCE_TYPE` environment variable.
1. Run vagrant up with provider `aws`:

    ```
    $ vagrant up --provider=aws
    ```

## Use Cloud Foundry

1. Run `vagrant ssh` to get to your CF environment:

    ```
    $ vagrant ssh
    ```

1. Now you can use `cf` CLI:

    ```
    $ cf api --skip-ssl-validation https://api.10.244.0.34.xip.io
    $ cf auth admin admin

    $ cf create-org me
    $ cf target -o me

    $ cf create-space development
    $ cf target -s development

    $ cf push ...
    ```

1. The spring-music demo app should already be running in the 'sample-org' organization and 'sample-space' space.
```
    $ cf auth admin admin

    $ cf target -o sample-org -s sample-space
    $ cf apps
```
