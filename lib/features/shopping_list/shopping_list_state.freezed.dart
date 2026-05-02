// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shopping_list_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShoppingListState {





@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShoppingListState);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShoppingListState()';
}


}

/// @nodoc
class $ShoppingListStateCopyWith<$Res>  {
$ShoppingListStateCopyWith(ShoppingListState _, $Res Function(ShoppingListState) __);
}


/// Adds pattern-matching-related methods to [ShoppingListState].
extension ShoppingListStatePatterns on ShoppingListState {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>({TResult Function( ShoppingListLoading value)?  loading,TResult Function( ShoppingListEmpty value)?  empty,TResult Function( ShoppingListData value)?  data,TResult Function( ShoppingListError value)?  error,required TResult orElse(),}){
final _that = this;
switch (_that) {
case ShoppingListLoading() when loading != null:
return loading(_that);case ShoppingListEmpty() when empty != null:
return empty(_that);case ShoppingListData() when data != null:
return data(_that);case ShoppingListError() when error != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>({required TResult Function( ShoppingListLoading value)  loading,required TResult Function( ShoppingListEmpty value)  empty,required TResult Function( ShoppingListData value)  data,required TResult Function( ShoppingListError value)  error,}){
final _that = this;
switch (_that) {
case ShoppingListLoading():
return loading(_that);case ShoppingListEmpty():
return empty(_that);case ShoppingListData():
return data(_that);case ShoppingListError():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>({TResult? Function( ShoppingListLoading value)?  loading,TResult? Function( ShoppingListEmpty value)?  empty,TResult? Function( ShoppingListData value)?  data,TResult? Function( ShoppingListError value)?  error,}){
final _that = this;
switch (_that) {
case ShoppingListLoading() when loading != null:
return loading(_that);case ShoppingListEmpty() when empty != null:
return empty(_that);case ShoppingListData() when data != null:
return data(_that);case ShoppingListError() when error != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>({TResult Function()?  loading,TResult Function()?  empty,TResult Function( List<ShoppingListItem> items,  ShoppingListPendingDelete? pendingDelete)?  data,TResult Function( Object error,  StackTrace stack)?  error,required TResult orElse(),}) {final _that = this;
switch (_that) {
case ShoppingListLoading() when loading != null:
return loading();case ShoppingListEmpty() when empty != null:
return empty();case ShoppingListData() when data != null:
return data(_that.items,_that.pendingDelete);case ShoppingListError() when error != null:
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

@optionalTypeArgs TResult when<TResult extends Object?>({required TResult Function()  loading,required TResult Function()  empty,required TResult Function( List<ShoppingListItem> items,  ShoppingListPendingDelete? pendingDelete)  data,required TResult Function( Object error,  StackTrace stack)  error,}) {final _that = this;
switch (_that) {
case ShoppingListLoading():
return loading();case ShoppingListEmpty():
return empty();case ShoppingListData():
return data(_that.items,_that.pendingDelete);case ShoppingListError():
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>({TResult? Function()?  loading,TResult? Function()?  empty,TResult? Function( List<ShoppingListItem> items,  ShoppingListPendingDelete? pendingDelete)?  data,TResult? Function( Object error,  StackTrace stack)?  error,}) {final _that = this;
switch (_that) {
case ShoppingListLoading() when loading != null:
return loading();case ShoppingListEmpty() when empty != null:
return empty();case ShoppingListData() when data != null:
return data(_that.items,_that.pendingDelete);case ShoppingListError() when error != null:
return error(_that.error,_that.stack);case _:
  return null;

}
}

}

/// @nodoc


class ShoppingListLoading implements ShoppingListState {
  const ShoppingListLoading();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShoppingListLoading);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShoppingListState.loading()';
}


}




/// @nodoc


class ShoppingListEmpty implements ShoppingListState {
  const ShoppingListEmpty();
  






@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShoppingListEmpty);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
  return 'ShoppingListState.empty()';
}


}




/// @nodoc


class ShoppingListData implements ShoppingListState {
  const ShoppingListData({required final  List<ShoppingListItem> items, required this.pendingDelete}): _items = items;
  

 final  List<ShoppingListItem> _items;
 List<ShoppingListItem> get items {
  if (_items is EqualUnmodifiableListView) return _items;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_items);
}

 final  ShoppingListPendingDelete? pendingDelete;

/// Create a copy of ShoppingListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShoppingListDataCopyWith<ShoppingListData> get copyWith => _$ShoppingListDataCopyWithImpl<ShoppingListData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShoppingListData&&const DeepCollectionEquality().equals(other._items, _items)&&(identical(other.pendingDelete, pendingDelete) || other.pendingDelete == pendingDelete));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(_items),pendingDelete);

@override
String toString() {
  return 'ShoppingListState.data(items: $items, pendingDelete: $pendingDelete)';
}


}

/// @nodoc
abstract mixin class $ShoppingListDataCopyWith<$Res> implements $ShoppingListStateCopyWith<$Res> {
  factory $ShoppingListDataCopyWith(ShoppingListData value, $Res Function(ShoppingListData) _then) = _$ShoppingListDataCopyWithImpl;
@useResult
$Res call({
 List<ShoppingListItem> items, ShoppingListPendingDelete? pendingDelete
});




}
/// @nodoc
class _$ShoppingListDataCopyWithImpl<$Res>
    implements $ShoppingListDataCopyWith<$Res> {
  _$ShoppingListDataCopyWithImpl(this._self, this._then);

  final ShoppingListData _self;
  final $Res Function(ShoppingListData) _then;

/// Create a copy of ShoppingListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? items = null,Object? pendingDelete = freezed,}) {
  return _then(ShoppingListData(
items: null == items ? _self._items : items // ignore: cast_nullable_to_non_nullable
as List<ShoppingListItem>,pendingDelete: freezed == pendingDelete ? _self.pendingDelete : pendingDelete // ignore: cast_nullable_to_non_nullable
as ShoppingListPendingDelete?,
  ));
}


}

/// @nodoc


class ShoppingListError implements ShoppingListState {
  const ShoppingListError(this.error, this.stack);
  

 final  Object error;
 final  StackTrace stack;

/// Create a copy of ShoppingListState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShoppingListErrorCopyWith<ShoppingListError> get copyWith => _$ShoppingListErrorCopyWithImpl<ShoppingListError>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShoppingListError&&const DeepCollectionEquality().equals(other.error, error)&&(identical(other.stack, stack) || other.stack == stack));
}


@override
int get hashCode => Object.hash(runtimeType,const DeepCollectionEquality().hash(error),stack);

@override
String toString() {
  return 'ShoppingListState.error(error: $error, stack: $stack)';
}


}

/// @nodoc
abstract mixin class $ShoppingListErrorCopyWith<$Res> implements $ShoppingListStateCopyWith<$Res> {
  factory $ShoppingListErrorCopyWith(ShoppingListError value, $Res Function(ShoppingListError) _then) = _$ShoppingListErrorCopyWithImpl;
@useResult
$Res call({
 Object error, StackTrace stack
});




}
/// @nodoc
class _$ShoppingListErrorCopyWithImpl<$Res>
    implements $ShoppingListErrorCopyWith<$Res> {
  _$ShoppingListErrorCopyWithImpl(this._self, this._then);

  final ShoppingListError _self;
  final $Res Function(ShoppingListError) _then;

/// Create a copy of ShoppingListState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? error = null,Object? stack = null,}) {
  return _then(ShoppingListError(
null == error ? _self.error : error ,null == stack ? _self.stack : stack // ignore: cast_nullable_to_non_nullable
as StackTrace,
  ));
}


}

// dart format on
