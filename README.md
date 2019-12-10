# AWS SDK for .NET - Unity Archive

If you are using Unity 2018.1 or later, please use the [AWS SDK for .NET](https://github.com/aws/aws-sdk-net) .NET Standard 2.0
binaries. Doing so will let you use all AWS offerings, use new features as soon as they are available,
and offers the same support as all other .NET Standard 2.0 platforms.

This is the archive for legacy Unity support. This repository is provided for customers who are currently using the Unity
specific binaries. This repository will not be supported by the AWS SDK for .NET team; use at your own risk. Please
consider migrating your app to a newer version of Unity, and use the AWS SDK for .NET - .NET Standard 2.0 binaries.

## Supported Services

This repository offers Unity support for the following packages:

* [Amazon Cognito](http://aws.amazon.com/cognito/)
* [Amazon DynamoDB](http://aws.amazon.com/dynamodb/)
* [AWS Identity and Access Management ](http://aws.amazon.com/)
* [Amazon Kinesis Streams](https://aws.amazon.com/kinesis/streams/)
* [AWS Lambda](https://aws.amazon.com/lambda/)
* [Amazon Mobile Analytics](http://aws.amazon.com/mobileanalytics/)
* [Amazon Simple Email Service](https://aws.amazon.com/ses/)
* [Amazon Simple Notification Service](http://aws.amazon.com/sns/)
* [Amazon Simple Queue Service](https://aws.amazon.com/sqs/)
* [Amazon Simple Storage Service](http://aws.amazon.com/s3/)

## Supported Unity Version

Unity versions > 4.6

If you are using Unity 2018.1 or later, please use the [AWS SDK for .NET](https://github.com/aws/aws-sdk-net) .NET Standard 2.0
binaries.

## Supported Platforms

The AWS SDK for .NET (Unity) is currently only supported on Android, iOS and on Standalone platforms.

## Unity SDK Fundamentals

There are only a few fundamentals that are helpful to know when developing against the AWS SDK for .NET on Unity

* To enable logging you need to create a config file called awsconfig.xml in a `Resources` directory add add the following

		<?xml version="1.0" encoding="utf-8"?>
		<aws 
			<logging
	    		logTo="UnityLogger"
	    		logResponses="Always"
	    		logMetrics="true"
	    		logMetricsFormat="JSON" />
			/>
		/>
	
  You can also do this configuration in a script

		var loggingConfig = AWSConfigs.LoggingConfig;
		loggingConfig.LogTo = LoggingOptions.UnityLogger;
		loggingConfig.LogMetrics = true;
		loggingConfig.LogResponses = ResponseLoggingOption.Always;
		loggingConfig.LogResponsesSizeLimit = 4096;
		loggingConfig.LogMetricsFormat = LogMetricsFormatOption.JSON;


* To Build the SDK from the `AWSSDK.Unity.sln` solution file you will need to either:
  * Have a Unity install location of C:\Program Files\Unity\
  * Specify the UnityDataPath msbuild parameter, pointing to the Editor>Data location inside your Unity install.

* The SDK uses reflection for platform specific components. In case of IL2CPP since `strip bytecode` is always enabled on iOS you need to have a `link.xml` in your assembly root with the following entries

		<linker>
			<!-- if you are using AWSConfigs.HttpClient.UnityWebRequest option-->

		<assembly fullname="UnityEngine">
			<type fullname="UnityEngine.Networking.UnityWebRequest" preserve="all" />
			<type fullname="UnityEngine.Networking.UploadHandlerRaw" preserve="all" />
			<type fullname="UnityEngine.Networking.UploadHandler" preserve="all" />
			<type fullname="UnityEngine.Networking.DownloadHandler" preserve="all" />
			<type fullname="UnityEngine.Networking.DownloadHandlerBuffer" preserve="all" />
		</assembly>
		
		<assembly fullname="mscorlib">
			<namespace fullname="System.Security.Cryptography" preserve="all"/>
   		</assembly>

		<assembly fullname="System">
			<namespace fullname="System.Security.Cryptography" preserve="all"/>
   		</assembly>

		<assembly fullname="AWSSDK.Core" preserve="all">
			<namespace fullname="Amazon.Util.Internal.PlatformServices" preserve="all"/>
		</assembly>
   		<assembly fullname="AWSSDK.CognitoIdentity" preserve="all"/>
   		<assembly fullname="AWSSDK.SecurityToken" preserve="all"/>
		add more services that you need here... 
		</linker>
