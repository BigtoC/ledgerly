// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'charts_selection_controller.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ChartsSelection {

 PeriodType get period; CategoryType get type; ChartDimension get dimension; DateTime get anchorDate;
/// Create a copy of ChartsSelection
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ChartsSelectionCopyWith<ChartsSelection> get copyWith => _$ChartsSelectionCopyWithImpl<ChartsSelection>(this as ChartsSelection, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ChartsSelection&&(identical(other.period, period) || other.period == period)&&(identical(other.type, type) || other.type == type)&&(identical(other.dimension, dimension) || other.dimension == dimension)&&(identical(other.anchorDate, anchorDate) || other.anchorDate == anchorDate));
}


@override
int get hashCode => Object.hash(runtimeType,period,type,dimension,anchorDate);

@override
String toString() {
  return 'ChartsSelection(period: $period, type: $type, dimension: $dimension, anchorDate: $anchorDate)';
}


}

/// @nodoc
abstract mixin class $ChartsSelectionCopyWith<$Res>  {
  factory $ChartsSelectionCopyWith(ChartsSelection value, $Res Function(ChartsSelection) _then) = _$ChartsSelectionCopyWithImpl;
@useResult
$Res call({
 PeriodType period, CategoryType type, ChartDimension dimension, DateTime anchorDate
});




}
/// @nodoc
class _$ChartsSelectionCopyWithImpl<$Res>
    implements $ChartsSelectionCopyWith<$Res> {
  _$ChartsSelectionCopyWithImpl(this._self, this._then);

  final ChartsSelection _self;
  final $Res Function(ChartsSelection) _then;

/// Create a copy of ChartsSelection
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? type = null,Object? dimension = null,Object? anchorDate = null,}) {
  return _then(_self.copyWith(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as PeriodType,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CategoryType,dimension: null == dimension ? _self.dimension : dimension // ignore: cast_nullable_to_non_nullable
as ChartDimension,anchorDate: null == anchorDate ? _self.anchorDate : anchorDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ChartsSelection].
extension ChartsSelectionPatterns on ChartsSelection {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ChartsSelection value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ChartsSelection() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ChartsSelection value)  $default,){
final _that = this;
switch (_that) {
case _ChartsSelection():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ChartsSelection value)?  $default,){
final _that = this;
switch (_that) {
case _ChartsSelection() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( PeriodType period,  CategoryType type,  ChartDimension dimension,  DateTime anchorDate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ChartsSelection() when $default != null:
return $default(_that.period,_that.type,_that.dimension,_that.anchorDate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( PeriodType period,  CategoryType type,  ChartDimension dimension,  DateTime anchorDate)  $default,) {final _that = this;
switch (_that) {
case _ChartsSelection():
return $default(_that.period,_that.type,_that.dimension,_that.anchorDate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( PeriodType period,  CategoryType type,  ChartDimension dimension,  DateTime anchorDate)?  $default,) {final _that = this;
switch (_that) {
case _ChartsSelection() when $default != null:
return $default(_that.period,_that.type,_that.dimension,_that.anchorDate);case _:
  return null;

}
}

}

/// @nodoc


class _ChartsSelection implements ChartsSelection {
  const _ChartsSelection({required this.period, required this.type, required this.dimension, required this.anchorDate});
  

@override final  PeriodType period;
@override final  CategoryType type;
@override final  ChartDimension dimension;
@override final  DateTime anchorDate;

/// Create a copy of ChartsSelection
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ChartsSelectionCopyWith<_ChartsSelection> get copyWith => __$ChartsSelectionCopyWithImpl<_ChartsSelection>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ChartsSelection&&(identical(other.period, period) || other.period == period)&&(identical(other.type, type) || other.type == type)&&(identical(other.dimension, dimension) || other.dimension == dimension)&&(identical(other.anchorDate, anchorDate) || other.anchorDate == anchorDate));
}


@override
int get hashCode => Object.hash(runtimeType,period,type,dimension,anchorDate);

@override
String toString() {
  return 'ChartsSelection(period: $period, type: $type, dimension: $dimension, anchorDate: $anchorDate)';
}


}

/// @nodoc
abstract mixin class _$ChartsSelectionCopyWith<$Res> implements $ChartsSelectionCopyWith<$Res> {
  factory _$ChartsSelectionCopyWith(_ChartsSelection value, $Res Function(_ChartsSelection) _then) = __$ChartsSelectionCopyWithImpl;
@override @useResult
$Res call({
 PeriodType period, CategoryType type, ChartDimension dimension, DateTime anchorDate
});




}
/// @nodoc
class __$ChartsSelectionCopyWithImpl<$Res>
    implements _$ChartsSelectionCopyWith<$Res> {
  __$ChartsSelectionCopyWithImpl(this._self, this._then);

  final _ChartsSelection _self;
  final $Res Function(_ChartsSelection) _then;

/// Create a copy of ChartsSelection
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? period = null,Object? type = null,Object? dimension = null,Object? anchorDate = null,}) {
  return _then(_ChartsSelection(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as PeriodType,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as CategoryType,dimension: null == dimension ? _self.dimension : dimension // ignore: cast_nullable_to_non_nullable
as ChartDimension,anchorDate: null == anchorDate ? _self.anchorDate : anchorDate // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
