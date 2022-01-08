# aliyun_oss_flutter

aliyun oss plugin for flutter. Use this plugin to upload、download、list files to aliyun oss.

## Usage


## 功能
- [x] PutObject 添加的Object大小不能超过5 GB。
- [x] ListObject 仅仅获取1000数据量一下的文件，oss设定
- [x] GetObject 下载文件到本地
- [] ListObject 分页获取文件

```dart
void main() async{
  //这里直接用子账号授权
  init();
  //上传文件
  await putTest("D:/19135//Pictures/pexels-pixabay-207636.jpg",DateTime.now().toString()+".jpg");
  //获取文件列表
  final listObjects = await OSSClient().listObjectsLimit1000();
  print(listObjects);
  //下载文件
  await OSSClient().getObject(OSSObjectGet("test/2022-01-02 11:31:28.948102.jpg", r"D:\19135\Pictures\948102.jpg"),onReceiveProgress: (count,total){
    print("${count}/${total}");
  });

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
```


### Example
感谢打牢提供的认证及上传代码 https://github.com/lucky1213/aliyun_oss
因改动太大我就不pull requet 了