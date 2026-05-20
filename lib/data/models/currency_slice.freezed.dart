// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'currency_slice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CurrencySlice {

 String get currencyCode; int get totalMinorUnits;
/// Create a copy of CurrencySlice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CurrencySliceCopyWith<CurrencySlice> get copyWith => _$CurrencySliceCopyWithImpl<CurrencySlice>(this as CurrencySlice, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CurrencySlice&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.totalMinorUnits, totalMinorUnits) || other.totalMinorUnits == totalMinorUnits));
}


@override
int get hashCode => Object.hash(runtimeType,currencyCode,totalMinorUnits);

@override
String toString() {
  return 'CurrencySlice(currencyCode: $currencyCode, totalMinorUnits: $totalMinorUnits)';
}


}

/// @nodoc
abstract mixin class $CurrencySliceCopyWith<$Res>  {
  factory $CurrencySliceCopyWith(CurrencySlice value, $Res Function(CurrencySlice) _then) = _$CurrencySliceCopyWithImpl;
@useResult
$Res call({
 String currencyCode, int totalMinorUnits
});




}
/// @nodoc
class _$CurrencySliceCopyWithImpl<$Res>
    implements $CurrencySliceCopyWith<$Res> {
  _$CurrencySliceCopyWithImpl(this._self, this._then);

  final CurrencySlice _self;
  final $Res Function(CurrencySlice) _then;

/// Create a copy of CurrencySlice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? currencyCode = null,Object? totalMinorUnits = null,}) {
  return _then(_self.copyWith(
currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,totalMinorUnits: null == totalMinorUnits ? _self.totalMinorUnits : totalMinorUnits // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CurrencySlice].
extension CurrencySlicePatterns on CurrencySlice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CurrencySlice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CurrencySlice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CurrencySlice value)  $default,){
final _that = this;
switch (_that) {
case _CurrencySlice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CurrencySlice value)?  $default,){
final _that = this;
switch (_that) {
case _CurrencySlice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String currencyCode,  int totalMinorUnits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CurrencySlice() when $default != null:
return $default(_that.currencyCode,_that.totalMinorUnits);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String currencyCode,  int totalMinorUnits)  $default,) {final _that = this;
switch (_that) {
case _CurrencySlice():
return $default(_that.currencyCode,_that.totalMinorUnits);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String currencyCode,  int totalMinorUnits)?  $default,) {final _that = this;
switch (_that) {
case _CurrencySlice() when $default != null:
return $default(_that.currencyCode,_that.totalMinorUnits);case _:
  return null;

}
}

}

/// @nodoc


class _CurrencySlice implements CurrencySlice {
  const _CurrencySlice({required this.currencyCode, required this.totalMinorUnits});
  

@override final  String currencyCode;
@override final  int totalMinorUnits;

/// Create a copy of CurrencySlice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CurrencySliceCopyWith<_CurrencySlice> get copyWith => __$CurrencySliceCopyWithImpl<_CurrencySlice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CurrencySlice&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.totalMinorUnits, totalMinorUnits) || other.totalMinorUnits == totalMinorUnits));
}


@override
int get hashCode => Object.hash(runtimeType,currencyCode,totalMinorUnits);

@override
String toString() {
  return 'CurrencySlice(currencyCode: $currencyCode, totalMinorUnits: $totalMinorUnits)';
}


}

/// @nodoc
abstract mixin class _$CurrencySliceCopyWith<$Res> implements $CurrencySliceCopyWith<$Res> {
  factory _$CurrencySliceCopyWith(_CurrencySlice value, $Res Function(_CurrencySlice) _then) = __$CurrencySliceCopyWithImpl;
@override @useResult
$Res call({
 String currencyCode, int totalMinorUnits
});




}
/// @nodoc
class __$CurrencySliceCopyWithImpl<$Res>
    implements _$CurrencySliceCopyWith<$Res> {
  __$CurrencySliceCopyWithImpl(this._self, this._then);

  final _CurrencySlice _self;
  final $Res Function(_CurrencySlice) _then;

/// Create a copy of CurrencySlice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? currencyCode = null,Object? totalMinorUnits = null,}) {
  return _then(_CurrencySlice(
currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,totalMinorUnits: null == totalMinorUnits ? _self.totalMinorUnits : totalMinorUnits // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
