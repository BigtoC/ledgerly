// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'csv_export_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$CsvExportState {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvExportState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CsvExportState()';
}


}

/// @nodoc
class $CsvExportStateCopyWith<$Res>  {
$CsvExportStateCopyWith(CsvExportState _, $Res Function(CsvExportState) __);
}


/// Adds pattern-matching-related methods to [CsvExportState].
extension CsvExportStatePatterns on CsvExportState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( CsvExportEmpty value)?  empty,TResult Function( CsvExportReady value)?  ready,required TResult orElse(),}){
final _that = this;
switch (_that) {
case CsvExportEmpty() when empty != null:
return empty(_that);case CsvExportReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( CsvExportEmpty value)  empty,required TResult Function( CsvExportReady value)  ready,}){
final _that = this;
switch (_that) {
case CsvExportEmpty():
return empty(_that);case CsvExportReady():
return ready(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( CsvExportEmpty value)?  empty,TResult? Function( CsvExportReady value)?  ready,}){
final _that = this;
switch (_that) {
case CsvExportEmpty() when empty != null:
return empty(_that);case CsvExportReady() when ready != null:
return ready(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  empty,TResult Function( DateTime firstDay,  DateTime lastDay,  DateTime rangeStart,  DateTime rangeEnd,  CsvExportStatus status,  int? exportedCount)?  ready,required TResult orElse(),}) {final _that = this;
switch (_that) {
case CsvExportEmpty() when empty != null:
return empty();case CsvExportReady() when ready != null:
return ready(_that.firstDay,_that.lastDay,_that.rangeStart,_that.rangeEnd,_that.status,_that.exportedCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  empty,required TResult Function( DateTime firstDay,  DateTime lastDay,  DateTime rangeStart,  DateTime rangeEnd,  CsvExportStatus status,  int? exportedCount)  ready,}) {final _that = this;
switch (_that) {
case CsvExportEmpty():
return empty();case CsvExportReady():
return ready(_that.firstDay,_that.lastDay,_that.rangeStart,_that.rangeEnd,_that.status,_that.exportedCount);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  empty,TResult? Function( DateTime firstDay,  DateTime lastDay,  DateTime rangeStart,  DateTime rangeEnd,  CsvExportStatus status,  int? exportedCount)?  ready,}) {final _that = this;
switch (_that) {
case CsvExportEmpty() when empty != null:
return empty();case CsvExportReady() when ready != null:
return ready(_that.firstDay,_that.lastDay,_that.rangeStart,_that.rangeEnd,_that.status,_that.exportedCount);case _:
  return null;

}
}

}

/// @nodoc


class CsvExportEmpty implements CsvExportState {
  const CsvExportEmpty();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvExportEmpty);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'CsvExportState.empty()';
}


}




/// @nodoc


class CsvExportReady implements CsvExportState {
  const CsvExportReady({required this.firstDay, required this.lastDay, required this.rangeStart, required this.rangeEnd, this.status = CsvExportStatus.idle, this.exportedCount});
  

/// Days of the earliest and latest transaction: the picker's bounds
/// and the default range.
 final  DateTime firstDay;
 final  DateTime lastDay;
/// The chosen range, both days included.
 final  DateTime rangeStart;
 final  DateTime rangeEnd;
@JsonKey() final  CsvExportStatus status;
/// Rows written by the last export; set when [status] is done.
 final  int? exportedCount;

/// Create a copy of CsvExportState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$CsvExportReadyCopyWith<CsvExportReady> get copyWith => _$CsvExportReadyCopyWithImpl<CsvExportReady>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is CsvExportReady&&(identical(other.firstDay, firstDay) || other.firstDay == firstDay)&&(identical(other.lastDay, lastDay) || other.lastDay == lastDay)&&(identical(other.rangeStart, rangeStart) || other.rangeStart == rangeStart)&&(identical(other.rangeEnd, rangeEnd) || other.rangeEnd == rangeEnd)&&(identical(other.status, status) || other.status == status)&&(identical(other.exportedCount, exportedCount) || other.exportedCount == exportedCount));
}


@override
int get hashCode {
    return Object.hash(runtimeType,firstDay,lastDay,rangeStart,rangeEnd,status,exportedCount);
}

@override
String toString() {
    return 'CsvExportState.ready(firstDay: $firstDay, lastDay: $lastDay, rangeStart: $rangeStart, rangeEnd: $rangeEnd, status: $status, exportedCount: $exportedCount)';
}


}

/// @nodoc
abstract mixin class $CsvExportReadyCopyWith<$Res> implements $CsvExportStateCopyWith<$Res> {
  factory $CsvExportReadyCopyWith(CsvExportReady value, $Res Function(CsvExportReady) _then) = _$CsvExportReadyCopyWithImpl;
@useResult
$Res call({
 DateTime firstDay, DateTime lastDay, DateTime rangeStart, DateTime rangeEnd, CsvExportStatus status, int? exportedCount
});




}
/// @nodoc
class _$CsvExportReadyCopyWithImpl<$Res>
    implements $CsvExportReadyCopyWith<$Res> {
  _$CsvExportReadyCopyWithImpl(this._self, this._then);

  final CsvExportReady _self;
  final $Res Function(CsvExportReady) _then;

/// Create a copy of CsvExportState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? firstDay = null,Object? lastDay = null,Object? rangeStart = null,Object? rangeEnd = null,Object? status = null,Object? exportedCount = freezed,}) {
  return _then(CsvExportReady(
firstDay: null == firstDay ? _self.firstDay : firstDay // ignore: cast_nullable_to_non_nullable
as DateTime,lastDay: null == lastDay ? _self.lastDay : lastDay // ignore: cast_nullable_to_non_nullable
as DateTime,rangeStart: null == rangeStart ? _self.rangeStart : rangeStart // ignore: cast_nullable_to_non_nullable
as DateTime,rangeEnd: null == rangeEnd ? _self.rangeEnd : rangeEnd // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as CsvExportStatus,exportedCount: freezed == exportedCount ? _self.exportedCount : exportedCount // ignore: cast_nullable_to_non_nullable
as int?,
  ));
}


}

// dart format on
