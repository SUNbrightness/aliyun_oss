part of aliyun_oss_flutter;

class OSSObjectGet extends OSSObject {
    String savePath;
    OSSObjectGet(String key,this.savePath) : super.key(key);
}