# To Make a Release
   
These steps will build an AMI and an AFI and upload them to
AWS. It is a combination of the steps in README.md

1. Clone this repository.

2. Update the `FPGA_IMAGE_VERSION` variable in [project.mk](project.mk)
to avoid naming conflicts. (`FPGA_IMAGE_VERSION` will be used as the value for the
'Version' key in the AMI and AFI Tags.)

3. Run `make build-afi` from inside this repository. (See the section Build an
Amazon FPGA Image)

4. Replace the `AGFI_ID` and `AMI_ID` variables in
[project.mk](project.mk) with the new values in upload.json (generated
by the previous step).

5. Commit your changes and push to a branch

6. Run `make build-ami` from inside this repository. (See the section Build an
Amazon Machine Image)

7. Test the release
    
8. Make a PR to `dev` or `master` depending on the state of the release.

9. Apply a tag to the release when it is merged to master
