# GitHub Action - RPM Build

[![GitHub Super-Linter](https://github.com/global-science-technology-inc/rpmbuild-action/actions/workflows/linter.yml/badge.svg)](https://github.com/super-linter/super-linter)
![CI](https://github.com/global-science-technology-inc/rpmbuild-action/actions/workflows/ci.yml/badge.svg)
[![Check dist/](https://github.com/global-science-technology-inc/rpmbuild-action/actions/workflows/check-dist.yml/badge.svg)](https://github.com/global-science-technology-inc/rpmbuild-action/actions/workflows/check-dist.yml)
[![CodeQL](https://github.com/global-science-technology-inc/rpmbuild-action/actions/workflows/codeql-analysis.yml/badge.svg)](https://github.com/global-science-technology-inc/rpmbuild-action/actions/workflows/codeql-analysis.yml)
[![Coverage](./badges/coverage.svg)](./badges/coverage.svg)

This GitHub Action builds RPMs from spec file and using repository contents as source (wraps the rpmbuild utility).
Integrates easily with GitHub Actions to allow RPMS to be uploaded as Artifact (actions/upload-artifact) or as Release Asset (actions/upload-release-asset).

## Usage

### Pre-requisites

Create a workflow `.yml` file in your repositories `.github/workflows` directory.
An [example workflow](#example-workflow---build-rpm) is available below.
For more information, reference the GitHub Help Documentation for [Creating a workflow file](https://help.github.com/en/articles/configuring-a-workflow#creating-a-workflow-file).

**Note:** You need to have a spec file in order to build RPM.

### Inputs

- `spec_file`: The path to the spec file in your repository. [**required**]

### Outputs

- `rpm_dir_path`: path to RPMS directory
- `source_rpm_path`: path to Source RPM file
- `source_rpm_dir_path`: path to  SRPMS directory
- `source_rpm_name`: name of Source RPM file
- `rpm_content_type`: Content-type for RPM Upload

This generated RPMS and SRPMS can be used in two ways.

1. Upload as build artifact
    You can use GitHub Action [`@actions/upload-artifact`](https://www.github.com/actions/upload-artifact)
1. Upload as Release assest
    If you want to upload as release asset, you also will need to have a release to upload your asset to.
    This could be created programmatically by [`@actions/create-release`](https://www.github.com/actions/create-release) as shown in the example workflow.

### Example workflow - build RPM

Basic:

```yaml
name: RPM Build
on: push

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v2

    - name: build RPM package
      id: rpm
      uses: global-science-technology-inc/rpmbuild-action@main
      with:
        spec_file: "cello.spec"

    - name: Upload artifact
      uses: actions/upload-artifact@v1.0.0
      with:
        name: Binary RPM
        path: ${{ steps.rpm.outputs.rpm_dir_path }}
```

This workflow triggered on every `push`, builds RPM and Source RPM using cello.spec and contents of that Git ref that triggered that action.
Contents are retrived through [GitHub API](https://developer.github.com/v3/repos/contents/#get-archive-link) [downloaded through archive link].
The generated RPMs or SRPMS can be uploaded as artifacts by using actions/upload-artifact.
The [outputs](#outputs) given by rpmbuild action can be used to specify path for upload action.

#### Above workflow will create an artifact like

![artifact_image](assets/upload_artifacts.png)

Use with Release:

```yaml
on:
    push:
      # Sequence of patterns matched against refs/tags
      tags:
        - 'v*' # Push events to matching v*, i.e. v1.0, v20.15.10

name: Create RPM Release

jobs:
    build:
        name: Create RPM Release
        runs-on: ubuntu-latest

        steps:

        - name: Checkout code
          uses: actions/checkout@master

        - name: Create Release
          id: create_release
          uses: actions/create-release@latest
          env:
              # This token is provided by Actions, you do not need to create your own token
              GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          with:
              tag_name: ${{ github.ref }}
              release_name: Release ${{ github.ref }}
              body: |
                Changes in this Release
                - Create RPM
                - Upload Source RPM
              draft: false
              prerelease: false

        - name: build RPM package
          id: rpm_build
          uses: global-science-technology-inc/rpmbuild-action@main
          with:
              spec_file: "cello.spec"

        - name: Upload Release Asset
          id: upload-release-asset
          uses: actions/upload-release-asset@v1
          env:
              GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
          with:
              # This pulls from the CREATE RELEASE step above
              # referencing it's ID to get its outputs object, which include a `upload_url`.
              # See this blog post for more info: https://jasonet.co/posts/new-features-of-github-actions/#passing-data-to-future-steps
              upload_url: ${{ steps.create_release.outputs.upload_url }}
              asset_path: ${{ steps.rpm_build.outputs.source_rpm_path }}
              asset_name: ${{ steps.rpm_build.outputs.source_rpm_name }}
              asset_content_type: ${{ steps.rpm_build.outputs.rpm_content_type }}
```

#### The above release uploads SRPM like

![artifact_image](assets/upload_release_asset.png)

Example Repository which uses [rpmbuild action](https://github.com/global-science-technology-inc/cextract)

Note on distribution:
If your RPMs are distribution specific like el7 or el8.

- Use global-science-technology-inc/rpmbuild-action@main for Centos7 *[el7]*
- Use global-science-technology-inc/rpmbuild-action@centos8 for Centos8 *[el8]*

```yaml
- name: build RPM package
    id: rpm_build
    uses: global-science-technology-inc/rpmbuild@centos8
    with:
        spec_file: "cextract.spec"
```

## Contribute

Feel free to contribute to this project. Read [CONTRIBUTING Guide](CONTRIBUTING.md) for more details.

## References

- [RPM Packaging Guide](https://rpm-packaging-guide.github.io/)
- [GitHub Learning Lab](https://lab.github.com/)
- [Container Toolkit Action](https://github.com/actions/container-toolkit-action)

## License

The scripts and documentation in this project are released under the [GNU GPLv3](LICENSE)

forked from [this repository](https://github.com/naveenrajm7/rpmbuild)
