part of aliyun_oss_flutter;


class OSSObject {
  OSSObject._(this.name,this.parentKey,this.isDir):key = parentKey + name;

  OSSObject.key(this.key):isDir = key[key.length-1] =='/'{
    //如果是文件夹就删除最后一位
    final substring = this.isDir? this.key.substring(0,this.key.length-1) :this.key;
    var separateIndex = substring.lastIndexOf("/");
    this.name = substring.substring(separateIndex==-1?0:separateIndex,substring.length);
    this.parentKey = substring.substring(0,separateIndex+1);
  }
  OSSObject.local(this.name,this.parentKey,this.isDir):key = parentKey + name;

  //唯一key
  String key;
  //是否是文件夹
  bool isDir;
  late String name;
  late String parentKey;
  int? size;
  //云端是否存在
  bool exist = true;

  List<OSSObject> childrenObject = [];

  @override
  String toString() {
    // TODO: implement toString
    return key+":"+childrenObject.toString();
  }
}
