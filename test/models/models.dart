import 'dart:async';
import 'dart:convert';

import 'package:flutter_data/annotations.dart';
import 'package:flutter_data/flutter_data.dart';
import 'package:flutter_data/adapters/json_api_adapter.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:http/http.dart' as http;

part 'models.freezed.dart';
part 'models.g.dart';

@DataRepository([])
@JsonSerializable()
class Model with DataSupport<Model> {
  @override
  final String id;
  final String name;
  final BelongsTo<Company> company;

  Model({this.id, this.name, this.company});
}

@freezed
@DataRepository([])
abstract class City with DataSupport<City>, _$City {
  City._();
  factory City({
    String id,
    String name,
  }) = _City;

  factory City.fromJson(Map<String, dynamic> json) => _$CityFromJson(json);
}

@freezed
@DataRepository([JSONAPIAdapter, TestMixin])
abstract class Company with DataSupport<Company>, _$Company {
  Company._();
  factory Company({
    String id,
    String name,
    String nasdaq,
    DateTime updatedAt,
    HasMany<Model> models,
  }) = _Company;

  factory Company.fromJson(Map<String, dynamic> json) =>
      _$CompanyFromJson(json);
}

//

mixin TestMixin<T extends DataSupport<T>> on RemoteAdapter<T> {
  @override
  String get baseUrl => 'http://127.0.0.1:17083/';

  @override
  Map<String, dynamic> get params => {
        'page': {'limit': 10}
      };

  @override
  Map<String, String> get headers => {'x-client-id': '2473272'};

  @override
  FutureOr<R> withResponse<R>(
      http.Response response, OnResponseSuccess<R> onSuccess) {
    if (type == 'models') {
      final data = json.decode(response.body);
      // if it's of type models and id is long (i.e. autogenerated)
      if (data['data']['type'] == 'models' &&
          data['data']['id'].toString().length > 6) {
        data['data']['id'] = '9217';
      }
      response = http.Response(json.encode(data), response.statusCode);
    }

    return super.withResponse(response, onSuccess);
  }
}

mixin NoThrottleAdapter on WatchAdapter<City> {
  @override
  Duration get throttleDuration => Duration.zero;
}

class ModelTestRepository = $ModelRepository with TestMixin, JSONAPIAdapter;
class CityTestRepository = $CityRepository
    with TestMixin, NoThrottleAdapter, JSONAPIAdapter;
