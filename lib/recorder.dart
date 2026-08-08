
import 'dart:async';

import 'main.dart';
import 'package:gal/gal.dart';
import 'dart:io';
import 'package:path/path.dart' as path;
import 'package:intl/intl.dart';
import 'package:camera/camera.dart';
import 'package:toastification/toastification.dart';
import 'package:flutter/material.dart';

class Recorder{
  late DateTime startTimeStamp;
  late DateTime endTimeStamp;
  Duration loopTime = Duration(minutes: 3);
  late XFile recordedFile;
  String albumName = "DashCam_Recordings";
  late Timer recordingTimer;
  bool isRecording = false;
  final List<Future<void>> pendingSaves = [];

  //Constructor
  Recorder();
  
  void updateAlbumName(String newName)
  {
    albumName = newName;
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

  void queueSave(XFile videoFile, String camType)
  {
    final newSave = endRecording(videoFile, camType);
    pendingSaves.add(newSave);
    newSave.whenComplete(() => pendingSaves.remove(newSave));
  }

  Future<void> cleanup() async
  {
    recordingTimer.cancel();
    await Future.wait(pendingSaves);
  }
  Future<void> endRecording(XFile videoFile, String camType) async
  {

    //Rename the video file
    recordedFile = await renameRecording( videoFile,camType );
    try{
      //Recompile using ffmpeg to insert timestamp in each frame
      //TODO SOON

      if(await Gal.hasAccess())
      {
        //await Future.delayed(const Duration(seconds:3));
        //Copy the recorded file to the Gallery (DCIM folder)
        await Gal.putVideo(recordedFile.path,album: albumName);

        //Delete the old file (in the internal folder) to prevent wasted space
        File oldFile = File(recordedFile.path);
        if( await oldFile.exists())
        {
          await oldFile.delete();
        }

        //Show the notification
        toastification.show(
          type: ToastificationType.info,
          style: ToastificationStyle.flat,
          title: Text('Recording Notification'),
          autoCloseDuration: const Duration(seconds: 5),
          description: Text('Saved ${recordedFile.name}'),
          alignment: Alignment.bottomCenter,
          );

      }
    }
    on GalException catch (e)
    {
      debugPrint("ERROR IN RUNTIME: ");
      debugPrint(e.toString());
    }

  }

  void toggleLoopRecording(CameraController? camController) async
  {
    
    if(isRecording) //End the loop recording
    {
      //Check if the timer is running
      if(recordingTimer.isActive)
      {
        //End the timer
        recordingTimer.cancel();
        
        if(camController!.value.isRecordingVideo)
        {
          //Save the recording
          XFile originalFile = await camController.stopVideoRecording();
          //Update endTimeStamp and end stopwatch
          endTimeStamp = DateTime.now();
          queueSave(originalFile, "Rear"); 
        }
        
      }

      isRecording = false;
    }
    else{ //Start the loop recording
      isRecording = true;

      //Start the recording
      startTimeStamp = DateTime.now();
      await camController!.prepareForVideoRecording();
      await camController.startVideoRecording();

      //Re-initialize timer
      recordingTimer = Timer.periodic(loopTime, (timer) async{

        if(camController.value.isRecordingVideo)
        {
          //End the recording
          XFile originalFile = await camController.stopVideoRecording();
          //Update endTimeStamp and end stopwatch
          endTimeStamp = DateTime.now();
          queueSave(originalFile, "Rear"); 

          
        }
        
        
        

        //Start the recording
        startTimeStamp = DateTime.now();
        camController.prepareForVideoRecording();
        camController.startVideoRecording();
      });
    }
    

    
    
  }


}