// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'settings_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SettingsState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsState()';
}


}

/// @nodoc
class $SettingsStateCopyWith<$Res>  {
$SettingsStateCopyWith(SettingsState _, $Res Function(SettingsState) __);
}


/// Adds pattern-matching-related methods to [SettingsState].
extension SettingsStatePatterns on SettingsState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SettingsLoading value)?  loading,TResult Function( SettingsData value)?  data,TResult Function( SettingsError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SettingsLoading() when loading != null:
return loading(_that);case SettingsData() when data != null:
return data(_that);case SettingsError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SettingsLoading value)  loading,required TResult Function( SettingsData value)  data,required TResult Function( SettingsError value)  error,}){
final _that = this;
switch (_that) {
case SettingsLoading():
return loading(_that);case SettingsData():
return data(_that);case SettingsError():
return error(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SettingsLoading value)?  loading,TResult? Function( SettingsData value)?  data,TResult? Function( SettingsError value)?  error,}){
final _that = this;
switch (_that) {
case SettingsLoading() when loading != null:
return loading(_that);case SettingsData() when data != null:
return data(_that);case SettingsError() when error != null:
return error(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( ThemeMode themeMode,  Locale? locale,  String defaultCurrency,  int? defaultAccountId,  bool splashEnabled,  DateTime? splashStartDate,  String? splashDisplayText,  String? splashButtonLabel)?  data,TResult Function( Object error,  StackTrace stack)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SettingsLoading() when loading != null:
return loading();case SettingsData() when data != null:
return data(_that.themeMode,_that.locale,_that.defaultCurrency,_that.defaultAccountId,_that.splashEnabled,_that.splashStartDate,_that.splashDisplayText,_that.splashButtonLabel);case SettingsError() when error != null:
return error(_that.error,_that.stack);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( ThemeMode themeMode,  Locale? locale,  String defaultCurrency,  int? defaultAccountId,  bool splashEnabled,  DateTime? splashStartDate,  String? splashDisplayText,  String? splashButtonLabel)  data,required TResult Function( Object error,  StackTrace stack)  error,}) {final _that = this;
switch (_that) {
case SettingsLoading():
return loading();case SettingsData():
return data(_that.themeMode,_that.locale,_that.defaultCurrency,_that.defaultAccountId,_that.splashEnabled,_that.splashStartDate,_that.splashDisplayText,_that.splashButtonLabel);case SettingsError():
return error(_that.error,_that.stack);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( ThemeMode themeMode,  Locale? locale,  String defaultCurrency,  int? defaultAccountId,  bool splashEnabled,  DateTime? splashStartDate,  String? splashDisplayText,  String? splashButtonLabel)?  data,TResult? Function( Object error,  StackTrace stack)?  error,}) {final _that = this;
switch (_that) {
case SettingsLoading() when loading != null:
return loading();case SettingsData() when data != null:
return data(_that.themeMode,_that.locale,_that.defaultCurrency,_that.defaultAccountId,_that.splashEnabled,_that.splashStartDate,_that.splashDisplayText,_that.splashButtonLabel);case SettingsError() when error != null:
return error(_that.error,_that.stack);case _:
  return null;

}
}

}

/// @nodoc


class SettingsLoading implements SettingsState {
  const SettingsLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SettingsState.loading()';
}


}




/// @nodoc


class SettingsData implements SettingsState {
  const SettingsData({required this.themeMode, required this.locale, required this.defaultCurrency, required this.defaultAccountId, required this.splashEnabled, required this.splashStartDate, required this.splashDisplayText, required this.splashButtonLabel});
  

 final  ThemeMode themeMode;
 final  Locale? locale;
 final  String defaultCurrency;
 final  int? defaultAccountId;
 final  bool splashEnabled;
 final  DateTime? splashStartDate;
 final  String? splashDisplayText;
 final  String? splashButtonLabel;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsDataCopyWith<SettingsData> get copyWith => _$SettingsDataCopyWithImpl<SettingsData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsData&&(identical(other.themeMode, themeMode) || other.themeMode == themeMode)&&(identical(other.locale, locale) || other.locale == locale)&&(identical(other.defaultCurrency, defaultCurrency) || other.defaultCurrency == defaultCurrency)&&(identical(other.defaultAccountId, defaultAccountId) || other.defaultAccountId == defaultAccountId)&&(identical(other.splashEnabled, splashEnabled) || other.splashEnabled == splashEnabled)&&(identical(other.splashStartDate, splashStartDate) || other.splashStartDate == splashStartDate)&&(identical(other.splashDisplayText, splashDisplayText) || other.splashDisplayText == splashDisplayText)&&(identical(other.splashButtonLabel, splashButtonLabel) || other.splashButtonLabel == splashButtonLabel));
}


@override
int get hashCode => Object.hash(runtimeType,themeMode,locale,defaultCurrency,defaultAccountId,splashEnabled,splashStartDate,splashDisplayText,splashButtonLabel);

@override
String toString() {
  return 'SettingsState.data(themeMode: $themeMode, locale: $locale, defaultCurrency: $defaultCurrency, defaultAccountId: $defaultAccountId, splashEnabled: $splashEnabled, splashStartDate: $splashStartDate, splashDisplayText: $splashDisplayText, splashButtonLabel: $splashButtonLabel)';
}


}

/// @nodoc
abstract mixin class $SettingsDataCopyWith<$Res> implements $SettingsStateCopyWith<$Res> {
  factory $SettingsDataCopyWith(SettingsData value, $Res Function(SettingsData) _then) = _$SettingsDataCopyWithImpl;
@useResult
$Res call({
 ThemeMode themeMode, Locale? locale, String defaultCurrency, int? defaultAccountId, bool splashEnabled, DateTime? splashStartDate, String? splashDisplayText, String? splashButtonLabel
});




}
/// @nodoc
class _$SettingsDataCopyWithImpl<$Res>
    implements $SettingsDataCopyWith<$Res> {
  _$SettingsDataCopyWithImpl(this._self, this._then);

  final SettingsData _self;
  final $Res Function(SettingsData) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? themeMode = null,Object? locale = freezed,Object? defaultCurrency = null,Object? defaultAccountId = freezed,Object? splashEnabled = null,Object? splashStartDate = freezed,Object? splashDisplayText = freezed,Object? splashButtonLabel = freezed,}) {
  return _then(SettingsData(
themeMode: null == themeMode ? _self.themeMode : themeMode // ignore: cast_nullable_to_non_nullable
as ThemeMode,locale: freezed == locale ? _self.locale : locale // ignore: cast_nullable_to_non_nullable
as Locale?,defaultCurrency: null == defaultCurrency ? _self.defaultCurrency : defaultCurrency // ignore: cast_nullable_to_non_nullable
as String,defaultAccountId: freezed == defaultAccountId ? _self.defaultAccountId : defaultAccountId // ignore: cast_nullable_to_non_nullable
as int?,splashEnabled: null == splashEnabled ? _self.splashEnabled : splashEnabled // ignore: cast_nullable_to_non_nullable
as bool,splashStartDate: freezed == splashStartDate ? _self.splashStartDate : splashStartDate // ignore: cast_nullable_to_non_nullable
as DateTime?,splashDisplayText: freezed == splashDisplayText ? _self.splashDisplayText : splashDisplayText // ignore: cast_nullable_to_non_nullable
as String?,splashButtonLabel: freezed == splashButtonLabel ? _self.splashButtonLabel : splashButtonLabel // ignore: cast_nullable_to_non_nullable
as String?,
  ));
}


}

/// @nodoc


class SettingsError implements SettingsState {
  const SettingsError(this.error, this.stack);
  

 final  Object error;
 final  StackTrace stack;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SettingsErrorCopyWith<SettingsError> get copyWith => _$SettingsErrorCopyWithImpl<SettingsError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SettingsError&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stack, stack) || other.stack == stack));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stack);

@override
String toString() {
  return 'SettingsState.error(error: $error, stack: $stack)';
}


}

/// @nodoc
abstract mixin class $SettingsErrorCopyWith<$Res> implements $SettingsStateCopyWith<$Res> {
  factory $SettingsErrorCopyWith(SettingsError value, $Res Function(SettingsError) _then) = _$SettingsErrorCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace stack
});




}
/// @nodoc
class _$SettingsErrorCopyWithImpl<$Res>
    implements $SettingsErrorCopyWith<$Res> {
  _$SettingsErrorCopyWithImpl(this._self, this._then);

  final SettingsError _self;
  final $Res Function(SettingsError) _then;

/// Create a copy of SettingsState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stack = null,}) {
  return _then(SettingsError(
null == error ? _self.error : error ,null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

// dart format on
