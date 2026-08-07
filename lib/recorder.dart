
import 'main.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:camera/camera.dart';

class Recorder{
  late DateTime startTimeStamp;
  late DateTime endTimeStamp;
  Duration loopTime = Duration(minutes: 3);
  Stopwatch timer = Stopwatch();
  late XFile recordedFile;
  String albumName = "DashCam_Recordings";
  //Constructor
  Recorder();
  
  void updateAlbumName(String newName)
  {
    albumName = newName;
  }

  void setStartTime()
  {
    startTimeStamp = DateTime.now();
  }

  void setEndTime()
  {
    endTimeStamp = DateTime.now();
  }

  Future<XFile> renameRecording(XFile initialVideo, String cameraType) async {
    
    //Convert XFile to File class to rename it
    File origFile = File(initialVideo.path);

    //Get the timestamp and file extension
    String formattedDateTime = DateFormat('yyyyMMdd_hhmmss').format(startTimeStamp);
    String fileExtension = path.extension(initialVideo.path);
    
    //Create a new string combining all the extracted info
    String newFileName = '${formattedDateTime}_$cameraType$fileExtension';
    String newFilePath = path.join(path.dirname(initialVideo.path), newFileName);

    //Rename the file
    File renamedFile = await origFile.rename(newFilePath);

    //Return the renamed file as an XFile
    return XFile(renamedFile.path);

  }

  void endRecording(Future<XFile> videoFile, String camType) async
  {
    //Update endTimeStamp and end stopwatch
    endTimeStamp = DateTime.now();
    if(timer.isRunning)
    {
      timer.stop();
      
    }
      
    //Rename the video file
    recordedFile = await renameRecording(await videoFile,camType );
    try{
      //Recompile using ffmpeg to insert timestamp in each frame
      //TODO SOON

      if(await Gal.hasAccess())
      {
        //Copy the recorded file to the Gallery (DCIM folder)
        Gal.putVideo(recordedFile.path,album: albumName);

        //Delete the old file (in the internal folder) to prevent wasted space
        File oldFile = File(recordedFile.path);
        if( await oldFile.exists())
        {
          await oldFile.delete();
        }

      }
    }
    catch (e)
    {
      
    }
    



  }


}