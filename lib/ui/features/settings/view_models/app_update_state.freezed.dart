// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'app_update_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AppUpdateState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUpdateState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppUpdateState()';
}


}

/// @nodoc
class $AppUpdateStateCopyWith<$Res>  {
$AppUpdateStateCopyWith(AppUpdateState _, $Res Function(AppUpdateState) __);
}


/// Adds pattern-matching-related methods to [AppUpdateState].
extension AppUpdateStatePatterns on AppUpdateState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( AppUpdateIdle value)?  idle,TResult Function( AppUpdateDownloading value)?  downloading,TResult Function( AppUpdateReady value)?  ready,TResult Function( AppUpdateInstalling value)?  installing,TResult Function( AppUpdateFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case AppUpdateIdle() when idle != null:
return idle(_that);case AppUpdateDownloading() when downloading != null:
return downloading(_that);case AppUpdateReady() when ready != null:
return ready(_that);case AppUpdateInstalling() when installing != null:
return installing(_that);case AppUpdateFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( AppUpdateIdle value)  idle,required TResult Function( AppUpdateDownloading value)  downloading,required TResult Function( AppUpdateReady value)  ready,required TResult Function( AppUpdateInstalling value)  installing,required TResult Function( AppUpdateFailed value)  failed,}){
final _that = this;
switch (_that) {
case AppUpdateIdle():
return idle(_that);case AppUpdateDownloading():
return downloading(_that);case AppUpdateReady():
return ready(_that);case AppUpdateInstalling():
return installing(_that);case AppUpdateFailed():
return failed(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( AppUpdateIdle value)?  idle,TResult? Function( AppUpdateDownloading value)?  downloading,TResult? Function( AppUpdateReady value)?  ready,TResult? Function( AppUpdateInstalling value)?  installing,TResult? Function( AppUpdateFailed value)?  failed,}){
final _that = this;
switch (_that) {
case AppUpdateIdle() when idle != null:
return idle(_that);case AppUpdateDownloading() when downloading != null:
return downloading(_that);case AppUpdateReady() when ready != null:
return ready(_that);case AppUpdateInstalling() when installing != null:
return installing(_that);case AppUpdateFailed() when failed != null:
return failed(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  idle,TResult Function( int percent)?  downloading,TResult Function( String path,  bool needsPermission)?  ready,TResult Function( String path)?  installing,TResult Function( UpdateFailure reason)?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case AppUpdateIdle() when idle != null:
return idle();case AppUpdateDownloading() when downloading != null:
return downloading(_that.percent);case AppUpdateReady() when ready != null:
return ready(_that.path,_that.needsPermission);case AppUpdateInstalling() when installing != null:
return installing(_that.path);case AppUpdateFailed() when failed != null:
return failed(_that.reason);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  idle,required TResult Function( int percent)  downloading,required TResult Function( String path,  bool needsPermission)  ready,required TResult Function( String path)  installing,required TResult Function( UpdateFailure reason)  failed,}) {final _that = this;
switch (_that) {
case AppUpdateIdle():
return idle();case AppUpdateDownloading():
return downloading(_that.percent);case AppUpdateReady():
return ready(_that.path,_that.needsPermission);case AppUpdateInstalling():
return installing(_that.path);case AppUpdateFailed():
return failed(_that.reason);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  idle,TResult? Function( int percent)?  downloading,TResult? Function( String path,  bool needsPermission)?  ready,TResult? Function( String path)?  installing,TResult? Function( UpdateFailure reason)?  failed,}) {final _that = this;
switch (_that) {
case AppUpdateIdle() when idle != null:
return idle();case AppUpdateDownloading() when downloading != null:
return downloading(_that.percent);case AppUpdateReady() when ready != null:
return ready(_that.path,_that.needsPermission);case AppUpdateInstalling() when installing != null:
return installing(_that.path);case AppUpdateFailed() when failed != null:
return failed(_that.reason);case _:
  return null;

}
}

}

/// @nodoc


class AppUpdateIdle implements AppUpdateState {
  const AppUpdateIdle();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUpdateIdle);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'AppUpdateState.idle()';
}


}




/// @nodoc


class AppUpdateDownloading implements AppUpdateState {
  const AppUpdateDownloading(this.percent);
  

 final  int percent;

/// Create a copy of AppUpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUpdateDownloadingCopyWith<AppUpdateDownloading> get copyWith => _$AppUpdateDownloadingCopyWithImpl<AppUpdateDownloading>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUpdateDownloading&&(identical(other.percent, percent) || other.percent == percent));
}


@override
int get hashCode {
    return Object.hash(runtimeType,percent);
}

@override
String toString() {
    return 'AppUpdateState.downloading(percent: $percent)';
}


}

/// @nodoc
abstract mixin class $AppUpdateDownloadingCopyWith<$Res> implements $AppUpdateStateCopyWith<$Res> {
  factory $AppUpdateDownloadingCopyWith(AppUpdateDownloading value, $Res Function(AppUpdateDownloading) _then) = _$AppUpdateDownloadingCopyWithImpl;
@useResult
$Res call({
 int percent
});




}
/// @nodoc
class _$AppUpdateDownloadingCopyWithImpl<$Res>
    implements $AppUpdateDownloadingCopyWith<$Res> {
  _$AppUpdateDownloadingCopyWithImpl(this._self, this._then);

  final AppUpdateDownloading _self;
  final $Res Function(AppUpdateDownloading) _then;

/// Create a copy of AppUpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? percent = null,}) {
  return _then(AppUpdateDownloading(
null == percent ? _self.percent : percent // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc


class AppUpdateReady implements AppUpdateState {
  const AppUpdateReady(this.path, {this.needsPermission = false});
  

 final  String path;
@JsonKey() final  bool needsPermission;

/// Create a copy of AppUpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUpdateReadyCopyWith<AppUpdateReady> get copyWith => _$AppUpdateReadyCopyWithImpl<AppUpdateReady>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUpdateReady&&(identical(other.path, path) || other.path == path)&&(identical(other.needsPermission, needsPermission) || other.needsPermission == needsPermission));
}


@override
int get hashCode {
    return Object.hash(runtimeType,path,needsPermission);
}

@override
String toString() {
    return 'AppUpdateState.ready(path: $path, needsPermission: $needsPermission)';
}


}

/// @nodoc
abstract mixin class $AppUpdateReadyCopyWith<$Res> implements $AppUpdateStateCopyWith<$Res> {
  factory $AppUpdateReadyCopyWith(AppUpdateReady value, $Res Function(AppUpdateReady) _then) = _$AppUpdateReadyCopyWithImpl;
@useResult
$Res call({
 String path, bool needsPermission
});




}
/// @nodoc
class _$AppUpdateReadyCopyWithImpl<$Res>
    implements $AppUpdateReadyCopyWith<$Res> {
  _$AppUpdateReadyCopyWithImpl(this._self, this._then);

  final AppUpdateReady _self;
  final $Res Function(AppUpdateReady) _then;

/// Create a copy of AppUpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? path = null,Object? needsPermission = null,}) {
  return _then(AppUpdateReady(
null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,needsPermission: null == needsPermission ? _self.needsPermission : needsPermission // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}


}

/// @nodoc


class AppUpdateInstalling implements AppUpdateState {
  const AppUpdateInstalling(this.path);
  

 final  String path;

/// Create a copy of AppUpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUpdateInstallingCopyWith<AppUpdateInstalling> get copyWith => _$AppUpdateInstallingCopyWithImpl<AppUpdateInstalling>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUpdateInstalling&&(identical(other.path, path) || other.path == path));
}


@override
int get hashCode {
    return Object.hash(runtimeType,path);
}

@override
String toString() {
    return 'AppUpdateState.installing(path: $path)';
}


}

/// @nodoc
abstract mixin class $AppUpdateInstallingCopyWith<$Res> implements $AppUpdateStateCopyWith<$Res> {
  factory $AppUpdateInstallingCopyWith(AppUpdateInstalling value, $Res Function(AppUpdateInstalling) _then) = _$AppUpdateInstallingCopyWithImpl;
@useResult
$Res call({
 String path
});




}
/// @nodoc
class _$AppUpdateInstallingCopyWithImpl<$Res>
    implements $AppUpdateInstallingCopyWith<$Res> {
  _$AppUpdateInstallingCopyWithImpl(this._self, this._then);

  final AppUpdateInstalling _self;
  final $Res Function(AppUpdateInstalling) _then;

/// Create a copy of AppUpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? path = null,}) {
  return _then(AppUpdateInstalling(
null == path ? _self.path : path // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class AppUpdateFailed implements AppUpdateState {
  const AppUpdateFailed(this.reason);
  

 final  UpdateFailure reason;

/// Create a copy of AppUpdateState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AppUpdateFailedCopyWith<AppUpdateFailed> get copyWith => _$AppUpdateFailedCopyWithImpl<AppUpdateFailed>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is AppUpdateFailed&&(identical(other.reason, reason) || other.reason == reason));
}


@override
int get hashCode {
    return Object.hash(runtimeType,reason);
}

@override
String toString() {
    return 'AppUpdateState.failed(reason: $reason)';
}


}

/// @nodoc
abstract mixin class $AppUpdateFailedCopyWith<$Res> implements $AppUpdateStateCopyWith<$Res> {
  factory $AppUpdateFailedCopyWith(AppUpdateFailed value, $Res Function(AppUpdateFailed) _then) = _$AppUpdateFailedCopyWithImpl;
@useResult
$Res call({
 UpdateFailure reason
});




}
/// @nodoc
class _$AppUpdateFailedCopyWithImpl<$Res>
    implements $AppUpdateFailedCopyWith<$Res> {
  _$AppUpdateFailedCopyWithImpl(this._self, this._then);

  final AppUpdateFailed _self;
  final $Res Function(AppUpdateFailed) _then;

/// Create a copy of AppUpdateState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? reason = null,}) {
  return _then(AppUpdateFailed(
null == reason ? _self.reason : reason // ignore: cast_nullable_to_non_nullable
as UpdateFailure,
  ));
}


}

// dart format on
