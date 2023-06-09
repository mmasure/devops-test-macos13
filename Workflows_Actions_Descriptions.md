# Description of workflows and actions

### "Recette build IOS App" workflow

The "Recette build IOS App" workflow is triggered by pushing a tag in the format "v*..-recette" from the develop branch.
It executes unit tests and builds the application by calling the "**wc_test**" and "**wc_build**" workflows respectively, and generates a pre-release.

This workflow consists of 4 jobs:

- Variables :

    - Use a matrix to run on multiple environments in parallel ('pprd' and 'prd')
    - Retrieve the source code from the repository
    - Select the specified version of Xcode from the variable 'vars.XCODE_VERSION'
    - Check the macOS version (simply display it in the logs)
    - Set the selected Xcode version in the variable 'VERSION' (output) and stop the workflow if the selected Xcode version is different from the specified one

- Test:

    - When the "Variables" job is successfully completed, call the "wc_test" workflow, passing the variables 'vars.XCODE_VERSION' and 'vars.PROJECT_NAME'

- Build:

    - Use a matrix to run on multiple environments in parallel ('pprd' and 'prd')
    - When the "Variables" job is successfully completed, call the "wc_build" workflow, providing the required variables and secrets
    - The variables are: 'environment' (from the matrix), 'XCODE_VERSION', 'PROFILE_NAME', 'PROJECT_NAME', 'PLIST_PATH', 'XARCHIVEPATH' (these variables are defined at the repository or 'pprd'/'prd' environment level)
    - The GitHub secrets are: 'PROVISIONING_PROFILE', 'CERTIFICATES_P12', 'CERTIFICATES_P12_PASSWORD', 'KEYCHAIN_PASSWORD', 'GH_PAT'

- Release:

    - Execute the steps only if the Build succeeded and it is a Git tag
    - Retrieve the artifact generated by the Build using the "download-artifact" action and the application version 'VERSION' returned by the "wc_build" workflow
    - Create a Release (pre-release version) on GitHub using 'GH_PAT', including the IPA files (required for iOS application distribution) and dSYM files (for debugging), and provide a release note

<br>

***

### "wc_test" workflow

The "wc_test" workflow is a reusable workflow called by the "**Recette build IOS App**" workflow. This workflow enables the execution of unit tests with Xcode.

The required inputs are:

- <u>xcodeversion</u>: the version of Xcode used (provided by the "Recette build IOS App" workflow)
- <u>profile_name</u>: the provisioning profile file name (provided by the "Recette build IOS App" workflow)

The main steps of "wc_test" are:
- Retrieve the source code from the repository
- Configure Xcode with the specified version 'xcodeversion'
- Execute the tests

<br>

***

### "wc_build" workflow

The "wc_build" workflow is a reusable workflow called by the "**Recette build IOS App**" workflow. Its main objective is to compile the application and generate an artifact whose name depends on the environment and version.
This workflow uses two actions, "**apple-certificate/action**" and "**apple-provisionning/action**", to import a P12 certificate and provide an Apple provisioning profile (essential for iOS application development and deployment).

The required inputs are:

- <u>xcodeversion</u>: the version of Xcode used (provided by the "Recette build IOS App" workflow)
- <u>profileName</u>: the provisioning profile file name (provided by the "Recette build IOS App" workflow and passed to the "apple-provisioning" action)
- <u>projectName</u>: the Xcode project name (provided by the "Recette build IOS App" workflow)
- <u>xarchivePath</u>: the path where the archive created with Xcode will be exported (provided by the "Recette build IOS App" workflow)
- <u>plistPath</u>: export options for the archive (provided by the "Recette build IOS App" workflow)

The optional inputs are:

- <u>environment</u>: the GitHub environment name, which defaults to 'dev' or 'pprd' when provided by the "Recette build IOS App" workflow
- <u>branches</u>: the Git branch from which the source code will be retrieved (default: 'develop')

The required secrets are:

- <u>PROVISIONING_PROFILE</u>: the provisioning profile file (provided by the "Recette build IOS App" workflow from GitHub secrets and passed to the "apple-provisioning" action)
- <u>CERTIFICATES_P12</u>: the P12 certificate (provided by the "Recette build IOS App" workflow from GitHub secrets and passed to the "apple-certificate" action)
- <u>KEYCHAIN_PASSWORD</u>: the keychain password (provided by the "Recette build IOS App" workflow from GitHub secrets and to the "apple-certificate" action to unlock the keychain)
- GH_PAT: GitHub token for retrieving the source code ( provided by the "Recette build IOS App" workflow from GitHub secrets)

The optional secrets are:

- <u>CERTIFICATES_P12_PASSWORD</u>: the password for the P12 certificate (provided by the "Recette build IOS App" workflow from GitHub secrets and passed to the "apple-certificate" action)

The main steps of "wc_build" are:
- Retrieve the source code from the repository using the 'branches' and 'GH_PAT' token
- Select the specified Xcode version using 'xcodeversion'
- Update the application version using the agvtool tool and retrieve the version in the 'VERSION' variable (output), which will be used for artifact naming
- Install the required Apple provisioning profile for application build using the "apple-provisioning" action and providing 'PROVISIONING_PROFILE' and 'profileName'
- Install the required Apple P12 certificate for application build using the "apple-certificate" action and providing 'CERTIFICATES_P12', 'CERTIFICATES_P12_PASSWORD', and 'KEYCHAIN_PASSWORD'
- Compile and generate an application archive using the "xcodebuild" command with 'CONFIGURATION_BUILD', 'projectName', 'xarchivePath', and 'profileName' variables
- Export the archive as a GitHub artifact using the "xcodebuild -exportArchive" command and the 'xarchivePath', 'CONFIGURATION_BUILD', and 'plistPath' variables
- Copy the application dSYM file to the 'Release' directory in the GitHub workspace
- Upload the archive as a GitHub artifact using the "upload-artifact" action from the 'Release' directory, naming it based on the 'environment' and the previously retrieved version.

<br>

***

### "run-create-release-from-artifact" workflow

The "run-create-release-from-artifact" workflow is triggered manually (with the branch and artifact name as inputs) to generate a GitHub release from the artifact generated by the "**Recette build IOS App**" workflow.

The required inputs are:
- <u>branch</u>: the name of the git branch from which the release will be created, with 'main' as the only available option
- <u>nameArtifact</u>: the name of the artifact that will be used to generate the release

The main steps of the "run-create-release-from-artifact" are:
- Check out the source code from the repository using the specified 'branch'
- Retrieve an artifact created from the "Recette build IOS App" workflow (if that workflow did not fail) with the specified 'nameArtifact', using the GitHub token 'GH_PAT'
- Create a release with the version extracted from the artifact's name (release-version) and export it as 'NAME' (output)
- Create and push a TAG named 'NAME' to GitHub using the 'GH_PAT' token
- Compress the dSYM file
- Display the list of files in the directory
- Create the named release using 'name', including the compressed dSYM file and the IPA file

<br>

***

### "develop-schedule-build-dev" workflow

The "develop-schedule-build-dev" workflow is automatically triggered every 2 hours between 8 AM and 6 PM. It checks the latest commit pushed to the develop branch, and if that commit is less than two hours old, the workflow will display "scheduled activated".

This workflow consists of 2 jobs:

- check_changes:
    - Retrieve the source code from the 'develop' branch of the repository
    - Display the latest commit
    - Check the commit date. If it is less than 2 hours ago, set the 'should_run' variable (output) to true

- build:
    - This step is triggered when the 'check_changes' step is completed and the 'should_run' variable is true
    - Retrieve the source code from the repository
    - Display "schedule activated" (a message indicating that the scheduler has been activated)

<br>

***

### "apple-certificat" action

The "apple-certificate" action allows the import of a P12 certificate, which provides the necessary credentials to sign and authenticate iOS applications during the build process.

The required inputs are:

- <u>P12_FILE_BASE64</u>: The file encoded in base64 (provided from the "wc_build" workflow using GitHub secrets)
- <u>KEYCHAIN_PASSWORD</u>: The password for the keychain (provided from the "wc_build" workflow using GitHub secrets)

The optional inputs are:

- <u>P12_PASSWORD</u>: The password for the P12 file (provided from the "wc_build" workflow using GitHub secrets)
- <u>P12_FILEPATH</u>: The path to place the P12 file (default is the temporary directory of the runner)
- <u>KEYCHAIN_PATH</u>: The path to place the keychain (default is the temporary directory of the runner)

The main steps of the 'apple-certificate' action are:

- Decode the P12 file 'P12_FILE_BASE64' and place it in the specified file path 'P12_FILEPATH'
- Create a keychain (used to store and manage sensitive security information) with password 'KEYCHAIN_PASSWORD' and specified path 'KEYCHAIN_PATH'
- Configure the keychain by setting a lock timeout (access time)
- Unlock the keychain with 'KEYCHAIN_PASSWORD' in 'KEYCHAIN_PATH'
- Display the list of files present in the runner's temporary directory
- Import the P12 file into the keychain (from 'P12_FILEPATH' and unlocked with 'P12_PASSWORD') as a PKCS12 certificate
- Display the list of keychains present in 'KEYCHAIN_PATH'

<br>

***

### "apple-provisionning" action

The "apple-provisioning" action allows the installation of an Apple provisioning profile that contains specific application-specific credentials, enabling the signing and authorization of the iOS application during the build process.

The required inputs are:

- <u>PROFILE_BASE64</u>: The base64-encoded provisioning profile file (provided from the "wc_build" workflow using GitHub secrets)
- <u>PROFILE_NAME</u>: The name of the provisioning profile file (provided from the "wc_build" workflow, which in turn retrieves it from the "Recette build IOS App" workflow using GitHub secrets)

The main steps of the "apple-provisioning" action are:

- Decoding the provisioning profile file 'PROFILE_BASE64' and placing it in the runner's temporary directory with the specified name 'PROFILE_NAME'
- Creating a new directory and copying the provisioning profile file into that directory