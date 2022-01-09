part of aliyun_oss_flutter;

class OSSClient {
  factory OSSClient() {
    return _instance!;
  }

  OSSClient._({
    required this.endpoint,
    required this.bucket,
    required this.credentials,
  }) {
    _signer = null;
  }

  /// * 初始化设置`endpoint` `bucket` `getCredentials`
  /// * [credentials] 获取 `Credentials`
  /// * 一旦初始化，则`signer`清空，上传前会重新拉取oss信息
  static OSSClient init({
    required String endpoint,
    required String bucket,
    required Future<Credentials> Function() credentials,
  }) {
    _instance = OSSClient._(
      endpoint: endpoint,
      bucket: bucket,
      credentials: credentials,
    );
    return _instance!;
  }

  static OSSClient? _instance;

  Signer? _signer;

  final String endpoint;
  final String bucket;
  final Future<Credentials> Function() credentials;

  /// * [bucket] [endpoint] 一次性生效
  /// * [path] 上传路径 如不写则自动以 Object[type] [time] 生成path
  Future<OSSObjectPut> putObject(OSSObjectPut object,{
    String? bucket,
    String? endpoint,
    String? path,
    ProgressCallback? onSendProgress
  }) async {
    await verify();

    final String objectPath = object.key;

    final Map<String, dynamic> safeHeaders = _signer!.sign(
      httpMethod: 'PUT',
      resourcePath: '/${bucket ?? this.bucket}/$objectPath',
      headers: {
        'content-type': object.mediaType.mimeType,
      },
    ).toHeaders();
    try {
      final String url =
          'https://${bucket ?? this.bucket}.${endpoint ?? this.endpoint}/$objectPath';
      final Uint8List bytes = object.bytes;
      // if (object is OSSImageObject && !object.fullImage) {
      //   bytes = MediaAssetUtils.compressImage(file);
      // }
      await _http.put<void>(
        url,
        data: Stream.fromIterable(bytes.map((e) => [e])),
        options: Options(
          headers: <String, dynamic>{
            ...safeHeaders,
            ...<String, dynamic>{
              'content-length': object.bytes.length,
            }
          },
          contentType: object.mediaType.mimeType,
        ),
          onSendProgress:onSendProgress
      );
      object.url = url;
      object.exist = true;
      return object;
    } catch (e) {
      rethrow;
    }
  }
  Future<void> getObject(OSSObjectGet ossObject,
      {String? bucket,
        ProgressCallback? onReceiveProgress,
        String? endpoint,
      }) async{
    await verify();
    final Map<String, dynamic> safeHeaders = _signer!.sign(
      httpMethod: 'GET',
      resourcePath: '/${bucket ?? this.bucket}/${ossObject.key}'
    ).toHeaders();
      final String url = 'https://${bucket ?? this.bucket}.${endpoint ?? this.endpoint}/${ossObject.key}';
      await _http.download(url, ossObject.savePath,
        options: Options(
          headers: <String, dynamic>{
            ...safeHeaders,
          },
        ),
          onReceiveProgress: onReceiveProgress
      );
  }


  //最大返回数据量100
  Future<List<OSSObject>> listObject({
    String? bucket,
    String? endpoint,
    String rootKey="",
    bool deep=true
  }) async {
    if(rootKey=="/"){
      rootKey = "";
    }else if(rootKey.isNotEmpty && rootKey[rootKey.length-1]!="/"){
      rootKey = rootKey + "/";
    }

    await verify();
    List<OSSObject> rootList = [];
    Map<String,OSSObject> cacheMap = {};
    String continuationToken = "";
    do{
      continuationToken =  await _listObjects(rootList,cacheMap,bucket:bucket,endpoint: endpoint,rootKey: rootKey,deep: deep,continuationToken: continuationToken);
        }while(continuationToken.isNotEmpty);

    return rootList;
  }

  //rootList 根object存放的集合，cacheMap 缓存用的
   Future<String> _listObjects(List<OSSObject> rootList,Map<String,OSSObject> cacheMap,{
    String? bucket,
    String? endpoint,
    String rootKey="",
    bool deep=true,
     String? continuationToken
  }) async {
    final Map<String, dynamic> safeHeaders = _signer!.sign(
        httpMethod: 'GET',
        resourcePath: '/${bucket ?? this.bucket}/',
        parameters: {
          //只有这个参数需要验证。。
          if(continuationToken?.isNotEmpty??false)"continuation-token":continuationToken!
        }
    ).toHeaders();

    final String url =
        'http://${bucket ?? this.bucket}.${endpoint ?? this.endpoint}';
    var result = await _http.get<String>(
      url,
      queryParameters: <String, dynamic>{
        'list-type':'2',
        'max-keys':1000,
        if(rootKey.isNotEmpty)"prefix":rootKey,
        if(!deep)"delimiter":"/",
        if(continuationToken?.isNotEmpty??false)"continuation-token":continuationToken
      },
      options: Options(
        headers: <String, dynamic>{
          ...safeHeaders,
        },
      ),
    );
    if(result.statusCode !=200){
      throw Exception(result);
    }
    //解析ddocument
    var rootDocument = XmlDocument.parse(result.data??"");
    var document = rootDocument.getElement("ListBucketResult");
    final childElements2 = document?.findAllElements("Contents");
    //整理数据
    childElements2?.forEach((element) {
      final String key = element.getElement("Key")!.text;
      final int size = int.parse(element.getElement("Size")?.text??"0");
      //填充其基本信息
      if(!cacheMap.containsKey(key)){
        cacheMap[key] = new OSSObject.key(key);
      }
      cacheMap[key]!.size = size;
      //找到对应父节点并构建层级目录
      _buildObjectTree(rootKey,rootList,cacheMap[key]!,cacheMap);
    });
    //空文件夹在 CommonPrefixes 节点中存储
    final commonPrefixes = document?.findAllElements("CommonPrefixes");
    commonPrefixes?.forEach((element) {
      var key = element.getElement("Prefix")!.text;
      if(!cacheMap.containsKey(key)){
        cacheMap[key] = new OSSObject.key(key);
        _buildObjectTree(rootKey,rootList,cacheMap[key]!,cacheMap);
      }
    });

    //数据最大只能一次返回1000还有其他数据需要再次请求
    final isTruncated = document?.getElement("IsTruncated")?.text;
    if(isTruncated=="true"){
      //返回请求剩余数据的token
      return document!.getElement("NextContinuationToken")!.text;
    }
    return "";
   }

  void _buildObjectTree(String rootKey,List<OSSObject> rootList,OSSObject oss,Map<String,OSSObject> cacheMap){
    //是否是正在目标目录的相对根节点
    final indexOf = oss.key.indexOf(rootKey);
    if(indexOf ==0){
      //属于当前节点
      final noRootPath = oss.key.substring(rootKey.length,oss.key.length);
      // AAA/ or bb.jpg
      final indexOf2 = noRootPath.indexOf("/");
      if((noRootPath.isNotEmpty&& indexOf2==-1 )|| indexOf2 == noRootPath.length-1){
        rootList.add(oss);
        //当前是根节点
        return;
      }
    }

    final parentKey = oss.parentKey;
    //找到了最大根节点
    if(parentKey.isEmpty){
      return null;
    }

    //父节点不存在就创建一个
    if(!cacheMap.containsKey(parentKey)&&parentKey.isNotEmpty){
      cacheMap[parentKey] = new OSSObject.key(parentKey);
      //父节点插入其父节点private_tcm
      this._buildObjectTree(rootKey, rootList, cacheMap[parentKey]!,cacheMap);
    }
    //将当前节点插入父节点
    cacheMap[parentKey]?.childrenObject.add(oss);
  }

  /// 验证检查
  Future<void> verify() async {
    // 首次使用
    if (_signer == null) {
      _signer = Signer(await credentials.call());
    } else {
      // 使用securityToken进行鉴权，则判断securityToken是否过期
      if (_signer!.credentials.useSecurityToken) {
        if (_signer!.credentials.expiration!.isBefore(DateTime.now().toUtc())) {
          _signer = Signer(await credentials.call());
        }
      } else {
        // expiration | securityToken中途丢失，则清空
        _signer!.credentials.clearSecurityToken();
      }
    }
  }
}
