import 'package:disk_space_2/disk_space_2.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

class StorageInfo
{

  StorageInfo();

  double totalDiskSpace = 0;
  double freeDiskSpace = 0;
  double consumedSpace = 0;
  double mib_to_gb_convFactor = 0.001048576;

  void fetchStorageInfo() async
  {
    totalDiskSpace = await updateStorageInfo("totalSpace", null);
    freeDiskSpace = await updateStorageInfo("freeSpace", null);
    consumedSpace = await updateStorageInfo("consumedSpace", null);

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
  
}


class Settings{

  Settings();

  double recordingStorageLimit = 0;
  bool runInBackground = false;
  SharedPreferencesAsync prefs = SharedPreferencesAsync();
  bool useExtStorage = false; //SD Card
  Directory extStoragePath = Directory("");

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

