// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'time_bucket_slice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TimeBucketSlice {

 DateTime get bucketStart; String get currencyCode; int get totalMinorUnits;
/// Create a copy of TimeBucketSlice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TimeBucketSliceCopyWith<TimeBucketSlice> get copyWith => _$TimeBucketSliceCopyWithImpl<TimeBucketSlice>(this as TimeBucketSlice, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TimeBucketSlice&&(identical(other.bucketStart, bucketStart) || other.bucketStart == bucketStart)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.totalMinorUnits, totalMinorUnits) || other.totalMinorUnits == totalMinorUnits));
}


@override
int get hashCode => Object.hash(runtimeType,bucketStart,currencyCode,totalMinorUnits);

@override
String toString() {
  return 'TimeBucketSlice(bucketStart: $bucketStart, currencyCode: $currencyCode, totalMinorUnits: $totalMinorUnits)';
}


}

/// @nodoc
abstract mixin class $TimeBucketSliceCopyWith<$Res>  {
  factory $TimeBucketSliceCopyWith(TimeBucketSlice value, $Res Function(TimeBucketSlice) _then) = _$TimeBucketSliceCopyWithImpl;
@useResult
$Res call({
 DateTime bucketStart, String currencyCode, int totalMinorUnits
});




}
/// @nodoc
class _$TimeBucketSliceCopyWithImpl<$Res>
    implements $TimeBucketSliceCopyWith<$Res> {
  _$TimeBucketSliceCopyWithImpl(this._self, this._then);

  final TimeBucketSlice _self;
  final $Res Function(TimeBucketSlice) _then;

/// Create a copy of TimeBucketSlice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? bucketStart = null,Object? currencyCode = null,Object? totalMinorUnits = null,}) {
  return _then(_self.copyWith(
bucketStart: null == bucketStart ? _self.bucketStart : bucketStart // ignore: cast_nullable_to_non_nullable
as DateTime,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,totalMinorUnits: null == totalMinorUnits ? _self.totalMinorUnits : totalMinorUnits // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [TimeBucketSlice].
extension TimeBucketSlicePatterns on TimeBucketSlice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _TimeBucketSlice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _TimeBucketSlice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _TimeBucketSlice value)  $default,){
final _that = this;
switch (_that) {
case _TimeBucketSlice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _TimeBucketSlice value)?  $default,){
final _that = this;
switch (_that) {
case _TimeBucketSlice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( DateTime bucketStart,  String currencyCode,  int totalMinorUnits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _TimeBucketSlice() when $default != null:
return $default(_that.bucketStart,_that.currencyCode,_that.totalMinorUnits);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( DateTime bucketStart,  String currencyCode,  int totalMinorUnits)  $default,) {final _that = this;
switch (_that) {
case _TimeBucketSlice():
return $default(_that.bucketStart,_that.currencyCode,_that.totalMinorUnits);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( DateTime bucketStart,  String currencyCode,  int totalMinorUnits)?  $default,) {final _that = this;
switch (_that) {
case _TimeBucketSlice() when $default != null:
return $default(_that.bucketStart,_that.currencyCode,_that.totalMinorUnits);case _:
  return null;

}
}

}

/// @nodoc


class _TimeBucketSlice implements TimeBucketSlice {
  const _TimeBucketSlice({required this.bucketStart, required this.currencyCode, required this.totalMinorUnits});
  

@override final  DateTime bucketStart;
@override final  String currencyCode;
@override final  int totalMinorUnits;

/// Create a copy of TimeBucketSlice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TimeBucketSliceCopyWith<_TimeBucketSlice> get copyWith => __$TimeBucketSliceCopyWithImpl<_TimeBucketSlice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _TimeBucketSlice&&(identical(other.bucketStart, bucketStart) || other.bucketStart == bucketStart)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.totalMinorUnits, totalMinorUnits) || other.totalMinorUnits == totalMinorUnits));
}


@override
int get hashCode => Object.hash(runtimeType,bucketStart,currencyCode,totalMinorUnits);

@override
String toString() {
  return 'TimeBucketSlice(bucketStart: $bucketStart, currencyCode: $currencyCode, totalMinorUnits: $totalMinorUnits)';
}


}

/// @nodoc
abstract mixin class _$TimeBucketSliceCopyWith<$Res> implements $TimeBucketSliceCopyWith<$Res> {
  factory _$TimeBucketSliceCopyWith(_TimeBucketSlice value, $Res Function(_TimeBucketSlice) _then) = __$TimeBucketSliceCopyWithImpl;
@override @useResult
$Res call({
 DateTime bucketStart, String currencyCode, int totalMinorUnits
});




}
/// @nodoc
class __$TimeBucketSliceCopyWithImpl<$Res>
    implements _$TimeBucketSliceCopyWith<$Res> {
  __$TimeBucketSliceCopyWithImpl(this._self, this._then);

  final _TimeBucketSlice _self;
  final $Res Function(_TimeBucketSlice) _then;

/// Create a copy of TimeBucketSlice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? bucketStart = null,Object? currencyCode = null,Object? totalMinorUnits = null,}) {
  return _then(_TimeBucketSlice(
bucketStart: null == bucketStart ? _self.bucketStart : bucketStart // ignore: cast_nullable_to_non_nullable
as DateTime,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,totalMinorUnits: null == totalMinorUnits ? _self.totalMinorUnits : totalMinorUnits // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
