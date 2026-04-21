// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'account_type.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$AccountType {

 int get id;/// Stable identity for seeded rows.
 String? get l10nKey;/// User override of the localized name.
 String? get customName;/// Optional default-currency hint. Null = no preference;
/// account-creation form falls back to
/// `user_preferences.default_currency`, then `'USD'`.
 Currency? get defaultCurrency;/// Icon-registry string key. Never `IconData`.
 String get icon;/// Index into `core/utils/color_palette.dart`. Never ARGB.
 int get color;/// Order in pickers.
 int get sortOrder;/// DB default `false`.
 bool get isArchived;
/// Create a copy of AccountType
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AccountTypeCopyWith<AccountType> get copyWith => _$AccountTypeCopyWithImpl<AccountType>(this as AccountType, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AccountType&&(identical(other.id, id) || other.id == id)&&(identical(other.l10nKey, l10nKey) || other.l10nKey == l10nKey)&&(identical(other.customName, customName) || other.customName == customName)&&(identical(other.defaultCurrency, defaultCurrency) || other.defaultCurrency == defaultCurrency)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}


@override
int get hashCode => Object.hash(runtimeType,id,l10nKey,customName,defaultCurrency,icon,color,sortOrder,isArchived);

@override
String toString() {
  return 'AccountType(id: $id, l10nKey: $l10nKey, customName: $customName, defaultCurrency: $defaultCurrency, icon: $icon, color: $color, sortOrder: $sortOrder, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class $AccountTypeCopyWith<$Res>  {
  factory $AccountTypeCopyWith(AccountType value, $Res Function(AccountType) _then) = _$AccountTypeCopyWithImpl;
@useResult
$Res call({
 int id, String? l10nKey, String? customName, Currency? defaultCurrency, String icon, int color, int sortOrder, bool isArchived
});


$CurrencyCopyWith<$Res>? get defaultCurrency;

}
/// @nodoc
class _$AccountTypeCopyWithImpl<$Res>
    implements $AccountTypeCopyWith<$Res> {
  _$AccountTypeCopyWithImpl(this._self, this._then);

  final AccountType _self;
  final $Res Function(AccountType) _then;

/// Create a copy of AccountType
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? l10nKey = freezed,Object? customName = freezed,Object? defaultCurrency = freezed,Object? icon = null,Object? color = null,Object? sortOrder = null,Object? isArchived = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,l10nKey: freezed == l10nKey ? _self.l10nKey : l10nKey // ignore: cast_nullable_to_non_nullable
as String?,customName: freezed == customName ? _self.customName : customName // ignore: cast_nullable_to_non_nullable
as String?,defaultCurrency: freezed == defaultCurrency ? _self.defaultCurrency : defaultCurrency // ignore: cast_nullable_to_non_nullable
as Currency?,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of AccountType
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CurrencyCopyWith<$Res>? get defaultCurrency {
    if (_self.defaultCurrency == null) {
    return null;
  }

  return $CurrencyCopyWith<$Res>(_self.defaultCurrency!, (value) {
    return _then(_self.copyWith(defaultCurrency: value));
  });
}
}


/// Adds pattern-matching-related methods to [AccountType].
extension AccountTypePatterns on AccountType {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _AccountType value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _AccountType() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _AccountType value)  $default,){
final _that = this;
switch (_that) {
case _AccountType():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _AccountType value)?  $default,){
final _that = this;
switch (_that) {
case _AccountType() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String? l10nKey,  String? customName,  Currency? defaultCurrency,  String icon,  int color,  int sortOrder,  bool isArchived)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _AccountType() when $default != null:
return $default(_that.id,_that.l10nKey,_that.customName,_that.defaultCurrency,_that.icon,_that.color,_that.sortOrder,_that.isArchived);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String? l10nKey,  String? customName,  Currency? defaultCurrency,  String icon,  int color,  int sortOrder,  bool isArchived)  $default,) {final _that = this;
switch (_that) {
case _AccountType():
return $default(_that.id,_that.l10nKey,_that.customName,_that.defaultCurrency,_that.icon,_that.color,_that.sortOrder,_that.isArchived);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String? l10nKey,  String? customName,  Currency? defaultCurrency,  String icon,  int color,  int sortOrder,  bool isArchived)?  $default,) {final _that = this;
switch (_that) {
case _AccountType() when $default != null:
return $default(_that.id,_that.l10nKey,_that.customName,_that.defaultCurrency,_that.icon,_that.color,_that.sortOrder,_that.isArchived);case _:
  return null;

}
}

}

/// @nodoc


class _AccountType implements AccountType {
  const _AccountType({required this.id, this.l10nKey, this.customName, this.defaultCurrency, required this.icon, required this.color, this.sortOrder = 0, this.isArchived = false});
  

@override final  int id;
/// Stable identity for seeded rows.
@override final  String? l10nKey;
/// User override of the localized name.
@override final  String? customName;
/// Optional default-currency hint. Null = no preference;
/// account-creation form falls back to
/// `user_preferences.default_currency`, then `'USD'`.
@override final  Currency? defaultCurrency;
/// Icon-registry string key. Never `IconData`.
@override final  String icon;
/// Index into `core/utils/color_palette.dart`. Never ARGB.
@override final  int color;
/// Order in pickers.
@override@JsonKey() final  int sortOrder;
/// DB default `false`.
@override@JsonKey() final  bool isArchived;

/// Create a copy of AccountType
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AccountTypeCopyWith<_AccountType> get copyWith => __$AccountTypeCopyWithImpl<_AccountType>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _AccountType&&(identical(other.id, id) || other.id == id)&&(identical(other.l10nKey, l10nKey) || other.l10nKey == l10nKey)&&(identical(other.customName, customName) || other.customName == customName)&&(identical(other.defaultCurrency, defaultCurrency) || other.defaultCurrency == defaultCurrency)&&(identical(other.icon, icon) || other.icon == icon)&&(identical(other.color, color) || other.color == color)&&(identical(other.sortOrder, sortOrder) || other.sortOrder == sortOrder)&&(identical(other.isArchived, isArchived) || other.isArchived == isArchived));
}


@override
int get hashCode => Object.hash(runtimeType,id,l10nKey,customName,defaultCurrency,icon,color,sortOrder,isArchived);

@override
String toString() {
  return 'AccountType(id: $id, l10nKey: $l10nKey, customName: $customName, defaultCurrency: $defaultCurrency, icon: $icon, color: $color, sortOrder: $sortOrder, isArchived: $isArchived)';
}


}

/// @nodoc
abstract mixin class _$AccountTypeCopyWith<$Res> implements $AccountTypeCopyWith<$Res> {
  factory _$AccountTypeCopyWith(_AccountType value, $Res Function(_AccountType) _then) = __$AccountTypeCopyWithImpl;
@override @useResult
$Res call({
 int id, String? l10nKey, String? customName, Currency? defaultCurrency, String icon, int color, int sortOrder, bool isArchived
});


@override $CurrencyCopyWith<$Res>? get defaultCurrency;

}
/// @nodoc
class __$AccountTypeCopyWithImpl<$Res>
    implements _$AccountTypeCopyWith<$Res> {
  __$AccountTypeCopyWithImpl(this._self, this._then);

  final _AccountType _self;
  final $Res Function(_AccountType) _then;

/// Create a copy of AccountType
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? l10nKey = freezed,Object? customName = freezed,Object? defaultCurrency = freezed,Object? icon = null,Object? color = null,Object? sortOrder = null,Object? isArchived = null,}) {
  return _then(_AccountType(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,l10nKey: freezed == l10nKey ? _self.l10nKey : l10nKey // ignore: cast_nullable_to_non_nullable
as String?,customName: freezed == customName ? _self.customName : customName // ignore: cast_nullable_to_non_nullable
as String?,defaultCurrency: freezed == defaultCurrency ? _self.defaultCurrency : defaultCurrency // ignore: cast_nullable_to_non_nullable
as Currency?,icon: null == icon ? _self.icon : icon // ignore: cast_nullable_to_non_nullable
as String,color: null == color ? _self.color : color // ignore: cast_nullable_to_non_nullable
as int,sortOrder: null == sortOrder ? _self.sortOrder : sortOrder // ignore: cast_nullable_to_non_nullable
as int,isArchived: null == isArchived ? _self.isArchived : isArchived // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of AccountType
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$CurrencyCopyWith<$Res>? get defaultCurrency {
    if (_self.defaultCurrency == null) {
    return null;
  }

  return $CurrencyCopyWith<$Res>(_self.defaultCurrency!, (value) {
    return _then(_self.copyWith(defaultCurrency: value));
  });
}
}

// dart format on
