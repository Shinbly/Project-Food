import 'dart:convert';
import 'dart:io';

Future  storeInCache(String fileName, String directoryName, dynamic content ) async{
  try{
    String _cachedSearchFileName = fileName;
    Directory tempDir = Directory.systemTemp;
    Directory searchDir = Directory("${tempDir.path}/$directoryName");
    if(! await searchDir.exists()){
      await searchDir.create();
    }
    File cachedFile = File("${tempDir.path}/$directoryName/$_cachedSearchFileName");
    if(!await cachedFile.exists()){
      await cachedFile.create();
    }
    return cachedFile.writeAsString(jsonDecode(content));
  }catch(e){}
}

Future<dynamic> getInCache(String fileName,String directoryName) async {
  try {
    String _cachedSearchFileName = fileName;
    Directory tempDir = Directory.systemTemp;
    Directory searchDir = Directory("${tempDir.path}/$directoryName");
    if (!await searchDir.exists()) {
      return null;
    }
    File cachedFile = File("${tempDir.path}/$directoryName/$_cachedSearchFileName");
    if (!await cachedFile.exists()) {
      return null;
    }
    return cachedFile.readAsString();
  }catch(e){
    return null;
  }
}