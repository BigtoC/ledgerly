// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'splash_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SplashLoading value)?  loading,TResult Function( SplashData value)?  data,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SplashLoading() when loading != null:
return loading(_that);case SplashData() when data != null:
return data(_that);case _:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SplashLoading value)  loading,required TResult Function( SplashData value)  data,}){
final _that = this;
switch (_that) {
case SplashLoading():
return loading(_that);case SplashData():
return data(_that);}
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SplashLoading value)?  loading,TResult? Function( SplashData value)?  data,}){
final _that = this;
switch (_that) {
case SplashLoading() when loading != null:
return loading(_that);case SplashData() when data != null:
return data(_that);case _:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function( DateTime startDate,  int dayCount,  List<SplashTextSegment> displayTextSegments,  String buttonLabel)?  data,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SplashLoading() when loading != null:
return loading();case SplashData() when data != null:
return data(_that.startDate,_that.dayCount,_that.displayTextSegments,_that.buttonLabel);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function( DateTime startDate,  int dayCount,  List<SplashTextSegment> displayTextSegments,  String buttonLabel)  data,}) {final _that = this;
switch (_that) {
case SplashLoading():
return loading();case SplashData():
return data(_that.startDate,_that.dayCount,_that.displayTextSegments,_that.buttonLabel);}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function( DateTime startDate,  int dayCount,  List<SplashTextSegment> displayTextSegments,  String buttonLabel)?  data,}) {final _that = this;
switch (_that) {
case SplashLoading() when loading != null:
return loading();case SplashData() when data != null:
return data(_that.startDate,_that.dayCount,_that.displayTextSegments,_that.buttonLabel);case _:
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
  const SplashData({required this.startDate, required this.dayCount, required  List<SplashTextSegment> displayTextSegments, required this.buttonLabel}): _displayTextSegments = displayTextSegments;
  

 final  DateTime startDate;
 final  int dayCount;
 final  List<SplashTextSegment> _displayTextSegments;
 List<SplashTextSegment> get displayTextSegments {
  if (_displayTextSegments is EqualUnmodifiableListView) return _displayTextSegments;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_displayTextSegments);
}

 final  String buttonLabel;

/// Create a copy of SplashState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SplashDataCopyWith<SplashData> get copyWith => _$SplashDataCopyWithImpl<SplashData>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SplashData&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.dayCount, dayCount) || other.dayCount == dayCount)&&const DeepCollectionEquality().equals(other.displayTextSegments, _displayTextSegments)&&(identical(other.buttonLabel, buttonLabel) || other.buttonLabel == buttonLabel));
}


@override
int get hashCode {
    return Object.hash(runtimeType,startDate,dayCount,const DeepCollectionEquality().hash(_displayTextSegments),buttonLabel);
}

@override
String toString() {
    return 'SplashState.data(startDate: $startDate, dayCount: $dayCount, displayTextSegments: $displayTextSegments, buttonLabel: $buttonLabel)';
}


}

/// @nodoc
abstract mixin class $SplashDataCopyWith<$Res> implements $SplashStateCopyWith<$Res> {
  factory $SplashDataCopyWith(SplashData value, $Res Function(SplashData) _then) = _$SplashDataCopyWithImpl;
@useResult
$Res call({
 DateTime startDate, int dayCount, List<SplashTextSegment> displayTextSegments, String buttonLabel
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
@pragma('vm:prefer-inline') $Res call({Object? startDate = null,Object? dayCount = null,Object? displayTextSegments = null,Object? buttonLabel = null,}) {
  return _then(SplashData(
startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as DateTime,dayCount: null == dayCount ? _self.dayCount : dayCount // ignore: cast_nullable_to_non_nullable
as int,displayTextSegments: null == displayTextSegments ? _self._displayTextSegments : displayTextSegments // ignore: cast_nullable_to_non_nullable
as List<SplashTextSegment>,buttonLabel: null == buttonLabel ? _self.buttonLabel : buttonLabel // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}

/// @nodoc
mixin _$SetSplashStartDateOutcome {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SetSplashStartDateOutcome);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SetSplashStartDateOutcome()';
}


}

/// @nodoc
class $SetSplashStartDateOutcomeCopyWith<$Res>  {
$SetSplashStartDateOutcomeCopyWith(SetSplashStartDateOutcome _, $Res Function(SetSplashStartDateOutcome) __);
}


/// Adds pattern-matching-related methods to [SetSplashStartDateOutcome].
extension SetSplashStartDateOutcomePatterns on SetSplashStartDateOutcome {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( SetSplashStartDateOk value)?  ok,TResult Function( SetSplashStartDateFailed value)?  failed,required TResult orElse(),}){
final _that = this;
switch (_that) {
case SetSplashStartDateOk() when ok != null:
return ok(_that);case SetSplashStartDateFailed() when failed != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( SetSplashStartDateOk value)  ok,required TResult Function( SetSplashStartDateFailed value)  failed,}){
final _that = this;
switch (_that) {
case SetSplashStartDateOk():
return ok(_that);case SetSplashStartDateFailed():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( SetSplashStartDateOk value)?  ok,TResult? Function( SetSplashStartDateFailed value)?  failed,}){
final _that = this;
switch (_that) {
case SetSplashStartDateOk() when ok != null:
return ok(_that);case SetSplashStartDateFailed() when failed != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  ok,TResult Function()?  failed,required TResult orElse(),}) {final _that = this;
switch (_that) {
case SetSplashStartDateOk() when ok != null:
return ok();case SetSplashStartDateFailed() when failed != null:
return failed();case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  ok,required TResult Function()  failed,}) {final _that = this;
switch (_that) {
case SetSplashStartDateOk():
return ok();case SetSplashStartDateFailed():
return failed();}
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  ok,TResult? Function()?  failed,}) {final _that = this;
switch (_that) {
case SetSplashStartDateOk() when ok != null:
return ok();case SetSplashStartDateFailed() when failed != null:
return failed();case _:
  return null;

}
}

}

/// @nodoc


class SetSplashStartDateOk implements SetSplashStartDateOutcome {
  const SetSplashStartDateOk();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SetSplashStartDateOk);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SetSplashStartDateOutcome.ok()';
}


}




/// @nodoc


class SetSplashStartDateFailed implements SetSplashStartDateOutcome {
  const SetSplashStartDateFailed();
  






@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SetSplashStartDateFailed);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'SetSplashStartDateOutcome.failed()';
}


}




// dart format on
