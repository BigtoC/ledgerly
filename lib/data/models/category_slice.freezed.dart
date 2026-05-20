// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_slice.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CategorySlice {

 int get categoryId; String get currencyCode; int get totalMinorUnits;
/// Create a copy of CategorySlice
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CategorySliceCopyWith<CategorySlice> get copyWith => _$CategorySliceCopyWithImpl<CategorySlice>(this as CategorySlice, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is CategorySlice&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.totalMinorUnits, totalMinorUnits) || other.totalMinorUnits == totalMinorUnits));
}


@override
int get hashCode => Object.hash(runtimeType,categoryId,currencyCode,totalMinorUnits);

@override
String toString() {
  return 'CategorySlice(categoryId: $categoryId, currencyCode: $currencyCode, totalMinorUnits: $totalMinorUnits)';
}


}

/// @nodoc
abstract mixin class $CategorySliceCopyWith<$Res>  {
  factory $CategorySliceCopyWith(CategorySlice value, $Res Function(CategorySlice) _then) = _$CategorySliceCopyWithImpl;
@useResult
$Res call({
 int categoryId, String currencyCode, int totalMinorUnits
});




}
/// @nodoc
class _$CategorySliceCopyWithImpl<$Res>
    implements $CategorySliceCopyWith<$Res> {
  _$CategorySliceCopyWithImpl(this._self, this._then);

  final CategorySlice _self;
  final $Res Function(CategorySlice) _then;

/// Create a copy of CategorySlice
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? categoryId = null,Object? currencyCode = null,Object? totalMinorUnits = null,}) {
  return _then(_self.copyWith(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,totalMinorUnits: null == totalMinorUnits ? _self.totalMinorUnits : totalMinorUnits // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [CategorySlice].
extension CategorySlicePatterns on CategorySlice {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _CategorySlice value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _CategorySlice() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _CategorySlice value)  $default,){
final _that = this;
switch (_that) {
case _CategorySlice():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _CategorySlice value)?  $default,){
final _that = this;
switch (_that) {
case _CategorySlice() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int categoryId,  String currencyCode,  int totalMinorUnits)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _CategorySlice() when $default != null:
return $default(_that.categoryId,_that.currencyCode,_that.totalMinorUnits);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int categoryId,  String currencyCode,  int totalMinorUnits)  $default,) {final _that = this;
switch (_that) {
case _CategorySlice():
return $default(_that.categoryId,_that.currencyCode,_that.totalMinorUnits);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int categoryId,  String currencyCode,  int totalMinorUnits)?  $default,) {final _that = this;
switch (_that) {
case _CategorySlice() when $default != null:
return $default(_that.categoryId,_that.currencyCode,_that.totalMinorUnits);case _:
  return null;

}
}

}

/// @nodoc


class _CategorySlice implements CategorySlice {
  const _CategorySlice({required this.categoryId, required this.currencyCode, required this.totalMinorUnits});
  

@override final  int categoryId;
@override final  String currencyCode;
@override final  int totalMinorUnits;

/// Create a copy of CategorySlice
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$CategorySliceCopyWith<_CategorySlice> get copyWith => __$CategorySliceCopyWithImpl<_CategorySlice>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _CategorySlice&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.currencyCode, currencyCode) || other.currencyCode == currencyCode)&&(identical(other.totalMinorUnits, totalMinorUnits) || other.totalMinorUnits == totalMinorUnits));
}


@override
int get hashCode => Object.hash(runtimeType,categoryId,currencyCode,totalMinorUnits);

@override
String toString() {
  return 'CategorySlice(categoryId: $categoryId, currencyCode: $currencyCode, totalMinorUnits: $totalMinorUnits)';
}


}

/// @nodoc
abstract mixin class _$CategorySliceCopyWith<$Res> implements $CategorySliceCopyWith<$Res> {
  factory _$CategorySliceCopyWith(_CategorySlice value, $Res Function(_CategorySlice) _then) = __$CategorySliceCopyWithImpl;
@override @useResult
$Res call({
 int categoryId, String currencyCode, int totalMinorUnits
});




}
/// @nodoc
class __$CategorySliceCopyWithImpl<$Res>
    implements _$CategorySliceCopyWith<$Res> {
  __$CategorySliceCopyWithImpl(this._self, this._then);

  final _CategorySlice _self;
  final $Res Function(_CategorySlice) _then;

/// Create a copy of CategorySlice
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? categoryId = null,Object? currencyCode = null,Object? totalMinorUnits = null,}) {
  return _then(_CategorySlice(
categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,currencyCode: null == currencyCode ? _self.currencyCode : currencyCode // ignore: cast_nullable_to_non_nullable
as String,totalMinorUnits: null == totalMinorUnits ? _self.totalMinorUnits : totalMinorUnits // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
