import 'dart:io';
import 'package:aliyun_oss_flutter2/aliyun_oss_flutter2.dart';
import 'test_oss_info2.dart';

void main() async{
  //这里直接用子账号授权
  init();
  //上传文件
  // await putTest("D:/19135//Pictures/pexels-pixabay-207636.jpg",DateTime.now().toString()+".jpg");
  //获取文件列表
  final listObjects = await OSSClient().listObject(rootKey: "",deep: false);
  print(listObjects);
  print(listObjects.length);
  //下载文件
  // await OSSClient().getObject(OSSObjectGet("test/2022-01-02 1Delimiter1:31:28.948102.jpg", r"D:\19135\Pictures\948102.jpg"),onReceiveProgress: (count,total){
  //   print("${count}/${total}");
  // });

}

//初始化授权
void init(){
  // 初始化OSSClient
  OSSClient.init(
    endpoint: OSSInfo.Endpoint,
    bucket: OSSInfo.Bucket,
    credentials: () async{
      return Credentials(
        accessKeyId: OSSInfo.accessKeyId,
        accessKeySecret: OSSInfo.AccessKeySecret,
      );
    },
  );
}
//上传文件
Future<void> putTest(String filePath,String oosName) async{
  var file = File(filePath);
  //文件不存在
  if (! await file.exists()) {
    print("文件不存在");
    return;
  }

  final object = await OSSClient().putObject(
    OSSObjectPut.fromFile(file:file,key:oosName),
    path: "test", // String?
  );
}