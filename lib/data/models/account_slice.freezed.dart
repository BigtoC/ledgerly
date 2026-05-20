// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_slice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountSlice {

 int get accountId; String get currencyCode; int get totalMinorUnits;
/// Create a copy of AccountSlice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountSliceCopyWith<AccountSlice> get copyWith => _$AccountSliceCopyWithImpl<AccountSlice>(this as AccountSlice, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountSlice&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.totalMinorUnits, totalMinorUnits) || other.totalMinorUnits == totalMinorUnits));
}


@override
int get hashCode => Object.hash(runtimeType,accountId,currencyCode,totalMinorUnits);

@override
String toString() {
  return 'AccountSlice(accountId: $accountId, currencyCode: $currencyCode, totalMinorUnits: $totalMinorUnits)';
}


}

/// @nodoc
abstract mixin class $AccountSliceCopyWith<$Res>  {
  factory $AccountSliceCopyWith(AccountSlice value, $Res Function(AccountSlice) _then) = _$AccountSliceCopyWithImpl;
@useResult
$Res call({
 int accountId, String currencyCode, int totalMinorUnits
});




}
/// @nodoc
class _$AccountSliceCopyWithImpl<$Res>
    implements $AccountSliceCopyWith<$Res> {
  _$AccountSliceCopyWithImpl(this._self, this._then);

  final AccountSlice _self;
  final $Res Function(AccountSlice) _then;

/// Create a copy of AccountSlice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? accountId = null,Object? currencyCode = null,Object? totalMinorUnits = null,}) {
  return _then(_self.copyWith(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,totalMinorUnits: null == totalMinorUnits ? _self.totalMinorUnits : totalMinorUnits // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [AccountSlice].
extension AccountSlicePatterns on AccountSlice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountSlice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountSlice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountSlice value)  $default,){
final _that = this;
switch (_that) {
case _AccountSlice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountSlice value)?  $default,){
final _that = this;
switch (_that) {
case _AccountSlice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int accountId,  String currencyCode,  int totalMinorUnits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountSlice() when $default != null:
return $default(_that.accountId,_that.currencyCode,_that.totalMinorUnits);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int accountId,  String currencyCode,  int totalMinorUnits)  $default,) {final _that = this;
switch (_that) {
case _AccountSlice():
return $default(_that.accountId,_that.currencyCode,_that.totalMinorUnits);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int accountId,  String currencyCode,  int totalMinorUnits)?  $default,) {final _that = this;
switch (_that) {
case _AccountSlice() when $default != null:
return $default(_that.accountId,_that.currencyCode,_that.totalMinorUnits);case _:
  return null;

}
}

}

/// @nodoc


class _AccountSlice implements AccountSlice {
  const _AccountSlice({required this.accountId, required this.currencyCode, required this.totalMinorUnits});
  

@override final  int accountId;
@override final  String currencyCode;
@override final  int totalMinorUnits;

/// Create a copy of AccountSlice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountSliceCopyWith<_AccountSlice> get copyWith => __$AccountSliceCopyWithImpl<_AccountSlice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountSlice&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.totalMinorUnits, totalMinorUnits) || other.totalMinorUnits == totalMinorUnits));
}


@override
int get hashCode => Object.hash(runtimeType,accountId,currencyCode,totalMinorUnits);

@override
String toString() {
  return 'AccountSlice(accountId: $accountId, currencyCode: $currencyCode, totalMinorUnits: $totalMinorUnits)';
}


}

/// @nodoc
abstract mixin class _$AccountSliceCopyWith<$Res> implements $AccountSliceCopyWith<$Res> {
  factory _$AccountSliceCopyWith(_AccountSlice value, $Res Function(_AccountSlice) _then) = __$AccountSliceCopyWithImpl;
@override @useResult
$Res call({
 int accountId, String currencyCode, int totalMinorUnits
});




}
/// @nodoc
class __$AccountSliceCopyWithImpl<$Res>
    implements _$AccountSliceCopyWith<$Res> {
  __$AccountSliceCopyWithImpl(this._self, this._then);

  final _AccountSlice _self;
  final $Res Function(_AccountSlice) _then;

/// Create a copy of AccountSlice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? accountId = null,Object? currencyCode = null,Object? totalMinorUnits = null,}) {
  return _then(_AccountSlice(
accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,totalMinorUnits: null == totalMinorUnits ? _self.totalMinorUnits : totalMinorUnits // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
