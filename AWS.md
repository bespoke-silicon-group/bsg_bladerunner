## F1 Execution

To run C/C++ applications on F1, build an AMI & AFI (instructions below), and
then run `make regression` inside of [bsg_replicant](bsg_replicant) on the generated AMI.

### Build an Amazon FPGA Image (AFI)

These steps will build the FPGA image and upload it to AWS. `FPGA_IMAGE_VERSION`
will be used as the value for the 'Version' key in AFI Tags. The new AFI/AGFI
IDs are printed on the command line and in upload.json.

To run these steps, you will need to install the [Amazon Web Services Command
Line Interface (CLI)](https://aws.amazon.com/cli/) and configure it for your
user account.

1. Clone this repository.

2. Update the `FPGA_IMAGE_VERSION` variable in [project.mk](project.mk)
to avoid naming conflicts. (`FPGA_IMAGE_VERSION` will be used as the value for the
'Version' key in the AMI and AFI Tags.)

3. Run `make build-afi` from inside this repository. 

The new AFI/AGFI IDs are printed on the command line and in upload.json.

### Build an Amazon Machine Image (AMI)
   
These steps will build the Machine image and upload it to
AWS. `FPGA_IMAGE_VERSION` will be used as the value for the 'Version' key in AMI
Tags. 

To run these steps, you will need to install the [Amazon Web Services Command
Line Interface (CLI)](https://aws.amazon.com/cli/) and configure it for your
user account.

1. Clone this repository.

2. Update the `FPGA_IMAGE_VERSION` variable in [project.mk](project.mk)
to avoid naming conflicts. (`FPGA_IMAGE_VERSION` will be used as the value for the
'Version' key in the AMI and AFI Tags.)

3. Commit changes and push to a branch. (This step is critical!)

4. Run `make build-ami` from inside this repository. 
