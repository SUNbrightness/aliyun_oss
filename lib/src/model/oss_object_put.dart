part of aliyun_oss_flutter;

class OSSObjectPut extends OSSObject {

  //数据格式
  MediaType mediaType;
  //二进制数据
  Uint8List bytes;
  //远程地址
  String? url;
  OSSObjectPut._({
    required this.bytes,
    required this.mediaType,
    required String key,
  }) : super.key(key){exist=false;}

  factory OSSObjectPut.fromBytes({
    required Uint8List bytes,
    required MediaType mediaType,
    required String key,
  }) {
    return OSSObjectPut._(
      bytes: bytes,
      mediaType: mediaType,
      key: key,
    );
  }
  factory OSSObjectPut.fromFile({
    required File file,
    required String key,
  }) {
    String subtype = path.extension(file.path).toLowerCase();
    subtype = subtype.isNotEmpty ? subtype.replaceFirst('.', '') : '*';
    return OSSObjectPut._(
      bytes: file.readAsBytesSync(),
      mediaType: MediaType('text', subtype),
       key :key,
    );
  }
}