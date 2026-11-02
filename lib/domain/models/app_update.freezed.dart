// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_update.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppUpdate {

/// Release tag, e.g. `v0.7.3`.
 String get version;/// Asset name, e.g. `ledgerly-v0.7.3-arm64-v8a.apk`.
 String get fileName;/// https `browser_download_url` of the asset.
 Uri get apkUrl;/// Lowercase hex SHA-256 from the asset's GitHub `digest`. Null, along
/// with [sizeBytes], when either is missing or malformed: the update
/// can then only be opened in the browser.
 String? get sha256;/// Asset size in bytes, shown before downloading.
 int? get sizeBytes;
/// Create a copy of AppUpdate
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUpdateCopyWith<AppUpdate> get copyWith => _$AppUpdateCopyWithImpl<AppUpdate>(this as AppUpdate, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AppUpdate;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUpdate&&(identical(other.version, _this.version) || other.version == _this.version)&&(identical(other.fileName, _this.fileName) || other.fileName == _this.fileName)&&(identical(other.apkUrl, _this.apkUrl) || other.apkUrl == _this.apkUrl)&&(identical(other.sha256, _this.sha256) || other.sha256 == _this.sha256)&&(identical(other.sizeBytes, _this.sizeBytes) || other.sizeBytes == _this.sizeBytes));
}


@override
int get hashCode {
  final _this = this as AppUpdate;
  return Object.hash(runtimeType,_this.version,_this.fileName,_this.apkUrl,_this.sha256,_this.sizeBytes);
}

@override
String toString() {
  final _this = this as AppUpdate;
  return 'AppUpdate(version: ${_this.version}, fileName: ${_this.fileName}, apkUrl: ${_this.apkUrl}, sha256: ${_this.sha256}, sizeBytes: ${_this.sizeBytes})';
}


}

/// @nodoc
abstract mixin class $AppUpdateCopyWith<$Res>  {
  factory $AppUpdateCopyWith(AppUpdate value, $Res Function(AppUpdate) _then) = _$AppUpdateCopyWithImpl;
@useResult
$Res call({
 String version, String fileName, Uri apkUrl, String? sha256, int? sizeBytes
});




}
/// @nodoc
class _$AppUpdateCopyWithImpl<$Res>
    implements $AppUpdateCopyWith<$Res> {
  _$AppUpdateCopyWithImpl(this._self, this._then);

  final AppUpdate _self;
  final $Res Function(AppUpdate) _then;

/// Create a copy of AppUpdate
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? version = null,Object? fileName = null,Object? apkUrl = null,Object? sha256 = freezed,Object? sizeBytes = freezed,}) {
  return _then(AppUpdate(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,apkUrl: null == apkUrl ? _self.apkUrl : apkUrl // ignore: cast_nullable_to_non_nullable
as Uri,sha256: freezed == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [AppUpdate].
extension AppUpdatePatterns on AppUpdate {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AppUpdate value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AppUpdate() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AppUpdate value)  $default,){
final _that = this;
switch (_that) {
case _AppUpdate():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AppUpdate value)?  $default,){
final _that = this;
switch (_that) {
case _AppUpdate() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String version,  String fileName,  Uri apkUrl,  String? sha256,  int? sizeBytes)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AppUpdate() when $default != null:
return $default(_that.version,_that.fileName,_that.apkUrl,_that.sha256,_that.sizeBytes);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String version,  String fileName,  Uri apkUrl,  String? sha256,  int? sizeBytes)  $default,) {final _that = this;
switch (_that) {
case _AppUpdate():
return $default(_that.version,_that.fileName,_that.apkUrl,_that.sha256,_that.sizeBytes);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String version,  String fileName,  Uri apkUrl,  String? sha256,  int? sizeBytes)?  $default,) {final _that = this;
switch (_that) {
case _AppUpdate() when $default != null:
return $default(_that.version,_that.fileName,_that.apkUrl,_that.sha256,_that.sizeBytes);case _:
  return null;

}
}

}

/// @nodoc


class _AppUpdate implements AppUpdate {
  const _AppUpdate({required this.version, required this.fileName, required this.apkUrl, this.sha256, this.sizeBytes});
  

/// Release tag, e.g. `v0.7.3`.
@override final  String version;
/// Asset name, e.g. `ledgerly-v0.7.3-arm64-v8a.apk`.
@override final  String fileName;
/// https `browser_download_url` of the asset.
@override final  Uri apkUrl;
/// Lowercase hex SHA-256 from the asset's GitHub `digest`. Null, along
/// with [sizeBytes], when either is missing or malformed: the update
/// can then only be opened in the browser.
@override final  String? sha256;
/// Asset size in bytes, shown before downloading.
@override final  int? sizeBytes;

/// Create a copy of AppUpdate
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AppUpdateCopyWith<_AppUpdate> get copyWith => __$AppUpdateCopyWithImpl<_AppUpdate>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AppUpdate&&(identical(other.version, version) || other.version == version)&&(identical(other.fileName, fileName) || other.fileName == fileName)&&(identical(other.apkUrl, apkUrl) || other.apkUrl == apkUrl)&&(identical(other.sha256, sha256) || other.sha256 == sha256)&&(identical(other.sizeBytes, sizeBytes) || other.sizeBytes == sizeBytes));
}


@override
int get hashCode {
    return Object.hash(runtimeType,version,fileName,apkUrl,sha256,sizeBytes);
}

@override
String toString() {
    return 'AppUpdate(version: $version, fileName: $fileName, apkUrl: $apkUrl, sha256: $sha256, sizeBytes: $sizeBytes)';
}


}

/// @nodoc
abstract mixin class _$AppUpdateCopyWith<$Res> implements $AppUpdateCopyWith<$Res> {
  factory _$AppUpdateCopyWith(_AppUpdate value, $Res Function(_AppUpdate) _then) = __$AppUpdateCopyWithImpl;
@override @useResult
$Res call({
 String version, String fileName, Uri apkUrl, String? sha256, int? sizeBytes
});




}
/// @nodoc
class __$AppUpdateCopyWithImpl<$Res>
    implements _$AppUpdateCopyWith<$Res> {
  __$AppUpdateCopyWithImpl(this._self, this._then);

  final _AppUpdate _self;
  final $Res Function(_AppUpdate) _then;

/// Create a copy of AppUpdate
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? version = null,Object? fileName = null,Object? apkUrl = null,Object? sha256 = freezed,Object? sizeBytes = freezed,}) {
  return _then(_AppUpdate(
version: null == version ? _self.version : version // ignore: cast_nullable_to_non_nullable
as String,fileName: null == fileName ? _self.fileName : fileName // ignore: cast_nullable_to_non_nullable
as String,apkUrl: null == apkUrl ? _self.apkUrl : apkUrl // ignore: cast_nullable_to_non_nullable
as Uri,sha256: freezed == sha256 ? _self.sha256 : sha256 // ignore: cast_nullable_to_non_nullable
as String?,sizeBytes: freezed == sizeBytes ? _self.sizeBytes : sizeBytes // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
