// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shopping_list_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$ShoppingListItem {

 int get id; int get categoryId; int get accountId; String? get memo;/// Null for zero-amount drafts. If non-null, [draftCurrencyCode] is
/// also non-null.
 int? get draftAmountMinorUnits;/// Null for zero-amount drafts. If non-null, [draftAmountMinorUnits] is
/// also non-null.
 String? get draftCurrencyCode;/// The date the user plans to make the transaction.
 DateTime get draftDate; DateTime get createdAt; DateTime get updatedAt;
/// Create a copy of ShoppingListItem
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ShoppingListItemCopyWith<ShoppingListItem> get copyWith => _$ShoppingListItemCopyWithImpl<ShoppingListItem>(this as ShoppingListItem, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is ShoppingListItem&&(identical(other.id, id) || other.id == id)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.draftAmountMinorUnits, draftAmountMinorUnits) || other.draftAmountMinorUnits == draftAmountMinorUnits)&&(identical(other.draftCurrencyCode, draftCurrencyCode) || other.draftCurrencyCode == draftCurrencyCode)&&(identical(other.draftDate, draftDate) || other.draftDate == draftDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,categoryId,accountId,memo,draftAmountMinorUnits,draftCurrencyCode,draftDate,createdAt,updatedAt);

@override
String toString() {
  return 'ShoppingListItem(id: $id, categoryId: $categoryId, accountId: $accountId, memo: $memo, draftAmountMinorUnits: $draftAmountMinorUnits, draftCurrencyCode: $draftCurrencyCode, draftDate: $draftDate, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class $ShoppingListItemCopyWith<$Res>  {
  factory $ShoppingListItemCopyWith(ShoppingListItem value, $Res Function(ShoppingListItem) _then) = _$ShoppingListItemCopyWithImpl;
@useResult
$Res call({
 int id, int categoryId, int accountId, String? memo, int? draftAmountMinorUnits, String? draftCurrencyCode, DateTime draftDate, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class _$ShoppingListItemCopyWithImpl<$Res>
    implements $ShoppingListItemCopyWith<$Res> {
  _$ShoppingListItemCopyWithImpl(this._self, this._then);

  final ShoppingListItem _self;
  final $Res Function(ShoppingListItem) _then;

/// Create a copy of ShoppingListItem
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? categoryId = null,Object? accountId = null,Object? memo = freezed,Object? draftAmountMinorUnits = freezed,Object? draftCurrencyCode = freezed,Object? draftDate = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,draftAmountMinorUnits: freezed == draftAmountMinorUnits ? _self.draftAmountMinorUnits : draftAmountMinorUnits // ignore: cast_nullable_to_non_nullable
as int?,draftCurrencyCode: freezed == draftCurrencyCode ? _self.draftCurrencyCode : draftCurrencyCode // ignore: cast_nullable_to_non_nullable
as String?,draftDate: null == draftDate ? _self.draftDate : draftDate // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [ShoppingListItem].
extension ShoppingListItemPatterns on ShoppingListItem {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _ShoppingListItem value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _ShoppingListItem() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _ShoppingListItem value)  $default,){
final _that = this;
switch (_that) {
case _ShoppingListItem():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _ShoppingListItem value)?  $default,){
final _that = this;
switch (_that) {
case _ShoppingListItem() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  int categoryId,  int accountId,  String? memo,  int? draftAmountMinorUnits,  String? draftCurrencyCode,  DateTime draftDate,  DateTime createdAt,  DateTime updatedAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _ShoppingListItem() when $default != null:
return $default(_that.id,_that.categoryId,_that.accountId,_that.memo,_that.draftAmountMinorUnits,_that.draftCurrencyCode,_that.draftDate,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  int categoryId,  int accountId,  String? memo,  int? draftAmountMinorUnits,  String? draftCurrencyCode,  DateTime draftDate,  DateTime createdAt,  DateTime updatedAt)  $default,) {final _that = this;
switch (_that) {
case _ShoppingListItem():
return $default(_that.id,_that.categoryId,_that.accountId,_that.memo,_that.draftAmountMinorUnits,_that.draftCurrencyCode,_that.draftDate,_that.createdAt,_that.updatedAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  int categoryId,  int accountId,  String? memo,  int? draftAmountMinorUnits,  String? draftCurrencyCode,  DateTime draftDate,  DateTime createdAt,  DateTime updatedAt)?  $default,) {final _that = this;
switch (_that) {
case _ShoppingListItem() when $default != null:
return $default(_that.id,_that.categoryId,_that.accountId,_that.memo,_that.draftAmountMinorUnits,_that.draftCurrencyCode,_that.draftDate,_that.createdAt,_that.updatedAt);case _:
  return null;

}
}

}

/// @nodoc


class _ShoppingListItem implements ShoppingListItem {
  const _ShoppingListItem({required this.id, required this.categoryId, required this.accountId, this.memo, this.draftAmountMinorUnits, this.draftCurrencyCode, required this.draftDate, required this.createdAt, required this.updatedAt});
  

@override final  int id;
@override final  int categoryId;
@override final  int accountId;
@override final  String? memo;
/// Null for zero-amount drafts. If non-null, [draftCurrencyCode] is
/// also non-null.
@override final  int? draftAmountMinorUnits;
/// Null for zero-amount drafts. If non-null, [draftAmountMinorUnits] is
/// also non-null.
@override final  String? draftCurrencyCode;
/// The date the user plans to make the transaction.
@override final  DateTime draftDate;
@override final  DateTime createdAt;
@override final  DateTime updatedAt;

/// Create a copy of ShoppingListItem
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$ShoppingListItemCopyWith<_ShoppingListItem> get copyWith => __$ShoppingListItemCopyWithImpl<_ShoppingListItem>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _ShoppingListItem&&(identical(other.id, id) || other.id == id)&&(identical(other.categoryId, categoryId) || other.categoryId == categoryId)&&(identical(other.accountId, accountId) || other.accountId == accountId)&&(identical(other.memo, memo) || other.memo == memo)&&(identical(other.draftAmountMinorUnits, draftAmountMinorUnits) || other.draftAmountMinorUnits == draftAmountMinorUnits)&&(identical(other.draftCurrencyCode, draftCurrencyCode) || other.draftCurrencyCode == draftCurrencyCode)&&(identical(other.draftDate, draftDate) || other.draftDate == draftDate)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,categoryId,accountId,memo,draftAmountMinorUnits,draftCurrencyCode,draftDate,createdAt,updatedAt);

@override
String toString() {
  return 'ShoppingListItem(id: $id, categoryId: $categoryId, accountId: $accountId, memo: $memo, draftAmountMinorUnits: $draftAmountMinorUnits, draftCurrencyCode: $draftCurrencyCode, draftDate: $draftDate, createdAt: $createdAt, updatedAt: $updatedAt)';
}


}

/// @nodoc
abstract mixin class _$ShoppingListItemCopyWith<$Res> implements $ShoppingListItemCopyWith<$Res> {
  factory _$ShoppingListItemCopyWith(_ShoppingListItem value, $Res Function(_ShoppingListItem) _then) = __$ShoppingListItemCopyWithImpl;
@override @useResult
$Res call({
 int id, int categoryId, int accountId, String? memo, int? draftAmountMinorUnits, String? draftCurrencyCode, DateTime draftDate, DateTime createdAt, DateTime updatedAt
});




}
/// @nodoc
class __$ShoppingListItemCopyWithImpl<$Res>
    implements _$ShoppingListItemCopyWith<$Res> {
  __$ShoppingListItemCopyWithImpl(this._self, this._then);

  final _ShoppingListItem _self;
  final $Res Function(_ShoppingListItem) _then;

/// Create a copy of ShoppingListItem
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? categoryId = null,Object? accountId = null,Object? memo = freezed,Object? draftAmountMinorUnits = freezed,Object? draftCurrencyCode = freezed,Object? draftDate = null,Object? createdAt = null,Object? updatedAt = null,}) {
  return _then(_ShoppingListItem(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,categoryId: null == categoryId ? _self.categoryId : categoryId // ignore: cast_nullable_to_non_nullable
as int,accountId: null == accountId ? _self.accountId : accountId // ignore: cast_nullable_to_non_nullable
as int,memo: freezed == memo ? _self.memo : memo // ignore: cast_nullable_to_non_nullable
as String?,draftAmountMinorUnits: freezed == draftAmountMinorUnits ? _self.draftAmountMinorUnits : draftAmountMinorUnits // ignore: cast_nullable_to_non_nullable
as int?,draftCurrencyCode: freezed == draftCurrencyCode ? _self.draftCurrencyCode : draftCurrencyCode // ignore: cast_nullable_to_non_nullable
as String?,draftDate: null == draftDate ? _self.draftDate : draftDate // ignore: cast_nullable_to_non_nullable
as DateTime,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,updatedAt: null == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
