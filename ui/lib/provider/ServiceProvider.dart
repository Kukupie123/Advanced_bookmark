// ignore_for_file: file_names

import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:ui/models/BookmarkModel.dart';
import 'package:ui/models/TemplateField.dart';
import 'package:ui/models/TemplateModel.dart';

import '../models/DirectoryModel.dart';
import '../models/Response/BaseResponseModel.dart';
import '../utils/Utils.dart';

class ServiceProvider {
  //AUTH SERVICE------------------------
  Future<String> login(String email, String password) async {
    String url = URLs.AUTH_BASE_URL + URLs.AUTH_LOGIN_URL;

    String body = jsonEncode({"email": email, "password": password});
    http.Response response = await http.post(Uri.parse(url),
        body: body, headers: {"Content-Type": "application/json"});
    var baseResp = BaseResponseModel.convertResponseToBaseResponse(response);

    if (baseResp.statusCode != 200) {
      throw Exception(baseResp.msg);
    }
    return baseResp.data;
  }

  Future<bool> reg(String name, String email, String password) async {
    String url = URLs.AUTH_BASE_URL + URLs.AUTH_REG_URL;

    String body =
        jsonEncode({"email": email, "password": password, "name": name});
    http.Response resp = await http.post(Uri.parse(url),
        body: body, headers: {"Content-Type": "application/json"});

    var baseResp = BaseResponseModel.convertResponseToBaseResponse(resp);

    if (baseResp.statusCode != 200) {
      throw Exception(baseResp.msg);
    }
    return baseResp.data as bool;
  }

  //DIR SERVICE-------------------------------

  ///Parses response body of type {data,msg} and returns a DirModel
  DirModel _createDirFromRespBody(String responseBody) {
    var data = jsonDecode(responseBody)['data'];
    String id = data['id'];
    String creatorID = data['creatorID'];
    String name = data['name'];
    String parentID = data['parent'];
    //IMPORTANT : List<String> will not work. Be sure to store list as List<dynamic>. Then iterate over them and then cast them appropriately.
    List<dynamic> childrenIDs = data['children'];
    List<dynamic> bookmarkIDs = data['bookmarks'];

    List<String> castedChildren = [];
    List<String> castedBookmarks = [];

    for (dynamic s in childrenIDs) {
      String a = s as String;
      castedChildren.add(a);
    }

    for (dynamic s in bookmarkIDs) {
      String a = s as String;
      castedBookmarks.add(a);
    }

    return DirModel(
        id, creatorID, name, parentID, castedChildren, castedBookmarks);
  }

  Future<DirModel> getDir(String jwtToken, String dirID) async {
    //GET http://localhost:8080/api/v1/gate/dir/{{id}}
    String url = "http://localhost:8080/api/v1/gate/dir/$dirID";
    var resp = await http
        .get(Uri.parse(url), headers: {"Authorization": "Bearer $jwtToken"});
    if (resp.statusCode != 200) {
      throw Exception("Something went wrong");
    }
    return _createDirFromRespBody(resp.body);
  }

  /// Get list of DirModel who are the children of parentID
  Future<List<DirModel>> getChildrenDirs(
      String jwtToken, String parentID) async {
    String url = URLs.DIR_BASE_URL + URLs.DIR_GET_DIRS(parentID);
    var resp = await http.get(
      Uri.parse(url),
      headers: {"Authorization": "Bearer $jwtToken"},
    );

    //The body will have a list of {data,msg} as string. We decode it to get a list of it as map but flutter sees it as List<dynamic>
    List<dynamic> dataList = jsonDecode(resp
        .body); //List<dynamic>  [{data: "", msg: ""}]. Probably because I return a flux from the server which is treated as a list
    List<String> dataListString =
        []; //To store the map as json String so that we can pass it to another function which will create DirModel for us
    //iterate and turn the Map into a json String
    for (Map s in dataList) {
      dataListString.add(jsonEncode(s));
    }
    List<DirModel> dirs = [];
    for (String s in dataListString) {
      var a = _createDirFromRespBody(s);
      dirs.add(a);
    }
    return dirs;
  }

  //BOOKMARK SERVICE---------------------
  Future<List<BookmarkModel>> getBookmarkFromDirID(
      String jwtToken, String dirID) async {
    String url = "http://localhost:8080/api/v1/gate/bookmark/dir/$dirID";
    var resp = await http
        .get(Uri.parse(url), headers: {"Authorization": "Bearer  $jwtToken"});

    if (resp.statusCode != 200) {
      throw Exception("Status code ${resp.statusCode}");
    }

    List<dynamic> body =
        jsonDecode(resp.body); //Body is going to return an array of {data,msg}
    List<dynamic> rawData = [];
    List<BookmarkModel> bookmarks = [];
    for (dynamic d in body) {
      rawData.add(d['data']);
    }
    print(rawData.toString());

    for (dynamic data in rawData) {
      bookmarks.add(BookmarkModel(data['id'], data['creatorID'],
          data['templateID'], data['dirID'], data['name'], data['data']));
    }

    print("----------------------");
    print(bookmarks.toString());
    return bookmarks;
  }

  //TEMPLATE SERVICE-------------

  Future<TemplateModel> getTemplateByID(
      String jwtToken, String templateID) async {
    //GET http://localhost:8080/api/v1/gate/temp/{{id}}
    String url = "http://localhost:8080/api/v1/gate/temp/$templateID";
    var resp = await http
        .get(Uri.parse(url), headers: {"Authorization": "Bearer $jwtToken"});
    if (resp.statusCode != 200) {
      throw Exception("Something went wrong");
    }
    Map<String, dynamic> data = jsonDecode(resp.body)['data'];
    //data['bookmarks'] is of type list<dynamic> and we can't cast it to list<String> so we need to integrate the dynamic list and cast the values ourselves
    List<String> bookmarks = [];
    for (dynamic c in data['bookmarks']) {
      bookmarks.add(c);
    }
    //data['struct'] is of type jsonMap so we need to manually parse it
    Map<dynamic, dynamic> rawStruct = data['struct'];
    Map<String, TemplateField> struct = {};
    rawStruct.forEach((key, value) {
      String fieldName = key;
      var templateField = TemplateField(value['fieldType'], value["optional"]);
      struct[fieldName] = templateField;
    });
    TemplateModel template = TemplateModel(
        data['id'], data['name'], data['creatorID'], bookmarks, struct);
    return template;
  }
}
