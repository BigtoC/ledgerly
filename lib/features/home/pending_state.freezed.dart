// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'pending_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PendingState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PendingState()';
}


}

/// @nodoc
class $PendingStateCopyWith<$Res>  {
$PendingStateCopyWith(PendingState _, $Res Function(PendingState) __);
}


/// Adds pattern-matching-related methods to [PendingState].
extension PendingStatePatterns on PendingState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( PendingLoading value)?  loading,TResult Function( PendingEmpty value)?  empty,TResult Function( PendingData value)?  data,TResult Function( PendingError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case PendingLoading() when loading != null:
return loading(_that);case PendingEmpty() when empty != null:
return empty(_that);case PendingData() when data != null:
return data(_that);case PendingError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( PendingLoading value)  loading,required TResult Function( PendingEmpty value)  empty,required TResult Function( PendingData value)  data,required TResult Function( PendingError value)  error,}){
final _that = this;
switch (_that) {
case PendingLoading():
return loading(_that);case PendingEmpty():
return empty(_that);case PendingData():
return data(_that);case PendingError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( PendingLoading value)?  loading,TResult? Function( PendingEmpty value)?  empty,TResult? Function( PendingData value)?  data,TResult? Function( PendingError value)?  error,}){
final _that = this;
switch (_that) {
case PendingLoading() when loading != null:
return loading(_that);case PendingEmpty() when empty != null:
return empty(_that);case PendingData() when data != null:
return data(_that);case PendingError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  empty,TResult Function( List<PendingTransaction> items,  PendingSkipScheduled? skipScheduled)?  data,TResult Function( Object error,  StackTrace stack)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case PendingLoading() when loading != null:
return loading();case PendingEmpty() when empty != null:
return empty();case PendingData() when data != null:
return data(_that.items,_that.skipScheduled);case PendingError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  empty,required TResult Function( List<PendingTransaction> items,  PendingSkipScheduled? skipScheduled)  data,required TResult Function( Object error,  StackTrace stack)  error,}) {final _that = this;
switch (_that) {
case PendingLoading():
return loading();case PendingEmpty():
return empty();case PendingData():
return data(_that.items,_that.skipScheduled);case PendingError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  empty,TResult? Function( List<PendingTransaction> items,  PendingSkipScheduled? skipScheduled)?  data,TResult? Function( Object error,  StackTrace stack)?  error,}) {final _that = this;
switch (_that) {
case PendingLoading() when loading != null:
return loading();case PendingEmpty() when empty != null:
return empty();case PendingData() when data != null:
return data(_that.items,_that.skipScheduled);case PendingError() when error != null:
return error(_that.error,_that.stack);case _:
  return null;

}
}

}

/// @nodoc


class PendingLoading implements PendingState {
  const PendingLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PendingState.loading()';
}


}




/// @nodoc


class PendingEmpty implements PendingState {
  const PendingEmpty();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingEmpty);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'PendingState.empty()';
}


}




/// @nodoc


class PendingData implements PendingState {
  const PendingData({required final  List<PendingTransaction> items, required this.skipScheduled}): _items = items;
  

 final  List<PendingTransaction> _items;
 List<PendingTransaction> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  PendingSkipScheduled? skipScheduled;

/// Create a copy of PendingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingDataCopyWith<PendingData> get copyWith => _$PendingDataCopyWithImpl<PendingData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingData&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.skipScheduled, skipScheduled) || other.skipScheduled == skipScheduled));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),skipScheduled);

@override
String toString() {
  return 'PendingState.data(items: $items, skipScheduled: $skipScheduled)';
}


}

/// @nodoc
abstract mixin class $PendingDataCopyWith<$Res> implements $PendingStateCopyWith<$Res> {
  factory $PendingDataCopyWith(PendingData value, $Res Function(PendingData) _then) = _$PendingDataCopyWithImpl;
@useResult
$Res call({
 List<PendingTransaction> items, PendingSkipScheduled? skipScheduled
});




}
/// @nodoc
class _$PendingDataCopyWithImpl<$Res>
    implements $PendingDataCopyWith<$Res> {
  _$PendingDataCopyWithImpl(this._self, this._then);

  final PendingData _self;
  final $Res Function(PendingData) _then;

/// Create a copy of PendingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? items = null,Object? skipScheduled = freezed,}) {
  return _then(PendingData(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<PendingTransaction>,skipScheduled: freezed == skipScheduled ? _self.skipScheduled : skipScheduled // ignore: cast_nullable_to_non_nullable
as PendingSkipScheduled?,
  ));
}


}

/// @nodoc


class PendingError implements PendingState {
  const PendingError(this.error, this.stack);
  

 final  Object error;
 final  StackTrace stack;

/// Create a copy of PendingState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PendingErrorCopyWith<PendingError> get copyWith => _$PendingErrorCopyWithImpl<PendingError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PendingError&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stack, stack) || other.stack == stack));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stack);

@override
String toString() {
  return 'PendingState.error(error: $error, stack: $stack)';
}


}

/// @nodoc
abstract mixin class $PendingErrorCopyWith<$Res> implements $PendingStateCopyWith<$Res> {
  factory $PendingErrorCopyWith(PendingError value, $Res Function(PendingError) _then) = _$PendingErrorCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace stack
});




}
/// @nodoc
class _$PendingErrorCopyWithImpl<$Res>
    implements $PendingErrorCopyWith<$Res> {
  _$PendingErrorCopyWithImpl(this._self, this._then);

  final PendingError _self;
  final $Res Function(PendingError) _then;

/// Create a copy of PendingState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stack = null,}) {
  return _then(PendingError(
null == error ? _self.error : error ,null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

// dart format on
