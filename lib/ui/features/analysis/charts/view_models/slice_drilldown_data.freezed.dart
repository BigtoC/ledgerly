// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'slice_drilldown_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$SliceDrilldownData {

 List<Transaction> get rows; int? get pendingDeleteId;
/// Create a copy of SliceDrilldownData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SliceDrilldownDataCopyWith<SliceDrilldownData> get copyWith => _$SliceDrilldownDataCopyWithImpl<SliceDrilldownData>(this as SliceDrilldownData, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as SliceDrilldownData;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SliceDrilldownData&&const DeepCollectionEquality().equals(other.rows, _this.rows)&&(identical(other.pendingDeleteId, _this.pendingDeleteId) || other.pendingDeleteId == _this.pendingDeleteId));
}


@override
int get hashCode {
  final _this = this as SliceDrilldownData;
  return Object.hash(runtimeType,const DeepCollectionEquality().hash(_this.rows),_this.pendingDeleteId);
}

@override
String toString() {
  final _this = this as SliceDrilldownData;
  return 'SliceDrilldownData(rows: ${_this.rows}, pendingDeleteId: ${_this.pendingDeleteId})';
}


}

/// @nodoc
abstract mixin class $SliceDrilldownDataCopyWith<$Res>  {
  factory $SliceDrilldownDataCopyWith(SliceDrilldownData value, $Res Function(SliceDrilldownData) _then) = _$SliceDrilldownDataCopyWithImpl;
@useResult
$Res call({
 List<Transaction> rows, int? pendingDeleteId
});




}
/// @nodoc
class _$SliceDrilldownDataCopyWithImpl<$Res>
    implements $SliceDrilldownDataCopyWith<$Res> {
  _$SliceDrilldownDataCopyWithImpl(this._self, this._then);

  final SliceDrilldownData _self;
  final $Res Function(SliceDrilldownData) _then;

/// Create a copy of SliceDrilldownData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? rows = null,Object? pendingDeleteId = freezed,}) {
  return _then(SliceDrilldownData(
rows: null == rows ? _self.rows : rows // ignore: cast_nullable_to_non_nullable
as List<Transaction>,pendingDeleteId: freezed == pendingDeleteId ? _self.pendingDeleteId : pendingDeleteId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}

}


/// Adds pattern-matching-related methods to [SliceDrilldownData].
extension SliceDrilldownDataPatterns on SliceDrilldownData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SliceDrilldownData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SliceDrilldownData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SliceDrilldownData value)  $default,){
final _that = this;
switch (_that) {
case _SliceDrilldownData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SliceDrilldownData value)?  $default,){
final _that = this;
switch (_that) {
case _SliceDrilldownData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( List<Transaction> rows,  int? pendingDeleteId)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SliceDrilldownData() when $default != null:
return $default(_that.rows,_that.pendingDeleteId);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( List<Transaction> rows,  int? pendingDeleteId)  $default,) {final _that = this;
switch (_that) {
case _SliceDrilldownData():
return $default(_that.rows,_that.pendingDeleteId);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( List<Transaction> rows,  int? pendingDeleteId)?  $default,) {final _that = this;
switch (_that) {
case _SliceDrilldownData() when $default != null:
return $default(_that.rows,_that.pendingDeleteId);case _:
  return null;

}
}

}

/// @nodoc


class _SliceDrilldownData implements SliceDrilldownData {
  const _SliceDrilldownData({required  List<Transaction> rows, this.pendingDeleteId}): _rows = rows;
  

 final  List<Transaction> _rows;
@override List<Transaction> get rows {
  if (_rows is EqualUnmodifiableListView) return _rows;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_rows);
}

@override final  int? pendingDeleteId;

/// Create a copy of SliceDrilldownData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SliceDrilldownDataCopyWith<_SliceDrilldownData> get copyWith => __$SliceDrilldownDataCopyWithImpl<_SliceDrilldownData>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _SliceDrilldownData&&const DeepCollectionEquality().equals(other.rows, _rows)&&(identical(other.pendingDeleteId, pendingDeleteId) || other.pendingDeleteId == pendingDeleteId));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(_rows),pendingDeleteId);
}

@override
String toString() {
    return 'SliceDrilldownData(rows: $rows, pendingDeleteId: $pendingDeleteId)';
}


}

/// @nodoc
abstract mixin class _$SliceDrilldownDataCopyWith<$Res> implements $SliceDrilldownDataCopyWith<$Res> {
  factory _$SliceDrilldownDataCopyWith(_SliceDrilldownData value, $Res Function(_SliceDrilldownData) _then) = __$SliceDrilldownDataCopyWithImpl;
@override @useResult
$Res call({
 List<Transaction> rows, int? pendingDeleteId
});




}
/// @nodoc
class __$SliceDrilldownDataCopyWithImpl<$Res>
    implements _$SliceDrilldownDataCopyWith<$Res> {
  __$SliceDrilldownDataCopyWithImpl(this._self, this._then);

  final _SliceDrilldownData _self;
  final $Res Function(_SliceDrilldownData) _then;

/// Create a copy of SliceDrilldownData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? rows = null,Object? pendingDeleteId = freezed,}) {
  return _then(_SliceDrilldownData(
rows: null == rows ? _self._rows : rows // ignore: cast_nullable_to_non_nullable
as List<Transaction>,pendingDeleteId: freezed == pendingDeleteId ? _self.pendingDeleteId : pendingDeleteId // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
