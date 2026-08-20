import 'package:disk_space_2/disk_space_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:photo_manager/photo_manager.dart';
import 'package:flutter/material.dart';


class StorageInfo
{

  StorageInfo();

  double totalDiskSpace = 0;
  double freeDiskSpace = 0;
  double consumedSpace = 0;
  double mib_to_gb_convFactor = 0.001048576;
  double consumedVideoSpace = 0;

  void fetchStorageInfo() async
  {
    totalDiskSpace = await updateStorageInfo("totalSpace", null);
    freeDiskSpace = await updateStorageInfo("freeSpace", null);
    consumedSpace = await updateStorageInfo("consumedSpace", null);
    consumedVideoSpace = await fetchStoredVideoSize();

  }

  Future<double> updateStorageInfo(String type, String? pathStr ) async
  {
    double ret = 0;

    if(type == "totalSpace")
    {
      ret = await DiskSpace.getTotalDiskSpace ?? 0;
    }
    else if(type == "freeSpace")
    {
      ret = await DiskSpace.getFreeDiskSpace ?? 0;
    }
    else if(type == "consumedSpace")
    {
      ret = (await DiskSpace.getTotalDiskSpace)! - (await DiskSpace.getFreeDiskSpace)!;
    }
    else if(type == "specificSpace" )
    {
      final dir_path = Directory(pathStr ?? "");
      if(await dir_path.exists())
      {
        ret = await DiskSpace.getFreeDiskSpaceForPath(pathStr ?? "") ?? 0;
      }
    }


    return double.parse((ret * mib_to_gb_convFactor).toStringAsFixed(2));
  }

  Future<double> fetchStoredVideoSize() async
  {
    double accumulatedSize = 0;
    //Check permissions
    PermissionState permission = await PhotoManager.requestPermissionExtend();
    if(!permission.isAuth) return -1;

    //Define Regex pattern
    final RegExp fileNamePattern = RegExp(r'^\d+_\d+_\w+\.mp4$');

    //Get all possible video locations
    List<AssetPathEntity> videoLocations = await PhotoManager.getAssetPathList(type: RequestType.video);

    //Iterate through each path
    for(var videoPath in videoLocations)
    {
      //Get the number of assets or video files in each path
      final numOfAssets = await videoPath.assetCountAsync;
      //Get the list of assets or videos
      List<AssetEntity> videoList = await videoPath.getAssetListRange(start: 0, end: numOfAssets, type: RequestType.video);

      //Iterate through each video
      for(var video in videoList)
      {

        //Check if the video is a dashcam video based on filename
        var fileName = await video.titleAsync;
        bool isDashCamVideo = fileNamePattern.hasMatch(fileName);

        //If the video is a dashcam video, add the filesize to the running sum
        if(await video.exists && video.type == AssetType.video &&  isDashCamVideo)
        {
          int fileSize = await video.fileSize;
          accumulatedSize += fileSize.toDouble();
        }
        
      }

    }

    //Convert the size from bytes to Gigabytes
    accumulatedSize /= 1000000000;

    //Return the total sum in gigabytes
    return accumulatedSize;

  }
  
}


class Settings{

  Settings();

  double recordingStorageLimit = 0;
  bool runInBackground = false;
  SharedPreferencesAsync prefs = SharedPreferencesAsync();
  bool useExtStorage = false; //SD Card
  Directory extStoragePath = Directory("");
  int loopRecordingDuration = 0;

  void initializeSettings() async
  {
    //Check the initially stored data
    if(await prefs.containsKey("storage_limit"))
    {
      recordingStorageLimit = await prefs.getDouble("storage_limit") ?? 0.00;
    }


    if(await prefs.containsKey("enable_running_in_background"))
    {
      runInBackground = await prefs.getBool("enable_running_in_background") ?? false;
    }

    if(await prefs.containsKey("use_external_storage"))
    {
      runInBackground = await prefs.getBool("enable_running_in_background") ?? false;
    }
    if(await prefs.containsKey("loop_recording_duration"))
    {
      loopRecordingDuration = await prefs.getInt("loop_recording_duration") ?? 0;
    }

  }


  void setParameter<T>(String key, T value) async{
    if(key == "storage_limit" && value is double)
    {
      await prefs.setDouble("storage_limit", (value as double));
    }
    else if(key == "enable_running_in_background" && value is bool )
    {
      await prefs.setBool("enable_running_in_background", (value as bool));
    }
    else if(key == "use_external_storage" && value is bool )
    {
      await prefs.setBool("use_external_storage", (value as bool));
    }
    else if(key == "loop_recording_duration" && value is int )
    {
      await prefs.setInt("loop_recording_duration", (value as int));
    }
  }

  Future<T> getParameter<T>(String key) async{
    if(key == "storage_limit")
    {
      return await prefs.getDouble("storage_limit") as T;
    }
    else if(key == "enable_running_in_background" )
    {
      return await prefs.getBool("enable_running_in_background") as T;
    }
    else if(key == "use_external_storage" )
    {
      return await prefs.getBool("use_external_storage") as T;
    }
    else if(key == "loop_recording_duration" )
    {
      return await prefs.getInt("loop_recording_duration") as T;
    }
    else{
      return false as T;
    }
  }

  void isExtStoragePresent() async
  {
    List<Directory>? directories = await getExternalStorageDirectories();

    if(directories != null && directories.isNotEmpty)
    {
      for(Directory d in directories)
      {
        debugPrint("DETECTED FILEPATHS:");
        debugPrint('Path: ${d.path}');
        if(!d.path.contains('emulated') && !d.path.contains('/storage/self'))
        {
          if(await d.exists())
          {
            useExtStorage = true;
          }
        }
      }
    }
    useExtStorage = false;
  }

  void getExtStoragePath() async
  {
    List<Directory>? directories = await getExternalStorageDirectories();

    if(directories != null && directories.isNotEmpty)
    {
      for(Directory d in directories)
      {
        if(!d.path.contains('emulated') && !d.path.contains('/storage/self'))
        {
          if(await d.exists())
          {
            extStoragePath = d;
          }
        }
      }
    }

  }

}

