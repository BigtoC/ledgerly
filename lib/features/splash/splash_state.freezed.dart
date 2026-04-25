// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'splash_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SplashState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SplashState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SplashState()';
}


}

/// @nodoc
class $SplashStateCopyWith<$Res>  {
$SplashStateCopyWith(SplashState _, $Res Function(SplashState) __);
}


/// Adds pattern-matching-related methods to [SplashState].
extension SplashStatePatterns on SplashState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SplashLoading value)?  loading,TResult Function( SplashData value)?  data,TResult Function( SplashError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SplashLoading() when loading != null:
return loading(_that);case SplashData() when data != null:
return data(_that);case SplashError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SplashLoading value)  loading,required TResult Function( SplashData value)  data,required TResult Function( SplashError value)  error,}){
final _that = this;
switch (_that) {
case SplashLoading():
return loading(_that);case SplashData():
return data(_that);case SplashError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SplashLoading value)?  loading,TResult? Function( SplashData value)?  data,TResult? Function( SplashError value)?  error,}){
final _that = this;
switch (_that) {
case SplashLoading() when loading != null:
return loading(_that);case SplashData() when data != null:
return data(_that);case SplashError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( DateTime startDate,  int dayCount,  String formattedStartDate,  String formattedDisplayText,  String buttonLabel)?  data,TResult Function( Object error,  StackTrace stack)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SplashLoading() when loading != null:
return loading();case SplashData() when data != null:
return data(_that.startDate,_that.dayCount,_that.formattedStartDate,_that.formattedDisplayText,_that.buttonLabel);case SplashError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( DateTime startDate,  int dayCount,  String formattedStartDate,  String formattedDisplayText,  String buttonLabel)  data,required TResult Function( Object error,  StackTrace stack)  error,}) {final _that = this;
switch (_that) {
case SplashLoading():
return loading();case SplashData():
return data(_that.startDate,_that.dayCount,_that.formattedStartDate,_that.formattedDisplayText,_that.buttonLabel);case SplashError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( DateTime startDate,  int dayCount,  String formattedStartDate,  String formattedDisplayText,  String buttonLabel)?  data,TResult? Function( Object error,  StackTrace stack)?  error,}) {final _that = this;
switch (_that) {
case SplashLoading() when loading != null:
return loading();case SplashData() when data != null:
return data(_that.startDate,_that.dayCount,_that.formattedStartDate,_that.formattedDisplayText,_that.buttonLabel);case SplashError() when error != null:
return error(_that.error,_that.stack);case _:
  return null;

}
}

}

/// @nodoc


class SplashLoading implements SplashState {
  const SplashLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SplashLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'SplashState.loading()';
}


}




/// @nodoc


class SplashData implements SplashState {
  const SplashData({required this.startDate, required this.dayCount, required this.formattedStartDate, required this.formattedDisplayText, required this.buttonLabel});
  

 final  DateTime startDate;
 final  int dayCount;
 final  String formattedStartDate;
 final  String formattedDisplayText;
 final  String buttonLabel;

/// Create a copy of SplashState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SplashDataCopyWith<SplashData> get copyWith => _$SplashDataCopyWithImpl<SplashData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SplashData&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.dayCount, dayCount) || other.dayCount == dayCount)&&(identical(other.formattedStartDate, formattedStartDate) || other.formattedStartDate == formattedStartDate)&&(identical(other.formattedDisplayText, formattedDisplayText) || other.formattedDisplayText == formattedDisplayText)&&(identical(other.buttonLabel, buttonLabel) || other.buttonLabel == buttonLabel));
}


@override
int get hashCode => Object.hash(runtimeType,startDate,dayCount,formattedStartDate,formattedDisplayText,buttonLabel);

@override
String toString() {
  return 'SplashState.data(startDate: $startDate, dayCount: $dayCount, formattedStartDate: $formattedStartDate, formattedDisplayText: $formattedDisplayText, buttonLabel: $buttonLabel)';
}


}

/// @nodoc
abstract mixin class $SplashDataCopyWith<$Res> implements $SplashStateCopyWith<$Res> {
  factory $SplashDataCopyWith(SplashData value, $Res Function(SplashData) _then) = _$SplashDataCopyWithImpl;
@useResult
$Res call({
 DateTime startDate, int dayCount, String formattedStartDate, String formattedDisplayText, String buttonLabel
});




}
/// @nodoc
class _$SplashDataCopyWithImpl<$Res>
    implements $SplashDataCopyWith<$Res> {
  _$SplashDataCopyWithImpl(this._self, this._then);

  final SplashData _self;
  final $Res Function(SplashData) _then;

/// Create a copy of SplashState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? startDate = null,Object? dayCount = null,Object? formattedStartDate = null,Object? formattedDisplayText = null,Object? buttonLabel = null,}) {
  return _then(SplashData(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,dayCount: null == dayCount ? _self.dayCount : dayCount // ignore: cast_nullable_to_non_nullable
as int,formattedStartDate: null == formattedStartDate ? _self.formattedStartDate : formattedStartDate // ignore: cast_nullable_to_non_nullable
as String,formattedDisplayText: null == formattedDisplayText ? _self.formattedDisplayText : formattedDisplayText // ignore: cast_nullable_to_non_nullable
as String,buttonLabel: null == buttonLabel ? _self.buttonLabel : buttonLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc


class SplashError implements SplashState {
  const SplashError(this.error, this.stack);
  

 final  Object error;
 final  StackTrace stack;

/// Create a copy of SplashState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SplashErrorCopyWith<SplashError> get copyWith => _$SplashErrorCopyWithImpl<SplashError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SplashError&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stack, stack) || other.stack == stack));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stack);

@override
String toString() {
  return 'SplashState.error(error: $error, stack: $stack)';
}


}

/// @nodoc
abstract mixin class $SplashErrorCopyWith<$Res> implements $SplashStateCopyWith<$Res> {
  factory $SplashErrorCopyWith(SplashError value, $Res Function(SplashError) _then) = _$SplashErrorCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace stack
});




}
/// @nodoc
class _$SplashErrorCopyWithImpl<$Res>
    implements $SplashErrorCopyWith<$Res> {
  _$SplashErrorCopyWithImpl(this._self, this._then);

  final SplashError _self;
  final $Res Function(SplashError) _then;

/// Create a copy of SplashState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stack = null,}) {
  return _then(SplashError(
null == error ? _self.error : error ,null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

// dart format on
