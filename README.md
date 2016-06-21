# Visual Studio Team Services Task
## Overview
This repository contains a Visual Studio Team Services (VSTS) task for deploying a WebApplication with Umbraco to Umbraco as a Service.

The following sections describes how to use this task in your own VSTS account, how to configure the Build and Deploy and finally how to setup a Visual Studio solution with Umbraco in order to successfully deploy it to Umbraco as a Service.

The approach outlined here assumes that you have a VSTS account and an Umbraco as a Service project.

## How to use this Task
## Setting up Build and Deploy tasks for Umbraco as a Service

`/p:UseWPP_CopyWebApplication=True /p:PipelineDependsOnBuild=False /p:PublishProfile=ToFileSys.pubxml /p:DeployOnBuild=true /p:AutoParameterizationWebConfigConnectionStrings=False /p:PublishOutDir=$(Build.StagingDirectory)\_Publish`

```
<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003">
  <PropertyGroup>
    <WebPublishMethod>FileSystem</WebPublishMethod>
    <ExcludeApp_Data>True</ExcludeApp_Data>
    <publishUrl>$(PublishOutDir)</publishUrl>
    <DeleteExistingFiles>False</DeleteExistingFiles>
  </PropertyGroup>
</Project>
```

## Setting up Umbraco in Visual Studio